import Foundation

public enum LidState: Equatable {
    case open
    case closed
}

public enum OpenLidMode: Equatable {
    case followSystem
    case forever
    case timed(minutes: Int)
}

public struct PowerPreferences: Equatable {
    public let openLidMode: OpenLidMode
    public let keepExternalDisplayAwakeWhenClosed: Bool

    public init(openLidMode: OpenLidMode, keepExternalDisplayAwakeWhenClosed: Bool) {
        self.openLidMode = openLidMode
        self.keepExternalDisplayAwakeWhenClosed = keepExternalDisplayAwakeWhenClosed
    }
}

public struct PowerEnvironment: Equatable {
    public let lidState: LidState
    public let hasExternalDisplay: Bool
    public let isOnACPower: Bool

    public init(lidState: LidState, hasExternalDisplay: Bool, isOnACPower: Bool) {
        self.lidState = lidState
        self.hasExternalDisplay = hasExternalDisplay
        self.isOnACPower = isOnACPower
    }
}

public enum ClosedLidUnavailableReason: Equatable {
    case noExternalDisplay
    case notOnACPower
}

public enum PowerStatus: Equatable {
    case followingSystem
    case openLidDisplayAwake
    case openLidTimedDisplayAwake(minutes: Int)
    case closedLidSystemDefault
    case closedLidExternalDisplayAwake
    case closedLidExternalDisplayUnavailable(reason: ClosedLidUnavailableReason)
}

public struct PowerPlan: Equatable {
    public let displaySleepPrevention: Bool
    public let systemIdleSleepPrevention: Bool
    public let expiration: Date?
    public let status: PowerStatus

    public init(
        displaySleepPrevention: Bool,
        systemIdleSleepPrevention: Bool,
        expiration: Date?,
        status: PowerStatus
    ) {
        self.displaySleepPrevention = displaySleepPrevention
        self.systemIdleSleepPrevention = systemIdleSleepPrevention
        self.expiration = expiration
        self.status = status
    }
}
