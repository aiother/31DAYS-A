# DOC-001 集成与合并后验证

集成者：Codex｜日期：2026-10-19｜结论：第2轮复审通过的固定提交已获用户授权并合入 master，合并后 G3 通过，任务已完成。

## 固定提交与合并检查

- 合并前 master：`f4847be4d169511a87555ec2f693bf1d185efd33`，与任务基线一致，没有额外提交或代码变化，索引为空。
- 第2轮实现 SHA：`243d6d37fd07155d601a809ecec529abf80ca7c9`。
- 第2轮交付 SHA：`ede7becc779aa0d68022f3cac13f9566231164da`。
- 固定审查 SHA／合并后被测 master：`c6dd17d23df8888c216a89c49d0fa0e20b910f8d`。
- 执行 `git merge --ff-only c6dd17d23df8888c216a89c49d0fa0e20b910f8d`，快进成功，没有合并可移动分支名。
- 合并差异仅涉及 T0、T1、相关规划测试和 DOC-001 的交付／审查／任务状态记录，与用户要求保护的 game/project.godot 无重叠。
- 第1轮审查历史保留，第2轮记录明确 R1、R2 已关闭；T2、T3 等范围外文档未修改。

## 合并后 G3

在主目录 `D:/31days` 的 master 执行：

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

结果：退出码0，summary.passed=true；被测 SHA 为上述固定审查 SHA；tests/ **71/71**、codexandclaude/tests/ **37/37**，两组完整执行且均为 OK。
汇总 dirty=true，status 为未跟踪的 .claude/settings.local.json，未操作或暂存该文件。
完整工具路径、版本、命令、退出码、计数及日志摘要保留在主目录 `codexandclaude/runs/20261019T155039.065645Z/summary.json` 与同目录命令日志；终端汇总为 runs/DOC-001-master-g3.txt。原始日志不提交。
按纯文档矩阵仅执行 G3，未运行 G2、G4，也未解析或调用 Godot。

## 用户文件与收尾

game/project.godot 在合并前及合并后验证完成时 SHA256 一致：
`683572e7c869772b23f73ac50914b3e11dad7821411cbbcc0a9f46526cddc5a7`。
没有暂存、覆盖或还原用户文件，没有使用 stash 或推送远程。

本证据提交只新增本记录并更新 task.md 首部为已完成，提交前再执行 G3，不因证据更新追加 G2。
BOARD 继续由规划维护者串行汇总，任务卡为权威状态；本次不改 BOARD。
证据提交 SHA 通过最终交付消息与 Git 历史提供，不写入自身记录。
