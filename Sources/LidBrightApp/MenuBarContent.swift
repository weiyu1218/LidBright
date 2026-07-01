import AppKit
import SwiftUI
import LidBrightCore

struct MenuBarContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.statusText)
                .font(.headline)
            Text(model.environmentText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let errorText = model.errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            Picker("开盖后", selection: $model.openLidSelection) {
                ForEach(OpenLidSelection.allCases) { selection in
                    Text(selection.title).tag(selection)
                }
            }

            Toggle("合盖后保持外接显示器亮屏", isOn: $model.keepExternalDisplayAwakeWhenClosed)

            Divider()

            Button("打开主页面") {
                openWindow(id: AppPresentationPolicy.mainWindowID)
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("退出") {
                NSApp.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }
}
