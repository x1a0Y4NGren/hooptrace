# HoopTrace 1.1 交接记录

更新日期：2026-08-28

## 当前状态

HoopTrace v1.0.0（versionCode 2）已在 `v1.0.0` tag 和 GitHub Release 发布，当前工作基线为该发布后的 `main`（提交 `8ac4dac`）。Android APK 已发布；iOS 尚未正式发布。核心功能保持离线，无账号、云同步、广告、遥测或运营后端。

本 worktree 用于执行 1.1 Player Comparison 计划。计划执行文件位于 `docs/superpowers/plans/2026-08-28-hooptrace-1-1-player-comparison.md`，仅在本地跟踪，不进行 push、tag、Release 或 F-Droid 提交。

## v1.0 已交付

- “黑场编辑部”视觉与统一计分、回放、历史、球员、规则和设置体验；
- 可恢复活动比赛、计时/暂停/结束、撤回、赛后修正及不可变审计；
- 离线 JSON 备份、替换/确定性合并、用户授权目录自动备份；
- 简体中文/英文、明暗主题、200% 字体和 Android 优先适配；
- v1.0 发布资料、Android 签名 APK 和隐私声明已就绪。

## 1.1 约束与验收

- 保持永久免费、开源、离线优先和 1v1；不升级主要依赖；
- 保留 schema v2 数据并兼容 v1.0 format-1/schema-2 备份；
- 完成计划中的测试、性能和本地构建核验后再评估下一次发布；
- 不在本任务中执行任何远程发布、F-Droid 提交或 iOS 发布操作。

## 注意事项

- 修改 Drift 表或查询后重新生成并提交 `app_database.g.dart`；
- Golden 变更须人工检查；不要提交签名密钥、真实数据或构建产物；
- 运行完整测试时应确认没有 Drift multiple-database warning。
