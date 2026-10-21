# UI-001 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-001`
基线：`e3c6142233d59810f3ab2a04c40031dd6c47b162`（第三批规划合入后的 master；不含 SYS-005，本任务不依赖它）
实现 SHA：`ed02593025142a12adb8445d2fa95e39c19cbc47`

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/style/dusk_style.gd`（`DuskStyle`） | 样张二色板（关键色固定：生命、可能性、成长、透支、警示、墨色）；黄昏程度按第几日与日内进度计算，最终战为满值；纸色、玻璃渐变、光晕、呼吸、边缘晚霞随黄昏变化；最终战光晕为同等黄昏的 70%（用户 G4）；纸签面板。时间输入为与 SYS-005 `ui_time_state()` 同形的字典（`day`、`day_progress`、`final_active`），UI-002 可直接传入 |
| `game/ui/style/ink_draw.gd`（`InkDraw`） | 从 EXP-002 原型整理的确定性手绘线、纸张、纸盘、光晕、渐变 |
| `game/ui/style/ui_theme.gd`（`UiTheme`） | 共享主题：霞鹜文楷、字号层级（标题/小标题/正文/小字）、按钮常态、悬停、按下、悬停按下、焦点（留给墨线下划线）、不可用。**不设为项目默认主题**，由各正式界面自行套用 |
| `game/assets/fonts/LXGWWenKai-Regular.ttf` | 与 `game/prototypes/EXP-002/fonts/` 中同一文件（SHA256 `2D73EEA9…FC8B`），git 中为同一份内容 |
| `game/assets/fonts/OFL.txt` | SIL OFL 1.1 全文与版权声明；用户 2026-10-21 同意下载；来源 `raw.githubusercontent.com/lxgw/LxgwWenKai/v1.530/OFL.txt`，5,171 字节，SHA256 `1A25E35D…BD21A0` |
| `game/assets/fonts/README.md` | 来源、哈希、授权要点，含“保留字体名”条款 |
| `game/tests/test_ui_style.gd` | 19 项，首行按 ENV-004 登记 |
| `codexandclaude/tests/test_collaboration.py` | 新增：字体、授权、说明文件存在且说明含保留字体名；`project.godot` 未设项目主题 |

只采用样张二，不再保留样张切换。原型目录未改动，原型仍可运行。

## 完成标准对照

1. 样式测试：关键色等于 EXP-002 README 色值；黄昏从第1日黎明到最终战严格递增（第1日起点为0，最终战为1）；最终战光晕为同等黄昏的 70%，其他时候不减弱；呼吸只在黄昏出现；输入缺失或越界时被夹住；主题字体为霞鹜文楷、各按钮状态都有样式、主题只构建一次。
2. 字体哈希与已同意下载的文件一致（测试中校验）；OFL.txt 随字体存放且来源与哈希写入说明。
3. 现有界面零变化：`git diff --stat e3c6142 ed02593 -- game/ui/menus game/project.godot game/world game/player` 输出为空；协作测试断言未设项目主题；现有全部测试通过。
4. 变异（逐项临时改源文件，跑 `test_ui_style.gd`，按原字节恢复后复跑 19/19）：

| 变异 | 结果 |
| --- | --- |
| 改动一个关键色（可能性） | 19 项中 1 项失败 |
| 去掉最终战光晕缩减 | 1 项失败 |
| 黄昏不随日期变化 | 6 项失败 |
| 主题不设手写字体 | 1 项失败 |

## 字体授权的一个发现

OFL.txt 中声明“霞鹜”“霞鶩”“落霞孤鹜”“落霞孤鶩”“LXGW”为**保留字体名**：修改版本（包括按用字裁剪）不得继续使用这些名称，例外只有未改源码的重新编译和仅用于网页字体分发的裁剪。因此若以后为缩小体积裁剪字体，裁剪后的字体文件与字体内部名称都必须改名。已写入 `game/assets/fonts/README.md`。按任务卡，本任务不裁剪（环境无 fontTools，安装需另行同意）。

## 检查证据

在实现 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`，ENV-005 自动摘要要点：

- 总结果：**通过**；模式 `full`；被测 SHA `ed02593025142a12adb8445d2fa95e39c19cbc47`；工作区干净。
- G2：实际 77 / 预期 77（导入、主场景180帧、75 个套件含新 `test_ui_style.gd`）；完整、通过。
- G3：`tests` 102、`codexandclaude/tests` 66（新增 1 项协作检查），完整、通过。
- 摘要目录：`codexandclaude/runs/20261021T032000.123378Z/`（不入库）。`content_stable=False`：G2 导入时两个 `game/assets/*.svg.import` 的已知换行改写（BL-113，ENV-006 处理），运行后已 `git restore`；因此本运行不能作复用来源，审查时请独立运行。
- 工具：Godot 4.7.2 stable（控制台版）、Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。
- 单项：`Godot --headless --path game --script res://tests/test_ui_style.gd` → `UI_STYLE_TESTS checks=19 failures=0`。

## 请审查重点关注

- 现有界面确实零变化；主题未设为项目默认。
- 样式规则与 EXP-002 用户选定一致（样张二、随天数变化、最终战光晕 70%）；时间输入形状与 SYS-005 `ui_time_state()` 对得上。
- 字体与授权文件的来源、哈希；保留字体名条款的理解。

## G4

不需要（无可见变化）。样式效果在 UI-002 中由用户实机验收。
