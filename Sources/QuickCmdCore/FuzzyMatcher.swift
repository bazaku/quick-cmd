import Foundation

public enum FuzzyMatcher {
    /// Subsequence match, case-insensitive. Returns nil if `query` is not a
    /// subsequence of `candidate`. Higher score = better: rewards consecutive
    /// runs and matches near the start of the string.
    public static func score(_ candidate: String, query: String) -> Int? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }

        let hay = Array(candidate.lowercased())
        let needle = Array(trimmed.lowercased())

        var total = 0
        var hayIndex = 0
        var previousMatch = -2   // for consecutive-run detection

        for target in needle {
            var found = false
            while hayIndex < hay.count {
                if hay[hayIndex] == target {
                    // Earlier matches score higher.
                    total += max(0, 20 - hayIndex)
                    // Adjacent matches score a consecutive-run bonus.
                    if hayIndex == previousMatch + 1 { total += 15 }
                    previousMatch = hayIndex
                    hayIndex += 1
                    found = true
                    break
                }
                hayIndex += 1
            }
            if !found { return nil }
        }
        return total
    }

    public static func filter(_ commands: [Command], query: String) -> [Command] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return commands }

        return commands
            .enumerated()
            .compactMap { index, command -> (Int, Int, Command)? in
                guard let s = score(command.name, query: trimmed) else { return nil }
                return (s, index, command)
            }
            // Descending score; ties keep original order (stable via index).
            .sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 < $1.1 }
            .map(\.2)
    }
}
