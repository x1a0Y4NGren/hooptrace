# HoopTrace 2.0 候选交接记录

更新：2026-10-06 · 版本 `2.0.0+4` · 最新应用源码 `480984fd61dc59dd907e435eb12e7b0eb30e11e4` · 历史完整旅程验收检查点 `94bb58e094736dfeaf42e524e308236de876a059`。

继续在隔离 worktree `C:/Users/48029/.codex/worktrees/hooptrace-v2/hooptrace`、分支 `codex/hooptrace-v2` 执行。原 `D:/GitHub/hooptrace` 的既有文档修改完整保留，当前 27 项逐文件 hash 未变。本轮按批准计划正常推送候选 `2ef56aa`，包含应用 `480984f` 的完整远端 CI 首次五项全部通过；后续文档提交不改变实际 CI／APK 来源。未合并 main、创建 PR、tag 或 GitHub Release。公开正式版仍为 v1.0.0，**不标记发布就绪**。

## 正式签名续验：口令恢复阻断（2026-10-06）

用户授权继续签名／升级后，重新核验原 keystore 哈希 `7dec9b85729f4594181e51bf71c0d1ffcf9936d3a7465c820c5867719ef3d03c`、正式 v1 APK 和原证书均一致；实际 v1 schema 2 基线再次通过 11 原表／rowid／审计顺序、完整性和外键核验。应用源码仍为 `480984f`，干净构建检查点为 `c7ac5fe`；原 CI `2ef56aa` 的五项成功输入不变。

已准备仓库外本机遮蔽口令窗口及正式构建入口，10 项合成辅助检查通过；Java Properties 真实解码、特殊字符、配置不覆盖／发布失败、错误口令日志不泄漏均验证。固定 Temurin 17.0.20+8 通过 492 个逐文件校验的硬链接保留在 `C:/Users/48029/.hooptrace/toolchains/temurin-17.0.20+8`，不受 `flutter clean` 删除，没有重复下载或 D 盘二进制复制，也未改全局 Flutter／Java 配置。

用户随后确认两个口令遗忘或不确定。本机窗口已关闭；两工作区、`.hooptrace`、文档同步和项目验收目录的限定配置文件名搜索均无副本。没有生成 `key.properties`、真实私钥探针或正式 v2 APK，未猜测口令、创建替代证书、新建 AVD 或恢复长期监控。现阶段需维护者找回原口令或旧配置；正式签名／同证升级／正式包设备继续阻断，不能将准备工作记作通过。材料在 `D:/DevCache/HoopTraceV2Artifacts/signed-upgrade-480984f-20261006/`，详情见[签名准备记录](docs/release/v2.0.0-signing-upgrade-verification.md)。本次仅提交本地交接文档，不推送或发布。

## 当前候选完整 CI（2026-10-06）

