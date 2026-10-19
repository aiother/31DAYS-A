# DOC-002 集成与合并后验证

集成者：Codex｜日期：2026-10-19｜结论：用户授权的第2轮审查固定提交已合入 master，合并后 G3 通过，任务已完成。

## 固定提交与合并检查

- 合并前 master：`58b82e614b9d82e36b14b3192390887dc328bd96`，仍为实现基线，没有后续提交；索引为空。
- 第2轮实现 SHA：`fcbeb4a9e130ab00c105b9bc235a5c2e7cd71253`。
- 第2轮交付 SHA：`29e8d029ffc5f03c87a742beba83ece6461a9deb`。
- 固定审查 SHA／合并后被测 master：`4f354ea37a4d9e4fca7618d8e4895fdfbbc360cb`，包含两轮实现、交付和审查记录。
- 执行 `git merge --ff-only 4f354ea37a4d9e4fca7618d8e4895fdfbbc360cb`，快进成功，没有合并可移动分支名。
- 差异仅新增 Words/待决事项总表.md、tests/test_pending_decisions.py、DOC-002 的 delivery.md/review.md，并更新 DOC-002/task.md 状态；与用户要求保护的 game/project.godot 无重叠。
- R1 旧槽救助保护、R2 攻击碎石并保存后开路均已通过第2轮复审；未扩展策划范围或替用户裁决 A 类条目。

## 合并后 G3

在主目录 `D:/31days` 的 master 执行：

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

退出码 0，summary.passed=true；被测 SHA 为上述固定审查 SHA；tests/ **79/79**、codexandclaude/tests/ **37/37**，两组 complete=true 且均为 OK。
汇总 dirty=true，status 仅列未跟踪的 .claude/settings.local.json；没有操作或暂存该文件。

工具路径、版本、命令、退出码及日志摘要在主目录 `codexandclaude/runs/20261019T162035.678606Z/summary.json` 与同目录命令日志；终端汇总为 runs/DOC-002-master-g3.txt。原始日志不提交。
按纯文档矩阵只执行 G3，无需 G2/G4，未调用 Godot。

## 用户文件与收尾

game/project.godot 在合并前及合并后 G3 完成时 SHA256 一致：
`683572e7c869772b23f73ac50914b3e11dad7821411cbbcc0a9f46526cddc5a7`。
没有暂存、覆盖或还原用户文件，没有使用 stash 或推送远程。

本证据提交只新增本记录并更新任务卡首部为已完成，提交前再次执行 G3 和差异检查，不因证据更新追加 G2。BOARD 由规划维护者串行汇总，任务卡为权威状态；本次不另改 BOARD。
证据提交 SHA 通过最终交付消息与 Git 历史提供，不写入自身记录。
