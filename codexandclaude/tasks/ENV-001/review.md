# ENV-001 审查记录

审查者：Claude｜日期：2026-10-19
被审实现 SHA：`f6c55516fa800ebe176ca84b050f1e3de275bbef`
被审交付 SHA：`bb6082f3075d455d4c7270f79d9c04a4dc3b30b1`
工作区：`worktrees/claude`，以 `git switch --detach <交付SHA>` 固定后复跑，审查分支 `claude/ENV-001-review` 建在交付提交上。

## 结论：通过

完成标准 1～6 全部满足，改动严格在任务卡允许的文件内，独立复跑的 G1、G3、G2 全部通过。下方“建议”列出三项非阻断改进，可作为后续任务处理，不影响本次合并。

## 范围核对

- `git diff <实现SHA> <交付SHA>`：仅新增 `codexandclaude/tasks/ENV-001/delivery.md`，其余文件无变化。
- 实现相对基线 `6a7b0d8` 的改动共 8 个文件：`codexandclaude/.gitignore`、`env.md`、`tasks/ENV-001/task.md`（仅首部状态）、`tests/test_run_checks.py`、`tools/run_checks.py`，以及 `tests/test_game_project.py`、`tests/test_t6_workbook.py`、`tests/test_t7_workbook.py`。与任务卡清单一致。
- 未修改 `scripts/verify_game.py`、游戏代码或游戏测试；T6/T7 测试只改 Node 路径来源，其余断言不变。

## 完成标准逐条核对

| 标准 | 结果 | 依据 |
| --- | --- | --- |
| 1 三种模式 | 满足 | `env` / `focused` / `full` 实现于 `run_checks.py:149-238`；`env` 缺工具时非零退出并给出配置提示（实测见下） |
| 2 路径解析 | 满足 | `resolve_tool`（`run_checks.py:84-106`）按 CLI → 配置 → `DAYS31_*` → 自动发现；显式路径无效时不回退；参数数组传递，无 shell 拼接；测试目录名含空格 |
| 3 不重写判断 | 满足 | G2 直接调用 `verify_game.py`；专项 Godot 通过子进程复用其 `execute()`；`g2_result` 只额外核对条目完整性，比原验证器更严格，不放宽 |
| 4 汇总输出 | 满足 | 终端与 `runs/<UTC>/summary.json` 同时输出 SHA、dirty、工具路径与版本、命令数组、退出码、耗时、日志 SHA256、计数 |
| 5 资源检查修复 | 满足 | `tests/test_game_project.py` 仅跳过 `res://../` 前缀；新测试覆盖工程外缺失通过、工程内缺失报错、补齐后通过；全新工作区 G3 独立通过（见下） |
| 6 失败场景测试 | 满足 | `test_run_checks.py` 共 19 项，覆盖缺工具、空格路径、子进程失败、超时与进程树终止、缺汇总行、Godot 版本不符、无效配置等，全部用模拟 |

## 独立复跑

环境：Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14 + openpyxl 3.1.5（由入口自动发现）；Git 2.56.0.windows.2；Node v24.19.0。

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| 全新工作区 G3 | `python codexandclaude/tools/run_checks.py focused --python-all`（运行前后均确认 `outputs/` 不存在） | tests/ 70/70，codexandclaude/tests/ 29/29，退出码 0；sha=交付 SHA，dirty=false |
| 自动发现 | 同上，用系统 PATH 上不带 openpyxl 的 Python 3.10.4 启动 | 正确跳过 3.10，选中带 openpyxl 的 3.12.14 |
| 显式路径不回退 | `run_checks.py env --node "D:/no such/node.exe"` | 退出码 1，reason 为 `Missing/unusable node; set --node, env.local.json["node"], or DAYS31_NODE ...`，未回退到自动发现 |
| 资源检查变异测试 | 在临时副本中删去 `res://../` 跳过逻辑，单跑新测试 | 失败（failures=1），说明新测试能抓住回退 |
| G2 + G3 全量 | `python codexandclaude/tools/run_checks.py full --jobs 4` | G2 预期 73、实际 73（导入、主场景 + 71 套件），引擎报告 71 行 `failures=0`、0 行非零失败、0 个错误/解析失败/泄漏/超时标记；G3 70/70 + 29/29；退出码 0；sha=交付 SHA，dirty=false；UTC 10:19:17 至 10:29:59；engine.txt SHA256 `171d9d24677158d4d0fe8eaeff59bff43761a4c786f5ddb8154bcdebc0980708` |

交付记录中的预提交全量运行是在 sha=基线、dirty=true 的工作树上执行的，交付记录如实说明并给出 blob 对应；本次审查在干净的交付 SHA 上重新全量通过，二者结论一致。

全量运行后 Godot 导入使两份 `.svg.import` 出现仅换行符的变化（`git diff --ignore-cr-at-eol` 无内容差异），已在审查工作区还原，未提交。原始日志位于审查工作区 `codexandclaude/runs/`，不入库。

## 建议（非阻断）

1. **G3 也要求 Godot。** 所有模式都会先解析并校验全部四个工具（`run_checks.py:180-191`，`env.md` 第 15 行已写明），因此在没有 Godot 的机器上，纯文档任务也无法通过入口跑 G3。建议以后按模式只解析需要的工具：`focused --python-all` 只需要 Git、Python、Node。
2. **`OK (skipped=N)` 被判为失败。** `python_result`（`run_checks.py:116-122`）只接受精确的 `OK` 行，这是有意的严格设计（`test_run_checks.py:90` 有断言），目前项目中也没有跳过的测试。但以后若有人加入 `skipUnless`，门禁会直接失败。建议在 `env.md` 中写明这条规则，或明确跳过测试的处理方式。
3. **未列出的异常不写汇总。** `main` 只捕获 `CheckFailure/OSError/ValueError/ImportError`（`run_checks.py:231`）；如出现 `KeyError`、`TypeError` 等意外异常，会直接抛出而不写 `summary.json`。退出码仍为非零，不会误判通过，但会丢失证据。建议兜底捕获并记录后返回 1。

## 合并说明

审查通过后，按 V2.2 第 5 节，待用户授权后由集成者合并**本审查记录所在提交（审查 SHA）**，它包含实现、交付和审查记录。本任务无 G4 要求。合并后按矩阵（验证流水线与协作工具）在 master 执行 G2 + G3。
