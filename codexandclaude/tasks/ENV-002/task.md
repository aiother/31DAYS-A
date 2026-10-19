# ENV-002：任务板、目录结构与 HUD-001 归档

状态：待批准｜级别：M｜实现：Claude｜审查：Codex
工作区：worktrees/claude｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：ENV-001（已合并）

## 目标

把 `codexandclaude/` 整理成 V2.2 第 4 节规定的结构：有一份任务板汇总所有任务，HUD-001 试点的过程文件整体归档，README 只保留现行入口。完成后，任何一方打开 README 就能找到现行规则、检查入口、任务板和各任务目录，不再需要翻试点期的十几份文件。

## 依据

- [协作方案 V2.2](../../plan_v2.md) 第 4 节（目录与任务状态）、第 11 节阶段 0（ENV-002）。
- 2026-10-19 用户确认按 V2.2 试行。

## 现状（起草时核对 master@e19e474）

- 顶层有 8 份 HUD-001 试点文件：`first_review.md`、`hud_baseline.md`、`hud_pilot.md`、`hud_pilot_delivery.md`、`hud_pilot_review.md`、`hud_acceptance.md`、`controller_confirm_fix.md`、`integration.md`；`tools/` 下有两个试点用的 Godot 脚本 `capture_hud_preview.gd`、`probe_controller_confirm.gd`。
- 这些文件之间没有 Markdown 链接；仓库内只有 `plan_v2.md` 第 5 行链接了 `integration.md`。游戏工程与根目录测试都不引用 `codexandclaude/`。
- README 仍以 HUD-001 试点为主线，列出全部试点文件。
- `tests/test_collaboration.py` 有 6 项测试直接读取上述试点文件的顶层路径。
- 还没有 `BOARD.md` 和 `archive/`。

## 允许修改的文件

- `codexandclaude/archive/HUD-001/`（新增）：用 `git mv` 移入上述 8 份文档和 2 个脚本（脚本放在 `archive/HUD-001/tools/`），文件内容不改
- `codexandclaude/BOARD.md`（新增）
- `codexandclaude/README.md`：重写为现行入口
- `codexandclaude/plan_v2.md`：只把第 5 行的 `integration.md` 链接改为 `archive/HUD-001/integration.md`，其余不动
- `codexandclaude/tests/test_collaboration.py`
- `codexandclaude/tasks/ENV-002/task.md`（只更新首部状态）、`codexandclaude/tasks/ENV-002/delivery.md`（新增）

## 完成标准

1. **归档**：8 份文档和 2 个脚本只在 `archive/HUD-001/` 下存在，Git 记录为重命名（内容不变，可用 `git log --follow` 追溯）。新增 `archive/HUD-001/README.md`，用几行话说明这是 HUD-001 试点的历史记录，以及各文件分别是什么。
2. **任务板**：`BOARD.md` 是 V2.2 第 4 节格式的一张表，列出 HUD-001（已归档）、ENV-001、ENV-002、ENV-003，以及阶段 1 计划中的 DOC-001、DOC-002（状态“草稿”）。每个 `tasks/<ID>/` 目录在任务板中都有对应行。
3. **README**：只放现行入口：试行中的协作方案、旧协作规范（说明试行期间以方案为准）、检查入口 `env.md`、任务板、`tasks/`、`archive/`，以及一条运行协作检查的命令。删除试点期的阶段描述。
4. **测试**：
   - 原来读取试点文件的测试改为读取归档路径，断言内容不变。
   - Markdown 链接检查扩大到 `codexandclaude/` 下除 `worktrees/`、`runs/` 外的全部 `.md` 文件，链接都必须能解析到协作目录内的真实文件。
   - 新增：README 链接到协作方案、协作规范、`env.md`、`BOARD.md`；`archive/HUD-001/` 包含全部 10 个归档文件，顶层不再有它们；每个 `tasks/<ID>/` 都在 `BOARD.md` 中有一行。
   - 不检查任务板中的状态是否与各 `task.md` 一致：按 V2.2，任务板由规划维护者串行汇总，合并后短时间不一致是允许的。

## 检查

- 按 V2.2 第 7 节矩阵，本任务属于纯文档与归档：G3，即 `python codexandclaude/tools/run_checks.py focused --python-all`。
- 不需要 G2、G4。

## 回滚方案

`git revert` 本任务的实现提交即可；重命名会随之还原。不涉及游戏代码、存档或输入配置。

## 不在范围内

- 修改 `collaboration.md` 的规则内容（按 V2.2，复盘后才并入）。
- 修改归档文件的内容，或修改 `env.md`、`tools/run_checks.py` 等 ENV-001/ENV-003 的文件。
- 删除 `worktrees/claude-hud`、`worktrees/codex-review` 两个试点工作区及其分支（需要用户另行决定）。
- 归档 ENV-001、ENV-003 等已完成任务（按 V2.2，每完成 3～5 个任务再统一归档）。
