# UI-004 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-004`
基线：`07fa7e924d9db048edb079043bbf3cf9646e5948`（SYS-007、SYS-008 合入后的 master，已含 UI-003）
实现 SHA：`8d2d4c96d993801e3f2c6ea6eda8879eaf5d7135`
状态：实现与 G1/G2/G3 完成，待 Codex 审查；G4 待用户验收。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/menus/menu_screen.gd`（新） | `MenuScreen`：确认纸页（默认焦点“返回”、打开时锁住其余焦点）、底部提示条、Esc / Back / Start 返回、浅色墨线按钮、`drawn` 绘制记录 |
| `game/ui/menus/title_screen.gd`（新） | `TitleScreen`：方案 A · 黄昏远景；标题在上方 1/3；新游戏、继续游戏（有存档才有，且默认焦点）、设置、退出游戏（确认） |
| `game/ui/menus/slot_select.gd`（新） | `SlotSelect`：方案 1 · 书签 + 天空条；四种状态样式；左右 / 十字键 / 鼠标；读 `slot_summaries()` |
| `game/ui/menus/sky_strip.gd`（新） | `SkyStrip`：按槽的第几日与当日进度画天空与太阳 |
| `game/ui/menus/life_ui.gd` | `show_title()` 换成正式主界面（有会话时走 `return_to_title()`）；`show_slots(mode = "continue")` 换成正式书签，名称与无参数调用保留；`save_failed()` 在界面打开时把信息画到界面提示条；没有会话时 `resume_game()` 回到主界面；从主界面打开设置后返回主界面 |
| `game/tests/test_title_slots.gd`（新） | 登记套件 `TITLE_SLOTS_TESTS`，77 项 |
| `game/tests/acceptance/ui004_title.gd`（新） | G4 适配 |
| `game/docs/title_slots_ui.md`（新） | 结构、行为表、提示规则、G4 入口 |
| 旧测试 5 处 | 见下节 |

没有改存档格式、输入映射、`CheckpointLab` / SYS-008 接口或共享样式模块。

## 旧断言改动（只因选槽界面表现改变）

| 文件 | 原断言 | 改为 |
| --- | --- | --- |
| `test_title_flow.gd` | 返回标题后 `_mode == "slots"`（SYS-008 回退占位） | `_mode == "title"` 且正式主界面可见 |
| `test_checkpoints.gd` | 灰盒面板第 3 行只有标签和“新游戏”两个子节点 | 正式书签槽三为 empty，绘制“没有存档” |
| `test_completed_slots.gd` | `slot_button` / `menu_button` 在灰盒行里找“继续 / 新游戏 / 确认开始”；已通关时灰盒错误标签可见 | 改为点正式书签（继续 / 新游戏两种模式）与确认纸页；已通关时错误文字仍为“游戏已通关”，且提示条实际绘制同一文字 |
| `test_pause_menu.gd` | “存档槽”打开灰盒 `_panel`；设置替换灰盒面板 | 打开正式书签；设置替换书签 |
| `tests/acceptance/completed_slots.gd`（SYS-004 G4 适配） | 同 `test_completed_slots.gd` 的两个查找函数 | 同上改法；自测 16/0 |

其余断言未改；`test_completed_slots.gd` 的 A-013、字节不变、新游戏覆盖等检查全部原样通过。

## 完成标准对照

1. **自动测试**（真实会话、系统缓存下隔离目录、真实键盘 / 手柄 / 鼠标事件，断言读 `drawn`）：
   - 主界面：标题矩形在上方 1/3 内且居中、菜单在标题带下；无存档时菜单为新游戏 / 设置 / 退出游戏、焦点新游戏；有存档时四项、焦点继续游戏；退出确认默认“返回”，Enter 不退出、Esc 关闭、确认才退出；设置打开现有设置页，Esc 与暂停纸页“继续游戏”都回到主界面；字体为霞鹜文楷。
   - 存档选择：进行中 / 已通关 / 无法读取 / 空四种书签的状态、文字（第2日 · 末日前2天、1:23:45、可能性6/10、珍珠、检查点名）、生命碎片 4/上限、只有已通关有印、太阳位置 = 当日进度 0.4、选中升起；右键 / 十字键 / 鼠标选择；已通关 Enter 提示“游戏已通关”并停留；空、无法读取说明原因；Esc、Back、鼠标“返回主界面”回到主界面。
   - 关键色：第2日槽与已通关槽的天空、纸色不同，日期、生命碎片、可能性颜色相同且等于 `DuskStyle` 常量。
   - 新游戏：有进度、无法读取的槽提示“将覆盖此槽现有进度”，默认焦点“返回”，Enter 返回不改；空槽无覆盖提示；左移到“开始”后确认进入该槽游戏，其他槽不变；重开后继续进行中的槽进入游戏。
   - 保存错误：写盘失败时错误画在提示条上，灰盒错误标签不在书签后露出。
2. **防重叠**：1280×720 与 1920×1080、三个焦点位置各一次：三张书签（含升起）、标题区、提示条、返回按钮两两不相交且都在窗口内（6 项检查）。
3. **现有全部测试**：见 G2 + G3。
4. **变异**（临时改源文件跑 `test_title_slots.gd`，按原字节恢复）：

| 变异 | 结果 |
| --- | --- |
| 去掉已通关印的绘制 | 77 项中 1 项失败，退出 1 |
| 无存档时仍显示继续游戏 | 77 项中 1 项失败，退出 1 |
| 确认纸页默认焦点改为确认 | 71 项中 17 项失败，退出 1 |
| 日期关键色随槽的纸色漂移 | 77 项中 1 项失败，退出 1 |

5. **G4**：待用户（见下）。

## G1

Godot 4.7.2 stable（控制台版）：

- `TITLE_SLOTS_TESTS` 77/0（`--fixed-fps 60`）
- `TITLE_FLOW_TESTS` 106/0、`CHECKPOINT_TESTS` 39/0、`COMPLETED_SLOTS_TESTS` 73/0、`PAUSE_MENU_TESTS` 53/0、`MENU_CONTROLLER_TESTS` 33/0、`ACCEPTANCE_LAUNCHER_TESTS` 11/0
- 验收自测（无头）：UI-004 22/0、SYS-004 16/0、UI-003 16/0；UI-004 有渲染截图自测 30/0，截图人工看过（主界面、三种书签、已通关提示、覆盖确认）。

## G2 + G3

在实现 SHA、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **86/86**（新增套件 +1），G3 **102/102 + 67/67**。content_stable=False，原因与 SYS-007/008 相同：导入生成 EXP-003 两个未跟踪 `.gd.uid`，已跟踪 diff 为空，结束后已删除；本轮不作为复用来源。摘要 `codexandclaude/runs/20261021T154141.986121Z/`（不入库）。

## G4（用户）

```
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui004_title.gd
```

独立临时存档，关闭窗口自动清理。开在主界面：槽1第2日进行中、槽2已通关、槽3无法读取。F2 切换槽3为空 / 无法读取，F3 清空全部临时存档（看没有“继续游戏”的主界面）。请看：主界面方案 A 的样子；书签与天空条；已通关印与提示；覆盖确认默认在“返回”；键盘、手柄、鼠标都试一下。

## 说明与未决

- “设置”在 UI-006 之前打开 UI-003 暂停菜单的设置页，左侧仍是暂停纸页（继续游戏、存档槽等）。卡上允许的过渡做法；UI-006 换成正式设置界面时一并处理。
- 共享验收框架在写完存档后打开选槽界面；UI-004 适配在第一次截图时改开主界面（覆盖 `capture()`），没有改框架。
- SYS-008 审查建议2（只有损坏槽时 `has_any_save()` 为真）：主界面照常显示“继续游戏”，书签把损坏槽画成“无法读取”并说明原因，可在新游戏中覆盖。
- 与 UI-005 的关系：暂停菜单“存档槽”和结束面板仍调用 `show_slots()`，现在打开正式书签；UI-005 换成“返回标题”。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`8d2d4c96d993801e3f2c6ea6eda8879eaf5d7135`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-21T15:41:41.987121+00:00；结束：2026-10-21T15:54:57.362222+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际86 / 预期86；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`6f66a81cea7653c1c6f19e2cd598e7379f60474f`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`2468c0b0fa4999b933167d4ced63e4cc5f6dfc248ce3927c4bda17149b725d56`；工作区范围指纹（原始字节）：`c4c9ac2b406a1c015fd56c6b98967c706c252095dda83f2a32d8d4b7ad66a950`。
全工作区指纹：`bc1f33998b242c4b71445bc2f9938a15025f5730eb16601a0a37c4ec7cd1874a`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\001.txt`；SHA256=`0ca558e049ce72c04bc8d4ce618f19fdcc33244528a895d9334b9504ba607c10`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261021T154141.986121Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=769.593秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\007.txt`；SHA256=`c0c8894fac2e33e0e11769b47ac151f1a67c77792f854408e94fa973a2b41844`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.532秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\008.txt`；SHA256=`024430380957be0aa1c83be860663c98d37a9495104ad557215b415d3e8c1255`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=20.296秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\009.txt`；SHA256=`5097548d9c256223ca100252d8ca64038c795549e55e0029887f736438688f9c`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261021T154141.986121Z\engine.txt` SHA256=`661f3263d18d60fcd4f0bd2873cb3842c3ff6678086f9b3dbf0f4babd0fe45c1`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
