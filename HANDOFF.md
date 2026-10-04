# HoopTrace 2.0 候选交接记录

更新：2026-10-04 · 版本 `2.0.0+4` · 最新应用源码 `ec9efae59da86d595cab8c2391dcc5494404afaa` · 完整旅程验收检查点 `94bb58e094736dfeaf42e524e308236de876a059`。

本轮在隔离worktree `C:/Users/48029/.codex/worktrees/hooptrace-v2/hooptrace`、分支 `codex/hooptrace-v2` 完成可执行范围。v2 实施期间，原 `D:/GitHub/hooptrace` 的 24 项既有文档修改完整保留；未push、合并、创建tag或GitHub Release。公开正式版仍为 v1.0.0，**不标记发布就绪**。

## 项目文档同步（2026-10-03）

本轮按后续请求，将原工作区已有的指导文件改进同步到候选分支，更新 AGENTS、贡献指南、PR 模板、发行模板、历史范围说明及文档入口。README 修正本地验收状态；隐私说明补齐实际自动备份策略和 2.0 私有安全副本，安全政策修正过期的 1.0 候选表述。

原工作区 main 的应用仍为 `1.1.0+3`；其 README/HANDOFF 已注明候选所在分支与本机路径，已有的 1.1 交接内容保留。文档同步前的原文已独立保存，原工作区改动继续保持未提交。本轮只校对文档与链接，不重建 APK、不将旧验收改标为新提交；上方应用源码、现有 APK 和发行阻断项保持原有来源。

完整文档入口见 [docs/README.md](docs/README.md)；指导规则以 [AGENTS.md](AGENTS.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md) 为准。文件实际版本、工作区状态与 APK 来源分别记录，避免将候选实现当作 main 已合并或正式已发布。

2026-10-04 本轮再次同步项目级文档：AGENTS/贡献指南补齐候选启动契约和证据要求，README、文档索引、PR/发行模板与候选记录同步最新应用来源和剩余门槛；修正已完成安装/设置恢复仍显示待补的交接文字。本轮仅执行文档内容、链接及 diff 检查；原 main 既有改动继续保留，各 APK 来源不变。

## 正式标识替换（2026-10-04）

用户明确批准 C「独眼球怪」并要求淘汰旧标识。内置 ImageGen 生成透明源图后，统一三色与单色源图、Android/iOS 启动器和原生启动画面、Flutter 入口、两语言商店图标及 README。旧 hoop PNG、原生引用和直接绘制篮板／篮网／轨迹的入口画笔已删除；新入口采用同一球怪的弹跳、轻微倾斜和落地回弹，保留跳过、反馈、关闭动画及进程内播放契约。

来源、生成命令和本轮资源／入口／Android 检查见[品牌记录](docs/design/brand/README.md)及[本轮验收](docs/design/brand/verification.md)。下方完整旅程结果与 `94bb58e` APK 保留原始来源，不包括本次标识替换。原 main 的未提交文档不变；签名、远端 CI 和 macOS 条件仍是发行阻断项。

## 实现

2026-10-04 后续启动动效：按用户批准的 Q 弹方案加入 48×48 纹理网格、衰减水波和局部余波；启动静音无震动，慢初始化显示静态品牌等待，淡出保留页面实例，跳过平滑归零。设计与本轮独立验证见[启动动效记录](docs/design/brand/entry-motion.md)。既有完整旅程、标识替换 APK 和发行阻断项仍保留各自来源。

本轮最终应用源码 `ec9efae59da86d595cab8c2391dcc5494404afaa`：1125 项全量测试、静态分析、Dart 格式及 11 项 Python 回归通过；9 张亮色 Golden 覆盖阶段及双语窄屏 200% 字体，暗主题通过 API36 实际启动检查。Linux 9 项 Golden 复用 `cce17cd` 生产快照及文字基准修正，其静态帧输入未受后续单次解码修复影响。

