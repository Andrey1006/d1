
import Foundation

enum CSVExporter {
    static func makeCSV(sessions: [PracticeSession], typeName: (UUID) -> String) -> String {
        var lines: [String] = []
        let header = "endedAt;practiceType;coefficient;durationSeconds;difficulty;concentration;fatigue;quality;excludeFromAnalytics;note"
        lines.append(header)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        for s in sessions.sorted(by: { $0.endedAt > $1.endedAt }) {
            let ended = iso.string(from: s.endedAt)
            let type = typeName(s.practiceTypeId).replacingOccurrences(of: ";", with: ",")
            let note = s.note.replacingOccurrences(of: ";", with: ",").replacingOccurrences(of: "\n", with: " ")
            let row = [
                ended,
                type,
                String(format: "%.2f", s.coefficient),
                "\(s.durationSeconds)",
                "\(s.difficulty)",
                "\(s.concentration)",
                "\(s.fatigue)",
                "\(s.quality)",
                s.excludeFromAnalytics ? "1" : "0",
                note,
            ].joined(separator: ";")
            lines.append(row)
        }
        let body = lines.joined(separator: "\n")
        return "\u{FEFF}" + body
    }

    static func writeTempCSVFile(sessions: [PracticeSession], typeName: (UUID) -> String) throws -> URL {
        let csv = makeCSV(sessions: sessions, typeName: typeName)
        let safeBase = PSTheme.appDisplayName.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeBase)_sessions.csv")
        try csv.data(using: .utf8)?.write(to: url)
        return url
    }
}
