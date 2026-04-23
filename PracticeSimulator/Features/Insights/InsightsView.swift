
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: PracticeDataStore

    private var pool: [PracticeSession] {
        store.analyticsSessionsInReportingPeriod
    }

    private var items: [InsightItem] {
        AnalyticsService.insights(sessions: pool, labelForCoefficient: store.coefficientLabel)
    }

    private var experiments: [ExperimentSuggestion] {
        ExperimentSuggestionsService.suggestions(sessions: pool, labelForCoefficient: store.coefficientLabel)
    }

    var body: some View {
        Group {
            if items.isEmpty {
                Text("Not enough data for insights yet.")
                    .foregroundStyle(PSTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PSCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("What to try")
                                        .font(.headline)
                                        .foregroundStyle(PSTheme.textPrimary)
                                    Spacer()
                                    Text("Period: \(store.reportingPeriod.title)")
                                        .font(.caption2)
                                        .foregroundStyle(PSTheme.accent)
                                }
                                Text("Short experiments to get comparable data faster.")
                                    .font(.caption)
                                    .foregroundStyle(PSTheme.textSecondary)
                                ForEach(experiments) { exp in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exp.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(PSTheme.textPrimary)
                                        Text(exp.detail)
                                            .font(.footnote)
                                            .foregroundStyle(PSTheme.textSecondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }

                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                NavigationLink {
                                    InsightDetailView(item: item)
                                } label: {
                                    insightRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .psHiddenScrollIndicators()
            }
        }
        .psScreenBackground()
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Period", selection: Binding(
                        get: { store.reportingPeriod },
                        set: { store.setReportingPeriod($0) }
                    )) {
                        ForEach(ReportingPeriod.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(PSTheme.accent)
                }
            }
        }
    }

    private func insightRow(_ item: InsightItem) -> some View {
        PSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(PSTheme.textPrimary)
                Text(item.message)
                    .font(.footnote)
                    .foregroundStyle(PSTheme.textSecondary)
                    .lineLimit(3)
                Text("Sample: \(item.sampleCount) sessions")
                    .font(.caption2)
                    .foregroundStyle(PSTheme.textSecondary.opacity(0.9))
            }
        }
    }
}

struct InsightDetailView: View {
    @EnvironmentObject private var store: PracticeDataStore
    let item: InsightItem

    private var pool: [PracticeSession] {
        store.analyticsSessionsInReportingPeriod
    }

    private var relatedSessions: [PracticeSession] {
        InsightSessionResolver.sessions(for: item, in: pool)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(PSTheme.textPrimary)
                        Text(item.message)
                            .foregroundStyle(PSTheme.textSecondary)
                        Divider()
                            .background(PSTheme.cardStroke)
                        Text("Sample: \(item.sampleCount) sessions (period: \(store.reportingPeriod.title))")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                        if let c = item.relatedCoefficient {
                            Text("Related coefficient: \(store.coefficientLabel(c))")
                                .font(.caption)
                                .foregroundStyle(PSTheme.accent)
                        }
                    }
                }

                if !relatedSessions.isEmpty {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sessions in sample")
                                .font(.headline)
                                .foregroundStyle(PSTheme.textPrimary)
                            ForEach(relatedSessions.prefix(80)) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(store.practiceTypeName(for: session.practiceTypeId))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(PSTheme.textPrimary)
                                            Text(TimeFormatting.shortRelative(session.endedAt))
                                                .font(.caption2)
                                                .foregroundStyle(PSTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text(store.coefficientLabel(session.coefficient))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(PSTheme.accent)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(PSTheme.textSecondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            if relatedSessions.count > 80 {
                                Text("Showing first 80 of \(relatedSessions.count).")
                                    .font(.caption2)
                                    .foregroundStyle(PSTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .psHiddenScrollIndicators()
        .psScreenBackground()
        .psPushHidesTabBar()
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
