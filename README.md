# HoopTrace

[![Flutter CI](https://github.com/x1a0Y4NGren/hooptrace/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/x1a0Y4NGren/hooptrace/actions/workflows/flutter-ci.yml)

HoopTrace 是一款面向篮球爱好者的离线单挑计分与复盘工具。它在横屏计分页中记录比分、犯规、事件和投篮落点，并在本机生成比赛历史、数据分析与复盘图片。

> **永久承诺：HoopTrace 官方项目将始终免费并保持开源。** 官方版本不会加入付费墙、订阅、广告或闭源核心功能。

## 主要能力

- 球场优先的横屏计分界面，支持 1、2、3 分和犯规记录。
- 得分后可确认或跳过标准半场上的投篮落点。
- 自定义球员名称、规则模板、目标分和计时设置。
- 本机比赛历史、事件时间线、投篮图与单场统计。
- 带审计记录的赛后事件和落点修正。
- 完整 JSON 备份导入导出、CSV 导出和复盘图片分享。
- 用户授权目录内的可选自动备份，默认关闭。

## 项目状态

- 当前版本：`0.1.0+1`，首个公开发行版准备阶段。
- 当前平台：Android 优先，最低 Android API 24。
- Android Application ID：`io.github.x1a0y4ngren.hooptrace`。
- iOS 工程和标识已经保留，但首版尚未完成 iOS 真机发布验收。
- 数据模型和界面以中文为主，同时保留 Flutter 本地化结构。

## 隐私与离线原则

首版没有账号、云同步、广告、分析 SDK、崩溃遥测或个人数据上传。比赛、球员、规则和设置保存在设备本地 SQLite 数据库中。

只有在用户主动导出、分享或选择备份目录时，数据才会离开应用私有目录。之后的处理由用户选择的系统目录或分享目标负责。完整说明见 [PRIVACY.md](PRIVACY.md)。

## 开发环境

推荐使用与当前项目一致的工具链：

- Flutter `3.41.9` stable
- Dart `3.11.5`
- Java 17
- Android SDK，包含可用的模拟器或 Android 设备

```powershell
git clone https://github.com/x1a0Y4NGren/hooptrace.git
cd hooptrace
flutter pub get
flutter doctor -v
flutter run -d <device-id>
```

计分页会自动要求横屏；主页和设置等页面支持正常设备方向。

## 质量验证

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test/main_loop_test.dart -d <android-device-id>
flutter build apk --debug
```

集成测试会使用每次运行唯一的测试球员名称，在测试设备上创建并结束一场本地比赛。

## 构建与发布

Debug APK：

```powershell
flutter build apk --debug
```

Release APK 必须使用项目维护者保管的正式密钥签名。仓库不会保存密钥；本地签名配置使用被 Git 忽略的 `android/key.properties`。没有密钥时普通 Release 构建会明确失败，只有 F-Droid 或可复现性验证可以显式选择未签名构建。完整流程见 [发布清单](docs/release/release-checklist.md)。

官方发布渠道规划：

1. [GitHub Releases](https://github.com/x1a0Y4NGren/hooptrace/releases) 提供签名 APK、校验和与源码归档。
2. 完成可复现构建核验后申请进入 F-Droid，准备说明见 [F-Droid Notes](docs/release/fdroid-notes.md)。这是 HoopTrace 为保持 GitHub 与 F-Droid 安装包签名一致而设置的项目门槛，并非 F-Droid 收录的一般性要求。

HoopTrace 不计划同时分发两个签名不同的官方 Android 包。F-Droid 首发前必须验证由相同源码重现并匹配 GitHub 上游签名 APK；在此之前，唯一的官方 APK 渠道是 GitHub Releases。这样可避免用户切换渠道时被迫卸载应用并承担本地数据丢失风险。

不要从未知来源安装声称由 HoopTrace 官方发布的 APK。正式版本应能对应到本仓库中的签名 Git tag 和 GitHub Release。

## 代码结构

- `lib/app`：应用装配、路由、主题与本地化。
- `lib/core`：领域模型、Drift 数据库、分析、审计与导出。
- `lib/features`：计分、复盘、历史、球员、规则和设置页面。
- `test`：单元测试与 Widget 测试。
- `integration_test`：Android 主流程端到端测试。
- `docs`：规划、分支执行说明和发布资料。

## 参与贡献

提交 Issue 或 Pull Request 前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。隐私、离线能力和永久免费开源承诺属于不可破坏的项目约束。

## 许可证

代码和仓库内项目资产按 [MIT License](LICENSE) 发布。
