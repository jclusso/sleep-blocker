import Foundation

@MainActor
final class RuleStore: ObservableObject {
    @Published private(set) var rules: [Rule] = []

    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent("SleepBlocker", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("rules.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        rules = (try? JSONDecoder().decode([Rule].self, from: data)) ?? []
    }

    func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(rules) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func add(_ rule: Rule) {
        let duplicate = rules.contains {
            $0.matchKey == rule.matchKey
                && $0.assertionNameGlob == rule.assertionNameGlob
                && $0.action == rule.action
        }
        if duplicate { return }
        rules.append(rule)
        save()
    }

    func remove(_ id: UUID) {
        rules.removeAll { $0.id == id }
        save()
    }

    func update(_ rule: Rule) {
        if let i = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[i] = rule
            save()
        }
    }

    func findMatch(for a: SleepAssertion) -> Rule? {
        rules.first { $0.matches(a) }
    }

    var hasRule: (SleepAssertion) -> Bool {
        { [weak self] a in self?.findMatch(for: a) != nil }
    }
}
