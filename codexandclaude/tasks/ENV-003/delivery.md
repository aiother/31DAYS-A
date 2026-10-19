# ENV-003 交付记录

实现者：Claude｜日期：2026-10-19
基线：`3f54a7bedf804b324d8d110fcb98da0af30294c9`（ENV-001 审查 SHA）
实现 SHA：`6cff1950ccd94b946a9e07b8ae2538808684342d`｜分支：`claude/ENV-003`｜工作区：`worktrees/claude`

## 改动

| 文件 | 内容 |
| --- | --- |
| `codexandclaude/tools/run_checks.py` | 新增 `required_tools()`，按模式只解析需要的工具，汇总新增 `tools_not_required`；只在需要时设置 `DAYS31_NODE`、加载原验证器；`python_result` 对跳过与 expected failures 给出明确原因；`main` 兜底捕获 `Exception`，写入 reason 与 traceback 后返回 1 |
| `codexandclaude/tests/test_run_checks.py` | 新增 6 项：纯 Python 专项不需要 Godot；纯 Godot 专项不需要 Node；env/full 仍要求全部工具；跳过与 expected failures 的失败原因；意外异常仍写汇总；不吞 KeyboardInterrupt |
| `codexandclaude/env.md` | 写明按模式的工具要求、跳过测试规则、意外异常的汇总字段 |
| `codexandclaude/tasks/ENV-003/task.md` | 新增任务卡（含用户批准原话与流程差异说明） |

未修改 `scripts/verify_game.py`、游戏代码或游戏测试；没有放宽任何 G2 判定。

## 先失败、后修复

新测试加入后、修改实现前：`test_run_checks.py` 25 项中 4 项失败、1 项错误（按模式解析两项、跳过原因两个子用例、意外异常一项）。“env/full 仍要求全部工具”和“不吞 KeyboardInterrupt”在修复前就通过，作为防回退保护保留。修复后 25/25 通过。

## 检查结果

环境：Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14 + openpyxl 3.1.5；Git 2.56.0.windows.2；Node v24.19.0。

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| G1 | `python -m unittest discover -s codexandclaude/tests -p test_run_checks.py` | 25/25 通过 |
| 无 Godot 跑 G3 | `run_checks.py focused --python-all --godot "D:/no such/godot.exe"` | 通过，tests/ 70/70、codexandclaude/tests/ 35/35，`tools_not_required: ["godot"]`，退出码 0 |
| 需要 Godot 时仍失败 | `run_checks.py env --godot "D:/no such/godot.exe"` | 退出码 1，reason 为 `Missing/unusable godot; ...` |
| G2 + G3 全量 | `run_checks.py full --jobs 4` | G2 预期 73、实际 73，引擎报告 71 行 `failures=0`、0 行非零失败、0 个错误/解析失败/泄漏/超时标记；G3 70/70 + 35/35；退出码 0；UTC 11:31:10 至 11:43:42；engine.txt SHA256 `20809adec712c86d9510bd38bc2b7c2e7887d07db46f5c62a11fe0bd7cb464bd` |
| 实现 SHA 干净 G3 | 提交后 `run_checks.py focused --python-all` | sha=实现 SHA，dirty=false，70/70 + 35/35，退出码 0 |

### 全量运行与实现 SHA 的对应

全量运行在提交前执行，汇总 sha 为基线 `3f54a7b`、dirty=true（正在测试未提交的实现）。运行期间四个文件未修改；提交后逐一核对，被测文件与实现提交中的 blob 完全一致：

| 文件 | blob |
| --- | --- |
| codexandclaude/tools/run_checks.py | 5897ba516cf10bce18ee1f11076bf6aa1374aa25 |
| codexandclaude/tests/test_run_checks.py | cc7aa4e2bac78ffc940243358cf41850d8ad483c |
| codexandclaude/env.md | d06183aca8a347a42be7e341282e0ac94aaba7d5 |
| codexandclaude/tasks/ENV-003/task.md | 3f657cf73c52a921261daf2fc78c24f3d896017d |

Godot 导入使两份 `.svg.import` 出现仅换行符变化（`git diff --ignore-cr-at-eol` 无内容差异），已还原，未提交。原始日志在 `worktrees/claude/codexandclaude/runs/`，不入库。

## 未验证与注意事项

- 没有在一台真正未安装 Godot 的机器上实测；“无 Godot”通过指定不存在的 Godot 路径模拟，自动发现路径未覆盖这种情况。
- 本任务基线是 ENV-001 的审查 SHA。若 Codex 合并 ENV-001 时 master 上产生了额外的代码变化，本任务合并前需在 master 上重新检查。
- 无 G4 要求。

## 审查请求

请 Codex 以 `git switch --detach <交付SHA>` 固定后审查，确认实现 SHA 到交付 SHA 之间只有本记录与任务卡状态变化，并独立复跑 G1、无 Godot 的 G3 和 G2 + G3 全量。
