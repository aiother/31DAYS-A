# UI-002 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-002`
基线：`c11d88045b0833d01a80c2d67df0ab5ae476f636`（SYS-005、UI-001 均合入后的 master）
实现 SHA：`3d53bcedc66716665d998550d77bbd1e4c371fa6`（代码与测试）；文档提交见分支历史（规格、说明文档，不改代码）

## 用户在开工时的两项决定（2026-10-21）

| 问题 | 选项 | 用户选择 |
| --- | --- | --- |
| 旧时间文字（`FinalBattleUI.clock_label`）与换日文字（`day_notice`）由会话驱动，相关文件不在允许修改范围 | 小幅扩范围 / 不扩、运行时由 HUD 藏起旧文字 / 新旧并存到第四批 | **小幅扩范围**（Claude 推荐：一处真相，不与会话逻辑抢显示状态） |
| 旧 HUD 的操作提示是否保留 | 小字纸签保留 / 去掉 / 开局显示后淡出 | **小字纸签保留**（Claude 推荐：V0.1 灰盒没有别处教键位） |

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/hud/formal_hud.gd`（新增，`FormalHud`） | 正式 HUD：徽记（生命碎片、可能性环、成长外圈、透支逆时针暗红、恢复进度弧、珍珠、范围与药包纸签）、不足闪烁、获得光点、最后1点生命边缘脉动、地平线与时刻、日期、换日前3分钟提示、换日纸签、最终战倒计时（加速 / 余时不足）。每帧写入 `drawn`（实际绘制记录）供测试读取 |
| `game/ui/hud/overdraft_distortion.gdshader`（新增） | 透支失真滤镜（取自 EXP-001），由 FormalHud 放在第10层 CanvasLayer |
| `game/ui/menus/life_ui.gd` | 删除文字 HUD 行；`_health` 改为操作提示小纸签；创建并挂接 FormalHud，HUD 可见性跟随 `_health`（剧情隐藏的既有路径不变）；错误提示仍排在提示之下 |
| `game/ui/menus/final_battle_ui.gd`（扩范围） | 删除 `clock_label`、`day_notice` 及其计时；超时、结局面板不变 |
| `game/world/final_battle_session.gd`（扩范围） | 不再写旧时间文字；`_announce_day` 只发布 `day_changed` |
| `game/world/start_room_session.tscn`（按要求8） | 灰盒说明文字（房间名、帮助、敌人状态、状态行）原在左上、左下，会被徽记与地平线盖住，移到右上、右对齐、自动换行；文字与节点路径不变 |
| `game/tests/test_formal_hud.gd`（新增） | 49 项，首行登记 |
| `game/tests/test_hud_layout.gd` | 按新布局改写，143 项 |
| `game/tests/test_day_clock_session.gd`、`test_medkit_session.gd`、`test_pearl_growth.gd`、`test_town_rescue.gd` | 只因 HUD 文字被替换而改的旧断言，见下表 |
| `game/docs/formal_hud_implementation.md`（新增）；`ui_data_interface.md`、`day_clock_implementation.md`、`medkit_implementation.md`、`pearl_growth_implementation.md` | 说明文档 |
| `Words/T4_3天倒计时系统.md`、`Words/T3_可能性_基础属性_成长_死亡.md` | 各追加一节 2026-10-21 实施修订：只写用户已选定的方案（A-015 由方案四代替、最终战显示、黄昏随天数、透支失真与不足闪烁），注明来源 |
| `Words/T7核对表.md`、`Words/待决事项总表.md` | A-015 写明最终方案与写入位置（BL-043 要求）；A-018 写入位置 |

## 旧断言改动（只因文字 HUD 被替换）

| 测试 | 原断言 | 现断言 |
| --- | --- | --- |
| `test_day_clock_session.gd` “one readable HUD…” | `clock_label` 可见且含“第 1 日” | 绘制记录的日期纸签为“第1日 · 末日前3天”，旧 DayUI 仍隐藏 |
| 同上 “natural date change…” | `day_notice` 为“第 2 日”且可见 | HUD 换日纸签为第2日且在显示期内 |
| 同上 “main entry uses one date announcement…” | `day_notice` 为“第 2 日”、对白通知不含日期 | HUD 换日纸签为第2日、对白通知不含日期；另在测试把日期手动改回第1日后加一次 `session._process(0)`，让会话按真实存档那样先发布第1日（原测试直接改字段、不经过发布，旧文字是上一次残留才碰巧通过） |
| `test_medkit_session.gd` “HUD exposes actual inventory…” | 文字含“药包 1 / 3” | 药包纸签画出“× 1”，提示纸签含“Q / Back 药包” |
| `test_pearl_growth.gd` “HUD reports combined real reach” | 文字含“珍珠 4 / 4 · 近战范围 140%” | 徽记画出 4 颗珍珠、范围纸签“范围 140%” |
| `test_town_rescue.gd` “HUD and quest reflect grown cap” | 文字含“4 / 12” | 徽记余额 4、成长外圈 2 段；任务文字断言不变 |

`test_field_room.gd`、`test_town_rescue.gd`、`test_final_battle.gd` 中检查 `_health.visible` 的断言未改，仍然成立（剧情隐藏 `_health` 即隐藏整个 HUD）。

## 完成标准对照

1. **自动测试**（`test_formal_hud.gd`，真实主会话与真实输入，断言读取 `FormalHud.drawn`）：
   - 要求1：生命碎片只画现有数量；可能性格数；珍珠与“范围 xx%”按 `range_multiplier()`；药包；成长外圈段数与点亮数；`gain()` 的光点数等于实得点数、起点为来源世界坐标的屏幕位置、落入环后脉动。
   - 要求2：真实“长按恢复”在余额2时环闪红（闪烁强度、外圈描线与填充色都偏向警示红），0.9 秒后回到关键色；真实连续两次闪避透支到 -2 时闪红、两格暗红、失真开启且滤镜层低于对白与 LifeUI、透支越深越强、回正后消退。
   - 要求3：生命为1时边缘朱红脉动，高于1时消失。
   - 要求4：地平线时刻与太阳位置随真实进度（1800 s 剩 900 s → 15:00、x=960）；日期纸签；剩180 s 时右下提示“即将进入第 2 日 · 3:00”；自然换日出现“第 2 日”纸签、提示消失、4 秒后纸签离开；载入存档与换槽到更晚日期都不出纸签（SYS-005 N1）；第三日没有换日提示。最终战：第三日余1500 s 开战，先显示“时间加速……”且显示值约1500 s、真实预算900 s；1 秒后显示值下降超过50 s 且仍高于真实值，真实预算同时减少；结束后墨色显示真实值；读档不重播；余552 s 开战显示“最终战倒计时 · 余时不足”、朱红、“09:12”。
   - 要求5：黄昏第三日明显深于第一日；最终战黄昏为1、光晕为 0.7。
   - 要求6：HUD 与提示纸签使用霞鹜文楷。
   - 关键色：第1日、第2日、第三日末、最终战画出的生命、可能性、调色板完全相同。
2. **防重叠**（`test_hud_layout.gd`）：1920×1080 与 1280×720 下，徽记、提示纸签、地平线、换日前提示、换日纸签、最终战倒计时两两不重叠，也不与短 / 长中文保存错误重叠，全部在窗口内；HUD、滤镜、错误提示不拦截鼠标。
3. **现有测试**：见检查证据；旧断言改动见上表。
4. **变异**（临时改 `formal_hud.gd`，跑 `test_formal_hud.gd`，脚本按原字节恢复后复跑 49/49）：

| 变异 | 结果 |
| --- | --- |
| 去掉不足闪烁（`deny_flash()` 恒为0） | 1 项失败：real heal shortfall flashes the ring red |
| 去掉失真（`distortion_target()` 恒为0） | 2 项失败：distorted under every UI layer / deepens with the overdraft |
| 最终战加速改为停表（显示值固定为开战余额） | 1 项失败：spin-down moves the displayed time |
| 关键色随日期漂移（可能性填充按黄昏混入紫色） | 3 项失败：flash ends… key colour / identical on day two / do not drift on the last day |

## 实现中的取舍（请审查与用户留意）

- **换日纸签的判定**：用 `day_changed`，但只在同一场景内日期变大时出纸签。选槽与死亡重来都会重建场景，所以读档不出；读回更早检查点（日期变小）也不出。
- **读档后的最终战**：SYS-005 把开战余额标为未知，此时不重播加速、也不标朱红（无法区分长短预算）。
- **最后1点生命的边缘脉动**比 EXP-002 样张强（每层 0.45 / 样张 0.16）：灰盒房间很暗，样张强度几乎看不见。强弱请在 G4 判断。
- **灰盒说明文字移到右上**：这是开发说明而非正式 UI，移位只为不被徽记盖住（要求8）。若用户更希望去掉或缩小，第四批处理。
- **旧文字 HUD 中未保留的内容**：复活保护剩余秒数、连续闪避次数（A-018 规定不显示）、恢复中秒数（改为徽记内的进度弧）。
- **渲染截图核对**：用临时脚本在真实会话里截了日常、透支+最后1点生命+换日前提示、最终战加速三张图，确认徽记、提示纸签、地平线、右下提示与灰盒说明文字互不遮挡（截图不入库）。

## 仍需用户决定（G4 时）

- **SYS-005 审查 N2**：闪避因透支下限被拒绝（根本没执行）时，现在没有任何提示。是否也要闪红？两种都不改规则。
  - 选项：不提示（现状） / 也闪红。Claude 推荐**也闪红**：玩家按了键却没反应，闪红能说明原因；需要 SYS-005 增加一个“下限拒绝”信号，属 Codex 职责，可作为小任务另立。

## 检查证据

在实现 SHA、开始时 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`，ENV-005 自动摘要要点：

