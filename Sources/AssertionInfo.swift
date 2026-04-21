import Foundation

enum AssertionInfo {
    static func summary(for type: String) -> String {
        switch type {
        case "PreventUserIdleSystemSleep":
            return "Stops the Mac from sleeping when you're idle. The display can still dim and sleep."
        case "PreventUserIdleDisplaySleep":
            return "Stops both the display and the Mac from sleeping while you're idle."
        case "PreventSystemSleep":
            return "Stops the Mac from sleeping even on battery. Used by drivers and background services."
        case "NoIdleSleepAssertion":
            return "Legacy name for PreventUserIdleSystemSleep. Blocks idle system sleep."
        case "NoDisplaySleepAssertion":
            return "Legacy name for PreventUserIdleDisplaySleep. Blocks display sleep."
        case "UserIsActive":
            return "Signals that a user is currently interacting. Does not itself block sleep."
        case "BackgroundTask":
            return "A background task is in progress. Usually short-lived, not a real blocker."
        case "NetworkClientActive":
            return "A network client wants the Mac to stay reachable. Does not block sleep directly."
        case "ApplePushServiceTask":
            return "Apple Push Notification Service activity. Transient."
        case "SoftwareUpdateTask":
            return "macOS software update is running."
        default:
            return "Power assertion of type \(type)."
        }
    }

    static func severity(for type: String) -> String {
        switch type {
        case "PreventUserIdleSystemSleep", "NoIdleSleepAssertion":
            return "Blocks system sleep"
        case "PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion":
            return "Blocks display + system sleep"
        case "PreventSystemSleep":
            return "Blocks all sleep (incl. battery)"
        default:
            return "Informational"
        }
    }
}
