import Foundation
import IOKit

// Reads the same `HIDIdleTime` property that macOS's own `powerd` uses to
// decide when to sleep. Counts nanoseconds since the last HID event (mouse,
// keyboard, scroll, trackpad). Read via the `IOHIDSystem` IOService.
enum IdleMonitor {
    static func secondsIdle() -> TimeInterval {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iterator
        )
        guard result == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        defer { IOObjectRelease(entry) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return 0
        }

        if let ns = dict["HIDIdleTime"] as? Int64 {
            return TimeInterval(ns) / 1_000_000_000.0
        }
        if let ns = dict["HIDIdleTime"] as? UInt64 {
            return TimeInterval(ns) / 1_000_000_000.0
        }
        return 0
    }
}
