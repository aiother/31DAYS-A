# ENV-003：协作检查入口的三项改进

状态：待合并（2026-10-19 Codex 独立审查通过，无 G4 要求；待用户授权合并）｜级别：M｜实现：Claude｜审查：Codex
工作区：worktrees/claude｜基线：`3f54a7bedf804b324d8d110fcb98da0af30294c9`（ENV-001 审查 SHA）｜依赖：ENV-001

## 批准与流程说明

用户 2026-10-19 在会话中指示：“关于非阻断的建议内容，不要等以后了，我让 codex 进行合并你能在这期间解决这三个问题吗”。

为与 Codex 合并 ENV-001 并行，本任务与 V2.2 第 5 节有两处不同，经上述指示接受：

- 基线取 ENV-001 的审查 SHA，而不是合并后的 master。该提交即 ENV-001 的合并对象，合并后本分支可直接接续；若 Codex 合并时产生了额外的代码变化，本任务需在 master 上重新检查后再合并。
- 任务卡与实现放在同一分支 `claude/ENV-003`，不单独走规划分支合入 master；用户的会话指示即批准依据。

## 目标

解决 ENV-001 审查记录中的三项非阻断建议：

1. 入口按模式只解析需要的工具，没有 Godot 的机器也能用入口跑 G3。
2. 明确并记录“跳过的测试”的处理规则，失败原因清楚可读。
3. 任何意外异常都写出 `summary.json` 并返回非零退出码，不丢失证据。

## 依据

- [ENV-001 审查记录](../ENV-001/review.md)“建议（非阻断）”三条。
- [协作方案 V2.2](../../plan_v2.md) 第 7 节通过条件：检查须真实执行完整、不得以缺失结果计为通过。

## 允许修改的文件

- `codexandclaude/tools/run_checks.py`
- `codexandclaude/tests/test_run_checks.py`
- `codexandclaude/env.md`
- `codexandclaude/tasks/ENV-003/task.md`（新增）、`codexandclaude/tasks/ENV-003/delivery.md`（新增）

## 完成标准

1. **按模式解析工具**：`env` 与 `full` 解析全部四个工具；`focused` 只运行 Python 时解析 Git、Python、Node；只运行 Godot 专项时解析 Git、Python、Godot；两者都有时取并集。未需要的工具不解析、不校验版本，汇总中如实列出“本次未要求”的工具。Godot 版本校验只在需要 Godot 时执行。
2. **跳过规则**：门禁不接受跳过的测试。unittest 汇总为 `OK (skipped=N)` 或含 expected failures 时判为失败，原因写明跳过数量和处理办法（修复依赖或移除跳过）；规则写入 `env.md`。
3. **兜底记录**：`main` 对未预期异常兜底，汇总写入异常类型、信息和调用栈，返回 1；`KeyboardInterrupt` 等非 `Exception` 不吞掉。
4. 原有 19 项测试继续通过，新增测试覆盖以上三点，并先在修复前确认失败。

## 检查

- G1：`codexandclaude/tests/test_run_checks.py`。
- G2 + G3：`run_checks.py full --jobs 4`（验证流水线与协作工具类改动）。
- 额外证明：用一个不存在的 Godot 路径跑 `focused --python-all`，应当通过；跑 `env` 应当失败。
- 不需要 G4。

## 回滚方案

`git revert` 本任务的实现提交即可；不涉及存档、输入配置或游戏代码。

## 不在范围内

- 修改 `scripts/verify_game.py`、游戏代码或游戏测试。
- 放宽 G2 的任何判定，或允许跳过的测试计为通过。
- ENV-002 的任务板与归档工作。
