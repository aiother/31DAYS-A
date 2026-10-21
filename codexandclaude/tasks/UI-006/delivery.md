# UI-006 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-006`
基线：`201244e345ae213d23955a0eef326622f6c06e04`（`claude/UI-004` 交付 + G4 记录，其下为 master `07fa7e924d9db048edb079043bbf3cf9646e5948`，已含 SYS-007、UI-003）
实现 SHA：`ea974a389956eb0636c3f58d17fdbb0b353a5e7a`
状态：实现与 G1/G2/G3 完成，待 Codex 审查；G4 待用户验收。

## 基线说明（偏离任务卡）

任务卡基线写的是“SYS-007 与 UI-003 合入后的 master”，与 UI-004 并行。本任务改为叠在 UI-004 之上：要求3“暂停菜单与主界面打开同一个设置页、从哪里打开就返回哪里”只有在主界面存在时才能实现和测试，且两者都改 `life_ui.gd` 的同一段（主界面“设置”入口），叠放可避免合并冲突。代价：**UI-006 须在 UI-004 合入之后合入**（UI-004 正在审查，用户 G4 已通过）。本分支相对 UI-004 的差异只有本任务改动（`git diff 201244e..` 可见）。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/menus/settings_page.gd`（新） | `SettingsPage`：六项设置、按键列表 `KeyList`（可滚动）、恢复默认（确认，默认焦点“返回”）、返回；全部经 `GameSettings` 接口 |
| `game/ui/menus/setting_row.gd`（新） | `SettingRow`：滑条 / 选项 / 开关 / 动作四种墨线设置行，键盘、手柄、鼠标 |
| `game/ui/menus/pause_menu.gd` | 设置页换成 `SettingsPage`（删去灰盒滑条、下拉框、复选框与“后续版本加入”说明）；`show_settings(from_title)`：主界面打开时隐藏暂停选项与时钟、设置页居中；`page_rect()` |
| `game/ui/menus/life_ui.gd` | 主界面“设置”把暂停菜单临时移到主界面之上、以 `from_title` 打开；返回时移回、焦点回主界面“设置”；`show_pause` / `show_title` 也确保层级复原 |
| `game/tests/test_settings_page.gd`（新） | 登记套件 `SETTINGS_PAGE_TESTS`，52 项 |
| `game/tests/acceptance/ui006_settings.gd`（新） | G4 适配，可透传 `--settings-file=` |
| `game/docs/settings_page_ui.md`（新）、`title_slots_ui.md`（一行） | 结构、操作、G4 入口；主界面“设置”一行改为正式设置页 |
| 旧测试 3 处 | 见下节 |

未改 `SettingsService`、设置文件格式、输入映射、存档。

## 旧断言改动（只因设置页改变）

| 文件 | 原断言 | 改为 |
| --- | --- | --- |
| `test_pause_menu.gd` | 在暂停菜单子节点里找 HSlider / OptionButton / CheckButton；拖 HSlider 改总线 | 找 `settings_page` 的六行；用总音量行 `commit(40)` 改总线（同样断言 Master 总线 0.4） |
| `test_settings.gd`（SYS-007 套件 `gray_settings`） | 同上三种灰盒控件及其 `value` / `item_selected` / `button_pressed` | 用设置页对应三行的 `commit()`；接口值、设置文件、窗口尺寸与暂停行为的断言原样保留 |
| `test_title_slots.gd`（UI-004 套件） | 主界面“设置”打开时主界面隐藏；暂停纸页“继续游戏”在无会话时回主界面 | 设置页盖在主界面之上（主界面仍可见）、不显示暂停选项；Esc 返回主界面且焦点在“设置”。原“继续游戏回主界面”路径已不存在（选项不显示），删去该条 |

`test_settings.gd` 不在任务卡允许修改的测试清单里，但完成标准要求现有测试全部通过，而该套件直接查找被替换的灰盒控件，只能随之修改；改法与 `test_pause_menu.gd` 相同，不削弱接口与持久化断言。

## 完成标准对照

1. **自动测试**（真实会话；测试进程的设置文件由 SYS-007 自动隔离到系统缓存；真实键盘 / 手柄 / 鼠标；断言读 `drawn`）：
   - 暂停 → 设置：六行与“恢复默认”的文字和当前值；焦点在“返回”，上键走到“总音量”。
   - 每一项：左键总音量 90、十字键效果音 95、鼠标点背景音条中点 50（各核对接口值、设置文件、对应总线音量）；窗口尺寸左右切换并保存；Enter / A 切换全屏并保存；帧率 120 → 不限制，`Engine.max_fps` 跟随而物理帧率仍 60；鼠标点左箭头退一档。
   - 按键列表：下键进入后逐行滚动，见到的动作与 `bindings()` 15 项同序一致，每行名称 / 键盘 / 手柄文字与接口一致，行始终在列表内；到底后下键移到“恢复默认”；滚轮可滚动；注明“自定义按键将在后续版本提供”。
   - 恢复默认：先问（焦点“返回”），问的时候不改值；“返回”与 Esc 都不改；确认后所有值与设置文件回到默认、各行显示刷新。
   - 返回原处：暂停中打开，Esc / Back / 鼠标“返回”都回暂停菜单“设置”，再 Esc 继续游戏；主界面打开，设置页居中、不显示暂停选项与时钟，是同一个设置页，改动同样经接口保存，Esc / Back / “返回”都回主界面“设置”，暂停菜单回到主界面之下。
2. **防重叠**：1920×1080 与 1280×720（经设置页本身切换）下，六行、恢复默认、按键列表、返回都在纸面内且两两不相交，纸面在窗口内；按键列表滚动全程行不出列表。
3. **现有全部测试**：见 G2 + G3。
4. **变异**（临时改 `settings_page.gd` 跑 `test_settings_page.gd`，按原字节恢复）：

| 变异 | 结果 |
| --- | --- |
| 界面绕过接口直接改 Master 总线 | 52 项中 9 项失败，退出 1 |
| 恢复默认不确认直接执行 | 52 项中 11 项失败，退出 1 |
| 按键列表漏最后一项 | 52 项中 2 项失败，退出 1 |

5. **G4**：待用户（见下）。

## G1

Godot 4.7.2 stable（控制台版）：

- `SETTINGS_PAGE_TESTS` 52/0（`--fixed-fps 60`）
- `SETTINGS_TESTS` 112/0、`PAUSE_MENU_TESTS` 53/0、`TITLE_SLOTS_TESTS` 75/0、`MENU_CONTROLLER_TESTS` 33/0
- 验收自测（无头）：UI-006 20/0、UI-004 22/0、UI-003 16/0、SYS-004 16/0；UI-006 有渲染截图自测 26/0，截图人工看过（主界面上的设置页、暂停中的设置页）。

## G2 + G3

在实现 SHA、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **87/87**（新增套件 +1），G3 **102/102 + 67/67**。content_stable=False，原因同前：导入生成 EXP-003 两个未跟踪 `.gd.uid`，已跟踪 diff 为空，结束后已删除；本轮不作为复用来源。摘要 `codexandclaude/runs/20261021T161535.163065Z/`（不入库）。

## G4（用户）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui006_settings.gd --settings-file=$env:TEMP\31days_ui006_settings.cfg
```