CI 提交 `2ef56aaad86f55f9d9a95379bf23a0f8ac516e78`、应用源码 `480984f`；[37429173938 / attempt 1](https://github.com/x1a0Y4NGren/hooptrace/actions/runs/37429173938) 首次 **5/5 作业全部成功**：质量／Debug、API24 两项集成、API36 四项集成、两份 fresh 未签名 Android 完整字节一致、macOS iOS 无签名 Release。1173 项远端 Flutter、63 项工具及 16 项 schema 通过；查询历史／复盘为 15.951／48.247ms，API36 命令 p95 为 37.332ms／100 样本，原门槛不变。

仓库外 `D:/DevCache/HoopTraceV2Artifacts/ci-480984f-20261006/run-37429173938/attempt-1/` 保存五份完整日志、终态、产物 metadata、独立核验和 `SHA256SUMS`。CI 报告未签名 APK SHA-256 `689c1e0724241c54a5f27c448b343c5ae3b93757ea9d39722603ceb706c0366d`；没有下载重复二进制，不声称本机回读或 Debug APK 的远端哈希。未改应用／工作流，无重跑，未建立本地设备；main 27 文件哈希未变。后续纯文档提交只同步记录，详见[本次 CI 验收](docs/release/v2.0.0-final-ci-verification.md)。正式签名／同证升级／正式包设备仍待条件，CI 不证明旧 ANR 根因已消除；自然调度未测且非阻断。

## 清理后的续验（2026-10-06）

用户要求继续中断任务后，仅建立一台可删除的合成 API36：`HoopTrace_V2_Resume_API36 / emulator-5564 / user10`，不操作原 Pixel 或真实数据。发现计分页将已累计的时钟投影再次计算，现场显示偏快，持久库与终场时长未重复累计；`480984f` 修复显示读取并保留到时／回退停止状态。两项正／倒计时回归先失败再通过，计分模块 110 项、分析、1173 项全量 Flutter 通过。新 Debug APK 位于 `D:/DevCache/HoopTraceV2Artifacts/resumed-acceptance-20261006/hooptrace-2.0.0+4-480984f-debug.apk`，SHA-256 `d09b4e9dc3baa2f66da7ce079faaa924bd9cc5076829b1e60905b3860b868e47`；版本、schema、JSON 不变。

新包保留合成数据覆盖安装后，恢复暂停、继续／记分／撤回、真实冷进程及下一步撤回通过；12 表及 rowid 在冷进程前后相同，运行显示按 Android epoch 和数据库 anchor 核对通过。实际记到 100:0，主要记分不显示可信命中率；最近配置 999 双击开始仅建一场，零事件且不复制完整度，显式完整零出手无百分比。成长页混合两场场均 54.5，完整场 FG/FT 为 100%/50%，不完整场图表留空。

实际当前 UI 导出 JSON 447,497 字节，12 组／175 行，SHA-256 `ffcc8ccdd2ac0a6cb9bfa90815c414ba59912a44c3e37429e3655a2bb12863a9`；生产 codec 恢复及第二次导出字节一致，证明附件独立核验通过。新证明 SHA-256 `346e1c4ae1de3cc0101cd5f9189701c59e0fe133eca22d06883551d9a30e534a`。损坏 checksum 拒绝并无成功证明。原 `996146f` 验证器和旧证据不改写。

正常 SAF 选取实际 JSON 后三场／两档案替换为两场／一档案，再通过手机安全副本回退恢复原三场／两档案；11 组业务及设置表字段、47 事件及 117 审计插入顺序相同，回退前也生成保护文件，实际保留两份。派生快照在保护导出时从 2 刷新为 4，独立记录而非声称全表行数不变。英文暗色 200% 字体目标输入／键盘／取消可用，关闭系统动画的真实冷启动进首页。设备、字体／主题／语言／动画／HWUI 临时设置恢复并回读；专用 AVD 已删除、原 Pixel 保留，ADB 无运行设备，D 可用约 53.97 GiB。main 27 文件、历史验证器 95 文件和既有六项关键哈希再次核验未变。

初始旧包 guest HWUI Vulkan 出现真实输入 ANR，完整线程栈显示 HWUI／gfxstream 提交等待；切换该独立设备的新进程后，实际 `Pipeline=Skia (OpenGL)` 下完成功能续验。它不证明根因消除，也不覆盖旧 T1 性能。日志、失败读样本、截图及文件库在上述仓库外目录，精确范围见[计时与设备续验](docs/release/v2.0.0-clock-device-verification.md)。旧启动／平台输入不变的证据保留原源码；该续验轮结束时新应用 CI 尚未运行；后续获授权的完整 CI 已在上方记录。正式签名／同证升级／正式包设备继续阻断，自然调度仍未测且非阻断。设备续验轮没有推送、发布或重启长期监控。

## 剩余验收与 D 盘清理（2026-10-06，清理阶段记录）

用户取消长期监控后，已删除暂停的 `hooptrace` 自动任务；自然调度准确保留为未完成实测的非阻断项。当前 `996146f` 生产 codec 合成自测和证明身份保护已完成，实际当前包 UI 导出 JSON 及其恢复证明仍待验。独立 API24 已安装正式 v1、加载真实 v1 命令生成的合成 fixture，实际取库核验 schema 2 的 11 表原始夹具行、rowid 及审计顺序保持；v1 初始化另加 4 条内置规则，规则总数 1→5，并非全表行数不变。正式 v2 签名条件仍缺失。独立 API36 仅完成当前 Debug 身份、离线首页和取消不建比赛，其余完整旅程尚未完成。

验收过程中用户要求优先释放 D 盘：先通过 Android 自带管理器删除六台专用测试 AVD（含本轮 5564／5566），通过 main Gradle `:app:clean` 清理 app 构建输出，释放约 41.21 GiB。普通文件删除被自动审批拒绝后，用户在本机执行核对脚本，余下 42 项旧 APK／Linux Golden 工具副本／Gradle transforms 已全部删除；执行日志无错误，再只读核验全部路径不存在。第二轮卷空间增加约 14.23 GiB，D 当前可用约 57.12 GiB，两轮累计约 55.45 GiB。原 Pixel、正式 v1、当前两个 APK、95 个历史恢复验证文件、小型证据和原 main 27 个未提交文件均核验保留；原待清理清单保存历史状态，最新结果为外部 `cleanup-completed-verification.json`。设备验收的未完成项保持待验。详情见[本轮剩余验收与清理](docs/release/v2.0.0-remaining-acceptance.md)。下方各历史设备运行状态只描述当时，六台已删除设备需有实际验收需求时再复建。

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

正式 keystore 公开证书与 v1 一致，但没有可用签名配置／凭据；正式同证升级及正式包设备验收仍阻断。最新应用源码 `480984f` 本地通过，CI 提交 `2ef56aa` 首次五项全部成功；`996146f` 启动输入未变，10-06 硬件 GPU 环境 40 次标准动作与独立录屏通过，保留该原来源。工具 `89ed822` 的旧 CI 保留原来源，新计时修复已有独立完整 CI 记录。用户已将 24 小时自然调度改为非阻断项并取消长期监控；旧区间仍为中断 pending，应用自动备份功能保留。授权失效 Worker 及历史旅程保持 `a51203c` 来源；不扩张模拟器／受控 fixture 结论。

完成剩余门槛后按[发行清单](docs/release/release-checklist.md)复核。后续纯文档提交不改变上面的应用来源；没有新的发布授权。
