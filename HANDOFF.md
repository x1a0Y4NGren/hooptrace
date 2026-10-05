# HoopTrace 2.0 候选交接记录

更新：2026-10-06 · 版本 `2.0.0+4` · 最新应用源码 `996146ff5c57efd5c4920dbb5e2955413af33af2` · 历史完整旅程验收检查点 `94bb58e094736dfeaf42e524e308236de876a059`。

继续在隔离 worktree `C:/Users/48029/.codex/worktrees/hooptrace-v2/hooptrace`、分支 `codex/hooptrace-v2` 执行。原 `D:/GitHub/hooptrace` 的既有文档修改完整保留，当前 27 项逐文件 hash 未变。本轮按明确授权推送候选分支并运行 CI；未合并 main、创建 PR、tag 或 GitHub Release。公开正式版仍为 v1.0.0，**不标记发布就绪**。

## 启动性能环境验收（2026-10-06）

新增独立 `HoopTrace_V2_Stable_API36 / emulator-5562 / user10`。同一 `996146f` Profile APK 在 ASG／隐藏 Qt／NVIDIA Vulkan 原生合成配置下，三组共 30 次及模拟器冷重启后 10 次均为 standard；各组构建／绘制 p95 均低于原 16.7ms 门槛，合并 2597 帧为 **2.948／11.064ms**。**T1 模拟器性能与连续录屏通过**，不替代实体设备或正式包验收。应用、Logo、48×48 网格、动作和等待期限未改；120 次原始记录及八组失败均保留。

