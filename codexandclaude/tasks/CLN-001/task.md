# CLN-001：清理已被正式交互提示取代的灰盒世界提示

状态：已批准（2026-10-22 用户批准）｜级别：S｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：UI-007（正式交互提示已合入）

## 目标

UI-007 合入后，靠近可交互对象时正式提示与灰盒“E / RB · 动作”文字同时出现（UI-007 交付记录“说明与未决”，用户 G4 时知悉）。本任务去掉这些重复的灰盒按键提示，保留仍有信息量的状态文字（BL-116，本卡起草时新增）。

## 依据

- 待办 BL-116；UI-007 交付记录与 `game/docs/area_prompts_ui.md`“已知与后续”；UI-007 审查记录“三个交付说明的判断”第 3 条（另立任务移除合理）。
- A-019：交互提示由 UI-007 的正式提示负责。

## 现状（起草时核对 master@6591165）

带“E / RB · 动作”的灰盒世界文字：

| 位置 | 文字 |
| --- | --- |
| `game/world/items/room_pickup.gd`（`prompt`） | “E / RB · 拾取××” |
| `game/world/hazards/room_rockfall.gd`（`prompt`） | “E / RB · 关闭本间落石” / “落石已永久关闭” |
| `game/world/rooms/connection_room.gd`（`Switch/Prompt`） | “E / RB · 开启前路” / “已开启” / “需要先清敌” |
| `town_room.gd`、`ravine_rescue_room.gd`、`outskirts_room.gd`（`Survivor/Prompt`）及 `ty_10001_1.tscn`、`ty_10002_1.tscn`、`hd_20001_2.tscn`、`nszc_10001_1.tscn` 中的提示 Label | “E / RB · 交谈 / 救助 / 免费救助” |
| 药包补给（`test_medkit_session.gd` 断言其提示含“已满”） | 补给提示与“已满”状态 |

另有不在本卡范围的灰盒文字：右上角 `$Instructions` 说明与调试状态、碎石堆状态、最终战胜利 StageLabel、NPC 名字（含“救助已过期”）。

## 要求

1. 去掉上表中**只表达“按 E / RB 做某事”**的灰盒文字（正式提示已覆盖同一对象与动作）。
2. **保留**表达状态、正式提示无法给出的信息：如“落石已永久关闭”“已开启”“需要先清敌”、药包“已满”等；保留方式可为原 Label 只显示状态文字（不再带“E / RB ·”）。逐项列在交付记录。
3. 不改交互范围、判定、可用性与任何规则；SYS-009 查询结果不变。
4. 依赖这些文字的旧断言（至少 `test_exploration_room.gd`、`test_environment_batch.gd`、`test_medkit_session.gd` 各一处）改为断言状态文字或 SYS-009 查询，交付记录逐条说明。

## 允许修改的文件

- 上表所列 `game/world/` 下脚本与场景（只改提示 Label 的文字与可见性）。
- `game/tests/` 中只因提示文字改变而必须修改的旧断言，以及新增或补充的测试（首行登记，`.uid` 一并提交）。
- `codexandclaude/tasks/CLN-001/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 完成标准

1. 自动测试：上表每个对象在可交互时不再出现“E / RB”灰盒文字；保留的状态文字在对应状态下出现；SYS-009 `interaction_targets()` 对这些对象的结果与修改前一致（同一用例前后比对）。
2. 现有全部测试通过；旧断言改动逐条说明。
3. 变异检查：恢复任一“E / RB”灰盒文字、去掉“已满”等状态文字，相应测试失败。
4. G2 + G3 通过。

## 检查

- G1：新增或补充的套件、`test_exploration_room.gd`、`test_environment_batch.gd`、`test_medkit_session.gd`、`test_quest_interactions.gd`、`test_area_prompts.gd`、救助相关套件。
- G2 + G3：全量，交付记录贴自动摘要。
- G4：不需要（可在 UI-008 或 UI-010 的 G4 时顺带观察）。

## 回滚方案

`git revert` 本任务提交即可恢复灰盒文字。

## 不在范围内

- `$Instructions` 说明与调试状态、NPC 名字、碎石堆与最终战提示等其他灰盒文字；交互规则；正式提示表现（UI-007）。
