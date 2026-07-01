import Foundation

public enum PowerPolicy {
    public static func plan(
        preferences: PowerPreferences,
        environment: PowerEnvironment,
        now: Date
    ) -> PowerPlan {
        switch environment.lidState {
        case .open:
            return openLidPlan(for: preferences.openLidMode, now: now)
        case .closed:
            return closedLidPlan(
                keepExternalDisplayAwake: preferences.keepExternalDisplayAwakeWhenClosed,
                environment: environment
            )
        }
    }

    private static func openLidPlan(for mode: OpenLidMode, now: Date) -> PowerPlan {
        switch mode {
        case .followSystem:
            return PowerPlan(
                displaySleepPrevention: false,
                systemIdleSleepPrevention: false,
                expiration: nil,
                status: .followingSystem
            )
        case .forever:
            return PowerPlan(
                displaySleepPrevention: true,
                systemIdleSleepPrevention: false,
                expiration: nil,
                status: .openLidDisplayAwake
            )
        case .timed(let minutes):
            return PowerPlan(
                displaySleepPrevention: true,
                systemIdleSleepPrevention: false,
                expiration: now.addingTimeInterval(TimeInterval(minutes * 60)),
                status: .openLidTimedDisplayAwake(minutes: minutes)
            )
        }
    }

    private static func closedLidPlan(
        keepExternalDisplayAwake: Bool,
        environment: PowerEnvironment
    ) -> PowerPlan {
        guard keepExternalDisplayAwake else {
            return PowerPlan(
                displaySleepPrevention: false,
                systemIdleSleepPrevention: false,
                expiration: nil,
                status: .closedLidSystemDefault
            )
        }

        guard environment.hasExternalDisplay else {
            return PowerPlan(
                displaySleepPrevention: false,
                systemIdleSleepPrevention: false,
                expiration: nil,
                status: .closedLidExternalDisplayUnavailable(reason: .noExternalDisplay)
            )
        }

        guard environment.isOnACPower else {
            return PowerPlan(
                displaySleepPrevention: false,
                systemIdleSleepPrevention: false,
                expiration: nil,
                status: .closedLidExternalDisplayUnavailable(reason: .notOnACPower)
            )
        }

        return PowerPlan(
            displaySleepPrevention: true,
            systemIdleSleepPrevention: true,
            expiration: nil,
            status: .closedLidExternalDisplayAwake
        )
    }
}
