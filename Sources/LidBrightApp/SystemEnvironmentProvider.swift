import AppKit
import CoreGraphics
import Foundation
import IOKit
import IOKit.ps
import LidBrightCore

struct SystemEnvironmentProvider {
    func currentEnvironment() -> PowerEnvironment {
        PowerEnvironment(
            lidState: currentLidState(),
            hasExternalDisplay: hasExternalDisplay(),
            isOnACPower: isOnACPower()
        )
    }

    private func currentLidState() -> LidState {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/IOResources/IOPMrootDomain")
        guard entry != 0 else { return .open }
        defer { IOObjectRelease(entry) }

        guard let property = IORegistryEntryCreateCFProperty(
            entry,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Bool else {
            return .open
        }

        return property ? .closed : .open
    }

    private func hasExternalDisplay() -> Bool {
        NSScreen.screens.contains { screen in
            guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }

            return CGDisplayIsBuiltin(CGDirectDisplayID(displayID.uint32Value)) == 0
        }
    }

    private func isOnACPower() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            guard let adapter = IOPSCopyExternalPowerAdapterDetails() else {
                return false
            }
            adapter.release()
            return true
        }

        let powerSource = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as String?
        return powerSource == kIOPMACPowerKey
    }
}
