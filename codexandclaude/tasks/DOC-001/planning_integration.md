# DOC-001 规划集成记录

集成者：Codex｜日期：2026-10-19｜结论：已批准规划提交已合入 master，合并后 G3 通过，待 Claude 实施。

## 固定提交与范围

- 合并前 master：`39f919374cc3be0e0c5f7c1f0f7dcbb9e2b0cd6e`。
- 用户授权的固定规划 SHA：`f2de6a32131abb228d7980703d6416263aeb2813`。
- 合并前核对差异：仅新增 DOC-001/task.md，并更新 BOARD.md 的日期、ENV-002 已完成状态和 DOC-001 任务卡入口；没有涉及 game/project.godot。
- 执行 `git merge --ff-only f2de6a32131abb228d7980703d6416263aeb2813`，快进成功，未合并可移动分支名。
- 本轮只集成规划，没有实施 T0、T1 改写或修改其测试。

## 合并后 G3

在 `D:/31days` 的 master 执行：

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

进程退出码 0，summary.passed=true；被测 SHA 为上述规划 SHA，tests/ **70/70**、codexandclaude/tests/ **37/37**，两组均为 OK，完整执行。
汇总 dirty=true，实际 status 为未跟踪的 .claude/settings.local.json；未操作或暂存该文件。
工具路径、版本、实际命令、退出码、计数和日志摘要保留在主目录 `codexandclaude/runs/20261019T152443.319152Z/summary.json` 及同目录命令日志，终端汇总为 runs/DOC-001-planning-master-g3.txt。原始日志不提交。
按纯文档矩阵仅运行 G3，未运行 G2、G4；该模式不需要 Godot。

## 用户文件保护与交接

用户要求保护的 game/project.godot，在合并前及合并后验证完成时 SHA256 均为：
`683572e7c869772b23f73ac50914b3e11dad7821411cbbcc0a9f46526cddc5a7`。
没有重叠、覆盖、还原或暂存用户文件，没有使用 stash 或推送远程。

本证据提交只新增本记录并更新任务首部的规划集成状态，任务范围和批准内容不变，提交前再跑 G3。
BOARD 由规划维护者串行汇总，权威批准状态以任务卡为准，本证据提交不再修改 BOARD。
Claude 从最终 master SHA 新建实现分支，按已批准任务卡实施；最终 SHA 在交付消息及 Git 历史中提供，不写入自身记录。
