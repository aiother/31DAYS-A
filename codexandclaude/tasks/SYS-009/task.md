# SYS-009：任务信息与交互对象数据

状态：进行中（基线2f79b83；按用户已批准任务卡实施）｜级别：M｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：无（UI-007 依赖交互对象查询；第七批任务信息界面依赖任务数据）

## 目标

为正式任务信息（BL-044）与场景交互提示（BL-049，UI-007）提供它们需要、而现有代码没有统一出口的系统部分：**任务状态查询与变化信号、可交互对象查询。只加信号与只读查询，不改任务、救助、拾取或交互规则，不做正式界面。**

## 依据

- 待办 BL-044（任务目标与完成状态在左侧中部偏上；任务进展、放弃、获得时画面中央动画提示；暂停菜单可查看）、BL-049；T7-B、T7-C、T7-F；裁决 A-019、A-020；T3 §9（7 的救助任务）、T4 §6（救助过期）。
- 现有 SYS-005 的做法：UI 数据接口只加信号与查询（`game/docs/ui_data_interface.md`）。

## 现状（起草时核对 master@2183e77）

- 任务：各会话各自实现 `quest_status_text()`（`field_session.gd`、`town_session.gd`、`outskirts_session.gd`、`ravine_depth_session.gd`、`ravine_rescue_session.gd` 等）返回一行中文，由 `FieldDialogue.quest` 每帧显示、`PauseMenu` 读取；没有结构化状态，也没有“进展 / 放弃 / 完成”的信号。
- 获得：拾取与成长补领通过 `save_current("获得…")` / `_notify` 写灰盒说明；没有供界面使用的“获得了什么”信号。
- 交互：约 17 个会话脚本各自在 `_physics_process` 里判断距离与条件后响应 E / RB；拾取物在 `room_pickups` 组；没有“当前有哪些可交互对象、在哪、能否交互”的统一查询。

## 要求

1. **任务查询**：会话提供 `quest_state() -> Dictionary`：`id`、`title`（如“救助”）、`objective`（当前目标一句）、`state`（无 / 进行中 / 已完成 / 已放弃 / 已过期）。沿用各会话现有判断，现有 `quest_status_text()` 的文字保持一致（可改为由 `quest_state()` 生成）。
2. **任务变化信号**：`quest_changed(kind, state)`，`kind` 为开始、进展、完成、放弃、过期；只在状态真的改变时发出一次，读档恢复时不补发历史事件（交付记录写明读档时界面如何取得当前状态）。
3. **获得信号**：`item_obtained(kind, display_name)`，在拾取物、珍珠、药包、Boss 成长等**已成功保存**后发出；保存失败或重试补领只在最终成功时发一次。
4. **交互对象查询**：`interaction_targets() -> Array[Dictionary]`，当前 Room 中每个可交互对象：`id`、`kind`（拾取 / 交谈 / 开关 / 检查点 / 补领等）、`action`（显示用动作名，如“拾取”“交谈”“开启”）、`position`（世界坐标）、`radius`（与现有判定一致的范围）、`available`（此刻按 E / RB 是否会生效）、`key_item`（是否关键物品，供高亮）。范围与可用性必须与现有判定同源，不另写一套近似。
5. 不新增存档字段，不改变任何交互、救助、拾取、计时规则；剧情锁定、对话、暂停时 `available` 为假。

## 允许修改的文件

- `game/world/` 下各会话脚本、`game/world/items/`、`game/world/rooms/`（仅为抽出共用判定与加查询 / 信号）。
- `game/debug/checkpoint_lab.gd` 或会话基类（如需放共用接口）。
- `game/tests/` 中新增或补充的测试（首行登记）；`game/docs/` 中相关说明（在 `ui_data_interface.md` 补充或新建）。
- `codexandclaude/tasks/SYS-009/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 接口与影响

- UI-007 只读 `interaction_targets()` 与 RoomConfig；第七批任务信息界面读 `quest_state()` 并监听 `quest_changed`、`item_obtained`。请在 `game/docs/` 写明字段、值域与发出时机。
- 抽出共用判定时，原行为由现有套件守护；若发现现有某处判定与其他处不一致，按现状保留并在交付记录列出，不顺手“统一”。

## 完成标准

1. 自动测试（真实会话、隔离存档）：每个现有任务（至少 7 的救助）开始 / 完成 / 放弃 / 过期各发一次正确信号，`quest_state()` 与 `quest_status_text()` 一致，读档不补发；拾取、珍珠、药包、Boss 成长成功保存后各发一次 `item_obtained`，保存失败不发、重试成功只发一次；每类可交互对象在范围内外、可用与不可用、剧情锁定时的查询结果与实际按 E / RB 的效果一致。
2. 现有全部测试通过；旧断言改动逐条说明。
3. 变异检查：任务状态不变也发信号、保存失败仍发获得信号、查询范围与实际判定不一致、剧情锁定时仍报可用，相应测试失败。
4. G2 + G3 通过。

## 检查

- G1：新增套件、`test_campaign.gd`、救助与拾取相关套件、`test_ui_data.gd`。
- G2 + G3：全量，交付记录贴自动摘要。
- G4：不需要（界面在 UI-007 与第七批验收）。

## 回滚方案

`git revert` 本任务提交即可；不改存档格式与规则。

## 不在范围内

- 正式任务信息界面、交互提示与区域名称界面（第七批、UI-007）。
- 新任务、新交互对象或规则调整。
