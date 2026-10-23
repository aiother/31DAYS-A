# T7-G 最终验收核对（PLN-001）

核对基线：master@`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`（第七批与第八批任务卡合入后）。来源：`Words/T7_UI_UX与存档规格填写模板.xlsx` 的“T7-G 最终验收”页，共 11 项，通过条件按原文抄录。

结论分三类：

- **已覆盖**：正式实现已合入，自动测试用真实会话 / 真实输入验证了通过条件，且对应任务已有用户 G4。
- **需实机确认**：自动测试覆盖了规则，但通过条件含“玩家清楚理解”“流程明确”等体验判断，或需要跨任务连起来看，须由用户在整体通关验收中确认。
- **未覆盖或不在 V0.1**：缺实现或缺测试（本次没有出现）。

“断言”列给出套件名与断言原文（可在 `game/tests/<套件>.gd` 中搜到），复跑方式：`Godot --headless --path game [--fixed-fps 60] --script res://tests/<套件>.gd`（帧率参数以套件首行登记为准），或 `python codexandclaude/tools/run_checks.py full --jobs 4`。

| # | 验收项目 | 通过条件（T7-G 原文） | 正式实现 | 自动测试（套件 · 断言） | 结论 |
| --- | --- | --- | --- | --- | --- |
| 1 | 主界面完整 | 能够开始游戏、继续游戏及进入设置 | UI-004（主界面 A、书签存档选择，系统部分 SYS-008）；UI-006 设置页；UI-005 返回标题 | `test_title_slots` · “a new game starts on the first empty slot”、“设置 opens the settings page over the title”、“Esc from settings returns to the title on 设置”、“confirming quits”；`test_title_flow` · “new launch requests the title exactly once without a save session”、“three missing slots are empty and do not offer continue”；`test_completed_slots` · “END displays the exact completed-game prompt” | 已覆盖（UI-004、UI-006 用户 G4 通过）；整体通关时顺带确认 |
| 2 | HUD完整 | 生命、可能性、日期及倒计时可正确显示 | UI-002（徽记、地平线时刻、换日纸签、最终战倒计时），数据 SYS-005 | `test_formal_hud` · “emblem draws current life shards and filled possibility”、“last life pulses the edge vermilion”、“day one draws life, possibility, growth and overdraft in the chosen colours”；`test_hud_layout`（两种分辨率下各区域不重叠）；`test_ui_data` | 已覆盖（UI-002 用户 G4 通过） |
| 3 | 资源反馈完整 | 玩家清楚理解资源获得、消耗及透支 | UI-002（获得光点飞入、不足发红 A-018、透支失真）、SYS-006；UI-010（“获得 · ××”中央提示） | `test_formal_hud` · “real heal shortfall flashes the ring red (A-018)”、“real second dodge overdraws and triggers the shortfall flash”、“game scene is distorted under every UI layer while overdrawn”、“distortion deepens with the overdraft”；`test_ui_data` · “exact heal cost emits no shortfall”；`test_quest_notices`（获得提示） | **需实机确认**：“清楚理解”是体验判断；消耗时的特效由 EXP-005 / BL-065 后续加强 |
| 4 | 对话交互完整 | 可完成7、10及基础NPC既定流程 | UI-008（纸笺、离开确认、G-08）；7 / 10 / 救助 NPC 的会话流程（既有） | `test_field_room` · “dialogue reveals text over time”、“pause retains current dialogue line and character progress”、“holding interact accelerates text without skipping dialogue”；`test_ten_rescue` · “falling entrance leads to temporary dialogue”、“dialogue completion triggers full-screen slash”；`test_town_rescue` · “real E begins free-control rescue dialogue at zero possibility”；`test_dialogue_ui` · “E next to 7 opens the paper slip (variant D)”、“after the last line the slip closes by itself” | **需实机确认**：各段单独测过，需在一次通关里连起来走完 7、10、救助 NPC；台词仍为临时文本（BL-080） |
| 5 | 任务反馈完整 | 救助成功、失败与注视成长能够正确反馈 | UI-010（任务纸签与中央提示），数据 SYS-009 | `test_quest_notices` · “completion: the signal and the session's text make one gold notice with its detail”、“the gaze notice keeps the text's detail”、“%s: a vermilion centre notice”；`test_quest_interactions` · “repeated save never repeats terminal signal”、“gaze obtained only after durable growth” | 已覆盖（UI-010 用户 G4 通过） |
| 6 | 菜单完整 | 暂停、设置和返回流程明确 | UI-003 暂停菜单；UI-006 设置；UI-005 返回标题与确认 | `test_pause_menu` · “real Esc opens the formal pause menu on continue”、“options are continue, settings, 返回标题 (UI-005, was the kept slot entry) and save and quit”、“game clock does not run while the pause menu is open”；`test_settings_page` · “Enter on 设置 opens the formal settings page”、“left lowers the master volume through the service, applied and saved”；`test_outcome_sheets` · “confirming returns to the title” | 已覆盖（UI-003、UI-005、UI-006 用户 G4 通过）；“流程明确”在整体通关时顺带确认 |
| 7 | 死亡恢复完整 | 正确恢复检查点、资源和世界状态 | UI-005 死亡界面；既有检查点与死亡规则 | `test_player_life` · “death event emitted exactly once”、“fade completes before death menu becomes ready”；`test_checkpoints` · “checkpoint does not refill resources”、“normal load preserves current resources without death penalty”；`test_outcome_sheets` · “death opens the formal death sheet”、“从检查点继续 still revives at the checkpoint”；`test_medkit_session` · “actual death reload keeps count and pickup keys” | 已覆盖（UI-005 用户 G4 通过）；整体通关时死一次确认 |
| 8 | 存档完整 | 永久事件不丢失、不重复领奖 | 分槽存档、永久事件与成长（既有）；SYS-004 已通关存档 | `test_slot_store` · “slots do not cross-contaminate”、“invalid %s rejected without modifying slot”；`test_quest_interactions` · “pearl obtained after durable save exactly once”、“repeated save never repeats terminal signal”；`test_pearl_growth` · “repeated saves never compound growth”；`test_completed_slots` · “completed slot still asks for new-game overwrite confirmation” | 已覆盖 |
| 9 | 时间状态完整 | 3天与最终倒计时的保存规则明确 | 自然计时、最终战计时（既有）；UI-002 时间显示 | `test_day_clock_session` · “menu pause freezes real frames and direct timer invocation”、“date crossing persists date and new-day clock atomically”；`test_final_clock` · “starting again never refills running budget”、“explicit retry restores original budget and required day window”；`test_world_day_session` · “date and expiry saved together” | 已覆盖；“规则明确”指玩家能看懂，整体通关时顺带确认 |
| 10 | 最终结算完整 | 胜利、超时、死亡不会触发错误结局 | 最终战结算（既有）、SYS-003 同帧胜利优先；UI-005 结束 / 超时界面 | `test_final_retry` · “same-frame final clear saves victory without timeout: ”、“late final kill cannot overturn a timeout committed in an earlier frame”、“failed same-frame victory save keeps retryable win without committing timeout”；`test_final_battle` · “E retries and persists final victory”、“saved victory permanently stops countdown”；`test_outcome_sheets` · “a final battle timeout opens its sheet”；`test_completed_slots` · “WON can finish dialogue and continue the ending” | 已覆盖；整体通关以胜利收尾确认结局画面 |
| 11 | V0.1范围一致 | 不引入T0之外的新功能系统 | — | 规格级核对，无自动测试 | **需实机确认**（文档级已核对）：M2 各任务卡均以 T7 / 待决事项裁决为依据，新增的界面表现（暂停菜单方案四、透支失真、G-08 短提示等）都是 T7 已有界面的表现或用户裁决，未引入新的功能系统；原型（EXP-001～005）均隔离在 `game/prototypes/`；SYS-010 动画框架属于 T6 已列的资源接入。由用户在整体通关后确认没有感到“多出来的系统” |

