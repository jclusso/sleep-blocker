import SwiftUI

@main
struct SleepBlockerApp: App {
    @StateObject private var ruleStore: RuleStore
    @StateObject private var monitor: AssertionMonitor

    init() {
        let store = RuleStore()
        _ruleStore = StateObject(wrappedValue: store)
        _monitor = StateObject(wrappedValue: AssertionMonitor(ruleStore: store))
        Actions.requestNotificationPermission()
        LaunchAtLogin.registerOnFirstLaunch()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environmentObject(monitor)
                .environmentObject(ruleStore)
        } label: {
            Image(systemName: monitor.hasUserBlockers ? "moon.zzz.fill" : "moon.zzz")
        }
        .menuBarExtraStyle(.window)

        Window("SleepBlocker Rules", id: "rules") {
            RulesWindow()
                .environmentObject(ruleStore)
                .frame(minWidth: 520, minHeight: 320)
        }
    }
}
