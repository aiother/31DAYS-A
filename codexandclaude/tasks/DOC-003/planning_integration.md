# DOC-003 规划集成与验证

集成者：Codex｜日期：2026-10-19｜结论：用户批准的固定规划提交已合入 master，G3 通过，Claude 可从本证据提交后的 master 开工。本轮只集成规划，没有实施 DOC-003。

## 固定提交与范围

- 合并前 master：`1e1672aa6f0531488bd9d094888419dd4cb97923`，索引为空。
- 用户授权的固定规划 SHA：`713d66bb0906dae96a6783d3a8b94fa761a61aa4`，共同基线就是上述 master。
- 执行 `git merge --ff-only 713d66bb0906dae96a6783d3a8b94fa761a61aa4`，快进成功，无冲突，没有合并可移动分支名。
- 合并后被测 master：`713d66bb0906dae96a6783d3a8b94fa761a61aa4`。
- 基线至固定提交只新增 `codexandclaude/tasks/DOC-003/task.md`、更新 `codexandclaude/BOARD.md`，与受保护的 `game/project.godot` 无重叠。
- BOARD 将 DOC-001、DOC-002 标为已完成，新增 DOC-003、SYS-001、SYS-002。DOC-003 汇总仍为“待批准”，保留批准提交的原始内容；权威任务卡已记载用户批准。

## 规划集成测试记录

本次更新以下集成验收用例与实测结果；不改游戏或验证工具的实现。

| 用例 | 操作与预期 | 实测结果 |
| --- | --- | --- |
| 固定提交与文件范围 | 核对 `git merge-base`、基线到固定 SHA 的 diff；应只有任务卡与 BOARD 两个文件 | 符合；共同基线为合并前 master |
| 用户文件保护 | 合并前后核对 `game/project.godot` 的 SHA256；应完全相同 | 相同，见下方哈希 |
| 完整 G3 | 在合并后的 master 执行下方命令；两组 Python 测试完整执行，退出码 0 | tests/ 79/79、codexandclaude/tests/ 37/37；complete=true、passed=true，入口退出码 0 |

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

被测 SHA 为上述固定规划 SHA；summary.passed=true。工具版本为 Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。

原始日志及命令、退出码、工具路径和日志哈希位于主目录 `codexandclaude/runs/20261019T165136.194890Z/summary.json` 与同目录日志，不提交原始日志。
汇总 dirty=true，仅列原有未跟踪文件 `.claude/settings.local.json`；未操作或暂存该文件。
按纯文档矩阵只运行 G3，无需 G2、G4，未调用 Godot。

## 用户文件与交接

合并前与合并后 G3 完成时，`game/project.godot` 的 SHA256 均为：
`683572e7c869772b23f73ac50914b3e11dad7821411cbbcc0a9f46526cddc5a7`。

当前 Git 未显示该配置文件有未提交差异；仍按用户指定的受保护文件处理，没有覆盖、暂存、还原或 stash。没有推送远程。

本证据提交只新增本记录，提交前再次执行 G3 并核对文件哈希与差异；最终提交 SHA 通过交付消息提供，不写入自身记录。Claude 应从最终 master SHA 开工，并在交付记录写明完整基线 SHA。
