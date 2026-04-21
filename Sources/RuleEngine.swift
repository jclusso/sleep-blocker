import Foundation

@MainActor
final class RuleEngine {
    private let store: RuleStore
    private var recent: [String: Date] = [:]
    private var lastReturnTime: Date = Date()
    private let activeIdleThreshold: TimeInterval = 2.0
    private let quickCooldown: TimeInterval = 60
    private let notifyCooldown: TimeInterval = 600
    private let sleepCooldown: TimeInterval = 600
    private let defaultIdleSeconds: Int

    private var maxCooldown: TimeInterval {
        max(quickCooldown, notifyCooldown, sleepCooldown)
    }

    init(store: RuleStore) {
        self.store = store
        self.defaultIdleSeconds = SystemSleepSettings.defaultIdleThresholdSeconds()
    }

    func evaluate(_ assertions: [SleepAssertion]) {
        let now = Date()
        let idle = IdleMonitor.secondsIdle()

        if idle < activeIdleThreshold {
            lastReturnTime = now
        }

        recent = recent.filter { now.timeIntervalSince($0.value) < maxCooldown }

        let userBlockers = assertions.filter { $0.isUserSleepBlocker }
        let hasUnruledBlocker = userBlockers.contains { a in
            !store.rules.contains(where: { $0.matches(a) })
        }

        DebugLog.write("[SleepBlocker] evaluate: idle=\(String(format: "%.1f", idle))s rules=\(store.rules.count) blockers=\(userBlockers.count) unruledBlocker=\(hasUnruledBlocker)")

        var alreadyFired = Set<String>()

        for a in userBlockers {
            for rule in store.rules where rule.matches(a) {
                let key = cooldownKey(for: a, rule: rule)
                if alreadyFired.contains(key) { continue }

                if rule.action == .forceSleep && hasUnruledBlocker {
                    continue
                }

                if let last = recent[key] {
                    if lastReturnTime > last {
                        recent[key] = nil
                    } else {
                        let cooldown: TimeInterval
                        switch rule.action {
                        case .forceSleep: cooldown = sleepCooldown
                        case .notify: cooldown = notifyCooldown
                        case .quit: cooldown = quickCooldown
                        }
                        let since = now.timeIntervalSince(last)
                        if since < cooldown {
                            DebugLog.write("[SleepBlocker] rule \(rule.displayName)/\(rule.action.rawValue) cooldown: \(Int(since))s < \(Int(cooldown))s (no return detected)")
                            continue
                        }
                    }
                }

                let threshold: TimeInterval
                switch rule.action {
                case .notify:
                    threshold = TimeInterval(rule.idleThresholdSeconds ?? defaultIdleSeconds)
                case .quit:
                    threshold = TimeInterval(rule.idleThresholdSeconds ?? 0)
                case .forceSleep:
                    threshold = TimeInterval(rule.idleThresholdSeconds ?? defaultIdleSeconds)
                }

                if idle < threshold {
                    DebugLog.write("[SleepBlocker] rule \(rule.displayName)/\(rule.action.rawValue) idle=\(String(format: "%.1f", idle))s < threshold=\(Int(threshold))s")
                    continue
                }

                DebugLog.write("[SleepBlocker] FIRING rule \(rule.displayName)/\(rule.action.rawValue) pid=\(a.pid) assertion=\(a.assertionType)")
                recent[key] = now
                alreadyFired.insert(key)
                Actions.perform(rule.action, on: a)
            }
        }
    }

    private func cooldownKey(for a: SleepAssertion, rule: Rule) -> String {
        switch rule.action {
        case .forceSleep: return "sleep:\(rule.id.uuidString)"
        case .notify: return "notify:\(rule.id.uuidString):\(a.pid)"
        case .quit: return "\(rule.id.uuidString):\(a.pid)"
        }
    }
}