- 总结果：**通过**；模式 `full`；被测 SHA `3d53bcedc66716665d998550d77bbd1e4c371fa6`。
- G2：实际 79 / 预期 79（含新 `test_formal_hud.gd`）；完整、通过。
- G3：`tests` 102、`codexandclaude/tests` 66，完整、通过。
- 摘要目录：`codexandclaude/runs/20261021T045638.140693Z/`（不入库）。`content_stable=False`：运行期间我在同一工作区写了文档（不影响 G2），另有已知的 `.svg.import` / 字体 `.import` 换行改写（BL-113），运行后已恢复。**本运行不能作复用来源，审查时请独立运行。**
- 文档提交后另跑 G3（`focused --python-all`）：`tests` 102、`codexandclaude/tests` 66 通过。中间一次失败：我起初在待决事项总表为 A-015 另加了一行，`test_pending_decisions` 要求每项一行且日期不变，已改为把最终方案并入原行。
- 单项（`--fixed-fps 60`）：`FORMAL_HUD_TESTS checks=49 failures=0`；`HUD_LAYOUT_TESTS checks=143 failures=0`；`DAY_CLOCK_SESSION_TESTS 43/0`、`MEDKIT_SESSION_TESTS 68/0`、`PEARL_GROWTH_TESTS 212/0`、`TOWN_RESCUE_TESTS 47/0`、`FIELD_ROOM_TESTS 50/0`、`FINAL_BATTLE_TESTS 29/0`、`UI_DATA_TESTS 42/0`、`UI_STYLE_TESTS 19/0`。
- 工具：Godot 4.7.2 stable（控制台版）、Codex 自带 Python、Git。

