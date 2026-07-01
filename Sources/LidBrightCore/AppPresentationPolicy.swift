public enum AppActivationMode: Equatable, Sendable {
    case regular
}

public enum AppPresentationPolicy {
    public static let activationMode: AppActivationMode = .regular
    public static let mainWindowID = "main"
}
