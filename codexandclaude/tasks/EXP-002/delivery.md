# EXP-002 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/EXP-002`
开工基线：`43e7dc2a5c8f9376b9b28db9053ebfddd6ed9c46`（用户已批准、交由 Codex 快进合入 master 的规划提交；合入后本分支合并 master 并在此补写基线）
实现 SHA：`bb5be39730faab84e6e61218f5cbbad475bf62f9`

## 方向调整（开工前用户决定）

任务卡初稿列甲、乙、丙三个方向。开工前用户回复：

> 甲和丙我都很喜欢，可以考虑用甲的基底加丙的质感与设计，或者你有更好的建议

Claude 提议在此基础上让“黄昏随末日临近浸入界面”，并把样张改为两种混合比例；用户回复“同意，我已经让codex在合了，后面一起吧”。因此任务卡“样张方向”与完成标准第1、3条随本交付一并修改（不另走规划合入），乙不再制作。

## 产物

全部位于 `game/prototypes/EXP-002/`，说明见该目录 `README.md`。

| 文件 | 内容 |
| --- | --- |
| `preview.tscn`、`preview.gd` | 预览场景与原始键码按键：切样张、跳第1/2/3日与最终战、开关随天数变化、暂停菜单、对话框样式，以及 EXP-001 的全部状态键 |
| `style.gd` | 色板（关键色固定、氛围色随黄昏变化）、黄昏程度计算（按日与日内进度，最终战为满值；样张一上限 55%）、纸签面板 |
| `ink.gd` | 确定性的手绘线、纸张（不规则边与纤维）、纸盘、光晕、渐变 |
| `hud_view.gd` | 徽记、地平线时刻与日期纸签、换日纸签、三分钟提示、最终战倒计时（加速演出与余时不足）、边缘晚霞、最后1点生命、光点飞入 |
| `pause_view.gd`、`ink_button.gd` | 暂停菜单（左侧纸页选项、右侧纸盘时钟与三天墨线进度；设置与确认页盖住时钟）；墨迹按钮的常态、悬停、选中、按下、不可用 |
| `dialog_sample.gd` | 通用对话框与按钮状态参考 |
| `tests/smoke_test.gd`、`tests/capture.gd`、`screenshots/`（含 `.gdignore`） | 冒烟测试、截图脚本、14 张截图 |
| `README.md`、`run_preview.cmd` | 说明（色板与色值、两样张对比、与规格的关系、字体建议、待判断问题）与双击启动 |

只读复用 `game/prototypes/EXP-001/hud_state.gd`（模拟状态与已修正的计时、闪避规则）和 `overdraft_distortion.gdshader`，未改 EXP-001 任何文件。

另：`codexandclaude/tests/test_collaboration.py` 新增 `test_exp002_prototype_stays_isolated_and_reuses_exp001_read_only`（必需文件；无全局 `class_name`；脚本与场景中的 `res://` 只指向 EXP-001/EXP-002 原型目录；验证入口不引用原型）。

## 完成标准对照

1. 两种样张，一条命令启动；场景内可切样张（1/2）、切第1/2/3日与最终战（5～8）、开关随天数变化（0），并可显示 HUD、时间、暂停菜单与设置页、对话框（Esc、K）及全部状态。
2. README 写明每个样张的做法、主色板色值、墨线与质感、动效节奏、与 T0/T7 基调的关系与偏离点。
3. 每个样张 7 张截图：第1日 HUD、第3日 HUD（对比黄昏浸入）、第3日高压（最后1点、透支失真、发红）、最终战倒计时、暂停菜单时钟、设置页、对话框。
4. 冒烟测试 38 项通过。
5. 正式游戏与 EXP-001 零改动（见下方差异检查）。

## 检查证据

- 工具：Godot 4.7.2 stable（控制台版）、Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。
- 冒烟：`Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd` → `EXP002_SMOKE checks=38 failures=0`，无 ERROR、WARNING。断言包括表现数据：两个样张的黄昏程度从第1日到最终战严格递增、样张一最终为 55%、样张二为 100%、关闭随天数变化后各日相同、只有样张二有玻璃渐变、按钮的选中/常态/不可用/按下状态。
- EXP-001 冒烟仍为 `EXP001_SMOKE checks=105 failures=0`（复用其状态后未受影响）。
- 隔离检查：`Godot --headless --path game --editor --import --quit` 与 `--quit-after 180` 均无 ERROR、WARNING；截图目录未被导入（无 `.import` 文件）。两个 SVG.import 的已知纯行尾变化已 `git restore`。
- G3：在实现 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py focused --python-all` → `tests` 102/102、`codexandclaude/tests` 47/47，complete=true、passed=true。协作测试由 46 增至 47，是新增的 EXP-002 隔离测试。
- 零改动：`git diff --stat 43e7dc2 bb5be39 -- . ':!game/prototypes/EXP-002' ':!codexandclaude/tests' ':!codexandclaude/tasks/EXP-002'` 输出为空。
- 截图逐张人工查看；查看中发现并修正：大面积光晕有明显同心色带（改为更多更淡的层）、空珍珠的深色墨线在深色场景上看不见（改为浅色描边）。

## 请审查重点关注

- 正式游戏与 EXP-001 确实零改动；原型不影响 G2 前两步。
- 两个样张都忠实沿用方案四的布局与交互，A-016、A-018、G-02 的表现在新风格下仍可辨认；关键颜色确实不随天数变化。
- 任务卡方向修改与用户原话一致，范围没有超出“视觉基调”。

## G4：等待用户挑选

用户双击 `game/prototypes/EXP-002/run_preview.cmd` 试玩，回答 README 末节三个问题（选哪个样张或比例、是否保留随天数变化及幅度、是否引入手写字体）。选择记入本节，作为 BL-042、BL-043、BL-046 等正式任务的视觉依据。
