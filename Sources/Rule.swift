import Foundation

enum RuleAction: String, Codable, CaseIterable, Hashable {
    case notify
    case quit
    case forceSleep

    var label: String {
        switch self {
        case .notify: return "Notify"
        case .quit: return "Quit app"
        case .forceSleep: return "Force sleep"
        }
    }
}

struct Rule: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var matchKey: String
    var displayName: String
    var assertionNameGlob: String?
    var action: RuleAction
    var enabled: Bool = true
    var idleThresholdSeconds: Int? = nil

    func matches(_ a: SleepAssertion) -> Bool {
        guard enabled else { return false }
        if matchKey.hasPrefix("proc:") {
            let n = String(matchKey.dropFirst(5))
            guard a.displayName == n else { return false }
        } else {
            guard a.bundleID == matchKey else { return false }
        }
        if let pat = assertionNameGlob, !pat.isEmpty {
            return Self.glob(pat, matches: a.name)
        }
        return true
    }

    static func glob(_ pattern: String, matches s: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
            .replacingOccurrences(of: "\\?", with: ".")
        let regex = "^" + escaped + "$"
        return s.range(of: regex, options: .regularExpression) != nil
    }

    static func keyFor(_ a: SleepAssertion) -> String {
        if let b = a.bundleID { return b }
        return "proc:\(a.displayName)"
    }
}
