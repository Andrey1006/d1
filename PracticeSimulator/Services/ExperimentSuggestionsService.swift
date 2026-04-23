
import Foundation

enum ExperimentSuggestionsService {
    static func suggestions(
        sessions: [PracticeSession],
        labelForCoefficient: (Double) -> String
    ) -> [ExperimentSuggestion] {
        var out: [ExperimentSuggestion] = []
        let baseline = sessions.filter { abs($0.coefficient - 1.0) < 0.001 }
        let has07 = sessions.contains { abs($0.coefficient - 0.7) < 0.001 }
        let has15 = sessions.contains { abs($0.coefficient - 1.5) < 0.001 }
        let has20 = sessions.contains { abs($0.coefficient - 2.0) < 0.001 }

        if baseline.count < 5 {
            out.append(
                ExperimentSuggestion(
                    title: "Calibrate 1×",
                    detail: "Run 5 sessions at \(labelForCoefficient(1.0)) for 20–40 minutes with honest metrics — that baseline anchors comparisons."
                )
            )
        }

        if !has07 {
            out.append(
                ExperimentSuggestion(
                    title: "Try 0.7×",
                    detail: "Add 2–3 sessions at \(labelForCoefficient(0.7)) on familiar material and compare quality and fatigue to 1×."
                )
            )
        }

        if !has15 {
            out.append(
                ExperimentSuggestion(
                    title: "Load at 1.5×",
                    detail: "Try \(labelForCoefficient(1.5)) in a short block (15–25 min) and log concentration and fatigue right after."
                )
            )
        }

        if !has20, sessions.count >= 5 {
            out.append(
                ExperimentSuggestion(
                    title: "Peak 2×",
                    detail: "One controlled \(labelForCoefficient(2.0)) session plus 1× the next day — you will see rebound and recovery."
                )
            )
        }

        if out.isEmpty {
            out.append(
                ExperimentSuggestion(
                    title: "Stabilize variables",
                    detail: "Repeat the same practice type three times at different coefficients with similar duration — less noise in the data."
                )
            )
        }

        return Array(out.prefix(5))
    }
}
