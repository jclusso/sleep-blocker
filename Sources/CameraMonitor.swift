import Foundation
import CoreMediaIO

enum CameraMonitor {
    static func isCameraInUse() -> Bool {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        var dataSize: UInt32 = 0
        let status = CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0, nil,
            &dataSize
        )
        guard status == noErr, dataSize > 0 else { return false }

        let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
        var devices = [CMIODeviceID](repeating: 0, count: deviceCount)
        var dataUsed: UInt32 = 0

        let status2 = CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0, nil,
            dataSize,
            &dataUsed,
            &devices
        )
        guard status2 == noErr else { return false }

        for device in devices {
            if isDeviceRunning(device) { return true }
        }
        return false
    }

    private static func isDeviceRunning(_ device: CMIODeviceID) -> Bool {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        var isRunning: UInt32 = 0
        var dataUsed: UInt32 = 0
        let size = UInt32(MemoryLayout<UInt32>.size)

        let status = CMIOObjectGetPropertyData(
            device,
            &property,
            0, nil,
            size,
            &dataUsed,
            &isRunning
        )
        return status == noErr && isRunning != 0
    }
}
