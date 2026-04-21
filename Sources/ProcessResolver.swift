import AppKit
import Darwin

enum ProcessResolver {
    struct Info {
        let bundleID: String?
        let displayName: String
        let path: String?
        let iconPNG: Data?
    }

    private static var cache: [pid_t: Info] = [:]

    static func resolve(pid: pid_t) -> Info {
        if let cached = cache[pid] { return cached }

        if let running = NSRunningApplication(processIdentifier: pid) {
            let name = running.localizedName
                ?? running.bundleURL?.deletingPathExtension().lastPathComponent
                ?? "PID \(pid)"
            let path = running.bundleURL?.path ?? running.executableURL?.path
            let icon = bestIcon(running: running, path: path)
            let info = Info(
                bundleID: running.bundleIdentifier,
                displayName: name,
                path: path,
                iconPNG: icon?.pngRepresentation()
            )
            cache[pid] = info
            return info
        }

        var buf = [CChar](repeating: 0, count: 4096)
        let ret = proc_pidpath(pid, &buf, UInt32(buf.count))
        let path: String? = ret > 0 ? String(cString: buf) : nil
        let name = path.map { ($0 as NSString).lastPathComponent } ?? "PID \(pid)"
        let info = Info(bundleID: nil, displayName: name, path: path, iconPNG: nil)
        cache[pid] = info
        return info
    }

    static func clearCache() { cache.removeAll() }

    private static func bestIcon(running: NSRunningApplication, path: String?) -> NSImage? {
        if let p = path {
            let ws = NSWorkspace.shared.icon(forFile: p)
            if !isGenericIcon(ws) { return ws }
        }
        if let icon = running.icon, !isGenericIcon(icon) { return icon }
        if let p = path { return NSWorkspace.shared.icon(forFile: p) }
        return running.icon
    }

    private static func isGenericIcon(_ img: NSImage) -> Bool {
        img.name() == NSImage.Name("NSDefaultApplicationIcon") ||
        img.name() == NSImage.Name("GenericApplicationIcon") ||
        img.name() == NSImage.Name("GenericDocumentIcon")
    }
}

extension NSImage {
    func pngRepresentation() -> Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
