import SwiftUI
import LidBrightCore

@main
struct LidBrightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("LidBright", id: AppPresentationPolicy.mainWindowID) {
            MainView(model: model)
                .frame(minWidth: 460, idealWidth: 520, minHeight: 360, idealHeight: 430)
        }
        .defaultSize(width: 520, height: 430)

        MenuBarExtra {
            MenuBarContent(model: model)
        } label: {
            Label("LidBright", systemImage: "display")
        }
        .menuBarExtraStyle(.menu)
    }
}
