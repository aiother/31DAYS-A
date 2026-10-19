# SYS-001 集成与用户验收

集成者：Codex｜日期：2026-10-19｜结论：用户 G4 通过并授权合并，固定审查提交已合入 master，合并后完整 G2＋G3 通过。

## 固定提交与前置检查

- 合并前 master：`1f9f0ff61a620792f1eb0e0d0472a7c1daae29c5`。
- 实现 SHA：`c47c4c0b4bc6048885ce8a73398bd5428aee8afd`；交付 SHA：`e315b3755939f8f645c242c670ef68be6c19a685`。
- 固定审查 SHA／合并后被测 master：`5aa3eb7f9b32a33d90e62653e2693ccb8360707d`。
- 合并前 `git diff`、`git diff --cached` 均确认主目录 game/project.godot 没有未提交差异；另将工作文件与 HEAD 内容比较（仅归一换行），相同，索引无 assume-unchanged/skip-worktree 标记。
- 执行 `git merge --ff-only 5aa3eb7f9b32a33d90e62653e2693ccb8360707d`，快进成功，未合并可移动分支名。没有还原、覆盖或 stash 用户文件。

## 用户 G4

来源：2026-10-19 用户本轮明确告知“用户已完成 G4 实机验收并授权合并”。依据审查记录所列步骤，验收范围为左右方向键正确移动、松键停止、PageUp 不移动，以及 A/D、手柄左摇杆和十字键左右移动正常。此处记录用户验收结果，不将自动输入测试表述为实机验收。

## 合并后集成验收

| 用例 | 预期与结果 |
| --- | --- |
| 配置保护 | 合并前确认配置无未提交改动才继续；符合。合并只包含获批的两个方向键事件变化。 |
| 固定 SHA | master 包含指定审查 SHA 的实现、交付和审查记录；符合。 |
| G2 全量 | 预期74、实际74条目（导入、主场景180帧、72套件），全通过；各套件 failures=0，无错误、解析失败、泄漏、非零失败或超时。 |
| G3 全量 | tests/ 81/81、codexandclaude/tests/ 37/37，complete=true、passed=true，入口退出0。 |

命令：`python codexandclaude/tools/run_checks.py full --jobs 4`。
summary.passed=true，sha 为上述审查 SHA，dirty=false。执行时间 UTC 2026-10-19 17:45:18 至17:56:04。

工具：Godot 4.7.2.stable.official.ed1daf0bf、Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。原始命令、工具路径、退出码和日志哈希见主目录 `codexandclaude/runs/20261019T174518.379477Z/summary.json` 与同目录 engine.txt；终端汇总为 runs/SYS-001-master-full-console.txt，不提交原始日志。
engine.txt SHA256：`1e68f09e266938061392dec5dd9a5515bc314f59b159ffdf537f1008eb62a4b4`。

验证后的 game/project.godot SHA256：`cd15b68c92683351ad95d8fb49a3388847b328665b91c735cf64709a7c79e270`，对应已合入配置；除获批修复外未改配置。未操作原有 `.claude/settings.local.json`，未推送远程。

本证据提交只新增本记录并更新任务卡为已完成；提交前运行 G3 和差异检查，不因证据更新重复 G2。BOARD 留给规划维护者串行汇总，任务卡为权威状态。SYS-002 从本证据提交后的 master 开工，最终基线 SHA 通过交付记录和 Git 历史提供，不写入本记录自身。
