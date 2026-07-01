import Foundation
import IOKit.pwr_mgt
import LidBrightCore

final class PowerAssertionClient {
    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0

    deinit {
        releaseAll()
    }

    func apply(_ plan: PowerPlan) throws {
        do {
            try setDisplaySleepPrevention(plan.displaySleepPrevention)
            try setSystemIdleSleepPrevention(plan.systemIdleSleepPrevention)
        } catch {
            releaseAll()
            throw error
        }
    }

    func releaseAll() {
        release(&displayAssertionID)
        release(&systemAssertionID)
    }

    private func setDisplaySleepPrevention(_ enabled: Bool) throws {
        try setAssertion(
            &displayAssertionID,
            enabled: enabled,
            type: kIOPMAssertPreventUserIdleDisplaySleep as CFString,
            name: "LidBright display awake" as CFString
        )
    }

    private func setSystemIdleSleepPrevention(_ enabled: Bool) throws {
        try setAssertion(
            &systemAssertionID,
            enabled: enabled,
            type: kIOPMAssertPreventUserIdleSystemSleep as CFString,
            name: "LidBright closed display mode" as CFString
        )
    }

    private func setAssertion(
        _ assertionID: inout IOPMAssertionID,
        enabled: Bool,
        type: CFString,
        name: CFString
    ) throws {
        if enabled {
            guard assertionID == 0 else { return }

            var newAssertionID = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                type,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                name,
                &newAssertionID
            )

            guard result == kIOReturnSuccess else {
                throw PowerAssertionError(code: result)
            }

            assertionID = newAssertionID
        } else {
            release(&assertionID)
        }
    }

    private func release(_ assertionID: inout IOPMAssertionID) {
        guard assertionID != 0 else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
    }
}

struct PowerAssertionError: LocalizedError {
    let code: IOReturn

    var errorDescription: String? {
        "Power assertion 创建失败，IOKit 返回码 \(code)"
    }
}
