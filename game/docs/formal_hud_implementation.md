# 正式 HUD 与时间显示（UI-002）

用户选定的方案落地：交互布局为 EXP-001 方案四，视觉为 EXP-002 样张二，样式来自 UI-001 的 `game/ui/style/`（DuskStyle、InkDraw、UiTheme）。替换此前的灰盒文字 HUD；暂停、死亡、存档槽等菜单仍是灰盒（第四批处理）。

## 结构

- `game/ui/hud/formal_hud.gd`（`FormalHud`，Control）：由 LifeUI 创建并挂在其根节点下，用 `_draw` 画出全部 HUD；每帧只读取真实玩家与会话，不改任何游戏状态。
- `game/ui/hud/overdraft_distortion.gdshader`：透支失真滤镜。FormalHud 把它放在单独的 CanvasLayer（第10层），低于对白（15）、救场演出（14）、最终战面板（18）和 LifeUI（20），所以只有游戏画面失真。
- `game/ui/menus/life_ui.gd`：`_health` 现在只是徽记下方的操作提示小纸签（“K / B 滑步 · 长按 L / Y 恢复 · Q / Back 药包”，用户2026-10-21决定保留）。剧情隐藏 HUD 的既有代码仍然隐藏 `_health`，FormalHud 跟随它的可见性。
- 保存错误提示仍在 `_health` 之下的同一列，按提示行自然下移。

## 数据来源

| 显示 | 来源 |
| --- | --- |
| 生命碎片（只画现有数量）、最后1点生命的边缘朱红脉动 | `PlayerLife.health` |
| 可能性环、成长外圈、透支逆时针暗红、恢复进度弧 | `PlayerPossibility.balance / maximum / config.maximum / state` |
| 不足闪烁（A-018） | `PlayerPossibility.shortfall` 信号，闪烁 0.9 秒 |
| 获得光点从来源飞入环 | `PlayerPossibility.gained(amount, source_world_position)`，世界坐标经画布变换换算到屏幕 |
| 珍珠与“范围 xx%”（G-02） | `PlayerCombat.pearl_count`、`range_multiplier()` |
| 药包（G-01） | 会话的 `medkit_count()`（没有该方法的场景不画） |
| 地平线、时刻、日期、换日前3分钟提示、黄昏、最终战 | `FinalBattleSession.ui_time_state()` |
| 换日纸签 | `FinalBattleSession.day_changed` |

没有 `ui_time_state()` 的开发场景只画徽记，不画时间。

## 行为要点

- **换日纸签**（SYS-005 审查 N1）：新会话的第一次 `day_changed` 是初始化，不出纸签；每次选槽、死亡重来都会重建场景，所以读档永远不出纸签；日期变小（读回更早的检查点）也不出。只有同一场景内日期变大时才出现，持续 `DayClock.CONFIG.announcement_seconds`。
- **最终战**（A-016）：HUD 看到 `final_active` 由假变真且 `final_acceleration` 为真时，用 2.5 秒把显示从开战时的第三日余额缓动到真实预算；期间真实预算照常减少。开战余额不足15分钟（且已知）时直接显示真实剩余，标题“最终战倒计时 · 余时不足”，朱红色。读档进入已开战的最终战时开战余额未知，不重播加速、按普通墨色显示。恰好15分钟既不加速也不警示，墨色显示真实预算。
- **失真**：余额低于0时目标强度为 `0.35 + 0.65 × 透支 / |透支下限|`，以每秒1.5的速度趋近；余额回到0及以上后消退。暂停时不变化。
- **最后1点生命**：边缘脉动比 EXP-002 样张更强（每层 0.45，样张为 0.16），以便在深色房间里看得见；最终强度留给 G4。
- **关键色**：生命、可能性、透支、成长、不足闪烁的颜色是 DuskStyle 常量，任何日期都不变；只有纸色、玻璃感、光晕、边缘晕染随黄昏变化，最终战光晕减弱约30%。
- **字体**：HUD 文字与操作提示都用 UiTheme 的霞鹜文楷。

## 范围外改动（用户2026-10-21批准的小幅扩范围）

- `game/ui/menus/final_battle_ui.gd`：删除旧时间文字 `clock_label` 与换日文字 `day_notice`；超时、结局面板不变。
- `game/world/final_battle_session.gd`：不再写旧时间文字；`_announce_day` 只发布 `day_changed`。
- `game/world/start_room_session.tscn`：灰盒说明文字（房间名、帮助、敌人状态、状态行）原在左上与左下，会被徽记与地平线盖住，按要求8移到右上、右对齐并自动换行。

## 测试

- `tests/test_formal_hud.gd`：真实主会话与真实输入。恢复不足闪烁、真实连续闪避透支（反向暗红、失真在所有界面层之下、随透支加深、回正后消退）、获得光点的起点与落点、成长外圈、最后1点生命、剧情隐藏；地平线时刻与日期、换日前3分钟、自然换日纸签、读档不出纸签、黄昏随天数加深而关键色不变；最终战长预算加速（显示在动、真实预算在走、结束后显示真实值）、30%光晕、读档不重播、短预算朱红。全部断言读取 `FormalHud.drawn`（实际绘制记录）。
- `tests/test_hud_layout.gd`：按新布局改写。1280×720 与 1920×1080 下，徽记、提示纸签、地平线、换日前提示、换日纸签、最终战倒计时彼此不重叠，也不与长短保存错误重叠，并都在窗口内；HUD、滤镜与错误提示都不拦截鼠标。
- 只因 HUD 文字被替换而改动的旧断言：`test_day_clock_session.gd`（3条）、`test_medkit_session.gd`、`test_pearl_growth.gd`、`test_town_rescue.gd`（各1条），改为读取绘制记录；逐条说明见任务交付记录。

## G4 验收入口

使用 ENV-006 通用启动器的 UI-002 适配 `tests/acceptance/ui002_hud.gd`：

```powershell
Godot --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui002_hud.gd
```

在系统缓存目录准备三个独立临时槽，停在真实选槽界面，关窗自动清理，不碰玩家存档：槽1 第1日剩3:20（约20秒后换日前提示、约3分20秒后换日纸签）；槽2、槽3 第三日在堑壕通道检查点，剩25:00 / 9:12，向右走进中心战场开始最终战（加速 / 余时不足）。选槽界面显示完整说明；进入游戏后面板只留一行只读状态（第几日、日内剩余、最终战、可能性、生命），放在右侧，避开 HUD。`--self-test` 无头逐槽检查，`test_hud_acceptance.gd` 把它登记进 G2。

