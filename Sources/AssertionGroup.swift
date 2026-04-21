import Foundation

struct AssertionGroup: Identifiable, Hashable {
    let items: [SleepAssertion]

    var id: String { String(pid) }
    var count: Int { items.count }
    var representative: SleepAssertion { items[0] }

    var pid: pid_t { representative.pid }
    var displayName: String { representative.displayName }
    var bundleID: String? { representative.bundleID }
    var executablePath: String? { representative.executablePath }
    var iconData: Data? { representative.iconData }
    var isSystemOwned: Bool { representative.isSystemOwned }

    var oldestCreatedAt: Date {
        items.map { $0.createdAt }.min() ?? representative.createdAt
    }

    var durationOldest: TimeInterval {
        Date().timeIntervalSince(oldestCreatedAt)
    }

    func durationOldest(at now: Date) -> TimeInterval {
        now.timeIntervalSince(oldestCreatedAt)
    }

    private static let severityRank: [String: Int] = [
        "PreventSystemSleep": 3,
        "PreventUserIdleDisplaySleep": 2,
        "NoDisplaySleepAssertion": 2,
        "PreventUserIdleSystemSleep": 1,
        "NoIdleSleepAssertion": 1,
    ]

    var primaryAssertionType: String {
        items.max(by: {
            (Self.severityRank[$0.assertionType] ?? 0) < (Self.severityRank[$1.assertionType] ?? 0)
        })?.assertionType ?? representative.assertionType
    }

    var distinctTypes: [String] {
        var seen = Set<String>(), order: [String] = []
        for a in items where !seen.contains(a.assertionType) {
            seen.insert(a.assertionType); order.append(a.assertionType)
        }
        return order
    }

    var distinctNames: [String] {
        var seen = Set<String>(), order: [String] = []
        for a in items where !seen.contains(a.name) {
            seen.insert(a.name); order.append(a.name)
        }
        return order
    }

    struct Breakdown: Hashable {
        let type: String
        let name: String
        let count: Int
        let durationOldest: TimeInterval
    }

    var breakdown: [Breakdown] {
        var buckets: [String: [SleepAssertion]] = [:]
        var order: [String] = []
        for a in items {
            let k = "\(a.assertionType)|\(a.name)"
            if buckets[k] == nil { order.append(k) }
            buckets[k, default: []].append(a)
        }
        return order.compactMap { k -> Breakdown? in
            guard let list = buckets[k], let first = list.first else { return nil }
            let oldest = list.map { $0.createdAt }.min() ?? first.createdAt
            return Breakdown(
                type: first.assertionType,
                name: first.name,
                count: list.count,
                durationOldest: Date().timeIntervalSince(oldest)
            )
        }
    }

    static func group(_ assertions: [SleepAssertion]) -> [AssertionGroup] {
        var buckets: [pid_t: [SleepAssertion]] = [:]
        var order: [pid_t] = []
        for a in assertions {
            if buckets[a.pid] == nil { order.append(a.pid) }
            buckets[a.pid, default: []].append(a)
        }
        return order.compactMap { pid in
            guard let list = buckets[pid] else { return nil }
            let sorted = list.sorted { $0.createdAt < $1.createdAt }
            return AssertionGroup(items: sorted)
        }
        .sorted { $0.durationOldest > $1.durationOldest }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(pid) }
    static func == (lhs: AssertionGroup, rhs: AssertionGroup) -> Bool { lhs.pid == rhs.pid }
}
