import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Picker("开盖后", selection: $model.openLidSelection) {
                ForEach(OpenLidSelection.allCases) { selection in
                    Text(selection.title).tag(selection)
                }
            }

            Toggle("合盖后保持外接显示器亮屏", isOn: $model.keepExternalDisplayAwakeWhenClosed)

            Section("当前状态") {
                Text(model.statusText)
                Text(model.environmentText)
                    .foregroundStyle(.secondary)

                if let errorText = model.errorText {
                    Text(errorText)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
