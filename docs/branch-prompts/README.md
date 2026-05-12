# HoopTrace Branch Prompts

这些文件用于在 Codex 中创建分支对话。每个分支对话只负责一个明确范围，避免多个对话同时修改同一批核心文件。

使用方式：

1. 先阅读 `docs/branch-execution-order.md`，确认当前应该启动哪一波。
2. 运行 `scripts/setup-worktrees.ps1 -DryRun` 查看将创建的 worktree。
3. 到合适波次时运行 `scripts/setup-worktrees.ps1 -Create -Wave <wave>`。
4. 在 Codex 中新建对话，把工作目录设置为对应 `.worktrees/<name>`。
5. 打开本目录对应 prompt 文件，把其中的 Prompt 复制给新对话。

不要跳过依赖顺序。前四个分支应顺序推进：项目地基、核心模型与数据库、现场计分主线、复盘历史。
