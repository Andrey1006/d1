
import Combine
import Foundation
import SwiftUI

@MainActor
final class PracticeDataStore: ObservableObject {
    private enum Keys {
        static let types = "ps.practiceTypes"
        static let sessions = "ps.sessions"
        static let templates = "ps.sessionTemplates"
        static let customCoeffs = "ps.customCoefficients"
        static let reportingPeriod = "ps.reportingPeriod"
        static let dailyGoalMinutes = "ps.dailyGoalMinutes"
    }

    @Published private(set) var practiceTypes: [PracticeType] = []
    @Published private(set) var sessions: [PracticeSession] = []
    @Published private(set) var sessionTemplates: [SessionTemplate] = []
    @Published private(set) var customCoefficients: [Double] = []
    @Published var reportingPeriod: ReportingPeriod = .all
    @Published var dailyGoalMinutes: Int = 20

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        load()
        if practiceTypes.isEmpty {
            seedDefaults()
        }
    }

    func setReportingPeriod(_ period: ReportingPeriod) {
        reportingPeriod = period
        save()
    }

    func practiceTypeName(for id: UUID) -> String {
        practiceTypes.first { $0.id == id }?.name ?? "Unknown type"
    }

    func coefficientLabel(_ value: Double) -> String {
        PracticeCoefficient.presets.first { abs($0.value - value) < 0.001 }?.shortLabel
            ?? String(format: "%.2f×", value)
    }

    func coefficientDetail(for value: Double) -> String {
        PracticeCoefficient.presets.first { abs($0.value - value) < 0.001 }?.detail
            ?? "Custom coefficient"
    }

    func sortedCoefficientChoices() -> [Double] {
        var seen = Set<Double>()
        var result: [Double] = []
        for v in PracticeCoefficient.presets.map(\.value) {
            let r = AnalyticsService.roundCoefficient(v)
            if !seen.contains(r) {
                seen.insert(r)
                result.append(r)
            }
        }
        for c in customCoefficients {
            let r = AnalyticsService.roundCoefficient(c)
            if !seen.contains(r) {
                seen.insert(r)
                result.append(r)
            }
        }
        for s in sessions.map(\.coefficient) {
            let r = AnalyticsService.roundCoefficient(s)
            if !seen.contains(r) {
                seen.insert(r)
                result.append(r)
            }
        }
        return result.sorted()
    }

    func journalCoefficientFilters() -> [CoefficientFilter] {
        [.all] + sortedCoefficientChoices().map { CoefficientFilter.value($0) }
    }

    func sessions(in period: ReportingPeriod, analyticsOnly: Bool) -> [PracticeSession] {
        let base = analyticsOnly ? sessions.filter { !$0.excludeFromAnalytics } : sessions
        return base.filter { period.contains($0.endedAt) }
    }

    var analyticsSessions: [PracticeSession] {
        sessions.filter { !$0.excludeFromAnalytics }
    }

    var analyticsSessionsInReportingPeriod: [PracticeSession] {
        sessions(in: reportingPeriod, analyticsOnly: true)
    }

    var baselineSessionCount: Int {
        analyticsSessionsInReportingPeriod.filter { abs($0.coefficient - 1.0) < 0.001 }.count
    }

    func recentSessionCombos(limit: Int = 5) -> [(practiceTypeId: UUID, coefficient: Double)] {
        var seen = Set<String>()
        var result: [(UUID, Double)] = []
        for s in sessions {
            let key = "\(s.practiceTypeId.uuidString)_\(AnalyticsService.roundCoefficient(s.coefficient))"
            if seen.insert(key).inserted {
                result.append((s.practiceTypeId, s.coefficient))
            }
            if result.count >= limit { break }
        }
        return result
    }

    func addSession(_ session: PracticeSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func updateSession(_ session: PracticeSession) {
        guard let idx = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[idx] = session
        save()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        save()
    }

    func addSessionTemplate(title: String, practiceTypeId: UUID, coefficient: Double, targetDurationSeconds: Int?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Template" : trimmed
        let t = SessionTemplate(
            title: name,
            practiceTypeId: practiceTypeId,
            coefficient: AnalyticsService.roundCoefficient(coefficient),
            targetDurationSeconds: targetDurationSeconds
        )
        sessionTemplates.insert(t, at: 0)
        save()
    }

    func deleteSessionTemplate(id: UUID) {
        sessionTemplates.removeAll { $0.id == id }
        save()
    }

    func addCustomCoefficient(_ raw: Double) {
        let v = min(10, max(0.1, AnalyticsService.roundCoefficient(raw)))
        if PracticeCoefficient.presets.contains(where: { abs($0.value - v) < 0.001 }) {
            return
        }
        if customCoefficients.contains(where: { abs($0 - v) < 0.001 }) {
            return
        }
        customCoefficients.append(v)
        customCoefficients.sort()
        save()
    }

    func removeCustomCoefficient(_ value: Double) {
        customCoefficients.removeAll { abs($0 - value) < 0.001 }
        save()
    }

    func addPracticeType(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        practiceTypes.append(PracticeType(name: trimmed))
        save()
    }

    func updatePracticeType(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = practiceTypes.firstIndex(where: { $0.id == id }) else { return }
        practiceTypes[idx].name = trimmed
        save()
    }

    func deletePracticeType(id: UUID) {
        sessions.removeAll { $0.practiceTypeId == id }
        practiceTypes.removeAll { $0.id == id }
        sessionTemplates.removeAll { $0.practiceTypeId == id }
        save()
    }

    func resetAllData() {
        practiceTypes = []
        sessions = []
        sessionTemplates = []
        customCoefficients = []
        reportingPeriod = .all
        dailyGoalMinutes = 20
        defaults.removeObject(forKey: Keys.types)
        defaults.removeObject(forKey: Keys.sessions)
        defaults.removeObject(forKey: Keys.templates)
        defaults.removeObject(forKey: Keys.customCoeffs)
        defaults.removeObject(forKey: Keys.reportingPeriod)
        defaults.removeObject(forKey: Keys.dailyGoalMinutes)
        seedDefaults()
        save()
    }

    func setDailyGoalMinutes(_ minutes: Int) {
        dailyGoalMinutes = max(1, min(600, minutes))
        save()
    }

    var dailyGoalSeconds: Int {
        max(60, dailyGoalMinutes * 60)
    }

    var todayPracticeSeconds: Int {
        totalPracticeSeconds(on: Date())
    }

    var todayProgress: Double {
        min(1, Double(todayPracticeSeconds) / Double(dailyGoalSeconds))
    }

    var todayGoalMet: Bool {
        todayPracticeSeconds >= dailyGoalSeconds
    }

    var currentStreakDays: Int {
        streakEnding(on: Date())
    }

    var bestStreakDays: Int {
        bestStreak()
    }

    private func totalPracticeSeconds(on date: Date) -> Int {
        let day = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { return 0 }
        return sessions
            .filter { $0.endedAt >= day && $0.endedAt < nextDay }
            .reduce(0) { $0 + max(0, $1.durationSeconds) }
    }

    private func goalMet(on date: Date) -> Bool {
        totalPracticeSeconds(on: date) >= dailyGoalSeconds
    }

    private func streakEnding(on date: Date) -> Int {
        var count = 0
        var cursor = calendar.startOfDay(for: date)
        while true {
            if goalMet(on: cursor) {
                count += 1
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    private func bestStreak() -> Int {
        var daysWithGoal: Set<Date> = []
        for s in sessions {
            let d = calendar.startOfDay(for: s.endedAt)
            if goalMet(on: d) {
                daysWithGoal.insert(d)
            }
        }
        if daysWithGoal.isEmpty { return 0 }
        let sorted = daysWithGoal.sorted(by: >)

        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let cur = sorted[i]
            if let expected = calendar.date(byAdding: .day, value: -1, to: prev),
               calendar.isDate(cur, inSameDayAs: expected) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    private func seedDefaults() {
        practiceTypes = [
            PracticeType(name: "Technique"),
            PracticeType(name: "Repertoire"),
            PracticeType(name: "Speed / endurance"),
            PracticeType(name: "Theory / analysis"),
        ]
        save()
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = defaults.data(forKey: Keys.types),
           let decoded = try? decoder.decode([PracticeType].self, from: data) {
            practiceTypes = decoded
        }
        if let data = defaults.data(forKey: Keys.sessions),
           let decoded = try? decoder.decode([PracticeSession].self, from: data) {
            sessions = decoded.sorted { $0.endedAt > $1.endedAt }
        }
        if let data = defaults.data(forKey: Keys.templates),
           let decoded = try? decoder.decode([SessionTemplate].self, from: data) {
            sessionTemplates = decoded
        }
        if let data = defaults.data(forKey: Keys.customCoeffs),
           let decoded = try? decoder.decode([Double].self, from: data) {
            customCoefficients = decoded.sorted()
        }
        if let raw = defaults.string(forKey: Keys.reportingPeriod),
           let p = ReportingPeriod(rawValue: raw) {
            reportingPeriod = p
        }
        let goal = defaults.integer(forKey: Keys.dailyGoalMinutes)
        if goal > 0 {
            dailyGoalMinutes = goal
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(practiceTypes) {
            defaults.set(data, forKey: Keys.types)
        }
        if let data = try? encoder.encode(sessions) {
            defaults.set(data, forKey: Keys.sessions)
        }
        if let data = try? encoder.encode(sessionTemplates) {
            defaults.set(data, forKey: Keys.templates)
        }
        if let data = try? encoder.encode(customCoefficients) {
            defaults.set(data, forKey: Keys.customCoeffs)
        }
        defaults.set(reportingPeriod.rawValue, forKey: Keys.reportingPeriod)
        defaults.set(dailyGoalMinutes, forKey: Keys.dailyGoalMinutes)
    }
}
