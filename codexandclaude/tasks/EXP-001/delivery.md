# EXP-001 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/EXP-001`
开工基线：`e2b69d95cb66917a1dff5b96a76e0eabc629291e`（用户已批准的规划提交；Codex 合入 master 后，本分支合并 master，并在本记录补写合并后的基线）
实现 SHA：`52bb67235d1720d5c4f83819d3f961f4cce67927`

## 产物

全部位于 `game/prototypes/EXP-001/`（28 个文件，含 Godot 生成的 `.uid`），说明见该目录 `README.md`。

| 文件 | 内容 |
| --- | --- |
| `hud_preview.tscn`、`hud_preview.gd` | 预览场景：模拟游戏背景、方案切换、按键驱动全部状态（只读原始键码，不用输入映射） |
| `hud_state.gd` | 模拟状态，数值取自灰盒配置（生命5、可能性0～10可透支到-9、恢复消耗3回复2、珍珠每颗+5%、一天1800秒） |
| `variant_base.gd`、`variant_corner.gd`、`variant_emblem.gd`、`variant_fracture.gd` | 方案一（左上角集中 + 时间常驻右下角，A-015 ①）、方案二（整体徽记 + 简要时间按 Tab 展开，A-015 ③）、方案三（偏离规格的表现力方案） |
| `shared_overlay.gd` | 三个方案共用：最后1点生命红色边缘、换日中上部展示、换日前3分钟右下角提示、最终战倒计时（A-016）、可能性获得光效飞入 |
| `tests/smoke_test.gd`、`tests/capture.gd` | 无头冒烟测试；截图脚本（需要窗口） |
| `screenshots/` | 每个方案一张常态、一张高压状态 |
| `README.md`、`run_preview.cmd` | 说明（按键、方案对比、偏离点、待判断问题）与双击启动 |

另：`codexandclaude/tests/test_collaboration.py` 新增 `test_exp001_prototype_stays_isolated_from_the_formal_game`（必需文件存在；原型脚本不声明全局 `class_name`；`verify_game.py` 与 `project.godot` 不引用原型）。

## 完成标准对照

1. 三个方案，一条命令启动：`--path game res://prototypes/EXP-001/hud_preview.tscn`，按 1/2/3 切换。
2. 任务卡状态 1～6 在每个方案都可演示，冒烟测试逐方案遍历；第 7 项药包数量（G-01）三个方案都可开关。
3. README 列出思路、按键、与 T7 的偏离点及理由、正式版粗估工作量，并提出三个需要用户判断的问题（日内时间的表示方式、A-018 发红是“尝试时闪”还是“持续发红”、方案二新增按键的代价）。
4. 冒烟测试 56 项通过，无脚本错误或警告。
5. 正式游戏零改动：`git diff --stat e2b69d9 52bb672 -- . ':!game/prototypes' ':!codexandclaude/tests'` 输出为空。

## 检查证据

- 工具：Godot 4.7.2 stable（控制台版）、Python 3.12.14（openpyxl 3.1.5）、Git 2.56.0.windows.2。
- 最小测试：`Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd` → `EXP001_SMOKE checks=56 failures=0`，输出无 ERROR、WARNING（在实现 SHA、干净工作区执行）。
- 截图：`Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-001/tests/capture.gd`，6 张截图逐张人工查看。
- G3：提交后在实现 SHA `52bb67235d1720d5c4f83819d3f961f4cce67927`、dirty=false 执行 `python codexandclaude/tools/run_checks.py focused --python-all` → `tests` 92/92、`codexandclaude/tests` 45/45，complete=true、passed=true。协作测试由 44 项增至 45 项，是新增的原型隔离测试。
- 按 §3.3 不跑 G2。运行 Godot 后两个 `.svg.import` 出现只有换行差异的改动（已知现象），已 `git restore`，未提交。

开发中自测发现并修复的问题（均在提交前）：
- 冒烟测试发现“跳到换日前3分钟”落在提示区间外 5 秒、重置未清药包显示开关。
- 截图发现叠加层与方案节点没有铺满屏幕（右下角时间、中上倒计时位置错误），改用 `set_anchors_and_offsets_preset`。
- 现有 `test_game_project` 发现截图脚本中带 `%s` 的 `res://` 路径模板会被当成缺失资源，改为由脚本自身路径推出。

## 请审查重点关注

- 正式游戏确实零改动；原型不会影响 G2（编辑器导入、主场景 180 帧）——原型脚本无全局类名、不被正式场景引用。
- 三个方案对 A-015、A-016、A-018、G-02 的演示是否忠实，偏离点是否都已标出。
- 冒烟测试的断言是否足以证明“可启动、可演示”。

