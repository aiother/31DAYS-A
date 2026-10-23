# UI-009：正式敌人介绍卡与战场波次横幅

状态：已完成（2026-10-22，复审与用户G4通过、用户授权合入，master full通过）｜级别：M｜实现：Claude｜审查：Codex
工作区：worktrees/claude｜基线：UI-008 合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：EXP-004（用户选定）；Claude 侧排在 UI-008 之后

## 目标

完成待办 BL-054：按用户在 EXP-004 选定的**介绍卡 2 · 墨条横幅**替换右上角灰盒介绍卡，普通敌人与 Boss 共用一套；战场波次等阶段提示改为画面中上一条独立短横幅，不再借用介绍卡（EXP-004 建议，用户未提异议）。

## 依据

- 用户 2026-10-22 在 EXP-004 选定介绍卡 2；原型 `game/prototypes/EXP-004/intro_card.gd` 方案 2、`preview.gd` 的波次横幅。
- 待办 BL-054；T5.4 §3.2（进入指定范围后显示右上角怪物介绍）、§6.1（天人战士介绍卡）；T7 Boss 名片；T7 核对表 G-04。

## 现状（起草时核对 master@6591165）

- `LifeUI.show_enemy_intro(duration, text)`：灰盒 PanelContainer 从右侧滑入右上，`text` 为“标题\n\n正文”。调用方：`two_room_session.gd`（首次遭遇无色实体）、`tian_session.gd`（天人战士）、`boss_session.gd`（渴望俯视）、`parasite_session.gd`（寄生同伴者），以及 `battlefield_session.gd`、`rescue_battlefield_session.gd`、`final_battle_session.gd` 的阶段与波次提示；`hide_enemy_intro()` 由会话在剧情与超时时调用。
- 卡片与提示共用一个节点，无法区分普通敌人、Boss 与战场阶段提示。

## 要求

1. **介绍卡（方案 2）**：右上角干墨横条写敌人名（纸色字），下接半透明说明块（类别一行、要点若干行）；Boss 版横条右侧加朱红竖印“首领”。从右侧滑入、停留（沿用调用方给的时长）、滑出；暂停时停住；`hide_enemy_intro()` 立即收起。
2. **类别**：无色实体为普通敌人，天人战士为精英（类别文字由 UI 给出，不改敌人数据），渴望俯视与寄生同伴者为首领。
3. **战场横幅**：战场阶段与波次提示（“敌方第 N 波即将进入”“新一波敌人进入战场”“首段完成”等）改为画面中上的独立短横幅，不占右上角卡位，淡入淡出，不遮挡 HUD、对话框与区域名称。
4. **接口**：`show_enemy_intro(duration, text)` 继续可用（作普通敌人卡，标题取第一行）；新增 `show_enemy_card(duration, title, kind, tips)` 与 `show_battle_banner(duration, text)`。为区分三类，**允许**把上述会话脚本中的 `ui.call("show_enemy_intro", …)` 调用行改为调用新方法（只改调用，不改触发条件、时长与文字内容）。
5. 文字用 UI-001 主题字体；关键色不变。

## 允许修改的文件

- `game/ui/menus/life_ui.gd`：介绍卡与横幅的挂载和接口。
- 新增 `game/ui/hud/` 下的介绍卡与横幅脚本。
- `game/world/two_room_session.gd`、`tian_session.gd`、`boss_session.gd`、`parasite_session.gd`、`battlefield_session.gd`、`rescue_battlefield_session.gd`、`final_battle_session.gd`：**只**改 `show_enemy_intro` 调用行。
- `game/tests/` 中新增测试（首行登记，`.uid` 一并提交）及只因表现改变而必须修改的旧断言（交付记录逐条说明）；新增 `game/tests/acceptance/` 下的 UI-009 验收适配；`game/docs/` 相关说明。
- `codexandclaude/tasks/UI-009/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 完成标准

1. 自动测试（真实会话，断言读实际绘制记录）：首次遭遇无色实体出现普通卡（名字、类别、要点）、天人战士出现精英卡、两场 Boss 出现首领卡（含竖印）；进入 / 停留 / 滑出与暂停停住；`hide_enemy_intro()` 立即收起；战场阶段与波次提示走横幅、不出现在右上角卡位。
2. 防重叠：1280×720 与 1920×1080 下卡片、横幅与 HUD、对话框、区域名称、交互提示、错误提示互不重叠且在窗口内。
3. 现有全部测试通过；旧断言改动逐条说明。
4. 变异检查：Boss 不画竖印、波次提示仍走右上卡、暂停时卡片仍移动、`hide_enemy_intro()` 不收起，相应测试失败。
5. G4（用户）：用验收入口看普通敌人、天人、两场 Boss 与战场波次。

## 检查

- G1：新增套件、`test_campaign.gd`、天人 / Boss / 寄生 / 战场相关套件、`test_ui_data.gd`。
- G2 + G3：全量，交付记录贴自动摘要。
- G4：用户实机验收。

## 回滚方案

`git revert` 本任务提交即可恢复灰盒介绍卡；调用行一并回退。

## 不在范围内

- 敌人数据、遭遇触发与时长；正式敌人立绘（M3）；对话界面（UI-008）、任务提示（UI-010）。