新比较工具／CI 入口为 `89ed822`，本地 Python 69 项（63 通过、6 跳过）；[新增工具 CI](https://github.com/x1a0Y4NGren/hooptrace/actions/runs/37345318798) 首轮 **5/5 作业全部通过**，包含 1171 项 Flutter、63 项 Linux 工具测试、API24／36 集成、未签名 Android 可复现构建和 iOS 无签名编译。五份作业日志与远端产物 metadata 已保存。guest／进程设置已回读恢复，新设备停止，原 5560 启动状态恢复，原 main 27 项 hash 不变。新原片、SHA 和复建步骤见[环境验收](docs/release/v2.0.0-startup-lab.md)。下方 10-05 失败结论保持原环境来源。

## 启动性能续验（2026-10-05）

本轮以首页提前挂载和绘制隔离各做十次实验，同一旧包前后绘制 p95 17.761／25.990ms 表明环境波动较大，收益未获证明，两项实验实现全部撤回。最终 `996146f` 相对 `f4ffcea` 仅保留 Profile handoff mark 和更完整的 Python presented 测量；原启动／页面时机、Logo、网格、轨迹、数据库顺序与期限不变。最终本地格式、分析、1171 项全量 Flutter、原 Golden 和 Python 59 项（53通过、6项 POSIX 跳过）通过。

独立 `emulator-5560` API36／NVIDIA host GPU／Impeller GLES 的最终十次全为标准动作；620 个 presented 帧构建／绘制 p95 **3.287／30.827ms**，原 visual 为 1.641／24.653ms，**绘制仍失败，T1 未完成**。新工具包含原生交接等待与可见静止准备，旧日志兼容原 visual；全部失败样本保留。3.034056 秒完整原片及当前 Debug／Profile 已核验，Debug 空比赛文件库冷进程 smoke／返回前台通过，首次设备读取失败及新目录重试均留证。T1 临时设置和原 foreground user0 已恢复。当前源码的 [CI 37332931443](https://github.com/x1a0Y4NGren/hooptrace/actions/runs/37332931443) 首轮五项全部通过：质量、API24／36 集成、两份 fresh 源码未签名 Android 可复现构建和 macOS iOS 无签名编译。完整日志与远端产物 metadata 已保存。

自然备份 `emulator-5556` 与防休眠进程已停止，最后同 boot 记录停在 10-05 22:32:56，距原基线仅 27110 秒／27109.78 秒；旧区间不能通过。原 `a51203c` APK 来源、基线及中断前后 status 保留，未重启或重置，新的完整区间需要另行授权。详情及原始记录见[启动续验](docs/release/v2.0.0-startup-performance.md)和[备份设备观察](docs/release/v2.0.0-backup-device-verification.md)。下方旧记录保留历史来源，不表示当前观察设备仍在运行。

## 前一轮发布前任务（a51203c，2026-10-05）

最新源码增加 Profile 准备阶段诊断、按显示尺寸解码和逐列复用水波计算，正式 Logo／48×48 网格／节奏不变。设备验收发现动态无障碍或动画模式切换会丢弃终场确认，已修复并补三项 RED→GREEN 回归。格式、分析及 1157 项全量 Flutter 测试通过，原 Golden 未改变。备份观察工具独立审查的三项问题修复后，Windows Python 45 项与 WSL shell 6 项通过。

独立 API36 使用 NVIDIA 宿主 GPU、Impeller OpenGLES，原模拟器 user10 未动。最终十次 Profile 冷启动为 6 次标准／4 次降级，构建／绘制 p95 为 10.202／55.829ms，**性能门槛仍失败**；完整标准启动到首页的最终连续录屏已取得，录屏不替代帧预算。真实 v1 源码生成的 schema 2 合成库已在 Debug 冷进程升级到 schema 3，原 11 表与审计顺序保留，重启后按正确顺序继续两次撤回。正式 keystore 公开证书与 v1 APK 相同，正式签名配置仍缺失，不能以此 Debug 检查代替同证覆盖升级。

最终候选 CI [37268869963](https://github.com/x1a0Y4NGren/hooptrace/actions/runs/37268869963) 对应 `a51203c`，5/5 作业全部通过；已修复首轮 Android action shell 解析和 Swift nullable registrar 编译错误，API24／36 全部集成、Android fresh 可复现及 macOS iOS 无签名编译均有当前证据。API24 的离线旅程／100与999／重复开始／冷进程撤回和大字体键盘已验证；API36 的实际 JSON／PNG 分享、授权撤销 Worker、重新授权及安全副本替换／回退通过，完整度与混合成长样本按当前结果归档。自然基线于北京时间 2026-10-05 15:01:08 开始，最早 10-06 15:01:08 后方可验收；新 WorkSpec `4e982fc6-7a21-4d4d-bace-ebca8bbd05ad`，观察区间冻结应用操作。当前线程每天 16:00 继续核验（automation `hooptrace`），结果仍 pending；设备／基线路径与恢复临时设置步骤见下方验收。最终 Debug／Profile 的 hash、录屏、原始测量及逐项状态见[本轮验收](docs/release/v2.0.0-pre-release-verification.md)，签名步骤见[同证升级准备](docs/release/v2.0.0-signing-upgrade-verification.md)，自然调度规范见[备份设备观察](docs/release/v2.0.0-backup-device-verification.md)。后续文档提交不改变这些 APK 来源；本轮不进行发行收尾。

## 目标分编辑（2026-10-05）

按本轮批准方案，赛前目标分可编辑为 1～999；点击数字打开预填、全选并自动聚焦的输入框，确认或键盘完成提交。空值、0、负数、小数、非数字和超限值保留输入并显示错误；取消、返回或外部关闭不改原值，连续打开／提交均有保护。数字控件保持至少 48dp，并将朗读标签、当前值和点击动作合并为一个无障碍按钮。范围常量由控制器、加减按钮及校验共用，模板默认及重置行为不变。

最新源码 `6d1b6cc`：格式与分析通过、1151 项全量测试通过；新增 Windows／Linux 双语明暗弹窗 Golden，原赛前 Golden 未改变。数据库持久化、最近配置／交换再赛、目标达到提示及双语窄屏 200% 字体／键盘布局均有回归。schema 3、JSON 格式 2 与版本 `2.0.0+4` 不变；既有规则、历史快照和备份不迁移、不截断。最终 Debug APK 已覆盖安装，SHA-256 `00AE09F8B47C08821070032D53E01E65C501B89D2A1AF812039D3F67A01A7676`；API36 实测输入／取消／键盘完成及英文亮色 200% 字体可用，原有 11 张业务表逐行一致，临时设置已恢复。本轮 APK、实际设备截图及校验和见[目标分验收](docs/release/v2.0.0-target-score.md)。其他验收仍保留原始源码；此次不重验启动性能或正式发行门槛。

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

启动动效轮最终应用源码 `ec9efae59da86d595cab8c2391dcc5494404afaa`：1125 项全量测试、静态分析、Dart 格式及 11 项 Python 回归通过；9 张亮色 Golden 覆盖阶段及双语窄屏 200% 字体，暗主题通过 API36 实际启动检查。Linux 9 项 Golden 复用 `cce17cd` 生产快照及文字基准修正，其静态帧输入未受后续单次解码修复影响。

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

正式 keystore 公开证书与 v1 一致，但没有可用签名配置／凭据；正式同证升级及正式包设备验收仍阻断。应用源码仍为 `996146f`；10-06 新硬件 GPU 环境 40 次标准动作与独立录屏通过，T1 不再因模拟器预算阻断。新增工具 `89ed822` 的 CI 五项全部通过，原应用源码 CI 仍保留原记录。自然观察区间因设备停止中断，需新完整区间，不能继续按原 10-06 下限判通过。授权失效 Worker 及历史旅程保持 `a51203c` 来源；不扩张模拟器／受控 fixture 结论。

完成剩余门槛后按[发行清单](docs/release/release-checklist.md)复核。后续纯文档提交不改变上面的应用来源；没有新的发布授权。
