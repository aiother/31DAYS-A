# UI-008：正式对话界面与 G-08 错失救助提示

状态：已批准（2026-10-22 用户批准）｜级别：L｜实现：Claude｜审查：Codex
工作区：worktrees/claude｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：EXP-004（用户选定）、SYS-009（任务状态与交互查询）

## 目标

完成待办 BL-048：按用户在 EXP-004 选定的**方案 D · 纸笺纸边**替换现有灰盒对话框，并按选定的 **G-08 · 2 短提示**实现“已无法拯救的 NPC 处提示更早到来曾有救助机会”。同步修订 T7-C（D 的底色不是“黑色半透明”）。

## 依据

- 用户 2026-10-22 在 EXP-004 选定：对话 D、G-08 短提示（EXP-004 交付记录“G4 用户选定”）；原型 `game/prototypes/EXP-004/`（`dialogue_view.gd` 方案 D、`preview.gd` 的 G-08 纸签）。
- 待办 BL-048；T7-A“NPC对话界面”、T7-C 对话框布局 / 文本 / 角色信息 / 推进 / 结束 / 救助选择、T7-F“玩家在对话中暂停”；T7 核对表 G-08；T4 §6；裁决 A-020（确认后才放弃救助）。
- SYS-009：`quest_state()`（`已过期`）、`interaction_targets()`（`交谈` 对象与 `in_range`）；普通对话门禁。

## 现状（起草时核对 master@6591165）

- `game/ui/dialogue/field_dialogue.gd`（`FieldDialogue`，CanvasLayer 15）：灰盒黑色 PanelContainer 在中上，逐字显示（`DialogueConfig.characters_per_second`、按住 E / RB 乘 `hold_speed_multiplier`）、单击补全 / 下一句、`show_departure()` 的“留下 / 确认离开并放弃救助”两个灰盒按钮；角色名 Label 在屏幕左下 (64, 912)；同一节点还承载左侧任务文字 `quest` 与中部 `notice`（`show_notice()`）。
- 每份 `DialogueConfig` 只有一个 `speaker`（多为“× · 临时台词”）。
- G-08：四处救助过期后，救助对象仍在原地，交谈时由 `rescue_expired_text()` 走同一对话框；房间里另有灰盒名字“幸存者 · 救助已过期”与说明文字。没有靠近即出现的提示。

## 要求

1. **对话框（方案 D）**：画面中上部的黄昏色纸笺，上下沿为撕开的纸边，墨色逐字文字；左下小块墨色名签写 `speaker`（纸色字）；句子显示完后右下出现继续标记，按住 E / RB 时出现加速标记；最后一句后自动关闭；强制剧情（`intro_active` 等）期间隐藏 HUD 的现有行为保持。按键说明行是否保留，按 G4 意见。
2. **推进与加速**：沿用 `DialogueConfig` 的速度与倍率；单击补全 / 下一句、按住加速、结束自动关闭的语义与现有实现一致；对话中暂停（Esc / Start）对话停在原处，返回后继续（T7-F）。
3. **救助离开确认**：沿用 `show_departure()` 与 `departure_confirmed / departure_cancelled` 信号；两个墨色按钮“留下 / 确认离开并放弃救助”互不重叠，默认焦点“留下”，焦点只在两者间；暂停时两按钮不可用、恢复后焦点还原（EXP-004 审查 R1、R2 的做法）。
4. **G-08 短提示**：当前 Room 的救助 `quest_state().state == "已过期"`，且该救助对象的 `交谈` 目标 `in_range` 时，在对象上方出现小纸签“此处曾有人需要帮助 / 更早到来，或许还来得及”，约 4 秒淡出，不锁操作；同一次进入 Room 只出现一次，离开后再来可再出现。交谈时的过期台词保持不变。
5. **T7-C 修订**：在 T7 核对表 / 主文档中把“中上部黑色半透明”改为方案 D 的描述，注明来源（EXP-004 用户选定），与 EXP-001 选定方案四后修订 T7 的做法一致。
6. `quest`（左侧任务文字）与 `show_notice()` 的现有行为本任务不改，留给 UI-010。

## 允许修改的文件

- `game/ui/dialogue/field_dialogue.gd`：对话框表现、离开确认、G-08 短提示；`quest` / `notice` 保持现有接口与表现。
- 新增 `game/ui/dialogue/` 下的绘制脚本（如需要），使用 `game/ui/style/`。
- `game/ui/menus/life_ui.gd`（如需挂载 G-08 节点）。
- `Words/T7核对表.md` 及 T7 中对应条目（只改对话框外观一项）。
- `game/tests/` 中新增测试（首行登记，`.uid` 一并提交）及只因表现改变而必须修改的旧断言（交付记录逐条说明）；新增 `game/tests/acceptance/` 下的 UI-008 验收适配；`game/docs/` 相关说明。
- `codexandclaude/tasks/UI-008/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 接口与影响

- 会话脚本对 `dialogue_ui.start / advance / show_departure / dismiss / active / confirming` 的用法不变；若必须改调用，停下报告。
- UI-010 将接管 `quest` 与 `notice`；UI-009 的介绍卡在右上，与本对话框不重叠（EXP-004 布局：对话框 840 宽居中，Boss 名片 480 宽）。

## 完成标准

1. 自动测试（真实会话、真实输入，断言读实际绘制记录）：方案 D 的纸面、撕边、名签与文字；逐字、单击补全 / 下一句、按住加速（同帧数比较单击与按住）、自动关闭；对话中暂停保持；离开确认默认“留下”、焦点约束、暂停时不可选、恢复后焦点；G-08 只在已过期救助处靠近时出现、约 4 秒淡出、不锁操作、同次进入只一次；强制剧情隐藏 HUD。
2. 防重叠：1280×720 与 1920×1080 下对话框、名签、确认按钮、G-08 纸签、HUD、区域名称、交互提示互不重叠且在窗口内。
3. 现有全部测试通过；旧断言改动逐条说明。
4. 变异检查：去掉长按加速、确认默认焦点改为离开、暂停时按钮仍可用、G-08 在未过期救助处也出现、G-08 锁住操作，相应测试失败。
5. G4（用户）：用验收入口与几处 NPC 对话（含救助离开确认与一处已过期救助），确认表现。

## 检查

- G1：新增套件、`test_campaign.gd`、救助相关套件（town / ravine / ravine_depth / outskirts rescue）、`test_quest_interactions.gd`、`test_pause_menu.gd`。
- G2 + G3：全量，交付记录贴自动摘要。
- G4：用户实机验收。

## 回滚方案

`git revert` 本任务提交即可恢复灰盒对话框；T7 修订一并回退。

## 不在范围内

- 正式台词与立绘（M3）；任务信息与中央提示（UI-010）；敌人介绍卡（UI-009）；灰盒世界提示清理（CLN-001）。
