# 正式对话界面与 G-08 短提示（UI-008）

## 对话纸笺

- 脚本：`game/ui/dialogue/field_dialogue.gd`（`FieldDialogue`，类名、信号与方法不变）。
- 外观按 EXP-004 用户定稿的方案 D：画面中上部 `BOX = Rect2(540, 120, 840, 250)`，当日黄昏色纸笺（`DuskStyle.PAPER_DUSK`，0.95 不透明），上下沿撕边，墨色正文，左下小块墨色名签（纸色字）；纸笺下方一行“E / RB 继续 · 长按加速”。
- 隐藏的 `text` / `speaker` / `hint` Label 仍是数据模型，原有会话与测试只读写它们；`panel` 负责绘制，`drawn` 记录与绘制同一次调用产生（`_ink()` 返回 `{text, color}`）。
- 逐字显示：`characters_per_second`，按住 E / RB 时乘 `hold_speed_multiplier`；一次按键先补全当前句（出现“继续”标记），再按进入下一句；最后一句结束自动关闭。
- 暂停：`process_mode = ALWAYS`，暂停时文字不动、按钮禁用；恢复后焦点回到原按钮。

## 离开确认

- `show_departure()`：纸笺内两枚按钮“留下”“确认离开并放弃救助”，默认焦点“留下”，焦点只在两枚按钮间移动；暂停时鼠标、Enter、A 都不能选。
- 信号 `departure_cancelled` / `departure_confirmed` 与原来一致，判定仍在各会话。

## G-08 短提示

- 条件：`quest_state()` 为“已过期”且任务 id 等于当前 Room id，玩家进入该对象的交互范围（无范围时按距离 `MISSED_REACH`）。
- 表现：对象上方 `MISSED_LIFT` 处一张小纸签“此处曾有人需要帮助 / 更早到来，或许还来得及”，约 `MISSED_SECONDS`（4 秒）淡出；不锁操作、不打开对话；每次进入该 Room 一次，离开再回来可再出现。
- 避让：上方放不下时放到对象下方；仍与 HUD 绘制矩形、区域名、交互提示、可见的保存失败提示相交时等待，不覆盖。对话打开时隐藏。
- 与对象交谈时的过期台词保留。

## 测试与验收

- `game/tests/test_dialogue_ui.gd`：纸笺、逐字、长按加速、暂停、自动关闭、离开确认焦点与暂停防护、G-08 出现 / 消失 / 每次进入一次 / 未过期与 7 处不出现、两种分辨率下的布局。
- 首个强制剧情隐藏 HUD 由 `test_field_room.gd` 覆盖。
- G4：`game/tests/acceptance/ui008_dialogue.gd`（槽 1 开局、槽 2 沟壑救助已过期、槽 3 沟壑救助未过期）。

## 已知与后续

- `quest` 任务文字与 `show_notice()` 中央提示仍为灰盒，由 UI-010 接管。
