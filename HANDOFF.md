# HoopTrace 2.0 候选交接记录

更新：2026-10-04 · 版本 `2.0.0+4` · 完整旅程验收检查点 `94bb58e094736dfeaf42e524e308236de876a059`。

本轮在隔离worktree `C:/Users/48029/.codex/worktrees/hooptrace-v2/hooptrace`、分支 `codex/hooptrace-v2` 完成可执行范围。v2 实施期间，原 `D:/GitHub/hooptrace` 的 24 项既有文档修改完整保留；未push、合并、创建tag或GitHub Release。公开正式版仍为 v1.0.0，**不标记发布就绪**。

## 项目文档同步（2026-10-03）

本轮按后续请求，将原工作区已有的指导文件改进同步到候选分支，更新 AGENTS、贡献指南、PR 模板、发行模板、历史范围说明及文档入口。README 修正本地验收状态；隐私说明补齐实际自动备份策略和 2.0 私有安全副本，安全政策修正过期的 1.0 候选表述。

原工作区 main 的应用仍为 `1.1.0+3`；其 README/HANDOFF 已注明候选所在分支与本机路径，已有的 1.1 交接内容保留。文档同步前的原文已独立保存，原工作区改动继续保持未提交。本轮只校对文档与链接，不重建 APK、不将旧验收改标为新提交；上方应用源码、现有 APK 和发行阻断项保持原有来源。

完整文档入口见 [docs/README.md](docs/README.md)；指导规则以 [AGENTS.md](AGENTS.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md) 为准。文件实际版本、工作区状态与 APK 来源分别记录，避免将候选实现当作 main 已合并或正式已发布。

## 正式标识替换（2026-10-04）

用户明确批准 C「独眼球怪」并要求淘汰旧标识。内置 ImageGen 生成透明源图后，统一三色与单色源图、Android/iOS 启动器和原生启动画面、Flutter 入口、两语言商店图标及 README。旧 hoop PNG、原生引用和直接绘制篮板／篮网／轨迹的入口画笔已删除；新入口采用同一球怪的弹跳、轻微倾斜和落地回弹，保留跳过、反馈、关闭动画及进程内播放契约。

来源、生成命令和本轮资源／入口／Android 检查见[品牌记录](docs/design/brand/README.md)及[本轮验收](docs/design/brand/verification.md)。下方完整旅程结果与 `94bb58e` APK 保留原始来源，不包括本次标识替换。原 main 的未提交文档不变；签名、远端 CI 和 macOS 条件仍是发行阻断项。

## 实现

三入口与保留浏览状态、有界最近三场、紧凑开赛/档案创建/预填交换、统一横屏记录/补点/撤回/重试/可跳过指引、终场总结/再赛/档案关联/分享/成长已贯通。完整度确认与纠正保留事务/审计/receipt/旧指纹，FG/FT分开且不完整或零出手不给可信百分比；落点采用确认运动战落点/记录运动战出手。

替换和回退先在数据库外保存回读验证的原子安全副本，写预留覆盖全过程，保留两份，活动比赛阻断。schema3/JSON2不变，支持schema2升级及两组旧备份。导入导出统一32MiB/100k单表/200k总行上限，不删receipt。实际分享裁切、旧自动备份trigger冷启动Sqlite1555、历史刷新及复盘统计/大字体布局已修复。

`3c829d5` 修正落点13%·1/8与200%分析；`94bb58e` 修正英文大字体竖屏误分栏。详细范围、双语发行说明、来源和限制见[候选记录](docs/release/v2.0.0-candidate.md)与[升级指南](docs/release/v2.0.0-upgrade.md)。

## 完整旅程检查点验证与产物（94bb58e）

- 当前源码：1093项全量通过、全仓分析无问题、291文件格式0改动；WindowsGolden无更新，Linux24项无更新通过；主机查询历史查询 15.464ms、复盘投影 50.827ms 均低于 500ms。
- 当前源码API24/36 main_loop各+1、退出0；当前MAIN Debug实际复盘13%·1/8与中英文200%亲验，集成测试后MAIN重建SHA一致，user10三场/档案/备份保留、临时设置恢复。
- 输入未变的备份/文件恢复/比较/命令性能/原生JUnit/依赖/分享证据复用且不改标：SwiftShader命令p95=81.951ms/100低于100ms；宿主GPU失败623.61ms并列保留。详见reused-inputs.json与候选逐项记录。
- 两份fresh源码固定路径unsignedRelease完整APK字节一致；版本/权限/allowBackup/证书报告/校验和齐全。可安装Debug：`D:/DevCache/HoopTraceV2Artifacts/94bb58e/hooptrace-2.0.0+4-debug.apk`；unsignedRelease及SHA256SUMS同目录。
- 8张真实Fastlane发行图仍为3a未改动页面来源，新复盘PNG/metadata另记当前源码；真实share/SAF/受控Worker文件、授权失效、旧库启动及进程重启证据保留原始提交。

## 仍需条件

正式keystore存在且公开证书与v1一致，但没有可用签名配置/凭据；私钥与正式同证升级未验证。远端CI无当前通过证据，Windows没有macOS iOS无签名编译条件。它们是发行阻断项，Debug/未签名包不得替代。自然24小时调度、失效授权后台Worker、实体折叠屏及跨runner复现范围仍未验；不扩张已记录模拟器/受控fixture结论。

完成剩余门槛后按[发行清单](docs/release/release-checklist.md)复核。后续纯文档提交不改变上面的应用来源；没有新的发布授权。