## G4（用户）

建议在 ENV-006 合入后用通用验收启动器进行；进入第3日与最终战两种预算需要验收入口（ENV-006 提供）。

1. 正常启动游戏，新游戏，从开场玩到第2日：看徽记（生命碎片、可能性环、珍珠、范围、药包）、操作提示纸签、底部地平线与时刻、右下日期；尝试余额不足时长按恢复看环闪红；连续闪避透支看画面失真（HUD 不失真）；剩1点生命看边缘朱红；换日前3分钟右下提示与换日纸签。
2. 用验收入口进入第3日，看黄昏明显加深、关键色不变。
3. 用验收入口进入最终战：第三日余额大于15分钟（如25分钟）看“时间加速”走到15:00；余额不足15分钟（如9:12）看朱红“余时不足”。
4. 切换 1280×720 与 1920×1080，确认没有遮挡。
5. 回答上面的 N2。

## 第1轮审查后修正（Codex R1）

审查 SHA：`4b13df5b306bcf5d2a3e2f21bd859acbf3631674`（`codex/UI-002-review`），结论需修改，R1（P2）：灰盒帮助文字移到右上后被敌人介绍卡（LifeUI 第20层，进入后 `(1460,100,460,220)`）遮挡。确认成立：介绍卡由普通遭遇、天人、Boss、最终战波次共用，原测试只测 FormalHud 自己的区域，漏掉了它。

