# HoopTrace

[![Flutter CI](https://github.com/x1a0Y4NGren/hooptrace/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/x1a0Y4NGren/hooptrace/actions/workflows/flutter-ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/x1a0Y4NGren/hooptrace)](https://github.com/x1a0Y4NGren/hooptrace/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-2f2a25.svg)](LICENSE)

> 把注意力留给球场，把比分、落点和复盘交给 HoopTrace。

HoopTrace 是一款为篮球爱好者准备的离线单挑计分工具。一台手机横过来，就能记比分、犯规、比赛事件和投篮落点；打完球再回头看看，哪一球是关键，哪一片篮筐今天格外不给面子。

球可以打铁，记录不能糊涂。

> **永久承诺：HoopTrace 官方项目将始终免费并保持开源。** 官方版本不会加入付费墙、订阅、广告或闭源核心功能。

**[下载最新正式版](https://github.com/x1a0Y4NGren/hooptrace/releases/latest)** · [查看隐私说明](PRIVACY.md) · [参与贡献](CONTRIBUTING.md)

## 先看比赛，不看说明书

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2-scoring.png" width="49%" alt="HoopTrace 横屏计分页">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3-replay.png" width="49%" alt="HoopTrace 比赛复盘页">
</p>

<p align="center"><sub>左边负责当场记清楚，右边负责赛后讲明白。</sub></p>

## 三步打完一场球

1. **开球前**：填好球员名称，选择规则、目标分和是否计时。
2. **得分时**：点 1、2、3 分或犯规；想记投篮位置，就在标准半场上落个点。
3. **终场后**：查看比分走势、事件时间线、投篮图和单场统计，需要时还能修正记录并保留审计痕迹。

全程不需要账号，不需要网络，也不用在暂停时和复杂表格斗智斗勇。

## 它会记住什么

- 球场优先的横屏计分界面，支持 1、2、3 分和犯规记录。
- 得分后可确认或跳过投篮落点，确认后的标点不会被现场误触带跑。
- 自定义球员名称、规则模板、目标分和计时设置。
- 本机比赛历史、事件时间线、投篮图、比分走势与单场统计。
- 带审计记录的赛后事件和落点修正，改过什么有迹可循。
- 完整 JSON 备份与恢复、CSV 导出和复盘图片分享。
- 用户授权目录内的可选自动备份，默认关闭，选择权始终在你手里。

## 当前阵容

- 当前源码版本：`1.0.0+2` 发布候选；功能与本地发布门槛已完成，但尚未签名、打 tag 或公开发布。当前公开正式版仍为 `0.1.0`。
- 当前平台：Android 优先，最低 Android API 24。
- Android Application ID：`io.github.x1a0y4ngren.hooptrace`。
- iOS 工程和标识已经保留，但尚未完成 iOS 真机发布验收。
- 界面完整支持简体中文和英文，默认跟随系统语言；主题可跟随系统或固定为浅色/深色。

## 隐私与离线原则

没有账号，没有广告，也不会悄悄把你的比赛送上云端。比赛、球员、规则和设置都保存在设备本地 SQLite 数据库中；应用不包含分析 SDK、追踪 SDK、崩溃遥测或运营后端。

只有在你主动导出、分享或选择备份目录时，数据才会离开应用私有目录。之后的处理由你选择的系统目录或分享目标负责。完整说明见 [PRIVACY.md](PRIVACY.md)。

## 把它跑起来

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

计分页会自动要求横屏；主页、历史和设置等页面支持正常设备方向。

## 认真部分

俏皮归俏皮，CI 不放水：

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test/main_loop_test.dart -d <android-device-id>
flutter build apk --debug
```

集成测试会使用每次运行唯一的测试球员名称，在测试设备上创建并结束一场本地比赛。

## 构建与发布

日常开发可以直接构建 Debug APK：

```powershell
flutter build apk --debug
```

Release APK 必须使用项目维护者保管的正式密钥签名。仓库不会保存密钥；本地签名配置使用被 Git 忽略的 `android/key.properties`。没有密钥时普通 Release 构建会明确失败，只有 F-Droid 或可复现性验证可以显式选择未签名构建。完整流程见 [发布清单](docs/release/release-checklist.md)。

官方发布渠道：

1. [GitHub Releases](https://github.com/x1a0Y4NGren/hooptrace/releases) 提供签名 APK、校验和与源码归档。
2. 完成可复现构建核验后申请进入 F-Droid，准备说明见 [F-Droid Notes](docs/release/fdroid-notes.md)。这是 HoopTrace 为保持 GitHub 与 F-Droid 安装包签名一致而设置的项目门槛，并非 F-Droid 收录的一般性要求。

HoopTrace 不计划同时分发两个签名不同的官方 Android 包。F-Droid 首发前必须验证由相同源码重现并匹配 GitHub 上游签名 APK；在此之前，唯一的官方 APK 渠道是 GitHub Releases。这样可避免用户切换渠道时被迫卸载应用并承担本地数据丢失风险。

不要从未知来源安装声称由 HoopTrace 官方发布的 APK。正式版本应能对应到本仓库中的签名 Git tag 和 GitHub Release。

## 逛仓库不迷路

- `lib/app`：应用装配、路由、主题与本地化。
- `lib/core`：领域模型、Drift 数据库、分析、审计与导出。
- `lib/features`：计分、复盘、历史、球员、规则和设置页面。
- `test`：单元测试与 Widget 测试。
- `integration_test`：Android 主流程端到端测试。
- `docs`：规划、分支执行说明和发布资料。

## 欢迎上场

Bug、想法、文档改进和代码贡献都欢迎。提交 Issue 或 Pull Request 前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。隐私、离线能力和永久免费开源承诺属于不可破坏的项目约束。

## 许可证

代码和仓库内项目资产按 [MIT License](LICENSE) 发布。
