# SYS-004 审查记录

审查者：Claude｜日期：2026-10-20｜结论：**通过**（无阻断项）｜用户 G4：**通过**

## 固定对象

- 基线：`30dbfcbffb09f91a478e3be5037508b9c1f02ace`（ENV-004 合并收尾后的 master，含 EXP-001）
- 实现：`2c4d6f399b633316c2322291987873a12e76c4dd`
- 交付／被审 SHA：`e4fd2c44da5140b7467ad9e54ee8ab7a2d7bc30a`，在 Claude 工作区 `git switch --detach e4fd2c4` 后审查，检查期间工作区干净；审查分支 `claude/SYS-004-review` 建在该提交上，只新增本记录。
- 实现到交付：`git diff --stat 2c4d6f3 e4fd2c4` 只有 `delivery.md`（新增）与任务卡首部一行，无代码变化。

## 范围

改动 11 个文件，均在任务卡允许范围内：`checkpoint_lab.gd`（入口拦截 5 行）、`slot_store.gd`（只读判断 3 行）、`life_ui.gd`（灰盒“已通关”附注 2 行）、`game/docs` 两段现行说明、新套件 `test_completed_slots.gd`（第一行按 ENV-004 方式登记）、`test_final_battle.gd` 与 `test_campaign.gd` 中“已完成槽重载成功”的旧断言改为“拒绝重入”。未改 `final_battle_session.gd`、存档格式、事件写入时机、`project.godot`、验证工具、BOARD 或 BACKLOG。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 END 继续：提示“游戏已通关”、不加载、不改主档与备份 | 成立。拦截位于 `load_slot()` 之后、检查点校验、新游戏写入与会话重载之前；测试比对主档、.bak、.tmp 字节与存在状态，并确认场景与 Room 实例不变 |
| 2 END 槽仍可新游戏 | 成立。`new_game` 分支读的是 `fresh()`，不受拦截；测试经确认对话真实开始并检查落盘主档不含 END |
| 3 WON、TALK、TIMEOUT、普通进行中都可进入 | 成立。判断只看 `FinalClock.END`；五类真实存档逐一经真实菜单进入并推进各自流程（WON 开始并完成胜利对话、TALK 完成演出后写 END、TIMEOUT 明确重试进入最终战、普通存档回到检查点） |
| 4 备份恢复出的 END 同样拦截 | 成立。主档损坏、主档缺失两种情况下由备份读出的 END 均被拒，主档状态与备份字节不变 |
| 5 当前会话完成结束事件的流程不变 | 成立。`final_battle_session.gd` 未改；新套件 TALK 路径与 `test_final_battle`、`test_campaign` 的真实通关回归都覆盖结束屏 |
| 6 判断在存档/入口层，界面只显示 | 成立。`SlotStore.is_completed()` 只读；`CheckpointLab.start_slot()` 拦截；`LifeUI` 只加附注，继续按钮仍可点以显示提示 |

另核对：已有其他槽的活跃会话时点 END 槽继续，不会打断或替换当前会话（新套件覆盖）。

## 独立检查

- **完整门禁**：在交付 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **76/76**（导入、主场景180帧、74 套件），G3 `tests` **102/102**、`codexandclaude/tests` **45/45**，passed=true。用时约 12.5 分钟。摘要 `codexandclaude/runs/20261020T132516.548934Z/summary.json`，engine.txt SHA256 `9BC07574…8385`（不入库）。两个 SVG.import 的已知纯行尾变化已 `git restore`。
- **变异**：临时删除 `start_slot()` 中 END 拦截的三行，分别运行三个相关套件后按原字节恢复（源文件复核一致）：

| 套件 | 去掉拦截后 |
| --- | --- |
| `test_completed_slots.gd` | 73 项中 16 项失败，退出1，无 SCRIPT ERROR（与交付记录一致） |
| `test_final_battle.gd` | 29 项中 2 项失败 |
| `test_campaign.gd` | 166 项中 2 项失败 |

- 工具：Godot 4.7.2 stable（控制台版）、Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## G4（用户）

用户 2026-10-20 在 Codex 工作区运行交付记录中的 `--acceptance` 入口（独立临时存档）后回复：“SYS-004 G4 通过”。即：槽1 显示“已通关”；点继续出现“游戏已通关”并停留在选槽；同槽新游戏经确认后正常开始。

## 非阻断观察

- 现有灰盒选槽里，已通关槽的“继续”按钮仍可点，点击后才提示。这符合 A-013“选择该槽时提示”，正式存档选择界面（BL-041）可再考虑是否直接把按钮做成已通关样式。不需要本任务处理。

## 结论

通过。审查 SHA 为本记录提交，见会话交接；合并需用户授权。
