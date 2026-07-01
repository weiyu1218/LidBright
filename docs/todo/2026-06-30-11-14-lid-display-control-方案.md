# LidBright 方案

## 目标

实现一款 macOS 菜单栏 App。App 运行期间临时控制亮屏策略，退出后恢复系统默认行为。

## 需求边界

- 开盖时支持三种策略：跟随系统、永不熄屏、定时后恢复系统熄屏。
- 合盖后默认按 macOS 行为熄屏或睡眠。
- 新增合盖后外接显示器继续亮屏选项。
- 不使用 `pmset` 修改系统全局电源设置。
- 不要求管理员权限。
- 不保证不满足 macOS closed-display 条件时强制合盖亮屏。

## 调用链路

用户操作菜单栏或设置窗口
-> SwiftUI 状态更新
-> UserDefaults 保存偏好
-> PowerCoordinator 读取偏好和当前环境
-> PowerPolicy 生成 assertion 计划
-> PowerAssertionClient 调用 IOKit 创建或释放 power assertion
-> macOS powerd 根据 assertion 改变空闲熄屏和空闲睡眠行为。

系统事件调用链：

NSWorkspace sleep/wake 通知或定时器触发
-> PowerCoordinator 重新读取环境
-> PowerPolicy 重新计算计划
-> PowerAssertionClient 同步 assertion 状态。

## 数据支撑

- 本机 `caffeinate` 手册显示 `-d` 阻止显示器睡眠，`-i` 阻止系统空闲睡眠，`-t` 支持超时。
- 本机 `pmset` 手册显示修改 `displaysleep` 和 `sleep` 需要 root，因此本方案不使用 `pmset`。
- 本机 SDK `IOPMLib.h` 显示 `IOPMAssertionCreateWithName` 不需要特殊权限。
- 本机 SDK `IOPMLib.h` 显示 `kIOPMAssertPreventUserIdleDisplaySleep` 可阻止显示器因用户空闲而熄屏，但仍可能因为合盖或系统睡眠而熄屏。
- 本机 SDK `IOPMLib.h` 显示 `kIOPMAssertPreventUserIdleSystemSleep` 可阻止系统因用户空闲而睡眠，但系统仍可能因为合盖、用户菜单、低电量等原因睡眠。

## 方案设计

### 模块

- `LidBrightCore`
  - `PowerPolicy`：纯函数策略层，负责把偏好和环境转换成 assertion 计划。
  - `PowerModels`：偏好、环境、模式、状态枚举。
- `LidBrightApp`
  - `LidBrightApp`：SwiftUI 入口，提供菜单栏和设置窗口。
  - `AppState`：用户偏好和运行状态。
  - `PowerCoordinator`：连接 UI、系统事件、环境读取和 IOKit assertion。
  - `SystemEnvironmentProvider`：读取合盖状态、外接显示器、电源状态。
  - `PowerAssertionClient`：封装 IOKit assertion 创建与释放。
  - `SettingsView`：开盖策略与合盖外接屏选项。

### Assertion 规则

- 开盖 + 跟随系统：不持有 assertion。
- 开盖 + 永不熄屏：持有 `PreventUserIdleDisplaySleep`。
- 开盖 + 定时：持有 `PreventUserIdleDisplaySleep`，到期释放。
- 合盖 + 外接屏选项关闭：释放所有 assertion。
- 合盖 + 外接屏选项开启 + 外接显示器存在 + 外接电源：持有 `PreventUserIdleDisplaySleep` 和 `PreventUserIdleSystemSleep`。
- 合盖 + 外接屏选项开启但条件不足：释放所有 assertion，并显示原因。

## KISS 自检

1. 这是现实问题，不是想象问题：用户明确要求开盖亮屏控制和合盖外接屏亮屏。
2. 更简单的做法：使用进程生命周期内的 IOKit assertion，不修改系统配置。
3. 会破坏什么：不改 `pmset`，退出释放 assertion，降低破坏系统电源设置的风险。
4. 当前项目需要这个功能：合盖外接屏是用户追加确认后的显性需求。

## 风险和限制

- macOS 可因合盖、低电量、热状态、用户手动睡眠等高优先级原因忽略或结束 assertion。
- 无外接显示器或无外接电源时，合盖外接屏亮屏选项不会强制生效。
- SwiftPM GUI App 需要打包成 `.app` 后启动，不能直接用裸二进制作为最终运行方式。

## 验证

- `swift test` 验证策略层分支。
- `swift build` 验证 App 和 Core 编译。
- `./script/build_and_run.sh --verify` 验证打包并启动 App 进程。
- `pmset -g assertions` 可人工确认运行期间 assertion 是否出现。
