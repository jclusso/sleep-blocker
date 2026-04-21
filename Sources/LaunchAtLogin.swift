import Foundation
import ServiceManagement

enum LaunchAtLogin {
    private static let didAttemptKey = "SleepBlocker.didAttemptLoginRegistration"

    static func registerOnFirstLaunch() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didAttemptKey) else { return }
        defaults.set(true, forKey: didAttemptKey)
        try? SMAppService.mainApp.register()
    }
}
