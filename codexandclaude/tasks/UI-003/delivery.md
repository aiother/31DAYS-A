# UI-003 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-003`
基线：`c6a8f937d504b80783b1d917764c3e5352cde4ca`（第四批任务卡合入后的 master）
实现 SHA：`1710212d13afa90d39d1d37908718ddb6a569a51`（含 `b27de15` 实现、`46f1146` 测试与文档、`1710212` 修正）

## 开工时用户的决定（2026-10-21）

| 问题 | 选项 | 用户选择 |
| --- | --- | --- |
| 保存反馈需要“检查点保存成功”信号，现有代码没有，属 Codex 负责的存档代码（任务卡“接口与影响”要求停下报告） | Claude 在 UI-003 中顺手加、Codex 审查 / 另立 SYS-008 交给 Codex / 保存反馈推迟到第五批 | **Claude 顺手加**（Claude 推荐：改动极小，审查方正好是存档代码负责方，一次交付） |

批准任务卡时已定：主界面完成前暂停菜单暂留“存档槽”。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/menus/pause_menu.gd`（新增，`PauseMenu`） | 方案四暂停菜单：左侧纸面选项（继续游戏、设置、存档槽、保存并退出）；右侧时钟（与 HUD 同一换算的时刻、第N日与末日倒数、三天进度、距下一日 / 最后一日 / 最终战剩余、当前任务）；设置与保存并退出确认作为二级页盖住时钟；返回时焦点回到打开它的那一项。纸面垫不透明纸底，HUD 与房间文字不透出。每帧写 `drawn` |
| `game/ui/menus/ink_button.gd`（新增，`InkButton`） | 墨线按钮，焦点为手绘下划线加朱红小三角 |
| `game/ui/menus/save_toast.gd`（新增，`SaveToast`） | “检查点已保存”小纸签，2.4 秒淡出，位于操作提示之下 |
| `game/ui/menus/life_ui.gd` | 公开方法不变，暂停、设置、保存并退出改为驱动 `PauseMenu`；其他灰盒面板打开前关闭暂停菜单；挂接保存反馈；`_quit_handler` 可替换以便测试 |
| `game/debug/checkpoint_lab.gd`（用户批准的接口改动） | 新增 `checkpoint_saved(id)`：`save_current()` 成功写盘、且写入的检查点与上次落盘不同时发出；`_restore()` 记下当前检查点。周期 / 资源 / 事件自动保存、读档、写盘失败都不发。放在 `save_current()` 而不是 `activate_checkpoint()`，因为营帐、沟壑、堑壕第二间三个子类自己处理检查点、不调用父类 |
| `game/tests/test_pause_menu.gd`（新增，41 项）、`test_pause_acceptance.gd`（新增）、`game/tests/acceptance/ui003_pause.gd`（新增） | 见下 |
| `game/tests/test_menu_controller.gd`、`test_field_room.gd` | 只因暂停菜单表现改变而改的旧断言，见下表 |
| `game/docs/pause_menu_implementation.md`（新增） | 说明 |
| `Words/T7核对表.md` | T7-A“暂停菜单”行追加 UI-003 修订：右侧为方案四时钟，当前任务为下方一行，二级界面盖住时钟，暂留存档槽；T7 原件不改 |

## 旧断言改动（只因暂停菜单表现改变）

| 测试 | 原断言 | 现断言 |
| --- | --- | --- |
| `test_menu_controller.gd` “A returns to pause …” | 从设置返回后焦点在“继续游戏” | 焦点回到“设置”（方案四原型行为），再用十字键上移回“继续游戏”并断言，后续“A 确认继续”不变 |
| `test_field_room.gd` “pause menu includes current rescue objective” | 遍历灰盒 `_menu` 的 Label 找“麦秆镇” | 等一帧后读 `PauseMenu.drawn["quest"]` 含“麦秆镇” |

其他 20 余个调用 `show_pause()` 的套件只断言暂停冻结，未改动。

## 完成标准对照

1. **自动测试**（`test_pause_menu.gd`，真实主会话，真实 Esc / 方向键 / 十字键 / Enter 与鼠标事件，断言读 `drawn`）：Esc 打开、焦点在继续；四项选项；时钟时刻等于 `FormalHud.clock_text`、日期、三天进度、距下一日与 `ui_time_state()` 一致；暂停 60 帧计时不走；方向键、十字键、鼠标点击都能选中；设置页与确认页盖住时钟、Esc 返回且焦点回到原项；保存并退出默认焦点“返回”，写盘失败不退出且页面显示错误，成功写盘后只退出一次；周期保存不提示、检查点写盘失败不提示、进入沟壑的真实检查点成功后提示并淡出；最终战暂停显示真实剩余、前两日满格、当前任务与会话一致。
2. **防重叠**：1920×1080 与 1280×720 下，保存提示不与 HUD 各区域及错误提示相交且在窗口内；暂停纸面、时钟、二级页都在窗口内且互不重叠。暂停时纸面本就盖住 HUD（模态）；暂停期间的存档错误改在确认页上显示原文，所以错误不会被纸面遮住而看不到。
3. **现有测试**：全部通过；旧断言改动见上表。
4. **变异**（临时改源文件，跑 `test_pause_menu.gd`，脚本按原字节恢复后复跑 41/41）：

| 变异 | 失败数 |
| --- | --- |
| 二级页不盖住时钟 | 3 |
| 暂停时计时继续走 | 4 |
| 保存失败仍退出 | 2 |
| 保存失败也显示“检查点已保存” | 1 |

5. **G4**：待用户，见下。

## 过程中的问题

- 第一次 full（`46f1146`，摘要 `runs/20261021T101237.732593Z`）失败 1 项：`test_field_room` 的当前任务断言。原因不只是断言过时：`FieldSession` 没有 `ui_time_state()`，暂停页不画时钟时把当前任务也一并丢了。`1710212` 改为没有时钟时单独画任务纸签并记录 `drawn["quest"]`，再改该断言。此前我只挑相关套件单跑，漏了它。
- 渲染截图发现纸面半透明，HUD 徽记与房间说明文字透出，已加不透明纸底。

## 检查证据

在实现 SHA、起止 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：

- 总结果：**通过**；被测 SHA `1710212d13afa90d39d1d37908718ddb6a569a51`。
- G2：实际 83 / 预期 83（新增 `test_pause_menu.gd`、`test_pause_acceptance.gd`）；完整、通过。
- G3：`tests` 102/102、`codexandclaude/tests` 67/67，完整、通过。
- `content_stable=True`。摘要 `codexandclaude/runs/20261021T102649.247068Z/`（不入库）。
- 单项：`PAUSE_MENU_TESTS 41/0`、`MENU_CONTROLLER_TESTS 33/0`、`FIELD_ROOM_TESTS 50/0`、`PAUSE_ACCEPTANCE_TESTS 3/0`（内部适配 16/0）。

## 与 SYS-007 的关系

SYS-007（Codex，进行中）也会改 `life_ui.gd` 的设置部分。本任务已把设置三项移到 `PauseMenu.show_settings()`，LifeUI 里不再有灰盒设置代码；后合入的一方按任务卡负责合并：SYS-007 若后合入，应把音量、窗口、全屏的调用改在 `pause_menu.gd` 的 `show_settings()` 里。

## G4（用户）

```powershell
Godot --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui003_pause.gd
```

（在 `D:\31days\codexandclaude\worktrees\claude` 下运行，或用完整路径。）三个临时槽，关窗自动清理：

1. 槽1（第1日）：Esc 打开暂停菜单，看左侧选项与右侧时钟、三天进度、距下一日；用方向键、手柄十字键、鼠标各试一次；进入设置与保存并退出，确认二级页盖住时钟、Esc 返回时焦点回到原项。
2. 走到下一个检查点，看“检查点已保存”纸签。
3. 槽2 / 槽3（第3日）：向右进入中心战场后暂停，看“最终战剩余”。
4. 切换 1280×720 与 1920×1080。

## 第1轮审查后修正（Codex R1）

审查 SHA：`7fed5dea15eb367476d6478f3eda59800f70f892`，R1（P2）：正常游戏中直接调用公开方法 `show_settings()` 时，设置页不可见、游戏也未暂停，改变了公开方法行为（任务卡要求6）。确认成立：旧实现经 `_clear_menu` 显示面板并暂停，新实现只建了二级页。

修正实现 SHA：`5e15a82ac1f77677bc9778adfcbb7b44ca8db21d`

- `life_ui.gd` 的 `show_settings()`：暂停菜单未打开时先 `show_pause()`（暂停、显示菜单、关闭灰盒面板），再进入设置页；已在暂停菜单中时行为不变（返回时焦点回到“设置”）。
- `test_pause_menu.gd` 新增 `direct_settings_cases()`：正常游戏中直接调用后已暂停、菜单可见、设置页焦点在“返回”；三个控件都在屏幕上，音量滑块确实改变主音量；Esc 回到时钟、再按 Esc 恢复游戏；从灰盒存档槽面板调用时替换该面板而不叠加。49 项。
- 变异：撤掉修复后 3 项失败，恢复后 49/0。
- 检查：起止 dirty=false 执行 `full --jobs 4`：G2 **83/83**，G3 102/102 + 67/67，**content_stable=True**。摘要 `codexandclaude/runs/20261021T120131.208159Z/`（不入库）。

## G4 用户验收与调整（2026-10-21）

用户要求：“‘检查点已保存’的纸签放到右上角，但别贴到屏幕边缘，调好之后截图给我看一下就行，不用让我跑实机，其他的没问题”。

调整实现 SHA：`47c8490b6035b6d61d79567c50ba89d2a0d75b09`（在复审通过的 `5e15a82` 之后，只改保存提示的位置）

- `save_toast.gd`：从 LifeUI 状态列移到根节点，每帧放在右上角，距顶边与右边各 `MARGIN = 40`（1920×1080 画布单位）；`life_ui.gd` 只改挂载位置。
- 位置在敌人介绍卡（y 100 起）与灰盒说明列（y 340 起）之上，不压最终战倒计时（x 725～1195）。
- `test_pause_menu.gd` 的布局用例：真实敌人介绍卡显示时，两种分辨率下断言纸签在右上角、距两边恰为边距、不与 HUD 各区域、错误提示、介绍卡、灰盒说明文字相交。53 项。
- 截图（第1日、同时有敌人介绍卡、最终战中）已给用户查看，未入库。
- 检查：起止 dirty=false 执行 `full --jobs 4`：G2 **83/83**，G3 102/102 + 67/67，**content_stable=True**。摘要 `codexandclaude/runs/20261021T131035.865297Z/`（不入库）。

用户结论：**UI-003 验收通过，同意合入**（用户原话：“UI-003 验收通过，同意合入”）。

