import Foundation
import LidBrightCore

enum OpenLidSelection: Int, CaseIterable, Identifiable {
    case followSystem = 0
    case forever = -1
    case minutes5 = 5
    case minutes10 = 10
    case minutes15 = 15
    case minutes30 = 30
    case minutes60 = 60

    static let allCases: [OpenLidSelection] = [
        .followSystem,
        .forever,
        .minutes5,
        .minutes10,
        .minutes15,
        .minutes30,
        .minutes60
    ]

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .followSystem:
            return "跟随系统"
        case .forever:
            return "永不熄屏"
        case .minutes5:
            return "5 分钟"
        case .minutes10:
            return "10 分钟"
        case .minutes15:
            return "15 分钟"
        case .minutes30:
            return "30 分钟"
        case .minutes60:
            return "60 分钟"
        }
    }

    var mode: OpenLidMode {
        switch self {
        case .followSystem:
            return .followSystem
        case .forever:
            return .forever
        case .minutes5:
            return .timed(minutes: 5)
        case .minutes10:
            return .timed(minutes: 10)
        case .minutes15:
            return .timed(minutes: 15)
        case .minutes30:
            return .timed(minutes: 30)
        case .minutes60:
            return .timed(minutes: 60)
        }
    }
}
