# 参与贡献

感谢你为 HoopTrace 提交问题、设计建议、文档或代码。项目永久免费开源，并优先保护离线使用、数据可控和球场现场操作效率。

## 开始之前

1. 搜索现有 Issue，避免重复工作。
2. 较大的功能或数据模型变更应先创建 Issue，说明使用场景、范围和迁移策略。
3. 安全问题不要公开披露；请使用 GitHub 仓库的 Private vulnerability reporting。
4. 所有贡献都按仓库的 MIT License 提供。

## 不可破坏的约束

- 官方项目永久免费并保持开源。
- 核心计分、复盘、历史和导出必须离线可用。
- 不引入广告、追踪、强制账号、付费墙或未说明的数据上传。
- 新增网络功能前必须先完成架构和隐私评审，并且不能成为核心流程依赖。
- 不使用广泛存储权限；文件访问应由系统选择器和用户授权驱动。
- Android 是当前首发平台，但公共领域层应保持可移植性。

## 本地环境

当前基准工具链为 Flutter `3.41.9` stable、Dart `3.11.5` 和 Java 17。

```powershell
flutter pub get
flutter doctor -v
flutter test
```

涉及数据库表或 Drift 查询时，重新生成并提交 `lib/core/data/app_database.g.dart`：

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## 分支与提交

- 从最新 `main` 创建短生命周期分支。
- 推荐分支前缀：`feat/`、`fix/`、`docs/`、`test/` 或 `codex/`。
- 一个 Pull Request 处理一个明确问题，避免夹带无关重构。
- 提交信息使用命令式短句，例如 `fix: keep scoring header within compact screens`。
- 不提交构建产物、密钥、`key.properties`、设备数据或 IDE 临时文件。

## 实现要求

- 优先沿用现有 Repository、Controller、Drift transaction 和页面结构。
- 数据恢复、编辑和迁移必须有事务边界及失败回滚测试。
- 新交互需要覆盖空状态、忙碌状态、取消和错误状态。
- 触屏目标、文本截断、横竖屏及小尺寸布局必须可用。
- 对用户可见的中文文案应直接、可操作；新增本地化文案时同步 ARB 结构。
- 依赖升级应说明必要性、许可证和对 F-Droid 构建的影响。

## 测试要求

按改动风险选择最小但充分的覆盖：

- 领域规则和数据转换：单元测试。
- Repository、事务和迁移：内存数据库测试。
- 页面状态和交互：Widget 测试。
- 跨页面主流程或平台插件：Integration Test 和模拟器验证。

Pull Request 提交前运行：

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

修改主页、赛前、计分、复盘或历史主链路时，还应运行：

```powershell
flutter test integration_test/main_loop_test.dart -d <android-device-id>
```

## Pull Request 内容

描述中应包含：

- 问题和实际用户影响。
- 实现选择及重要取舍。
- 数据库、隐私、权限或兼容性影响。
- 已执行的验证命令及结果。
- 有视觉变化时附上真实设备或模拟器截图。

维护者会优先审查行为回归、数据安全、缺失测试、可访问性和发布风险。
