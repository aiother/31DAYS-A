# 第一批任务规划集成记录

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
