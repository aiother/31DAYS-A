# EXP-001 集成记录

## 前序：第一批任务规划集成

本记录仅覆盖 EXP-001、ENV-004、SYS-004 的规划批次；不表示 EXP-001 原型已获准合并，也不表示三项任务完成。

- 授权：2026-10-20，本会话用户明确回复“授权现在合入规划”。授权后执行合并。
- 合并前 master：`e568f84623cd37722aed78f9235a928a9793b16d`。
- 固定规划提交与快进后 master：`e2b69d95cb66917a1dff5b96a76e0eabc629291e`。命令：`git merge --ff-only e2b69d95cb66917a1dff5b96a76e0eabc629291e`；无冲突，未使用可移动分支名。
- 范围：三张任务卡、BOARD、BACKLOG，以及 DOC-007 非阻断建议对应的快照测试收紧。六个文件，无游戏文件变化。ENV-004 采用甲（文件首部登记）；SYS-004 等 ENV-004，EXP-001 可并行。
- 合并前无重叠未提交修改。普通沙箱 Git 显示的 `.claude/` 未跟踪目录未触碰；实际门禁进程记录 dirty=false、status=[]。
- master 上执行：`python codexandclaude/tools/run_checks.py focused --python-all`。在固定规划 SHA、dirty=false 上，tests 92/92、协作测试 44/44，complete=true、passed=true，全部子命令退出0。
- 工具：Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。纯规划不跑 G2。
- 原始证据：主工作区 `codexandclaude/runs/20261020T114723.959233Z/summary.json` 及同目录日志（忽略，不入库）。本记录提交前再跑 G3 和 `git diff --check`。

EXP-001 的交付审查在 Codex 工作区固定 `bb4aedf21aac056906ef4a350bd1c71f548bebba` 独立执行；实现者可在收到本记录提交 SHA 后合并 master，补写基线。没有开工 ENV-004 或 SYS-004，也没有合并 EXP-001 实现。

## EXP-001 原型合并与收尾（2026-10-20）

- 用户授权：本会话“EXP-001合并吧”，授权后才执行本次合并。此前用户已选定方案四，交付记录G4第2轮保留原话“我觉得没问题，你现在的方案4处理比较符合我的意向”；这是探索原型的方案选择，不代表正式视觉品质定稿。
- 合并前master：`66ee2b5ff0abaf110186a00760605efde17b4fb7`；无重叠未提交修改。普通沙箱可见的未跟踪`.claude/`目录未触碰，门禁记录dirty=false、status=[]。
- 固定审查SHA：`baf09fef8522d2c307c06c7696a9d8edc73cef06`。执行 `git merge --ff-only baf09fef8522d2c307c06c7696a9d8edc73cef06`，无冲突；快进后master即该SHA，没有另造合并提交，未合并可移动分支名。
- 合并后在master执行 `python codexandclaude/tools/run_checks.py focused --python-all`：tests **92/92**、协作测试 **45/45**，complete=true、passed=true，所有子命令退出0。被测SHA为上述固定审查SHA，dirty=false。原始日志 `codexandclaude/runs/20261020T123659.645664Z/summary.json` 及同目录日志（忽略，不入库）。
- 同一master补跑 `Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd`：**EXP001_SMOKE checks=105 failures=0**，退出0，无ERROR/WARNING。工具Godot4.7.2.stable.official.ed1daf0bf、Python3.12.14/openpyxl3.1.5、Git2.56.0.windows.2、Nodev24.19.0。
- 本次按用户授权入库隔离原型，正式游戏、输入、存档、验证流水线均未修改；按§3.3不跑全套G2。选中方案的正式HUD/时间/暂停菜单实现及T7同步仍由BL-042/043/046后续任务承担。
- 收尾只更新本记录与任务卡首部为已完成；BOARD/BACKLOG由规划维护者后续串行刷新。提交前再跑G3及差异检查。ENV-004仍在独立实现分支待Claude审查，本次未合入，SYS-004未开工。


## 按用户追加要求补跑完整G2+G3（2026-10-20）

用户明确要求：EXP-001新增Godot原型脚本与shader会进入编辑器导入，本次合并补跑全量，并刷新任务板EXP-001状态。前节保留的是首次收尾的实际执行历史；本节补齐最新验收要求。

- 本次开始时master为 `7483c8e7c349c8d9e367f3b73a1ca81498462960`，已包含固定审查SHA `baf09fef8522d2c307c06c7696a9d8edc73cef06`，用祖先检查确认，无需重复合并。与审查SHA相比仅有此前两份收尾记录改动，没有未审查代码。无重叠未提交修改；普通沙箱可见的`.claude/`目录未触碰。
- 在该master、dirty=false、status=[]执行：`python codexandclaude/tools/run_checks.py full --jobs 4`。
- G2 **75/75**：编辑器导入、主场景180帧及全部原73套件通过。原型未登记为正式引擎套件，但已随本次编辑器导入纳入检查。无退出错误、解析错误、泄漏或超时。
- G3：tests **92/92**，codexandclaude/tests **45/45**，两组complete=true、passed=true；汇总passed=true，所有子命令退出0。
- 工具：Godot4.7.2.stable.official.ed1daf0bf、Python3.12.14/openpyxl3.1.5、Git2.56.0.windows.2、Nodev24.19.0。
- 原始证据：`codexandclaude/runs/20261020T123853.737701Z/summary.json`、同目录engine.txt与逐命令日志；引擎报告SHA256：`0d11c3b983f3eef1076cc38392d1099793a0fbb4166fe1ee9d37afe0f0ed7756`。原始日志忽略，不入库。
- 全量执行后检查两份SVG.import无内容差异，清理检查后没有正式游戏文件或已审查原型的改动。
- 本次仅追加集成记录、任务卡首部注明全量通过、BOARD中EXP-001改为已完成并注明本项汇总基线；用户已选定方案四。BL-042、BL-043及BACKLOG不改，选中方案的正式任务待规划立项。提交前再跑G3和差异检查。
- ENV-004仍由Claude审查，不在本次合并范围，SYS-004未开工。未来获授权合并ENV-004时，test_collaboration.py若有冲突须保留双方测试，本次不提前合并该分支。
