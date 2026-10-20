# DOC-004：V2.3 修订并正式并入协作规范

状态：待审查（2026-10-19 用户批准；实现完成，G3 通过）｜级别：M｜实现：Claude｜审查：Codex
工作区：worktrees/claude｜基线：`82ba37e`（master，含 SYS-002 收尾与待办清单）｜依赖：无

## 批准与流程说明

用户 2026-10-19 在会话中确认 Claude 归纳的 V2.3 修订要点：“没问题，我批准了”。

本任务按刚达成一致的简化规则执行：用户在会话中确认要点即视为批准，任务卡与实现放在同一分支 `claude/DOC-004`，不单独走规划合并。这一做法本身是本次修订的内容之一（见 V2.3 第 5 节）。

## 目标

完成协作方案的阶段 2 复盘（待办清单 BL-002）：把 V2.2 试行规则与三方复盘意见合并为 V2.3，改写 `collaboration.md` 为唯一现行规范，结束试行。

## 依据：三方复盘意见（2026-10-19）

**用户**

1. 转话机制保留，便于了解两个 Agent 在做什么。
2. 开发后希望两个 Agent 能相互优化代码、探讨需求。
3. UI 设计与交互开发不要过于死板，保持较高的探讨度。

**Codex**

1. 规划合并可以简化：已批准且互不冲突的任务卡批量合入；S 级任务卡可与实现同分支；M/L 默认保留规划先行（BL-003）。
2. 多行、含引号或特殊字符的提交说明统一用 `git commit -F <文件>`，写入 env.md（BL-004）。
3. G4 入口在任务卡阶段规划，与实现一并交付；验收脚本的检查等级写入矩阵（BL-005）。
4. 测试登记改为分散登记、入口汇总，并检查漏登（BL-103）。
5. 检查入口自动汇总被测 SHA、未提交改动与内容哈希，生成可提交摘要。
6. 明确收尾责任与主目录例外：集成者可在 master 修改集成记录与任务卡状态；规划维护者在任务关闭后统一刷新 BOARD/BACKLOG 并注明基线 SHA。

**Claude**

1. 把审查中的变异检查写成规则。
2. 把 S 级与 M 级的界线写具体。
3. 把 safe.directory 等环境细节写入 env.md。

## 允许修改的文件

- `codexandclaude/collaboration.md`：改写为 V2.3 现行规范
- `codexandclaude/plan_v2.md`：首部状态改为“已并入”，修订记录加一行；其余内容保留为历史
- `codexandclaude/env.md`：补充 Git 与提交说明的操作细节
- `codexandclaude/README.md`：现行依据改为指向 collaboration.md
- `codexandclaude/BOARD.md`、`codexandclaude/BACKLOG.md`：刷新状态，登记本任务与新增待办
- `codexandclaude/tests/test_collaboration.py`
- `codexandclaude/tasks/DOC-004/task.md`（只更新首部状态）、`codexandclaude/tasks/DOC-004/delivery.md`（新增）

## 完成标准

1. `collaboration.md` 是唯一现行规范，完整覆盖 V2.2 的有效规则，并写入上述全部复盘意见；保留原规范中仍有效的安全边界（人工触发、不自动合并或推送、不互传令牌、保护未提交改动等）。
2. 需要改代码的两项（Codex 第4、5条）不在本任务实现，作为工具任务记入待办清单。
3. `plan_v2.md` 标为已并入，README 不再把它当作现行依据。
4. 待办清单：BL-001 已完成；BL-002～005 已立项 DOC-004；新增测试分散登记与证据自动汇总两项。
5. 测试：现行规范测试改为检查 collaboration.md 中的 V2.3 关键规则；plan_v2 测试改为检查“已并入”；保留其他已有检查。

## 检查

- 纯文档：G3，即 `python codexandclaude/tools/run_checks.py focused --python-all`。不需要 G2、G4。
- 审查重点（Codex）：三方意见是否如实、完整地写入；有无遗漏 V2.2 的有效规则；新规则之间是否矛盾；两项工具任务的范围描述是否准确。

## 回滚方案

`git revert` 本任务的提交即可；只涉及协作文档与协作测试。

## 不在范围内

- 实现测试分散登记、证据自动汇总、通用 G4 启动器等工具。
- 修改任何游戏代码或策划文档。
