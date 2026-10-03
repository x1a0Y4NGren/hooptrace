# HoopTrace 2.0 候选交接记录

更新日期：2026-10-03 · 当前源码版本：`2.0.0+4` · 验收源码：`3a0166c3a4a510e76a3093142a8b2d559ba7be93`

## 当前状态

本轮在隔离 worktree `hooptrace-v2` 实施 2.0 候选。当前公开正式版仍为 [v1.0.0](https://github.com/x1a0Y4NGren/hooptrace/releases/tag/v1.0.0)；未创建 2.0 tag 或 Release，不标记发布就绪。默认位置的正式 keystore 存在，公开证书指纹与历史发行记录一致，但 `android/key.properties` 和可用签名凭据缺失，尚未验证私钥可用性；同证覆盖升级与签名候选阻断。远端 CI 与 macOS iOS 无签名构建亦无本轮通过证据。

核心计分、历史、复盘、分析与备份继续离线，无账号、广告、追踪、遥测或项目后端。详细范围、实施与逐项验收见[候选记录](docs/release/v2.0.0-candidate.md)，升级前阅读[升级与备份指南](docs/release/v2.0.0-upgrade.md)。

## 已实施范围

- 比赛、历史、球员三个主入口；最近结果打开总结，球员列表优先打开生涯。赛前、横屏计分、总结、复盘作为全屏流程。
- 赛前临时/已有/新建球员、最近配置、交换双方与规则摘要。MatchSetupPreset 只复制参与者及规则；新比赛不继承比分、事件、计时或完整度声明。
- 实际设备复核后在 `1a98458` 修正规则摘要首屏可见性、无计时比赛误标“暂停”，并统一“历史 / 本场姓名”及不修改档案的提示；新增 6 项回归。
- `117105b` 修复实际 Android 分享图片中记录范围/报告指标被裁切的问题，新增导出可见性回归；`37766b7` 修复启用自动备份后冷启动的 Sqlite1555：触发器使用无重复键插入与显式更新，启动写入内置规则前先修复旧文件触发器。
- `3a0166c` 补充真实命令载荷的精确容量边界及固定重赛时钟测试；触发器回归验证重复键 REPLACE/IGNORE、UPSERT、dirtyRevision、dirtySince 和事务回滚。schema 3 / JSON 格式 2 保持。
- 横屏固定双方 `+1 / +2 / +3 / 未命中`，48dp 主目标要求保持；增加保存状态、上一步操作、失败重试和可跳过的三步指引。
- 结束确认同时支持出手完整度；总结从 MatchDetail 投影展示比分、关键回合和范围，支持档案关联、再赛、复盘和报告分享。
- FinishMatchCommand 可选 coverage 字段为 null 时不进入 payload，保留旧 receipt 指纹；SetTrackingCoverageCommand 显式修正、写 edit 审计和 receipt，不进入现场撤回。
- FG% 和 FT% 分开，未声明完整出手或零分母显示无数据；确认落点覆盖使用已记录投篮出手分母。生涯曲线按比赛顺序显示，缺失可信样本保留间隙。
- 球员统计 CSV 13 列，只汇总 finished/archived；档案按 ID 聚合，临时参与者按比赛+参与者 ID 独立，同名不合并。原始比赛/事件 CSV 保留原范围。
- 替换/回退前强制在数据库外保存安全副本；写入 flush、回读完整校验、同目录 rename 后才恢复。SQLite 非变更写预留覆盖采集、落盘和恢复，阻断并发业务写。
- 安全副本页列出最近两份有效副本，活动比赛禁用替换/回退，恢复前也保护当前状态；成功替换后才清理保留。恢复后自动备份配置重置。
- schema 仍为 3，JSON 仍为格式 2；接受格式 1/schema 2 与格式 2/schema 3。导出和导入同为 32 MiB、单表 100,000 行、合计 200,000 行限制。

## 当前验收证据

主机全量与跨平台界面验证已通过；设备、构建和签名门槛单独记录：

| 检查 | 结果 |
| --- | --- |
| 预设/赛前 | 64 项通过（执行账本） |
| 生涯成长 | 14 项通过（执行账本） |
| 备份核心既有回归 | 112 项通过（执行账本） |
| 安全副本设置页面 | 6 项通过，中英/大字体/错误与取消覆盖 |
| CSV/导出/真实命令长比赛 | 21 项既有定向通过；最新 1,080 项全量覆盖 DB 关闭顺序与新增精确容量边界 |
| 定向导出 Dart 分析 | 无问题 |
| 版本/文字元数据/文档链接 | 源码与最新 3a0166c Debug/未签名 release APK 均为 2.0.0 / 4；此前文字元数据校验退出 0；新 8 图已更新，最终 metadata 与文档统一复核待执行 |
| Android runtime 坐标 | 本轮 fresh 导出与固定清单均为 67 项，字节一致；SHA-256 `af32d63257ccab67f5058cef89b561abb605580ef0458ab7c3971e46c8ed327e`；notices 确定性生成 |
| 候选全仓分析/测试/格式 | `3a0166c` 最新 1,080 项通过（54 秒）；分析无问题（4.6 秒）；290 文件格式 0 改动 |
| 设备复核 UI 回归 | 6 项实际 RED → GREEN；78 项既有定向通过，包含在最新 1,080 全量 |
| 分享指标与启用备份后启动修复 | 导出可见性回归与实际最终 PNG 接收通过，7 项指标/范围/样本说明完整可见；两个 Sqlite1555 回归及冲突/回滚断言 RED → GREEN；最新 Debug 覆盖旧 trigger 文件后 API 36 user 10 冷启动成功，8:11、3 档案、enabled=true/目录/lastBackup 保留 |
| 实际 schema 2 文件升级 | 官方 schema 2 文件迁移/规范表保留、审计/receipt 幂等、撤回和 schema 3 再次打开均通过 |
| 历史刷新 | 42 项定向且全量通过，保留搜索/筛选/滚动和已加载范围，查询 ≤20 行/次 |
| 主机查询性能 | 20 行历史 20.117ms；1,009 事件复盘投影 57.86ms；500ms 阈值保持 |
| Android API 36 最终集成 | 3a0166c / synthetic user 11：main_loop、v2_file_recovery、2026-10-03 resumed player_comparison 各 +1 / All tests passed、退出 0；最终 command_performance 失败，不能称四项通过；user 10 force-stopped 保留 native 验收数据 |
| Android 命令性能 | 已通过（SwiftShader 复验） | 2026-10-03 final p95 81.951ms / 100、退出 0，阈值 100ms；宿主 GPU 条件的 623.61ms / 退出 1 并列保留。产品/测试输入未变，条件差异不证明唯一根因；65.574ms 为历史记录 |
| Android native JUnit | 4 项通过，0 failure / error / skip；原生文件/工作策略输入未变，可复用单元证据；不等于 SAF 手动通过 |
| 主应用 Debug 构建 | 最新 3a0166c 包 63.4 秒通过，195,977,590 字节，2.0.0 / 4、min 24 / target 36、allowBackup=false；固定外部 APK/SHA 与报告已保存 |
| Android API 36 实际进程重启 | b5e1012 基础 force-stop/COLD 证明保留；最新 3a0166c 在同一 synthetic user 10 旧文件与启用备份配置上冷启动成功，旧 trigger 自动修复，8:11 与 3 档案保留 |
| Android API 24 | 最新 3a0166c / emulator-5556 / synthetic user 0：main_loop 和 v2_file_recovery 均退出 0、各 +1；实际 SQLite 文件关闭重开/provider rebuild。另安装固定最终 MAIN Debug、关闭 Wi-Fi/data 后冷启动至主页成功，XML/截图记录中；文件重开不能替代进程重启 |
| 真实后台自动备份写入 | 已授权到期应用+唯一 WorkManager 元数据 fixture，Launcher 在前台，worker SUCCESS；独立 actual SAF provider/文件字节证明 80,195 字节/SHA 4de664bc…371a5c，12 表共 62 行与 manifest 全匹配，lastBackup 推进/dirty=false；不是自然 24 小时调度 |
| 前台完赛后的立即自动备份 | 07:26 / 07:36 两份实际 JSON 有正常 UI 结束、已提交 finish receipt、provider 时间/字节和生产 callback 路径的归因证据；不是另一次已观察到的 headless worker，不扩展自然 24 小时调度结论 |
| 实际后台 JSON 生产校验/恢复 | 额外主机产物验收 +1：实际 80,195 字节文件通过完整 checksum/row/domain/graph/limit、内存恢复与再次导出/decode；8:11、1 比赛/3 档案/9 事件/29 审计与 IDs 顺序保留，不计入 tracked 1,080 全量，不是设备重新导入 |
| SAF 授权失效与重新授权 | 完整 structured proof：仅 user 10 own UID 授权 3 → 无；立即备份明确不可写/上次成功仍 07:12，失效后冷启动 8:11 主页正常；真实 TREE 再授权后 07:19 新写入 80,196 字节 JSON/SHA 54a51118…503d9；未另 force 失效授权下 worker |
| 未签名可复现构建与 release 权限 | 最新 3a0166c 两次 fresh 快照构建 164.5 / 168.3 秒；完整 APK 字节一致，76,471,900 字节、SHA 4eae1040…fc217d；同机固定路径，无跨 OS 结论；release 无 INTERNET，allowBackup=false，签名报告 DOES NOT VERIFY |
| Windows/Linux Golden | 每平台 21 张；Windows 最新全量含全部 Golden，无更新通过；Linux 最新三文件无更新 24 项通过；此前 21 份复制 SHA 一致，变更 8 张/平台由主任务逐图检查 |
| 最终实际 PNG 分享目标接收 | 已通过：3a0166c ACTION_SEND，provider MIME=image/png，167,173 字节、2700×1688、SHA 75bbac18…ddab6d，原图已亲验；不使用旧 PNG |
| v2 真实设备截图 | 25 张 3a0166c MAIN Debug 原始采集图；8 张原样写入 Fastlane，中英各 home/scoring/summary/history，SHA 与原图一致，主任务原图亲验；另亲验 200%/大窗口/Backup/Career。来源见 screenshots.json，旧 3-replay.png 已由 3-summary.png 替换 |
| 整分支最后范围审查 | final_candidate_review 对 117105b/37766b7/3a0166c 源码与产物只读审查，报告无已验证 P0/P1/P2；覆盖 rollback、旧文件启动与 PNG 双语言/双主题/长名称/零值/200% 字体；未执行构建/ADB |
| 正式同证覆盖升级、签名发行 | 阻断：缺可用 key.properties 与解锁凭据；公开证书指纹匹配 |
| 远端 CI、macOS iOS 无签名构建 | 阻断：无本轮成功证据 |

长比赛 fixture 使用 135 次真实命令，保留 120 条事件（12 条撤回）和 270 条审计（135 条 receipts）。JSON 实测 3,054,170 字节、398 行；字节、每表最大行数和总行数预算同时精确等于实测值时可往返与分享（调用 1 次），同载荷在低一字节或低一行预算下拒绝，原数据保留。精确取等号的是该 fixture 的 3,054,170 字节/270 单表行/398 总行预算，不是 literal 32 MiB/100,000 单表行/200,000 总行压力测试。receipt 历史投影全部保留；该样本不是无限长度保证。

最新验收源码为 `3a0166c3a4a510e76a3093142a8b2d559ba7be93`。固定外部 Debug APK 为 `D:/DevCache/HoopTraceV2Artifacts/3a0166c/hooptrace-2.0.0+4-debug.apk`，195,977,590 字节，SHA-256 `6e08827d8a9f2dc1d30d0d1e54b66e3f4950d720bcad831c63a57d36e62d4cda`，主应用构建 63.4 秒通过；同目录有 badging、permissions、signature、manifest 和 SHA256SUMS。Debug v2 scheme 验证通过，使用 Android Debug 证书；INTERNET 来自 Flutter 调试 manifest，不能用此证书作正式覆盖升级。

最新未签名 release 固定副本为 `D:/DevCache/HoopTraceV2Artifacts/3a0166c/hooptrace-2.0.0+4-unsigned-release.apk`，76,471,900 字节，SHA-256 `4eae104031d6b9ebf726647005e9638320db0939ec25f5e6d8ca2dc0bbfc217d`。同目录 `release-{badging,permissions,signature,manifest}.txt` 和 REPRODUCIBILITY.txt 记录 2.0.0 / 4、min 24 / target 36、allowBackup=false；权限仅 WAKE_LOCK、ACCESS_NETWORK_STATE、RECEIVE_BOOT_COMPLETED、FOREGROUND_SERVICE 与应用私有 DYNAMIC_RECEIVER，无 INTERNET。签名报告为 DOES NOT VERIFY，与未签名候选一致；正式签名门槛仍阻断。

API 36 既有进程重启证明位于 `D:/DevCache/HoopTraceV2NativeAcceptance/evidence-api36/process-restart-proof.json`：b5e1012 包从 PID 7774 被 force-stop 至无 PID，再 COLD 启动至 PID 8904，保留 2:3 和两份档案。后续 1a98458 包启用备份后的启动失败实际来自内置规则 UPSERT 触发重复键，数据库完整性为 ok。最新 3a0166c Debug 已覆盖安装到同一 synthetic user 10 的旧持久化 trigger 测试库，冷启动成功；`repaired-startup-home.xml` 记录 8:11，3 档案与 enabled=true/目录/lastBackup 保留，旧 trigger 在写规则前自动修复。

真实后台写入使用明确授权的到期 fixture：仅将应用 dirtySince 与唯一 WorkManager worker last_enqueue_time 设为 now-25h，Launcher 在前台时 worker SUCCESS。实际 SAF 文件 `hooptrace-auto-20261002-071035.json` 为 80,195 字节，SHA-256 `4de664bcc88a483a3bab1e39468bb81c3660bac8b300a16b27f9f1d45f371a5c`；完整 `real-background-due-fixture-proof.json` 已合并 file_bytes_proof、provider size=80,195/mtime=1790925035556、application/json、JSON/table counts 与 `received/1790926704078-proof.json` 来源。实际字节 SHA 和 12 表/62 行计数匹配，lastBackup 推进/dirty=false。这证明已到期应用+WM 元数据夹具的真实后台写入，不证明自然等待 24 小时或自然调度。

后续 `hooptrace-auto-20261002-072638.json`（96,425 字节）与 `hooptrace-auto-20261002-073603.json`（137,694 字节）属于正常前台完赛后的立即备份。`foreground-finish-auto-backup-proof.json` 对照实际 UI、已提交 finish receipt、provider 时间/字节及生产 `_runAutomaticBackup → runAfterMatchFinish` 路径；导出时距 dirtySince 分别约 261 / 402 秒，07:10 成功后没有再注入到期元数据或强制 worker。最终 lastBackupPath 的 07:36 文件不能作自然 24 小时或另一次 headless WorkManager 证据；这些文件的触发进程未单独记录，归因依据是上述证据链。

最终实际分享 PNG 与 proof 位于 `D:/DevCache/HoopTraceV2NativeAcceptance/evidence-api36/received/`：`1790925625937-0-hooptrace-replay-match-1790917711974266.png`，167,173 字节、2700×1688、SHA-256 `75bbac18cbfa15fb3d360212456cf98ceaffcd4ddb3f8841f2e0d2bae0ddab6d`；`1790925625937-proof.json` 确认 ACTION_SEND 的目标实际收到 image/png。原图 7 指标、完整范围及记录样本说明可见，Jordan 8 / River 11、FG 88%（7/8）、FT 暂无、落点 1/8 与 fixture 相符。

实际后台 JSON 的独立 production JsonBackupCodec 校验/内存恢复/再导出验收为额外 1 项，通过日志 `.superpowers/sdd/2026-09-24-hooptrace-v2/actual-worker-backup-validation.log` 的 `ACTUAL_WORKER_BACKUP ... productionValidationAndRestore=passed`。完整 checksum/row/domain/graph/limit 与 event/audit/player IDs 顺序通过；不加到 tracked 全量 1,080 项，也不是设备重新导入。

完整 `uri-grant-revocation-proof.json` 记录仅释放 synthetic user 10 own UID1010223 的持久 TREE 读写授权：`revoked-backup-error`（07:17:24）明确不可写，上次成功仍为 07:12；`revoked-grant-startup-home`（07:17:41）保留 8:11；`reauthorized-backup-written`（07:19:23）显示新备份成功。重新授权实际文件 `hooptrace-backup-20261002-071920.json` 为 80,196 字节、SHA-256 `54a51118cfe2e432c8de5f7be48ba02e4d9c098e201d493666ccdfafdbc503d9`，来源是 `received/1790926704078-proof.json`。引用包含 source SHA/capture UTC 的最新无扩展名 XML，旧 07:12 .xml/.png 明确是撤销前对照，不充当此项证据。未另强制运行失效授权下的 WorkManager。

native 手动验收已结束并停止设备写入。三个 synthetic 比赛均由正常 UI 结束，active_sessions 为空；最终 handoff 冷启动 3176ms，系统 font/wm/全局动画临时设置已恢复原值。截图索引 `D:/DevCache/HoopTraceV2NativeAcceptance/evidence-api36/final-capture-index.json` 保存 25 图来源、fixture IDs/比分与 capture 时 active/finished；不是用最终 finished 状态倒推早期计分截图。八张发行图原样复制，见[截图来源记录](docs/release/v2.0.0-screenshots.json)，主任务排除有临时 Snackbar 的 zh-light-scoring，选用干净的 zh-dark-scoring。大窗口验收是模拟器窗口设置，未使用实体折叠屏硬件。

可复查的 native 证据副本归档在 `D:/DevCache/HoopTraceV2Artifacts/3a0166c/verification/native-api36/`，`FILES.json` 记录各文件字节数与 SHA-256；逐文件校验无差异，未归档设备数据库或签名材料。完整截图矩阵及尚未验收的页面见[截图清单](docs/release/screenshots-checklist.md)，不把 25 图采集概括为全部视觉通过。

最新可复现证据在 `build/reproducible/windows-20261002-150013-b15521e3/`：同一源码两份 fresh git archive 在同一外部固定路径 `D:/HoopTrace-Reproducibility/hooptrace-reproducible-source` 构建，完整未签名 APK 字节一致，SHA 与上面的固定 release 副本相同；locked dependencies 与构建后 lock 再核验均记录。仅验证同机同环境，未验证跨 runner/跨 OS。a3dc97e 的先前复现保留为历史记录。

API 24 最新两份日志为 `build/integration-v2-api24/main_loop_test.log`（构建 37.7 秒、安装 3.6 秒、测试 17 秒）和 `v2_file_recovery_test.log`（构建 22.7 秒、安装 3.1 秒、测试 5 秒），均 +1 / All tests passed。API 36 最终日志在 `build/integration-v2-api36-final/`：独立 synthetic user 11 的 main_loop（构建 25.2 秒/测试 69 秒）、v2_file_recovery（22.2 秒/45 秒）各 +1 / All tests passed。最初 comparison/performance 受 quota/主机停止而中断，无完成结果，不计为通过或产品失败。2026-10-03 resumed player_comparison（106.9 秒构建/166 秒测试）+1 / All tests passed；比较测试期间实际遇到模拟器休眠，唤醒后完成，166 秒不是性能基线，临时 display timeout 记录在 `display-awake-fixture-20261003.json`。同日 `command_performance_test-resumed-20261003.log` 测得 100 样本 p95 623.61ms，超过保留的 100ms 门槛，退出 1 / Some tests failed；诊断未完成前保留为性能阻断，不以既有 65.574ms 代替。原生 4 项单元与 67 项 runtime 清单输入未变。

最新全量与分析日志为 `.superpowers/sdd/2026-09-24-hooptrace-v2/final-share-backup-{full-suite,analyze}.log`；Linux 无更新结果为 `final-share-backup-golden-linux.log`。触发器 RED/GREEN 与旧文件启动 RED 分别见 `backup-dirty-upsert-{red,green}.log`、`backup-old-trigger-startup-red.log`，后者独立复现持久化旧触发器的 exact Sqlite1555。

已忽略的工作日志位于 `.superpowers/sdd/2026-09-24-hooptrace-v2/`。工具链基准为 Flutter 3.41.9、Dart 3.11.5、Java 17；本轮读取确认本地 Windows Dart 3.11.5。安装镜像/工具不等于设备流程通过。

2026-09-16 的 1.1 交接曾记录 966 项测试、API 36 主流程和 Debug 安装通过；这些是历史证据，不用于宣称本次 2.0 已通过。

## 继续验收与交付

1. 最新 3a0166c 主机格式、分析、1,080 项全量与两平台无更新 Golden 已通过；本地化/Drift 生成保留对应证据，后续修改相关输入再作针对性复验。
2. native 手动流程、授权失效/重新授权与 25 图 / 8 张发行图已归档；API36 四项在记录的环境中通过，保留宿主 GPU 623.61ms 失败与 SwiftShader 81.951ms 复验。新发现的复盘总览落点分母不一致正在修正，修复后须更新受影响界面与候选产物。
3. 最新主应用 Debug/未签名 release 固定路径/SHA 与截图来源已记录；完成新图后的最后一次 metadata 校验及文档链接/差异复核。
4. 最新 3a0166c 的同机固定路径、两份 fresh 快照完整 APK 字节一致与 release 权限已通过；保留跨 runner/OS 未验证的范围限制。
5. 待正式签名环境可用后完成同证覆盖升级、候选签名/证书/SHA-256；补齐远端 CI 与 macOS iOS 编译证据，保留已完成的最后范围审查结果。
6. 按当前授权交付候选记录与产物；发布、tag、Release 和 F-Droid 提交需后续授权。

最终验收结果补充到[候选记录](docs/release/v2.0.0-candidate.md)，不要把“已实施”改写为“已通过”。

## 保留的实现边界

- 展示筛选、未中点显隐不改变存储事件、统计、回放；隐藏位置也必须退出命中检测。
- 现场撤回按持久化审计顺序；得分后补位置先撤位置再撤事件，球场优先原子撤回。暂停、继续、结束与完整度修正不进入该栈。
- 200% 字体、600×400 横屏下恢复选择与确认弹窗必须可滚动。
- Widget 路由测试若触发 SafetyBackupStore，使用内存文件存储 fixture；FakeAsync 下真实文件 I/O 会使 pumpAndSettle 等待。
- 备份与分享继续保留事件/审计插入顺序和原 receipt 指纹；冲突合并仅重映射实体引用，不改写审计 prose 或 fingerprints。
- 应用内安全副本会随卸载/清数据丢失，不能代替用户外部 JSON；超限不通过删除记录或丢弃 receipts 规避。
- Android Integration Test 会覆盖同名 app-debug.apk；手动安装前须重新 build apk --debug。

补充检查（2026-10-03）：最终 MAIN 在集成测试后重新构建 29.9 秒，完整 SHA 与固定 3a0166c APK 相同；还原 synthetic user 11 息屏时间和全局动画设置，覆盖回 user 10 后 COLD 启动正常。补拍复盘时发现总览以得分事件作落点分母（14% vs 正确 1/8=13%），修复正在执行；当前 3a0166c 包保留为该问题的原始证据，不将它标记为正式发布就绪。
