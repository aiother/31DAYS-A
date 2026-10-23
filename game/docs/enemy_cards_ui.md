# 正式敌人介绍卡与战场横幅（UI-009）

## 介绍卡

- 脚本：`game/ui/hud/enemy_card.gd`（`EnemyCard`，继承 `PanelContainer`）。`LifeUI._enemy_intro` 就是它，仍由 LifeUI 用 `position` 滑入滑出；隐藏的子 Label 保存“名字\n\n要点”，旧会话与旧测试照常读取。
- 外观按 EXP-004 用户选定的方案 2 · 墨条横幅：右上角干墨横条写敌人名（纸色字），左端有干笔飞白；横条下接半透明墨色说明块，第一行类别（朱红偏亮），下面是要点。首领卡更宽（480，普通 440），横条更高，右侧加朱红竖印“首领”。
- 位置：停靠时右边缘在 `EnemyCard.RIGHT = 1880`（距右边 40，与原型一致），顶边 `TOP = 100`；高度随要点行数变化。
- 类别（UI 给出，不改敌人数据）：无色实体“普通敌人”，天人战士“精英”，渴望俯视与寄生同伴者“首领”。
- 进出：从右侧滑入 0.2 秒，停留调用方给的时长，滑出后隐藏；暂停时 Tween 与剩余时间都停住；`hide_enemy_intro()` 立即收起。
- `drawn` 记录由绘制调用返回：`band`（横条矩形与颜色）、`title`、`kind`、`tips`、`under`、首领的 `seal`（矩形、颜色、文字）。隐藏时清空。

## 战场横幅

- 脚本：`game/ui/hud/battle_banner.gd`（`BattleBanner`，`LifeUI._battle_banner`）。
- 战场阶段与波次提示（“中心战场 · 首段完成”“新一波敌人进入战场”“中心战场 · 10协同阶段完成”“敌方第 N 波即将进入”）改走横幅，不再占右上角卡位。第一行作标题，其余作小字。
- 画面中上 680 宽的墨色横带，顶部一道朱红细线；淡入淡出 0.25 秒；暂停时停住。
- 避让：依次试 y = 196 / 330 / 430，取第一个不与 HUD 绘制矩形（含地平线、最终倒计时、换日纸签）、打开的对话纸笺、区域名称、交互提示、介绍卡、可见的保存失败提示相交的位置；都不行时这一帧让位不画，计时照走。
- `drawn` 记录由绘制调用返回：`band`（`_fill()` 实际填充的矩形与带 alpha 的墨色）、`heading`、`line`；让位或结束时为空。
- `hide_enemy_intro()` 同时收起横幅：阶段提示原本与介绍卡共用一个节点，会话在剧情与结局时调用它来清掉当前提示，保持这一效果。

## 接口

- `show_enemy_intro(duration, text)`：保留，作普通敌人卡，第一行为名字，其余为要点。
- `show_enemy_card(duration, title, kind, tips)`：`kind` 取 `EnemyCard.KINDS`（普通敌人 / 精英 / 首领）。
- `show_battle_banner(duration, text)`。
- 会话脚本只改了调用行：天人战士用精英卡，两场 Boss 用首领卡，四处战场提示用横幅；触发条件、时长与文字不变。首次遭遇无色实体仍调用 `show_enemy_intro`。
- 介绍卡与横幅加入 `LifeUI._protected_rects()`，区域名称、交互提示与 G-08 纸签都会让开它们。

## 测试与验收

- `game/tests/test_enemy_cards.gd`：真实遭遇触发的普通、精英、两场首领卡（含竖印）；滑入 / 停靠 / 滑出、暂停停住、`hide_enemy_intro()`；最终战真实波次走横幅、位置与暂停、淡出、被 `hide_enemy_intro()` 清掉；两种分辨率下卡片、横幅与 HUD、对话纸笺、区域名、交互提示、保存失败提示互不重叠且在窗口内。
- G4：`game/tests/acceptance/ui009_enemy_cards.gd`（普通、精英、渴望俯视）与 `ui009_battle.gd`（寄生同伴者、救10后的新一波、最终战波次）。
