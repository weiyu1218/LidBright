import AppKit
import Foundation
import LidBrightCore

@MainActor
final class AppModel: ObservableObject {
    @Published var openLidSelection: OpenLidSelection {
        didSet {
            guard oldValue != openLidSelection else { return }
            defaults.set(openLidSelection.rawValue, forKey: DefaultsKey.openLidSelection)
            resetTimedSession()
            applyPolicy()
        }
    }

    @Published var keepExternalDisplayAwakeWhenClosed: Bool {
        didSet {
            guard oldValue != keepExternalDisplayAwakeWhenClosed else { return }
            defaults.set(keepExternalDisplayAwakeWhenClosed, forKey: DefaultsKey.keepExternalDisplayAwakeWhenClosed)
            applyPolicy()
        }
    }

    @Published private(set) var statusText: String = "正在读取状态"
    @Published private(set) var environmentText: String = ""
    @Published private(set) var errorText: String?

    private let defaults: UserDefaults
    private let environmentProvider: SystemEnvironmentProvider
    private let assertionClient: PowerAssertionClient
    private var expirationTimer: Timer?
    private var refreshTimer: Timer?
    private var notificationTokens: [Any] = []
    private var openLidTimedExpiration: Date?
    private var timedModeElapsed = false
    private var lastObservedLidState: LidState?

    init(
        defaults: UserDefaults = .standard,
        environmentProvider: SystemEnvironmentProvider = SystemEnvironmentProvider(),
        assertionClient: PowerAssertionClient = PowerAssertionClient()
    ) {
        self.defaults = defaults
        self.environmentProvider = environmentProvider
        self.assertionClient = assertionClient

        let storedSelection = defaults.object(forKey: DefaultsKey.openLidSelection) as? Int
        self.openLidSelection = storedSelection.flatMap(OpenLidSelection.init(rawValue:)) ?? .forever
        self.keepExternalDisplayAwakeWhenClosed = defaults.bool(
            forKey: DefaultsKey.keepExternalDisplayAwakeWhenClosed
        )

        installObservers()
        startRefreshTimer()
        applyPolicy()
    }

    func applyPolicy() {
        let now = Date()
        let environment = environmentProvider.currentEnvironment()
        updateTimedSession(for: environment, now: now)

        let preferences = PowerPreferences(
            openLidMode: openLidSelection.mode,
            keepExternalDisplayAwakeWhenClosed: keepExternalDisplayAwakeWhenClosed
        )
        var plan = PowerPolicy.plan(preferences: preferences, environment: environment, now: now)
        plan = adjustedTimedPlan(plan, environment: environment, now: now)

        do {
            try assertionClient.apply(plan)
            errorText = nil
        } catch {
            errorText = error.localizedDescription
        }

        statusText = statusDescription(for: plan.status)
        environmentText = environmentDescription(for: environment, expiration: plan.expiration)
        scheduleExpiration(plan.expiration)
    }

    func releaseAssertions() {
        assertionClient.releaseAll()
        expirationTimer?.invalidate()
        expirationTimer = nil
        statusText = "当前跟随系统"
    }

    private func installObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        notificationTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.applyPolicy() }
            }
        )
        notificationTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.releaseAssertions() }
            }
        )
        notificationTokens.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.applyPolicy() }
            }
        )
        notificationTokens.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.assertionClient.releaseAll() }
            }
        )
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.applyPolicy() }
        }
    }

    private func updateTimedSession(for environment: PowerEnvironment, now: Date) {
        if lastObservedLidState != environment.lidState {
            resetTimedSession()
            lastObservedLidState = environment.lidState
        }

        guard environment.lidState == .open else {
            resetTimedSession()
            return
        }

        guard case .timed = openLidSelection.mode else {
            resetTimedSession()
            return
        }

        if let expiration = openLidTimedExpiration, expiration <= now {
            timedModeElapsed = true
            openLidTimedExpiration = nil
        }
    }

    private func adjustedTimedPlan(
        _ plan: PowerPlan,
        environment: PowerEnvironment,
        now: Date
    ) -> PowerPlan {
        guard environment.lidState == .open else { return plan }
        guard case .timed(let minutes) = openLidSelection.mode else { return plan }

        if timedModeElapsed {
            return PowerPlan(
                displaySleepPrevention: false,
                systemIdleSleepPrevention: false,
                expiration: nil,
                status: .followingSystem
            )
        }

        let expiration = openLidTimedExpiration ?? now.addingTimeInterval(TimeInterval(minutes * 60))
        openLidTimedExpiration = expiration

        return PowerPlan(
            displaySleepPrevention: true,
            systemIdleSleepPrevention: false,
            expiration: expiration,
            status: .openLidTimedDisplayAwake(minutes: minutes)
        )
    }

    private func scheduleExpiration(_ expiration: Date?) {
        expirationTimer?.invalidate()
        expirationTimer = nil

        guard let expiration else { return }

        let interval = max(expiration.timeIntervalSinceNow, 0)
        expirationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.timedModeElapsed = true
                self?.openLidTimedExpiration = nil
                self?.applyPolicy()
            }
        }
    }

    private func resetTimedSession() {
        timedModeElapsed = false
        openLidTimedExpiration = nil
    }

    private func statusDescription(for status: PowerStatus) -> String {
        if timedModeElapsed {
            return "定时已结束，当前跟随系统"
        }

        switch status {
        case .followingSystem:
            return "当前跟随系统"
        case .openLidDisplayAwake:
            return "开盖时保持亮屏"
        case .openLidTimedDisplayAwake(let minutes):
            return "开盖后 \(minutes) 分钟内保持亮屏"
        case .closedLidSystemDefault:
            return "合盖后按系统默认处理"
        case .closedLidExternalDisplayAwake:
            return "合盖后保持外接显示器亮屏"
        case .closedLidExternalDisplayUnavailable(let reason):
            switch reason {
            case .noExternalDisplay:
                return "未检测到外接显示器"
            case .notOnACPower:
                return "未连接外接电源"
            }
        }
    }

    private func environmentDescription(for environment: PowerEnvironment, expiration: Date?) -> String {
        var parts: [String] = [
            environment.lidState == .open ? "开盖" : "合盖",
            environment.hasExternalDisplay ? "有外接显示器" : "无外接显示器",
            environment.isOnACPower ? "外接电源" : "电池供电"
        ]

        if let expiration {
            parts.append("到期 \(expiration.formatted(date: .omitted, time: .shortened))")
        }

        return parts.joined(separator: " / ")
    }
}

private enum DefaultsKey {
    static let openLidSelection = "openLidSelection"
    static let keepExternalDisplayAwakeWhenClosed = "keepExternalDisplayAwakeWhenClosed"
}
