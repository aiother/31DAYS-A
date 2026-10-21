# UI-003 审查（第1轮）

审查者：Codex｜日期：2026-10-21｜结论：**需修改**。
被审交付 SHA：`9d930fbb707c1e64a2b5c9cd846a1f8be6728b0b`。
实现 SHA：`1710212d13afa90d39d1d37908718ddb6a569a51`；基线：`c6a8f937d504b80783b1d917764c3e5352cde4ca`。

## 范围与已核对内容

- 实现到交付只有 `delivery.md` 新增与任务卡首部状态变化。
- 实现文件符合任务卡及用户批准的 `checkpoint_saved` 接口扩展；T7 核对表只更新暂停菜单行。
- 编辑器导入退出 0，未见 ERROR / WARNING。菜单、保存信号与测试已作初步代码检查；以下阻断项经真实会话复现后按用户停止条件结束本轮。

## R1（P2）：公开 show_settings() 不再自行显示或暂停

位置：`game/ui/menus/life_ui.gd` 的 `show_settings()`（约 224 行）。

旧实现首先 `_clear_menu("设置", "settings")`，该路径显示面板并暂停。现实现只设置 `_mode` 和调用 `_pause.show_settings()`；后者只创建二级页，没有将隐藏的 PauseMenu 显示出来，也没有暂停会话。因此从正常游戏直接调用公开方法时，设置页不可见，游戏继续运行。这违背任务卡要求6“LifeUI 现有公开方法的行为与调用方式不变”。

独立复现（固定交付 SHA，真实 FinalBattleSession，缓存目录中的新槽，不接触正式存档）：`start_slot(1, true)` → `resume_game()` → `show_settings()` → 等待一帧。

```text
BEFORE paused=false visible=false
AFTER paused=false visible=false mode=settings page=settings
```

探针与输出保留在本地 `codexandclaude/runs/ui003-review-public.gd`、`ui003-review-public.txt`（不入库）。引擎退出 0，无 ERROR / WARNING。

建议：公开入口在需要时建立可见、已暂停的暂停菜单上下文，再进入设置页；从已有暂停菜单进入时保持焦点返回行为。补真实会话回归：正常游戏中直接调用 show_settings，断言暂停、菜单可见、三控件可操作，并验证返回/继续；若从灰盒面板调用，也应避免两个面板叠加。

现 `test_pause_menu.gd` 只在先 show_pause 的上下文打开设置，无法拦住这一回归。

## 后续复审

按用户“发现阻断问题时写审查记录并停止”执行：本轮未运行完整 G2+G3、四项变异和剩余功能探针，不能以实现者的通过记录代替独立证据。修正后继续覆盖保存信号各路径（含三个自行处理检查点的子类）、其余公开方法、四项变异，并独立跑 full。未修改实现分支，未合并；G4 仍待用户。


## 第2轮复审：R1 已解决，通过

审查者：Codex｜日期：2026-10-21｜本轮结论：**通过，无阻断项**。
固定交付 SHA：`3c539a556cf20530fae7ccfd9b6cba3e38132072`。
修正实现 SHA：`5e15a82ac1f77677bc9778adfcbb7b44ca8db21d`。

### 修订与功能核对

- 修正实现到交付只追加 delivery.md；代码修正相对上轮交付只在 LifeUI.show_settings 和暂停菜单回归测试。
- show_settings 在 PauseMenu 尚未显示时先 show_pause：暂停、显示菜单并隐藏灰盒面板；已有暂停菜单的二级页与返回焦点规则保留。新增正常游戏/灰盒存档槽两个公开入口回归，以及控件、真实音量、Esc 两级返回检查。独立49/49；撤掉修复3项失败，R1解决。
- 上轮未完成项目已继续核对：LifeUI 其他公开方法仍保留灰盒死亡、存档槽、边界等行为；打开灰盒面板会关闭暂停菜单。保存退出成功后执行退出、失败保留确认与原错误文字；计时暂停、最终战真实余时、布局与字体覆盖由专项和full验证。
- 保存信号在成功写盘且检查点相对上次落盘变化时发出，_restore记住已读入检查点。真实 FinalBattleSession 的营帐、沟壑、堑壕第二间三条子类路径分别独立探测：读档无信号；周期/资源/事件保存同一检查点无信号；检查点写盘失败回滚且无信号；重试成功一次；随后保存和恢复不重复。共21/21，通过，隔离缓存目录且结束清理。
- 两条旧断言修改合理：设置返回焦点回原项后再移回继续；FieldSession 的当前任务读取真实绘制记录，且无时钟时仍画任务纸签。G1/full覆盖相关套件。
- 与SYS-007的合并点仍是PauseMenu.show_settings中的三个控件；本轮没有接入或改变SYS-007。

### 独立证据

环境：Godot `4.7.2.stable.official.ed1daf0bf`，Python `3.12.14`。
被测固定交付SHA如上；命令 `python codexandclaude/tools/run_checks.py full --jobs 4`。

- G2：预期83，实际83/83，完整通过；包含编辑器导入、主场景180帧、全部登记套件。
- G3：预期/实际102/102 + 67/67，完整通过；总命令退出0。
- 起止dirty=false，content_stable=True；未复用实现者证据。
- 自动摘要：`codexandclaude/runs/20261021T123750.109718Z/summary.json`；对应engine.txt及各命令原始输出保留本地，不入库。
- 暂停菜单专项：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_pause_menu.gd`，`PAUSE_MENU_TESTS checks=49 failures=0`。
- 保存信号独立探针：`runs/ui003-r2-signals.gd`，`UI003_REVIEW_SIGNALS checks=21 failures=0`，无ERROR/WARNING。
- 五项临时变异：撤掉R1修复3项失败；二级页仍画时钟3项；暂停仍走时6项；保存失败仍退出2项；保存失败也发保存信号3项。各变异均退出1，未把编译失败作为通过证据；源文件逐字节恢复后49/0。计时和失败信号变异作用于真实会话调用点，失败数与实现者采用的变异范围可能不同。

### 非阻断说明

1. 实现分支未先快进7fed5de，上轮review.md不在当前交付树。本次在审查分支补回上轮原文并追加本节；后续修订请先快进审查SHA，保留审查历史。
2. 任务卡要求4写手柄Back，而T1冻结表、现有InputMap与实现沿用Start暂停。保留冻结映射合理，建议规划维护时统一任务卡表述，不因本任务修改键位。

G4仍待用户通过ui003_pause验收入口检查；本次审查不替代G4，不合并master。
