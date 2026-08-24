# Reproducible Android builds / Android 可复现构建

## Contract / 约定

HoopTrace's reproducibility gate compares two unsigned release APKs produced on
one clean CI runner from the same committed source, lockfile, Flutter revision,
Temurin Java version, Android SDK/build-tools/NDK, vendored SQLite amalgamation,
and `SOURCE_DATE_EPOCH`. A passing `cmp` proves those independent source-tree
builds are byte-identical before upstream signing. Cross-runner or cross-OS
reproducibility is a separate comparison using the recorded toolchain files.

HoopTrace 的可复现性门槛会固定源码提交、锁文件、Flutter revision、Java、
Android SDK/build-tools/NDK、仓库内 SQLite amalgamation 与 `SOURCE_DATE_EPOCH`，
在同一干净 CI runner 上分别构建两份未签名 APK；只有逐字节完全一致才通过。
跨 runner 或跨操作系统的结论必须使用输出中的工具链记录另行比较。

```bash
bash tool/release/verify_unsigned_reproducible_android.sh
sha256sum -c build/reproducible/SHA256SUMS
```

The native SQLite hook is configured with `source: source` and the checked-in
`third_party/sqlite/sqlite3.c` amalgamation (SQLite 3.53.4, SHA-256
`b1dd5d74ec7f29055a6684fa06fb3c2f6821c87dd38f9a458dfd2e8a1db28189`). A clean
build therefore does not fetch a `sqlite3` GitHub release binary. The matching
`sqlite3.h`, public-domain notice, and official archive URL live beside it.

原生 SQLite hook 使用 `source: source`，从仓库内固定的
`third_party/sqlite/sqlite3.c`（SQLite 3.53.4，SHA-256 如上）编译；干净构建不再
下载 `sqlite3` GitHub Release 原生库。对应的 `sqlite3.h`、公有领域声明和官方
源码归档 URL 与其放在同一目录。

CI runs this in two independent `git archive` source trees on one runner and
publishes the verified unsigned artifact with `PUBSPEC_LOCK_SHA256`,
`RUNNER_IDENTITY.txt`, `REPRODUCIBILITY.txt`, and the toolchain snapshots. The
script re-hashes `pubspec.lock` after each locked dependency resolution and
checks the runner fingerprint before each build; `sameRunner=true` therefore
describes this single invocation only. The artifact is evidence, not an install
channel and not an official signed release.

CI 会在同一 runner 的两份独立 `git archive` 源码树中执行该流程，并随产物保存
锁文件哈希、runner 身份、复现结论和工具链快照；脚本会在每次锁定依赖解析后
重新计算 `pubspec.lock`，并在每次构建前核对 runner 指纹。`sameRunner=true`
只表示这一次脚本调用，不代表跨 runner 复现。产物只是短期证据，不是安装渠道，
也不是正式签名发行包。

The pinned release toolchain is Flutter 3.41.9 at framework revision
`00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`, Temurin 17.0.20+8,
compile/target SDK 36, Android build-tools 36.1.0, NDK 28.2.13676358,
AGP 8.11.1, and Gradle 8.14. The wrapper JAR is checked against
`7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`; the
distribution is checked against
`efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1`. The
output records Flutter, Java, Android, wrapper, commit, and epoch details beside
the APK hash.

固定发行工具链为 Flutter 3.41.9（framework revision 如上）、Temurin
17.0.20+8、compile/target SDK 36、Android build-tools 36.1.0、NDK
28.2.13676358、AGP 8.11.1 与 Gradle 8.14；wrapper JAR SHA-256 为
`7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`，发行包
Gradle distribution SHA-256 为
`efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1`；脚本会把
工具链、wrapper、提交与 epoch 记录在 APK 哈希旁。

## Signed APK comparison / 签名 APK 对比

Android signing changes the archive. For F-Droid upstream-binary verification:

1. Rebuild the unsigned APK from the public tag in the documented toolchain.
2. Obtain the published signed APK and certificate fingerprint.
3. Use current F-Droid verification tooling to remove/normalize the signature
   layer and compare the unsigned payload; use `diffoscope` when it differs.
4. Record tag, commit, toolchain image/digests, SHA-256 values, certificate, and
   comparison result in the release record.
5. Never copy the upstream keystore into fdroiddata or CI.

Android 签名会改变归档。F-Droid 上游二进制验证应从公开 tag 重建未签名包，
核对公开 APK 与证书，用 F-Droid 当前验证工具归一化签名层后比较；有差异时使用
`diffoscope`。发布记录必须保存 tag、commit、工具链、哈希、证书与比较结果，
且绝不能把上游 keystore 放入 fdroiddata 或 CI。

## Known sources of drift / 常见差异来源

- a different Flutter engine, Android build-tools, NDK, Java, or Gradle cache;
- a changed `pubspec.lock` or generated Drift/l10n output;
- a changed `third_party/sqlite/sqlite3.c` or `sqlite3.h` amalgamation;
- absolute build paths embedded by native tooling;
- source-tree timestamps or VCS metadata;
- non-clean generated plugin registrants left by integration tests.

The release command intentionally does not pass `--no-pub`. Flutter uses that
release-mode dependency-injection pass to regenerate the ignored Android plugin
registrant without dev-only `integration_test`, while retaining the runtime
plugins. Dependency versions remain pinned by the preceding
`flutter pub get --enforce-lockfile` step.

发行命令有意不传 `--no-pub`，因为 Flutter 需要在 release 模式重新生成排除
`integration_test` 的插件注册文件；依赖版本仍由前一步
`flutter pub get --enforce-lockfile` 锁定。

When comparison fails, keep both APKs, run `zipinfo -v`, compare decompressed
trees, then use `diffoscope`. Fix the source of nondeterminism; never weaken the
gate to compare only selected files.

比较失败时应保留两份 APK，依次检查 `zipinfo -v`、解压目录和 `diffoscope`。
必须消除不确定来源，不能把门槛降级为只比较部分文件。