## G4 第1轮：用户挑选结果（2026-10-20）

用户原话：

> 我比较喜欢方案二的思路和方案三的时间显示，关于你的问题：
> 1. 我会更喜欢时刻，但在日常游玩显示时方案三的底部地平线会更加舒适
> 2. 可能性不足时两种显示可以同步存在，当玩家尝试恢复或闪避时可能性容器会闪烁，同时在可能性低于0以下时给画面蒙上一层失真感的滤镜……
> 3. 因为我们现在没有地图操作，所以你可以修改一下暂停界面的菜单布局，把选项放到左侧，右侧默认展示时间、天数的进展，这里的时间就可以用时钟式的设计，在玩家选择有二级界面的选项，比方说设置选项时，将时钟覆盖掉

按 §3.3“用户挑选、组合或要求再探索”，在同一任务内做了第2轮原型“方案四（组合）”，原方案一至三保留以便对照。

**范围说明**：暂停菜单属于 M2-b 的 BL-046，原在本任务“不在范围内”。第3点是用户为替代方案二的 Tab 展开而直接提出的，因此按用户要求在原型中一并演示；仍只在原型目录，不改正式菜单。

## 第2轮修订（方案四）

修订 SHA：`29aa1bffe9115425fbd674d93029a90124e8aa60`。

| 文件 | 内容 |
| --- | --- |
| `variant_combo.gd`（新增） | 继承方案二徽记；时间换成底部地平线并显示时刻；不再有 Tab 展开 |
| `overdraft_distortion.gdshader`（新增）、`hud_preview.gd` | 可能性低于0时，HUD 之下的游戏画面加失真滤镜（波动、色散、去色、暗角），强度随透支加深并平滑过渡；只在方案四开启 |
| `pause_menu.gd`、`pause_clock.gd`（新增）、`hud_preview.gd` | Esc 打开暂停菜单：左侧继续游戏、设置、保存并退出；右侧时钟（表盘、时刻、第N日与末日倒数、三天进度、距下一日，下方一行当前任务）；设置页与确认页盖住时钟，Esc 返回；菜单打开时暂停模拟时间、屏蔽调试键 |
| `tests/smoke_test.gd` | 遍历四个方案；新增方案四检查：不透支无滤镜、透支有滤镜、闪烁与滤镜并存、切回方案一滤镜消失、Esc 打开菜单且时间暂停、调试键被屏蔽、设置页与确认页盖住时钟、Esc 逐级返回并恢复时间 |
| `tests/capture.gd`、`screenshots/` | 新增方案四常态、高压、透支失真，暂停菜单时钟、设置页截图；`screenshots/.gdignore` 让 Godot 不把截图导入为游戏资源 |
| `README.md` | 按键、方案四说明、已回答的问题 |
| `codexandclaude/tests/test_collaboration.py` | 隔离测试增加 `screenshots/.gdignore` |

需要用户再确认（README 已写）：T7 与 BL-046 写的是“暂停菜单右侧显示当前任务”，方案四改为以时钟为主、任务作为时钟下方一行小字；若采纳，正式任务需同步修订 T7。

第2轮证据：
- 冒烟测试：`EXP001_SMOKE checks=85 failures=0`，无 ERROR、WARNING。
- 截图 11 张逐张人工查看；查看中发现并修正暂停页“距下一日”与“当前任务”重叠、背景过亮。
- G3：在修订 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py focused --python-all` → `tests` 92/92、`codexandclaude/tests` 45/45，complete=true、passed=true。
- 正式游戏仍零改动：`git diff --stat e2b69d9 29aa1bf -- . ':!game/prototypes' ':!codexandclaude/tests' ':!codexandclaude/tasks/EXP-001' ':!codexandclaude/BOARD.md'` 输出为空。

## G4 第2轮：用户选定方案四（2026-10-20）

用户原话：“我觉得没问题，你现在的方案4处理比较符合我的意向”。据此：

- 选定方案四作为 HUD 与时间显示的交互方向：徽记 HUD、地平线时刻、可能性不足时闪烁与透支失真滤镜并存、完整时间放在暂停菜单右侧时钟（不新增按键）。
- 暂停菜单采用左侧选项、右侧时钟、二级界面盖住时钟的布局；当前任务作为时钟下方的一行（用户确认“没问题”）。正式任务需同步修订 T7 暂停菜单“右侧显示当前任务”的描述。
- 原型只确定布局与交互，视觉品质（形状、配色、字体、动效、质感）不是定稿，留待 UI 视觉方向探索（M2-b 前）与正式实现任务。
- 后续正式任务：BL-042（HUD）、BL-043（时间显示）、BL-046（暂停菜单），立项时以本节与原型为依据。
