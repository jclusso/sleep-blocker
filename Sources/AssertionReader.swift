import Foundation
import IOKit.pwr_mgt

enum AssertionReader {
    static func read() -> [SleepAssertion] {
        var cf: Unmanaged<CFDictionary>?
        let status = IOPMCopyAssertionsByProcess(&cf)
        guard status == kIOReturnSuccess, let raw = cf?.takeRetainedValue() else {
            return []
        }
        guard let dict = raw as? [NSNumber: [[String: Any]]] else { return [] }

        var results: [SleepAssertion] = []
        for (pidNum, list) in dict {
            let pid = pid_t(pidNum.int32Value)
            let info = ProcessResolver.resolve(pid: pid)
            for a in list {
                guard let type = a[kIOPMAssertionTypeKey as String] as? String else { continue }
                let name = (a[kIOPMAssertionNameKey as String] as? String) ?? "(unnamed)"
                let created = (a["AssertStartWhen"] as? Date) ?? Date()
                let timeout = a["TimeoutSeconds"] as? TimeInterval
                let id = "\(pid)-\(type)-\(name)-\(Int(created.timeIntervalSince1970))"
                results.append(SleepAssertion(
                    id: id,
                    pid: pid,
                    bundleID: info.bundleID,
                    displayName: info.displayName,
                    executablePath: info.path,
                    assertionType: type,
                    name: name,
                    createdAt: created,
                    timeout: timeout,
                    iconData: info.iconPNG
                ))
            }
        }
        return results.sorted { $0.duration > $1.duration }
    }
}
