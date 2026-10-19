# ENV-001：协作检查入口

状态：已完成（2026-10-19 用户授权合并，master 的 G2/G3 全量通过；见 integration.md）｜级别：M｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：无

## 目标

提供一个统一的协作检查入口，让两个 Agent 在任何工作区都能用同一条命令完成环境检查、专项检查和全量检查，并得到可核对的汇总；同时消除 G3 对 G2 的前置依赖，使纯文档任务在全新工作区只跑 G3 就能通过。

## 依据

- [协作方案 V2.2](../../plan_v2.md) 第 7 节（质量门与通过条件）、第 10 节（ENV-001）、第 11 节（阶段 0）。
- Codex 第一轮审阅意见：复用现有验证器，增加薄入口；路径按“显式参数 → 本地配置或环境变量 → 自动发现”解析；覆盖 Node。
- 2026-10-19 用户确认按 V2.2 试行。

## 现状（起草时核对）

- `tests/test_game_project.py:9` 的资源引用检查用正则抓取所有 `res://` 路径，把 `game/tests/test_air_pursuit.gd:151` 的输出路径 `res://../outputs/pursuit_air.json` 也当成资源。`outputs/` 被 git 忽略，所以全新工作区在跑 G2 之前，这项检查必然失败。
- `tests/test_t6_workbook.py:32` 与 `tests/test_t7_workbook.py:27` 把 Node 路径写死为 Codex 运行时目录；系统 PATH 上没有 `node`，系统 Python 也没有 openpyxl。
- `scripts/verify_game.py` 已经检查退出码、各套件汇总行与 failures=0、错误标记、泄漏和超时，命令行参数为 `--godot`、`--project`、`--report`、`--jobs`。

## 允许修改的文件

- `codexandclaude/tools/run_checks.py`（新增）：协作检查入口
- `codexandclaude/tests/test_run_checks.py`（新增）：入口的测试
- `codexandclaude/env.md`（新增）：工具解析顺序、本地配置格式、三种模式的用法
- `codexandclaude/.gitignore`：追加本地配置文件的忽略规则
- `tests/test_game_project.py`：资源检查跳过 `res://../` 开头的路径，并补测试
- `tests/test_t6_workbook.py`、`tests/test_t7_workbook.py`：Node 路径改为先读环境变量，找不到时回退到原默认路径；不改其余断言
- `codexandclaude/tasks/ENV-001/task.md`（只更新首部状态）、`codexandclaude/tasks/ENV-001/delivery.md`（新增）

## 完成标准

1. **三种模式**：
   - `env`：报告 Godot（需为 4.7.2 stable）、Python 及 openpyxl、Git、Node 是否可用，以及各自的路径和版本；任何一项缺失都以非零退出码失败，并说明缺的是什么、去哪里配置。
   - `focused`：只运行指定的 Godot 测试脚本或 Python 测试模块。
   - `full`：调用 `scripts/verify_game.py` 跑 G2，再跑 G3（`tests/` 与 `codexandclaude/tests/`）。
2. **路径解析**：按“命令行参数 → 本地配置文件或环境变量 → 自动发现（PATH 与已知安装位置）”的顺序解析；本地配置文件被 git 忽略。路径含空格也能正常工作。
3. **不重写判断逻辑**：G2 的通过判定完全交给 `scripts/verify_game.py`，入口只负责调用和汇总。
4. **汇总输出**：每次运行在终端输出、并在 `codexandclaude/runs/` 写一份汇总，包含被测 SHA、工作区是否有未提交改动、工具路径与版本、实际执行的命令、套件完整性与计数、通过或失败及原因摘要。
5. **资源检查修复**：`tests/test_game_project.py` 跳过 `res://../` 开头的运行时输出路径；新增测试证明工程内缺失的资源仍会报错，`res://../` 路径被忽略。修复后，在没有 `outputs/` 目录的全新工作区，G3 能独立通过。
6. **失败场景测试**：`test_run_checks.py` 覆盖缺工具、路径含空格、子进程失败、超时、缺少汇总行，以及 Godot 版本不符；测试使用模拟，不依赖本机真实安装。

## 检查

- G1：`codexandclaude/tests/test_run_checks.py`；`tests/test_game_project.py` 的新测试。
- G2 + G3：用新入口的 `full` 模式执行一次，汇总写进交付记录。
- 额外证明：在一个没有 `outputs/` 的全新工作区只跑 G3，结果写进交付记录。
- 不需要 G4（无画面或操作变化）。

## 回滚方案

撤销本任务的实现提交即可（`git revert`）。不涉及存档、输入配置或游戏代码；本地配置文件不入库，删除即可。

## 不在范围内

- 修改 `scripts/verify_game.py` 的判断逻辑或套件清单。
- 任何游戏代码或游戏测试的修复。
- 自动安装依赖、修改全局设置或 PATH。
- 自动合并、推送，或调用另一个 Agent。
- 建立 BOARD、tasks 目录规范或归档 HUD-001（属于 ENV-002）。
