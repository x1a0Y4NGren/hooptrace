# 1.0 performance evidence / 1.0 性能证据

## Deterministic query fixture / 确定性查询夹具

`test/performance/task15_query_benchmarks_test.dart` creates exactly 1,000
finished matches, 2,000 participants, and 10,000 events. It measures a bounded
20-row history first page and a 1,009-event replay load plus analytics mapping.
Both hard-fail at 500 ms.

该测试精确生成 1,000 场比赛、2,000 名对局参与者和 10,000 条事件，测量 20 条
历史首屏以及包含 1,009 条事件的复盘加载/分析映射；任一达到 500ms 即失败。

Final controller run on 2026-08-24 (Windows 11, Flutter 3.41.9, in-memory
SQLite, debug test process): history first page 17.062 ms; replay projection
51.819 ms. CI logs every run with the `TASK15_QUERY_BENCHMARK` marker. These are
regression measurements, not cross-device marketing claims.

2026-08-24 主控环境参考值（Windows 11、Flutter 3.41.9、内存 SQLite、debug
测试进程）：历史首屏 17.062ms，复盘投影 51.819ms。CI 通过
`TASK15_QUERY_BENCHMARK` 输出每次结果；这些仅用于回归，不用于跨设备宣传。

## Android command benchmark / Android 命令基准

`integration_test/command_performance_test.dart` starts a real command-backed
match through `openAppDatabaseAt` and Drift's production background executor in
a temporary file, discards five warm-up writes, times 100 committed event
commands, sorts the samples, and hard-fails when p95 reaches 100 ms. The
temporary directory is removed after the database closes. The CI reference is
an Android API 36 Pixel 6 x86_64 emulator with animations disabled, running the
Flutter integration-test debug process. Results are logged with
`TASK15_COMMAND_BENCHMARK`.

Final API 36 emulator verification on 2026-08-24 recorded p95 80.061 ms for
100 samples, below the 100 ms gate.

该集成测试启动真实命令层比赛，丢弃 5 次预热，测量 100 次已提交事件命令并计算
p95；达到 100ms 即失败。CI 参考设备为关闭动画的 Android API 36 Pixel 6
x86_64 模拟器，运行 Flutter integration-test debug 进程，日志标记为
`TASK15_COMMAND_BENCHMARK`。

2026-08-24 的 API 36 模拟器最终验证记录为 100 个样本、p95 80.061ms，低于
100ms 门槛。

Run locally with:

```bash
flutter test test/performance/task15_query_benchmarks_test.dart --reporter expanded
flutter test integration_test/command_performance_test.dart -d <android-device-id>
```

Record real-device results separately with model, SoC, Android/API, build mode,
thermal state, available storage, commit, and sample count. Never replace the
CI threshold using a faster unrecorded machine.
