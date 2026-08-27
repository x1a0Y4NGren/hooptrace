# HoopTrace UI 优化交接记录

更新日期：2026-08-27

## 当前任务与状态

本轮目标是把 HoopTrace 全应用升级为统一的“黑场编辑部”视觉，并继续优化计分页、投篮动效、结束/暂停流程及响应式体验。功能和视觉实现均已完成，独立复审结论为 **READY**，当前没有代码阻断。

- 最终分支：`codex/editorial-ui-redesign`
- Worktree：`D:\GitHub\hooptrace\.worktrees\editorial-ui-redesign`
- 当前提交：`6cdb0b8 refactor(scoring): rebalance scoreboard controls`
- 分支状态：worktree 干净；相对本地 `main` 领先 64 个提交、无分叉。
- 交付状态：尚未合并到 `main`，没有 upstream，尚未推送或发布。

## 已完成内容

- 建立编辑出版物式明暗主题、离线字体、设计令牌、共享表面/导航/比赛组件，并统一首页、赛前、计分、回放、历史、球员、规则、设置与关于页面。
- 保留并强化“飞球—拖尾—颜料落点”签名动效；支持标准、精简和系统禁用动画，失败或生命周期变化时回落到真实数据投影。
- 统一计分界面：左右各为 `+1 / +2 / +3 / 犯规` 单列；球队与比分在顶栏两端，计时严格居中。
- 最新计分布局为“返回 → 撤回 → 计时 → 更多 → 结束”；左右操作栏只显示“犯规 N”，不再重复球队名。
- 增加显式结束入口：结束面板提供“返回计分 / 暂停比赛 / 结束比赛”；暂停面板提供“返回主页 / 继续比赛 / 结束比赛”。
- 暂停/恢复与计分共用 FIFO 命令队列；失败重试复用原命令与幂等 ID，不会清除球场灰点；不可重试错误不会显示重试按钮。
- 修复结束后的返回死路、失效 `BuildContext`、弹窗 controller 过早释放、错误路由 pop、快速连续操作和补点/撤回竞态。

关键收尾提交：

- `bab856b`：显式暂停与结束控制
- `e0228a6`、`a8ae12b`：暂停转换串行化与排队意图
- `3904171`、`ea08d58`：弹窗内重试及 retry capability 修复
- `6cdb0b8`：犯规摘要去重和顶栏重新平衡

## 验证与验收材料

- `flutter analyze`：通过，无问题。
- `flutter test`：853 项全部通过。
- 计分页专项：102 项通过；四张计分页中英文/明暗 Golden 已更新并人工检查。
- Android 主流程 integration test：1/1 通过（截至 `ea08d58`；之后仅修改展示布局）。
- `6cdb0b8` 已完成 Debug APK 构建、安装和模拟器实机检查。
- APK：`D:\GitHub\hooptrace\.worktrees\editorial-ui-redesign\build\app\outputs\flutter-apk\app-debug.apk`
- 最终计分页截图：`D:\temp\hooptrace-rebalanced-scoring.png`
- 暂停面板截图：`D:\temp\hooptrace-final-paused.png`

## 未完成或待决策事项

没有实现卡点。后续仅需用户决定是否：

1. 将 `codex/editorial-ui-redesign` 快进合并到 `main`；
2. 推送分支或 `main`；
3. 清理大量阶段性 worktree；
4. 进入 Release/商店发布流程。

执行合并前先检查主工作区。当前根目录有未跟踪的 `AGENTS.md`、`HANDOFF.md`、`android/.settings/` 和 `artifacts/`；不要误删或覆盖用户文件。

## 踩过的坑

- `flutter test integration_test/...` 会生成/安装测试 runner APK。设备验收前必须再次执行普通 `flutter build apk --debug`，否则启动后可能只看到启动页。
- 比赛结束会触发 Provider 重建；结束命令前应保存路由对象，成功后使用 canonical `go()`，不要继续使用可能失效的页面 `BuildContext`。
- 弹窗必须由自己的 `dialogContext` 关闭。通用 `Navigator.pop()` 可能误关上层结束确认或错误路由。
- 暂停/恢复不能绕过计分命令队列，否则忙碌时暂停意图可能被静默丢弃；重试必须检查 `canRetry`。
- Pause/Resume 的成功重试不能调用 `cancelCourtFirstShot()`，否则会误删未提交灰点。
- 文本输入弹窗应完整持有 controller 生命周期；过早释放曾触发 `_dependents.isEmpty` / disposed assertion。
- Golden 测试必须使用生产字体并人工查看差异；不要只因像素变化就批量接受。
- Android 模拟器或 ADB 偶尔会掉线。先运行 `adb devices`，必要时重新启动 `Pixel_API_36`，再继续安装和截图。
