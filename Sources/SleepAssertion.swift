import Foundation

struct SleepAssertion: Identifiable, Hashable {
    let id: String
    let pid: pid_t
    let bundleID: String?
    let displayName: String
    let executablePath: String?
    let assertionType: String
    let name: String
    let createdAt: Date
    let timeout: TimeInterval?
    let iconData: Data?

    static let sleepBlockingTypes: Set<String> = [
        "PreventUserIdleSystemSleep",
        "PreventUserIdleDisplaySleep",
        "PreventSystemSleep",
        "NoIdleSleepAssertion",
        "NoDisplaySleepAssertion",
    ]

    var isSystemOwned: Bool {
        if let b = bundleID, b.hasPrefix("com.apple.") { return true }
        if pid <= 100 { return true }
        let systemProcs: Set<String> = [
            "powerd", "WindowServer", "coreaudiod", "bluetoothd",
            "useractivityd", "sharingd", "mds_stores", "kernel_task",
        ]
        return systemProcs.contains(displayName)
    }

    var isSleepBlockingType: Bool {
        SleepAssertion.sleepBlockingTypes.contains(assertionType)
    }

    var isUserSleepBlocker: Bool {
        isSleepBlockingType && !isSystemOwned
    }

    var duration: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SleepAssertion, rhs: SleepAssertion) -> Bool { lhs.id == rhs.id }
}
