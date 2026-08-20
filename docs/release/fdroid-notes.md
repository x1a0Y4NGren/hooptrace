# F-Droid Preparation Notes

本文记录 HoopTrace 申请进入官方 F-Droid 仓库前的构建事实、隐私声明和剩余工作。它不是已经通过审核的 fdroiddata recipe。

## 应用身份

- Name：HoopTrace
- Application ID：`io.github.x1a0y4ngren.hooptrace`
- License：MIT
- Source：`https://github.com/x1a0Y4NGren/hooptrace`
- Issue tracker：`https://github.com/x1a0Y4NGren/hooptrace/issues`
- Current version：`0.1.0`，versionCode `1`
- Platform：Flutter，Android 优先

Application ID 已脱离 Flutter 模板的 `com.example` 命名，并与 GitHub Pages 命名空间对应。正式发布后不可再更改。

## 构建工具链

当前开发和 CI 基准：

- Flutter `3.41.9` stable
- Flutter revision `00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`
- Dart `3.11.5`
- Java 17
- Android minSdk 24，compile/target SDK 由该 Flutter stable 版本提供

从源码构建的基本命令：

```bash
flutter pub get
HOOPTRACE_ALLOW_UNSIGNED_RELEASE=true flutter build apk --release --no-pub
```

仓库不包含 keystore 或 `key.properties`。普通 Release 构建在没有正式签名配置时会失败，防止维护者误发未签名 APK；F-Droid 或可复现性验证必须通过上面的显式环境变量选择未签名构建。任何模式都不会回退到 debug key。

## 依赖说明

直接依赖来自 Flutter SDK 或 pub.dev：Drift/SQLite、Riverpod、go_router、file_picker、path_provider、share_plus、url_launcher、csv、crypto、uuid 和 Dart 基础包。

- 没有 Google Play Services、Firebase、广告、分析或专有追踪 SDK。
- `file_picker` 用于系统文件/目录选择器。
- `share_plus` 用于用户主动发起的系统分享。
- `url_launcher` 只在用户点击项目外部链接时调用系统浏览器。
- `sqlite3_flutter_libs` 和 Flutter engine 会引入预编译原生组件，提交 recipe 时需要按 F-Droid 对 Flutter SDK 和受信二进制来源的当前规则检查。

提交前应在 fdroidserver 环境执行依赖扫描，并确认所有 Maven 和 pub 包来源满足 Inclusion Policy。

## 网络和隐私行为

首版核心功能完全离线：

- 无账号、云同步、广告、分析、追踪或崩溃遥测。
- 无应用运营后端，不上传球员、比赛、落点或设置。
- Android 应用级系统备份关闭。
- 只有用户主动点击外部链接时才把 URL 交给浏览器。
- 导出和自动备份由系统分享面板或用户授权目录驱动。

预计不需要 F-Droid Anti-Features。最终结论以 fdroidserver 扫描和人工审核为准。完整声明见 [`PRIVACY.md`](../../PRIVACY.md)。

## 上游元数据

仓库维护以下 Fastlane-compatible 元数据：

- `fastlane/metadata/android/en-US/short_description.txt`
- `fastlane/metadata/android/en-US/full_description.txt`
- `fastlane/metadata/android/en-US/changelogs/1.txt`
- 对应的 `zh-CN` 文件
- 两个 locale 的 `images/icon.png`
- 两个 locale 的 4 张手机截图：主页、计分、复盘和历史

截图来自 Android 模拟器中的默认球员名称和测试比分，不包含个人信息。正式提交前应确保 release tag 中包含最终 metadata。

## 源码与 tag 要求

- 每个公开 `versionName` 必须有唯一 tag，例如 `v0.1.0`。
- tag 必须指向用于构建发布 APK 的干净提交。
- GitHub source archive 应能在无私有文件、无预下载构建产物的环境中完成构建。
- `pubspec.lock` 必须提交，避免解析到不同依赖版本。
- 版本更新同时维护 Fastlane `changelogs/<versionCode>.txt`。

## 可复现构建注意事项

F-Droid 基础收录不强制上游提供可复现构建，但普通 F-Droid 源码构建会由 F-Droid 使用不同证书签名，无法覆盖安装 GitHub 渠道的 APK。HoopTrace 不计划维护两个签名不同的官方 Android 包，因此把可复现构建和上游二进制验证设为项目自己的 F-Droid 首发门槛。

F-Droid 官方文档指出 Flutter/NDK 原生库可能嵌入 SDK 或工作目录路径。首次 recipe 验证应：

1. 固定 Flutter revision、Android SDK/NDK 和 Java 版本。
2. 从干净 tag 在 fdroidserver 标准路径构建。
3. 使用 `diffoscope` 对比上游和 F-Droid 构建产物。
4. 检查 Flutter SDK 路径、Android platform revision 和 VCS info 是否造成差异。
5. 构建可重复后采用 F-Droid 的 `Binaries`/upstream signature 流程，使 GitHub 与 F-Droid 用户都能沿用同一应用签名升级。

参考：

- <https://f-droid.org/docs/Inclusion_Policy/>
- <https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/>
- <https://f-droid.org/docs/Reproducible_Builds/>
- <https://f-droid.org/docs/Building_Applications/>

## 提交前剩余阻断项

- [ ] 将完整源码、工作流和 Fastlane 元数据合并并推送到公开 `main`。
- [ ] 创建并公开首个签名 Git tag 和 GitHub Release。
- [x] 添加经过隐私检查的手机截图。
- [ ] 在 fdroiddata fork 中生成最终 build metadata，或验证仓库根目录 `.fdroid.yml`。
- [ ] 运行 `fdroid lint` 和 server-mode build。
- [ ] 完成 Flutter 原生库可复现性评估。
- [ ] 向 fdroiddata 提交 merge request；需要前置讨论时再提交 Request For Packaging。

完成这些事项之前，项目属于“本地代码和上游元数据已准备，尚未具备 F-Droid 发布资格”。