开在主界面（UI-004 的临时存档）。主界面 → 设置逐项调整，返回；继续游戏 → 槽1 → Esc → 设置，确认是同一个页面、值已保留。关闭后用同一命令再开，确认设置被保存。验收后可删除 `%TEMP%\31days_ui006_settings.cfg`。

## 说明与未决

- 打开设置时焦点在“返回”，沿用 UI-003 二级页的约定（用户 G4 时接受过）；如果更希望落在“总音量”，改一行即可。
- SYS-007 审查的非阻断建议：（1）`set_value()` 每次都重设窗口——改音量时窗口会回到所选尺寸，属 SYS-007 代码，本任务未改；（2）滑条每一步写一次文件——本页步长 5，拖动最多约 20 次写入，可接受；（3）按键列表包含“调试重置”——按冻结键位表原样显示，未隐藏。
- 设置页文字在 1280×720 下按键列表两行字号偏小（16px 按 1080p 设计），G4 可留意。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`ea974a389956eb0636c3f58d17fdbb0b353a5e7a`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-21T16:15:35.163065+00:00；结束：2026-10-21T16:28:54.149268+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际87 / 预期87；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`4d920ac1583e75be7b752e631332ebe9b66d156c`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`aa88a0a81d44d75fbd1ecafff3514ca089924c4b0825107d732e613222f44fb9`；工作区范围指纹（原始字节）：`b7d6c5b333efdd99cf2be918632068d418b3a0a109919df7abdee07d219f3c91`。
全工作区指纹：`97dac0ea610debe6f96379b59ae3a587e43e343f8f7bc77fbc9cceab0aaa40be`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\001.txt`；SHA256=`67c8be143611376895051186a8ba7206f1871995a8e1512ff600ee1ddfe4da0b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261021T161535.163065Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=773.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\007.txt`；SHA256=`25eb8063b4e1011228b5d17544903cd6af36820d43961634a1bbd3f613863192`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.407秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\008.txt`；SHA256=`b4e591a87d155ba4ad9a284c684614825533e8578024f69f58242e6e99f0c0bd`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=20.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\009.txt`；SHA256=`5667f699f6e181e1e3207251f08f44cbc74d7f613b05b25b70096443ce9e9446`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T161535.163065Z\engine.txt` SHA256=`56ca3fd680b457a2609ec6dd9a847955ddfe736b94abec202d3b5c36a7761ceb`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
