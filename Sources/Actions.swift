import AppKit
import UserNotifications
import Darwin

enum Actions {
    static func perform(_ action: RuleAction, on a: SleepAssertion) {
        switch action {
        case .notify: notify(a)
        case .quit: quit(a)
        case .forceSleep: forceSleep()
        }
    }

    static func notify(_ a: SleepAssertion) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DebugLog.write("[SleepBlocker] notify auth status: \(settings.authorizationStatus.rawValue), alert: \(settings.alertSetting.rawValue)")
        }
        let content = UNMutableNotificationContent()
        content.title = "\(a.displayName) is preventing sleep"
        content.body = "\(a.assertionType) — \(a.name)"
        if let attachment = makeIconAttachment(for: a) {
            content.attachments = [attachment]
        }
        let req = UNNotificationRequest(
            identifier: "sleepblocker-\(a.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { error in
            if let error = error {
                DebugLog.write("[SleepBlocker] notify delivery FAILED: \(error)")
            } else {
                DebugLog.write("[SleepBlocker] notify delivered: \(req.identifier) for \(a.displayName)")
            }
        }
    }

    private static func makeIconAttachment(for a: SleepAssertion) -> UNNotificationAttachment? {
        let iconPNG: Data
        if let d = a.iconData {
            iconPNG = d
        } else if let appIconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let icns = NSImage(contentsOf: appIconURL),
                  let png = icns.pngRepresentation() {
            iconPNG = png
        } else {
            return nil
        }
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SleepBlockerNotifications", isDirectory: true)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let url = tmpDir.appendingPathComponent("\(UUID().uuidString).png")
        do {
            try iconPNG.write(to: url)
            return try UNNotificationAttachment(identifier: "icon", url: url, options: nil)
        } catch {
            return nil
        }
    }

    static func quit(_ a: SleepAssertion) {
        let pid = a.pid
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.terminate()
        } else {
            kill(pid, SIGTERM)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if kill(pid, 0) == 0 {
                kill(pid, SIGKILL)
            }
        }
    }

    static func forceSleep() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["sleepnow"]
        try? task.run()
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