Profile 与 Debug 最终构建成功。调试 APK 为 `D:/DevCache/HoopTraceV2Artifacts/entry-motion-20261004/hooptrace-2.0.0+4-elastic-debug.apk`，SHA-256 `C6C3BAAEBB25DEB1A7FD2D5F8D9ED1F9544852CB854E8AECABCBD4E67E61D35A`；Android Debug 签名，非正式发行包。API36 SwiftShader 恢复后的 10 次冷启动包含 1 次标准动作、9 次降级淡出；可见阶段构建/绘制 p95 为 83.925/160.203ms，**16.7ms 门槛未通过**，10 次完整动作及实体设备流畅度未验收。最终 Debug 已覆盖安装并通过冷启动及返回前台检查，既有比赛保留，测试设置已恢复。标准动作直至首页的完整连续设备录屏仍未验收；Flutter 渲染预览和设备录屏分别保留范围。旧测量和中断记录均独立保留，后续文档提交不改变 APK 来源。

三入口与保留浏览状态、有界最近三场、紧凑开赛/档案创建/预填交换、统一横屏记录/补点/撤回/重试/可跳过指引、终场总结/再赛/档案关联/分享/成长已贯通。完整度确认与纠正保留事务/审计/receipt/旧指纹，FG/FT分开且不完整或零出手不给可信百分比；落点采用确认运动战落点/记录运动战出手。

替换和回退先在数据库外保存回读验证的原子安全副本，写预留覆盖全过程，保留两份，活动比赛阻断。schema3/JSON2不变，支持schema2升级及两组旧备份。导入导出统一32MiB/100k单表/200k总行上限，不删receipt。实际分享裁切、旧自动备份trigger冷启动Sqlite1555、历史刷新及复盘统计/大字体布局已修复。

`3c829d5` 修正落点13%·1/8与200%分析；`94bb58e` 修正英文大字体竖屏误分栏。详细范围、双语发行说明、来源和限制见[候选记录](docs/release/v2.0.0-candidate.md)与[升级指南](docs/release/v2.0.0-upgrade.md)。

## 完整旅程检查点验证与产物（94bb58e）

- 该检查点源码：1093项全量通过、全仓分析无问题、291文件格式0改动；WindowsGolden无更新，Linux24项无更新通过；主机查询历史查询 15.464ms、复盘投影 50.827ms 均低于 500ms。
- 该检查点源码API24/36 main_loop各+1、退出0；当前MAIN Debug实际复盘13%·1/8与中英文200%亲验，集成测试后MAIN重建SHA一致，user10三场/档案/备份保留、临时设置恢复。
- 输入未变的备份/文件恢复/比较/命令性能/原生JUnit/依赖/分享证据复用且不改标：SwiftShader命令p95=81.951ms/100低于100ms；宿主GPU失败623.61ms并列保留。详见reused-inputs.json与候选逐项记录。
- 两份fresh源码固定路径unsignedRelease完整APK字节一致；版本/权限/allowBackup/证书报告/校验和齐全。可安装Debug：`D:/DevCache/HoopTraceV2Artifacts/94bb58e/hooptrace-2.0.0+4-debug.apk`；unsignedRelease及SHA256SUMS同目录。
- 8张真实Fastlane发行图仍为3a未改动页面来源，新复盘PNG/metadata另记当前源码；真实share/SAF/受控Worker文件、授权失效、旧库启动及进程重启证据保留原始提交。

## 仍需条件

正式keystore存在且公开证书与v1一致，但没有可用签名配置/凭据；私钥与正式同证升级未验证。远端CI无当前通过证据，Windows没有macOS iOS无签名编译条件。它们是发行阻断项，Debug/未签名包不得替代。自然24小时调度、失效授权后台Worker、实体折叠屏及跨runner复现范围仍未验；不扩张已记录模拟器/受控fixture结论。

完成剩余门槛后按[发行清单](docs/release/release-checklist.md)复核。后续纯文档提交不改变上面的应用来源；没有新的发布授权。