## 汇总

- 已覆盖：1、2、5、6、7、8、9、10（其中 1、6、7、9、10 在整体通关中顺带复查）。
- 需实机确认：3、4、11。
- 未覆盖：无。

## 整体通关验收要点（G4）

分两部分，见交付记录“G4（用户）”：

1. **真实启动游戏**（主场景，不用验收入口）：主界面 → 新游戏 → 开场与第一段遭遇；暂停菜单（继续、设置、返回标题、保存并退出）；故意死一次，看死亡界面与“从检查点继续”；返回标题后“继续游戏”回到存档。对应 1、6、7。
2. **验收入口 `pln001_campaign.gd` 的三个存档槽**，按时间顺序跳着走完：
   - 槽 1 第 1 日·渴望俯视之后：田野 7 的剧情、麦秆镇救助（成功）、回 7 获得注视。对应 3、4、5。
   - 槽 2 第 2 日·巢都沟壑入口：沟壑救助、珍珠拾取、换日提示。对应 3、5、9。
   - 槽 3 第 3 日·中心战场前（已救 10，最终战预算较长）：进入战场、10 协同、最终战倒计时，打到胜利与结局画面。对应 4、9、10。
3. 走完后对照第 11 项，说一下有没有感到 T0 之外的新系统。

逐项结果写入交付记录；“需实机确认”的三项都通过、其余顺带复查无异常，即可关闭 M2。
