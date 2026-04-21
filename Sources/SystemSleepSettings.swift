import Foundation

enum SystemSleepSettings {
    static func defaultIdleThresholdSeconds() -> Int {
        if let displayMinutes = pmsetValue(for: "displaysleep"), displayMinutes > 0 {
            return displayMinutes * 60
        }
        if let sleepMinutes = pmsetValue(for: "sleep"), sleepMinutes > 0 {
            return sleepMinutes * 60
        }
        return 10 * 60
    }

    private static func pmsetValue(for key: String) -> Int? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return nil }
        task.waitUntilExit()
        guard let data = try? pipe.fileHandleForReading.readToEnd(),
              let out = String(data: data, encoding: .utf8) else { return nil }
        for line in out.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
            if parts.count >= 2, parts[0] == Substring(key) {
                return Int(parts[1])
            }
        }
        return nil
    }
}