修正实现 SHA：`be97ad142926905894aacdee2116ffc4c5d89c7e`

| 文件 | 修改 |
| --- | --- |
| `game/world/start_room_session.tscn` | 灰盒说明仍在右侧右对齐、自动换行，但整列下移到介绍卡之下：Title y=340、Help y=400、EnemyStatus y=620、Status y=670（留足帮助文字换行的高度）。没有隐藏任何文字，文字与节点路径不变 |
| `game/tests/test_hud_layout.gd` | `regions()` 增加 Instructions 下全部可见且非空的 Label 与真实介绍卡；新增 `show_intro()`，调用真实 `show_enemy_intro(6.0)` 并等入场结束。新增四个用例：起始区与最终战 × 1920×1080 与 1280×720；所有区域两两不重叠、不与错误提示重叠、都在窗口内；最终战中断言帮助与标题确实被测量。268 项 |

回归能抓住问题（同一测试，只换 `start_room_session.tscn`）：

| 布局 | 结果 |
| --- | --- |
| 本次修正 | 268 / 0 |
| 第1轮交付（右上 y=34 起） | 14 项失败，均为 `instructions Help` 与 `enemy intro` 相交 |
| 基线（左上 x=64） | 17 项失败，均为 `emblem` 与灰盒说明相交 |

另在有渲染的真实会话里截了最终战加速 + 介绍卡同时显示的图，确认互不遮挡（截图不入库）。

检查：在修正 SHA、起止 dirty=false 执行 `full --jobs 4`：G2 **79/79**，G3 `tests` **102/102**、`codexandclaude/tests` **66/66**，passed=true，**content_stable=True**。摘要 `codexandclaude/runs/20261021T053056.533962Z/`（不入库）。单项：`FORMAL_HUD_TESTS 49/0`、`FIELD_ROOM_TESTS 50/0`、`TWO_ROOM_TESTS 38/0`。审查记录中未完成的项目（四项变异复现、其余功能审查）请复审继续覆盖。

## 第2轮审查后修正（Codex R2、N1）

审查 SHA：`3c07dba9f08441859471dae59391a729e3c6536c`（`codex/UI-002-review-r2`），R1 已解决；R2（P2）：成长外圈实际绘制颜色没有被断言——`drawn["palette"]` 写的是常量表，`key_colours()` 只核对了生命与可能性；把成长弧改画成朱红仍 49/49。确认成立。

修正实现 SHA：`7889615ca661eae4a8b216717ab7ef71a8469b20`

