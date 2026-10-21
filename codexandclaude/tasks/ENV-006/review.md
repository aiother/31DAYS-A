# ENV-006 审查记录

审查者：Claude｜日期：2026-10-21｜结论：**通过**（无阻断项；3 条非阻断说明）

## 固定对象

- 基线：`c11d88045b0833d01a80c2d67df0ab5ae476f636`（UI-001 收尾后的 master）
- 实现：`d7a450bdf7e06e4f51fc8e9cfbb711cd5ff80a1d`（含 `1633695` 基线更新）
- 交付／被审 SHA：`8a199d0792ca99a3207c89ea9f97a3c88a567e0d`，在 Claude 工作区 `git switch --detach 8a199d0` 后审查；审查分支 `claude/ENV-006-review` 只新增本记录。
- 实现到交付：只有 `delivery.md` 与任务卡首部（`git diff --stat d7a450b 8a199d0`）。

## 范围

新增 `game/tests/acceptance/`（`acceptance_harness.gd`、`completed_slots.gd`、`run_acceptance.gd` 及 .uid）与 `game/tests/test_acceptance_launcher.gd`（首行登记）；`test_completed_slots.gd` 只改验收分派；`.gitattributes` 增加 `*.import text eol=lf`；新增 `codexandclaude/tests/test_import_line_endings.py`；`env.md` 用法说明。未改 `run_checks.py`、游戏规则、存档格式或正式 UI，均在任务卡范围内。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 通用部分 | 成立。每进程在 OS 缓存目录新建唯一目录；场景进树前设置 `save_directory`，进树后核对 `store.directory`，确认后才写夹具；参数解析拒绝非法槽与未知参数；只读面板可关；无头自测注入真实鼠标事件；截图要求有渲染、无头时明确失败；关闭窗口与退出树都清理，清理只认本进程的 `31days_acceptance_` 目录 |
| 2 场景适配 | 成立。适配只需 `configuration()`（场景、槽快照、是否进入、说明），可选 `status_fields()`、`self_test()`；SYS-004 迁为第一个适配，主档/备份夹具与原入口一致 |
| 3 真实输入与计时 | 成立。不推进计时，只等真实帧、推送真实输入事件 |
| 4 BL-113 | 成立（Claude 工作区复现见下） |

`test_completed_slots.gd`：逐行核对，除删除 `acceptance()`/`capture()` 并改 `run()` 分派外无改动；保留的 `click`、`slot_button`、`menu_button`、`disk_bytes`、`launch`、`write_pair` 仍被普通测试使用。

## 独立检查

- **BL-113 迁移（Claude 工作区）**：固定交付后，`git ls-files --eol` 显示三份 `.import` 为 `i/lf w/crlf`，与仓库内容只差行尾（逐文件 `diff --strip-trailing-cr` 无差异）。**交付记录与 `env.md` 给出的 `git checkout-index --force` + `git add --renormalize` 在本工作区无效**，执行后仍为 `w/crlf`、暂存为空（见 N1）。改为删除这三份文件后 `git checkout -- <文件>`，四份均为 `w/lf`，状态干净。
- **完整门禁**：随后在交付 SHA、起止均 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **79/79**，G3 `tests` **102/102**、`codexandclaude/tests` **67/67**，passed=true，**`content_stable=True`**，运行后无需恢复任何文件。摘要 `codexandclaude/runs/20261021T051209.315976Z/`（不入库）。对照：此前同一工作区 UI-001（`20261021T032000.123378Z`）与 UI-002（`20261021T045638.140693Z`）的 full 均因 `.import` 行尾为 False。完成标准3满足。
- **G1 单项**（无头）：`test_acceptance_launcher.gd` → ACCEPTANCE_LAUNCHER_TESTS 11/0（内部 SYS-004 适配 16/0、进入适配 11/0）；`test_completed_slots.gd` → 73/0；旧入口 `-- --acceptance-smoke` → 16/0；新入口 `run_acceptance.gd -- --self-test` → 16/0。运行后缓存目录无 `31days_acceptance_` 残留。
- **变异**（临时改 `acceptance_harness.gd`，跑 `test_acceptance_launcher.gd`，按原字节恢复后复跑 11/0）：

| 变异 | 结果 |
| --- | --- |
| `cleanup()` 直接返回 | 11 项中 4 项失败，两个适配各 1 项“temporary directory cleaned”失败，退出 1（与交付记录一致） |
| 不设置 `save_directory` | 11 项中 2 项失败，两个适配都在“save directory redirected before ready”处停止、未写夹具，退出 1（与交付记录一致） |

截图模式与真实关窗探针未复跑（需要有渲染的交互进程），采信交付记录；G4 可选项留给用户。

工具：Godot 4.7.2 stable（控制台版）、Codex 自带 Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## 问题与建议（均不阻断）

- **N1 迁移命令无效**：已有 CRLF 检出的工作区，`checkout-index --force` 不会按新属性重写（文件状态未变，Git 视为最新），`add --renormalize` 也无暂存可做。建议 `env.md` 与交付记录改为：确认只差行尾后删除这些 `.import` 再 `git checkout -- <文件>`（或 `git rm --cached` 后 `git reset --hard` 等价做法，但前者更安全），并用 `git ls-files --eol` 确认 `w/lf`。
- **N2 面板位置固定**：只读面板固定在 (820, 850)。UI-002 的正式 HUD 底部有地平线与时刻纸签（约 y 988～1022），说明文字多于4～5行就会压上。建议给 `configuration()` 加可选面板位置（如 `panel_position`），或默认移到右上。在此之前，UI-002 的适配可自行移动 `panel` 下的标签。
- **N3 UI-002 适配**：按任务卡，UI-002 自己写适配（第3日、最终战长短两种预算）。ENV-006 合入后由 Claude 在 `claude/UI-002` 上补充，G4 才进行。

## 结论

通过。可按 `8a199d0` 合入 master；N1 建议在合入时或之后一并修正说明文字。
