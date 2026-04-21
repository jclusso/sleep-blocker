import Foundation
import Combine

@MainActor
final class AssertionMonitor: ObservableObject {
    @Published var assertions: [SleepAssertion] = []
    @Published var showAll: Bool = false
    @Published var secondsIdle: TimeInterval = 0

    private var timer: Timer?
    private let engine: RuleEngine

    init(ruleStore: RuleStore) {
        self.engine = RuleEngine(store: ruleStore)
        refresh()
        startTimer(interval: 5)
    }

    func setPopoverOpen(_ open: Bool) {
        startTimer(interval: open ? 2 : 5)
        if open { refresh() }
    }

    private func startTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func refresh() {
        let fresh = AssertionReader.read()
        self.assertions = fresh
        self.secondsIdle = IdleMonitor.secondsIdle()
        engine.evaluate(fresh)
    }

    var userBlockers: [AssertionGroup] {
        AssertionGroup.group(assertions.filter { $0.isUserSleepBlocker })
    }

    var hasUserBlockers: Bool { !userBlockers.isEmpty }

    var visibleOther: [AssertionGroup] {
        let pool: [SleepAssertion]
        if showAll {
            pool = assertions.filter { !$0.isUserSleepBlocker }
        } else {
            pool = assertions.filter { $0.isSleepBlockingType && $0.isSystemOwned }
        }
        return AssertionGroup.group(pool)
    }
}
