# Changelog

本项目的显著变更记录在此文件中，版本号遵循 Semantic Versioning。

## [Unreleased]

### 1.0 release candidate / 1.0 发布候选

- 完成离线单挑计分、可恢复比赛、规则/球权、分页历史、复盘审计和真实数据覆盖分析。
- 提供版本化备份的安全替换/确定性合并、用户授权目录自动备份及保留策略。
- 完成简体中文/英文、系统/浅色/深色主题、自适应布局、无障碍和 Android 16 适配。
- 建立性能基准、API 36 集成验证、未签名可复现构建和 iOS 无签名编译门槛。

The 1.0 entry will be dated only after the signed release tag and all RC gates
are complete. Until then, this section describes the release candidate and is
not a published version.

## [0.1.0] - 2026-08-21

### Added

- Android 优先的离线单挑篮球计分、犯规与规则提示。
- 标准半场投篮落点、比赛复盘、历史记录和单场分析。
- 球员与规则模板管理，以及带审计日志的赛后修正。
- JSON 完整备份、CSV 数据导出、复盘图片和可选自动备份。
- Android 主流程集成测试、发布文档与 GitHub Actions CI。

### Changed

- 使用正式应用标识 `io.github.x1a0y4ngren.hooptrace` 和 HoopTrace 启动图标。
- 计分页顶部信息在小屏横屏和长球员名称下保持稳定布局。
- 未配置正式密钥时，上游 Release 构建明确失败；未签名构建必须显式选择。

[Unreleased]: https://github.com/x1a0Y4NGren/hooptrace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/x1a0Y4NGren/hooptrace/releases/tag/v0.1.0
