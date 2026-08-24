# HoopTrace 1.0 source build / 1.0 源码构建

This guide builds the Android application from the public source tree without
signing or publishing it. The official upstream APK is signed separately by the
maintainer. 本文只说明如何从公开源码构建未签名 Android 包，不执行发布；上游
正式 APK 由维护者另行签名。

## Pinned toolchain / 固定工具链

- Flutter 3.41.9 stable, revision `00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`
- Dart 3.11.5 (bundled with Flutter)
- Temurin Java 17.0.20+8
- Android SDK API 36, build-tools 36.1.0, and NDK 28.2.13676358
- Gradle 8.14 via the checked-in wrapper (wrapper SHA-256
  `7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`)
- A C compiler available to Dart native hooks (the Android NDK supplies this
  for Android builds; desktop host tests need the platform toolchain)
- Git and a POSIX shell for the reproducibility helper
- The checked-in SQLite 3.53.4 amalgamation under `third_party/sqlite/`

Use the committed `pubspec.lock`. A release verification build must not update
dependencies. 发布核验必须使用已提交的 `pubspec.lock`，不能在构建时升级依赖。

The `sqlite3` native hook is configured for `source: source`, so the build
compiles the repository's SQLite amalgamation and does not download a binary
from a package GitHub release. Do not replace that source with `source: system`
for Android release verification.

## Clean unsigned build / 干净未签名构建

```bash
git clone https://github.com/x1a0Y4NGren/hooptrace.git
cd hooptrace
git checkout v1.0.0
flutter doctor -v
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --reporter expanded
HOOPTRACE_ALLOW_UNSIGNED_RELEASE=true flutter build apk --release
```

Before a release-verification build, run
`bash tool/release/prepare_android_toolchain.sh`. The CI gate also exports the
release runtime Maven graph and compares it with
`third_party/android_runtime/coordinates.txt`, then regenerates
`THIRD_PARTY_NOTICES.md`; every graph coordinate must remain represented there
with its complete license text.

The result is `build/app/outputs/flutter-apk/app-release.apk`. The explicit
environment variable is accepted only for F-Droid/reproducibility work; a normal
release build fails when maintainer signing is absent and never falls back to a
debug key.

输出位于 `build/app/outputs/flutter-apk/app-release.apk`。环境变量只用于
F-Droid/可复现性核验；普通 Release 在缺少维护者签名时会失败，绝不会回退到
debug key。

## Database compatibility warning / 数据库兼容警告

Version 1.0 uses a new schema and backup format. A v0.1 database or v0.1 JSON
backup is deliberately not migrated. The app detects the legacy database and
shows a blocking clean-install explanation instead of deleting it silently.
Export anything needed from v0.1 before installing 1.0, then clear/uninstall the
old app data and install 1.0. Do not claim that a v0.1 backup can be restored.

1.0 使用新的数据库和备份格式，不承诺迁移 v0.1 数据库或 JSON 备份。应用会
识别旧库并显示阻断说明，而不会静默删除。升级前请先从 v0.1 导出所需资料，
随后清除/卸载旧数据再安装 1.0；不要尝试把 v0.1 备份恢复到 1.0。

## Verification / 核验

Run `bash tool/release/verify_unsigned_reproducible_android.sh` from a clean,
committed revision. It exports that exact revision into two independent temporary
source trees, builds both with a shared `SOURCE_DATE_EPOCH`, byte-compares the
APKs, and writes the verified artifact and checksum to `build/reproducible/`.

在干净且已提交的版本上运行上述脚本；它会创建两份独立源码树、构建并逐字节
比较 APK，最后把验证通过的产物和校验和写入 `build/reproducible/`。
