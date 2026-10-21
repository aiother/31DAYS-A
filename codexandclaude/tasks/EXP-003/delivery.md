# EXP-003 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/EXP-003`
基线：`c6a8f937d504b80783b1d917764c3e5352cde4ca`（第四批任务卡合入后的 master）
实现 SHA：`d83bee80f996ff75c73a87ef08b8627503083324`（含原型 `360fcc1` 与截图脚本路径修正）

## 改动

只新增 `game/prototypes/EXP-003/`：

| 文件 | 内容 |
| --- | --- |
| `preview.tscn`、`preview.gd` | 原型入口：主界面方案 A/B/C 与存档选择方案 1/2 切换，串起完整流程，右上按键说明 |
| `mock_slots.gd` | 模拟存档：进行中、已通关、空、无法读取 |
| `screen_base.gd`、`ink_button.gd` | 共用：墨线按钮、确认框（默认焦点“返回”、打开时焦点不外溢）、绘制记录 |
| `title_base.gd`、`title_dusk.gd`、`title_page.gd`、`title_blur.gd`、`haze_blur.gdshader` | 主界面三个方案 |
| `slots_base.gd`、`slots_bookmark.gd`、`slots_cards.gd` | 存档选择两个方案（共用选择逻辑与 A-013 提示） |
| `game_stub.gd` | “游戏中”占位画面，演示暂停、死亡、结束、超时各自返回标题 |
| `README.md`、`run_preview.cmd`、`screenshots/`（12 张，含 `.gdignore`）、`tests/smoke_test.gd`、`tests/capture.gd` | 说明、启动、截图、冒烟测试 |

没有改正式场景、共享脚本、`project.godot`、输入映射或存档；冒烟测试不登记进验证流水线（与 EXP-001、EXP-002 一致）。只读引用 UI-001 的 `DuskStyle`、`InkDraw`、`UiTheme`。

## 方案对比

### 主界面

| | A · 黄昏远景 | B · 纸页水墨 | C · 朦胧战场 |
| --- | --- | --- | --- |
| 截图 | `title_a_dusk.png`、`title_a_no_saves.png` | `title_b_page.png` | `title_c_haze.png` |
| 看点 | 黄昏、太阳、残破城市剪影，与 HUD 的黄昏氛围最连贯 | 纸张与水墨，和暂停菜单、HUD 纸签的材质最统一 | 最贴近 T7“朦胧滤镜与打光”；以后可换成真实游戏画面 |
| 顾虑 | 剪影是程序画的，正式美术前略显简单 | 太亮太“书卷”，颓废感最弱 | 现在背景是灰盒替身；正式版要渲染真实场景（子视口或截图），工作量最大 |
| 正式版工作量 | 小 | 小 | 中 |

### 存档选择

| | 1 · 书签 | 2 · 黄昏卡片 |
| --- | --- | --- |
| 截图 | `slots_1_continue.png`、`slots_1_completed_prompt.png`、`slots_1_new_overwrite.png` | `slots_2_continue.png`、`slots_2_completed_prompt.png`、`slots_2_new_overwrite.png` |
| 看点 | 最贴合 T7“横向书签式”的字面；朱红“已通关”圆印醒目 | 天空条一眼看出该槽到了第几日的黄昏；信息紧凑 |
| 顾虑 | 竖排较疏，信息多时会挤 | 不像“书签” |

流程截图：`flow_death.png`（A-014 四个选项）、`flow_end.png`（夕阳将至）。

## Claude 的推荐（供参考，用户决定）

- **主界面：A · 黄昏远景**。理由：与已选的黄昏 HUD 一脉相承，正式化成本最低；C 的“模糊真实画面”可以作为以后有正式美术时的升级方向。
- **存档选择：1 · 书签，借用 2 的天空条**。理由：书签最符合 T7 的“横向书签式”，在书签上部加一条该槽当日的天空与太阳位置，就补上了“一眼看出进度”的优点。
- **流程**：有存档时主界面默认焦点放在“继续游戏”；新游戏的确认放在选槽之后（知道覆盖哪一槽时再确认，T7“新游戏需确认”）；暂停菜单在主界面完成后把“存档槽”换成“返回标题”。

## 检查

- 冒烟测试（无头）：`EXP003_SMOKE checks=43 failures=0`。覆盖：三个主界面方案的标题都在上方 1/3、菜单顺序与默认焦点、无存档时隐藏“继续游戏”、方向键与左右键导航（C 方案横排）；两个存档选择方案的三种状态、检查点与时长、默认焦点、左右键、已通关提示“游戏已通关”且停留（A-013）、覆盖确认默认“返回”、Esc 取消；空槽确认开始新游戏；死亡、结束、超时三页都能返回标题；游戏中 Esc 打开暂停；退出先确认。
- 有渲染截图 12 张，已逐张查看；查看时修正了三处：A 菜单压在剪影上（上移）、B 印章贴字（右移）、C 暗角条纹（改为渐变）。
- 第一次 G3 失败 1 项：截图脚本里写了目录路径 `res://prototypes/EXP-003/screenshots/`，资源引用检查要求每个 `res://` 都是文件；已改为从脚本自身路径推出目录（EXP-002 同样做法）。
- 独立启动：`--headless --quit-after 30 res://prototypes/EXP-003/preview.tscn` 无错误。
- G3：本记录写入后执行 `python codexandclaude/tools/run_checks.py focused --python-all`，`tests` 102/102、`codexandclaude/tests` 67/67 通过（摘要见提交说明）。按检查矩阵，探索型原型不跑 G2；原型脚本在编辑器导入时编译无错误。

## G4（用户）

双击 `game/prototypes/EXP-003/run_preview.cmd`（在 `codexandclaude/worktrees/claude` 分支目录下），按 1/2/3 比较主界面、4/5 比较存档选择，按 N、B 看无存档与损坏槽；从继续游戏 / 新游戏进入“游戏中”，用 K、F、T 与 Esc 试各条返回标题的路径。请选定主界面与存档选择方案（可组合、可提修改），结论写入本记录，作为第五批任务卡的依据。
