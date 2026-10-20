# SYS-002 集成与合并后验证

集成者：Codex｜日期：2026-10-19（America/Los_Angeles）｜结论：用户授权的固定提交已合入 master，用户 G4 四项通过，合并后完整 G2＋G3 通过，任务已完成。

## 固定对象与合并前检查

- 合并前 master：`fdfc4c2b3eff199c9234af6f3103a04de05db93e`，没有后续提交，索引为空。
- 实现 SHA：`87b0dbeadb3cf768c7c1eae936c819cc24289b22`；交付 SHA：`511abbf0a82a73fdee536feb379c5a1928cd2b63`。
- 实现审查：`70b1ae17bb4bb45f422fb09dcb0b03a3f4c38823`；其后包括验收入口实现/交付 `0a1f1ff`、`442f62e`、Claude S 级审查 `d9908de` 和用户验收结果。
- 用户授权的固定合并 SHA／合并后被测 master：`af85fb823f74f8f84363caa3b5eeb3466619e648`。
- 合并前 `git diff -- game/project.godot`、`git diff --cached -- game/project.godot` 均为空；`git ls-files -v` 为 H，没有 assume-unchanged/skip-worktree 标记。另逐字节比较工作文件与 HEAD（仅归一换行），相同，符合用户指定的配置保护前置条件。
- 执行 `git merge --ff-only af85fb823f74f8f84363caa3b5eeb3466619e648`，快进成功；未合并可移动分支名，没有重复合并已在 master 的 SYS-001。

## 用户 G4 与审批链

用户本轮明确授权合并，确认 af85fb8 包含其“四项均通过”的 G4 结果。已核对 acceptance.md 的用户验收表：生成/+2、在场上限与余额回升、暂停/结束清理、高处平台观察均通过；来源为用户会话反馈“没问题”，由 Claude 代填。没有把启动自测或自动套件当作用户实机验收。

该固定提交已完整包含实现、交付、Claude 实现审查、验收入口及其 S 级审查、用户 G4 记录；本次没有改动已批准的实现或验收结果。

## 合并后集成验收

| 用例 | 预期 | 实测结果 |
| --- | --- | --- |
| 固定提交与前置条件 | master 基线一致，配置无未提交改动，合入完整审批链 | 符合；快进到上述固定 SHA |
| G2 全量 | 预期全部条目执行，套件均零失败，无错误/解析失败/泄漏/超时 | 预期75、实际75（导入、主场景180帧、73套件），全部退出0；73个零失败摘要，错误标记0 |
| 重点专项 | 保底实体与已有输入无回归 | REMNANT_POSSIBILITY_TESTS 269/269、INPUT_BINDINGS_TESTS 89/89 |
| G3 全量 | 两个 Python 目录完整通过 | tests/ 81/81、codexandclaude/tests/ 37/37，complete=true、passed=true，入口退出0 |
| 配置保护 | SYS-002 不修改主目录 project.godot | 合并前及最终验证后哈希一致，见下方 |

在主目录 `D:/31days` 的 master 实际执行：

```powershell
python codexandclaude/tools/run_checks.py full --jobs 4
```

最终有效运行：UTC 2026-10-20 05:01:10 至05:11:56（洛杉矶时间10月19日22:01至22:11）。summary.passed=true，sha 为上述固定合并提交，入口记录 dirty=false、status=[]；普通权限 Git 状态另显示原有未跟踪 `.claude/`，未操作或纳入提交。

工具：Godot 4.7.2.stable.official.ed1daf0bf、Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。原始命令、工具路径、退出码及日志哈希在主目录 `codexandclaude/runs/20261020T050110.148512Z/summary.json` 与同目录 engine.txt；终端汇总为 runs/SYS-002-master-full-resumed-console.txt。原始日志不入库。
engine.txt SHA256：`bed4f3aebc91aeb76ce22de79e02f1bca58f2c037ade8843cd43d0e1ebf56ce3`。

首轮 `runs/20261019T190145.905121Z/` 留下74/75个引擎条目，但没有最终 summary.json；恢复处理时原进程已结束。保留该不完整日志及 runs/SYS-002-master-full-console.txt，不以其声称通过；随后重新执行了上述完整 G2＋G3，最终结论仅依据完整重跑结果。

## 文件保护与收尾

game/project.godot 在合并前及最终完整验证后 SHA256 均为：
`cd15b68c92683351ad95d8fb49a3388847b328665b91c735cf64709a7c79e270`。

没有覆盖、还原、暂存用户配置，没有 stash、推送或操作他人的工作区。BOARD 由规划维护者串行汇总，任务卡为权威状态。

本证据提交只新增本记录、更新 SYS-002/task.md 首部为已完成；提交前再跑 G3 与差异检查，不因证据记录重复 G2。最终 master SHA 在交付消息和 Git 历史中提供，不写入自身记录。
