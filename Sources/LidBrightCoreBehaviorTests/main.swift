import Darwin
import Foundation
import LidBrightCore

var failures: [String] = []

@MainActor
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        failures.append(message)
    }
}

@MainActor
func checkPlan(
    _ plan: PowerPlan,
    displaySleepPrevention: Bool,
    systemIdleSleepPrevention: Bool,
    expiration: Date?,
    status: PowerStatus,
    file: StaticString = #file,
    line: UInt = #line
) {
    check(
        plan.displaySleepPrevention == displaySleepPrevention,
        "\(file):\(line) displaySleepPrevention expected \(displaySleepPrevention), got \(plan.displaySleepPrevention)"
    )
    check(
        plan.systemIdleSleepPrevention == systemIdleSleepPrevention,
        "\(file):\(line) systemIdleSleepPrevention expected \(systemIdleSleepPrevention), got \(plan.systemIdleSleepPrevention)"
    )
    check(
        plan.expiration == expiration,
        "\(file):\(line) expiration expected \(String(describing: expiration)), got \(String(describing: plan.expiration))"
    )
    check(
        plan.status == status,
        "\(file):\(line) status expected \(status), got \(plan.status)"
    )
}

let now = Date(timeIntervalSince1970: 1_000)

checkPlan(
    PowerPolicy.plan(
        preferences: PowerPreferences(openLidMode: .followSystem, keepExternalDisplayAwakeWhenClosed: false),
        environment: PowerEnvironment(lidState: .open, hasExternalDisplay: false, isOnACPower: false),
        now: now
    ),
    displaySleepPrevention: false,
    systemIdleSleepPrevention: false,
    expiration: nil,
    status: .followingSystem
)

checkPlan(
    PowerPolicy.plan(
        preferences: PowerPreferences(openLidMode: .forever, keepExternalDisplayAwakeWhenClosed: false),
        environment: PowerEnvironment(lidState: .open, hasExternalDisplay: false, isOnACPower: false),
        now: now
    ),
    displaySleepPrevention: true,
    systemIdleSleepPrevention: false,
    expiration: nil,
    status: .openLidDisplayAwake
)

checkPlan(
    PowerPolicy.plan(
        preferences: PowerPreferences(openLidMode: .timed(minutes: 15), keepExternalDisplayAwakeWhenClosed: false),
        environment: PowerEnvironment(lidState: .open, hasExternalDisplay: false, isOnACPower: false),
        now: now
    ),
    displaySleepPrevention: true,
    systemIdleSleepPrevention: false,
    expiration: now.addingTimeInterval(900),
    status: .openLidTimedDisplayAwake(minutes: 15)
)

checkPlan(
    PowerPolicy.plan(
        preferences: PowerPreferences(openLidMode: .forever, keepExternalDisplayAwakeWhenClosed: false),
        environment: PowerEnvironment(lidState: .closed, hasExternalDisplay: true, isOnACPower: true),
        now: now
    ),
    displaySleepPrevention: false,
    systemIdleSleepPrevention: false,
    expiration: nil,
    status: .closedLidSystemDefault
)

checkPlan(
    PowerPolicy.plan(
        preferences: PowerPreferences(openLidMode: .followSystem, keepExternalDisplayAwakeWhenClosed: true),
        environment: PowerEnvironment(lidState: .closed, hasExternalDisplay: true, isOnACPower: true),
        now: now
    ),
    displaySleepPrevention: true,
    systemIdleSleepPrevention: true,
    expiration: nil,
    status: .closedLidExternalDisplayAwake
)

checkPlan(
    PowerPolicy.plan(
        preferences: PowerPreferences(openLidMode: .followSystem, keepExternalDisplayAwakeWhenClosed: true),
        environment: PowerEnvironment(lidState: .closed, hasExternalDisplay: true, isOnACPower: false),
        now: now
    ),
    displaySleepPrevention: false,
    systemIdleSleepPrevention: false,
    expiration: nil,
    status: .closedLidExternalDisplayUnavailable(reason: .notOnACPower)
)

check(
    AppPresentationPolicy.activationMode == .regular,
    "application activation mode must be regular so the app has a normal main-window entry"
)
check(
    AppPresentationPolicy.mainWindowID == "main",
    "main window id must stay stable for menu-bar open-window actions"
)

if failures.isEmpty {
    print("LidBrightCoreBehaviorTests passed")
} else {
    for failure in failures {
        fputs("FAIL: \(failure)\n", stderr)
    }
    exit(1)
}