| 文件 | 修改 |
| --- | --- |
| `game/ui/hud/formal_hud.gd` | 成长弧在绘制调用处记录实际颜色（点亮 `growth_fill`、未点亮 `growth_dim`）；删除常量表 `drawn["palette"]`，绘制记录只含真实传给绘制调用的颜色。最终战“余时不足”的判定由 `<= 15分钟` 改为 `< 15分钟`（审查 N1，与规格“不足15分钟”一致） |
| `game/tests/test_formal_hud.gd` | `key_colours()` 改为真实绘制两个状态：有成长余量（成长外圈 2 段、1 段点亮）与透支 -3，读取实际画出的生命、可能性、成长点亮/未点亮、透支颜色；第1日、第2日、第三日末、最终战都与用户选定色值 `CHOSEN` 直接比较（不再只比较“与第1日相同”）。新增“恰好15分钟：墨色、不加速、不警示”。52 项 |
| `game/docs/formal_hud_implementation.md` | 最终战一句改为“不足15分钟”，补恰好15分钟的说明 |

变异（临时改 `formal_hud.gd`，跑 `test_formal_hud.gd`，脚本按原字节恢复后复跑 52/52）：

| 变异 | 失败数 |
| --- | --- |
| 去掉不足闪烁 | 1 |
| 去掉失真 | 2 |
| 最终战加速改为停表 | 1 |
| 成长弧改画朱红（R2 原探针） | 4 |
| 透支改画成长金色 | 4 |
| 恰好15分钟按“余时不足” | 1 |
| 可能性填充随黄昏漂移 | 5 |

检查：在修正 SHA、起止 dirty=false 执行 `full --jobs 4`：G2 **79/79**，G3 `tests` **102/102**、`codexandclaude/tests` **66/66**，passed=true，**content_stable=True**。摘要 `codexandclaude/runs/20261021T063704.108148Z/`（不入库）。

## 同步 master 与验收适配（第3轮复审通过后）

Codex 第3轮复审通过（审查 SHA `3009c4b0d8cc09390eb7c57a4e2588d61c050cad`，`codex/UI-002-review-r3`；独立 full G2 79/79、G3 102/102 + 66/66、content_stable=True，七项变异均复现），未合并。ENV-006 已合入 master `3650b726631b299663ddb09183d03bff65b05f32`。

- `c0ea5f3`：把 master `3650b72` 普通合并进 `claude/UI-002`，无冲突（只带入 ENV-006 的文件）。
- 新增 `game/tests/acceptance/ui002_hud.gd`（ENV-006 启动器适配，任务卡与 ENV-006 卡约定由 UI-002 自己写）：三个临时槽——槽1 第1日剩200秒；槽2、槽3 第三日堑壕通道检查点、剩1500 / 552秒。只读面板：选槽界面在左侧显示完整说明（避开徽记与提示纸签），进入游戏后只留一行状态放在右侧（避开地平线、换日前提示、最终战倒计时；ENV-006 审查 N2）。`self_test()` 逐槽载入：第1日无载入纸签、可到换日前提示；槽2 进入中心战场显示“时间加速……”；槽3 显示朱红“余时不足”。
- 新增 `game/tests/test_hud_acceptance.gd`（首行登记）：通过启动器跑上述自测并确认临时目录被清理。
- `game/docs/formal_hud_implementation.md` 增加“G4 验收入口”。
- 有渲染截图自测：`run_acceptance.gd -- --adapter=res://tests/acceptance/ui002_hud.gd --self-test --capture` 27/0；看过选槽、换日前提示、最终战长/短预算四张图，面板与 HUD、房间说明互不遮挡（截图不入库）。
- 实现 SHA：`f502eea034e47f4171786bb452eeb661af65d172`。检查：起止 dirty=false 执行 `full --jobs 4`：G2 **81/81**（含 ENV-006 的启动器套件与新 `test_hud_acceptance.gd`），G3 `tests` **102/102**、`codexandclaude/tests` **67/67**，passed=true，**content_stable=True**。摘要 `codexandclaude/runs/20261021T071831.927514Z/`（不入库）。单项：`HUD_ACCEPTANCE_TESTS 3/0`（内部适配 19/0）。
- 本节只新增验收适配与说明，HUD 代码与已复审的 `7889615` 相同（`git diff 7889615 f502eea -- game/ui game/world` 只有 master 合并带入的内容，为空）。

