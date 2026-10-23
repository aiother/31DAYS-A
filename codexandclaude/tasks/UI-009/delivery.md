# UI-009 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-009`
基线：`412933f65295142f53945e59d1964258e47f1211`（UI-008 合入后的 master）
实现 SHA：`42a40876ffbe069d8b1785d0456a27a75bd5db3b`（`c7bc10c` 实现与测试 + `42a4087` 验收适配与文档）
状态：实现与 G1/G2/G3 完成，待 Codex 审查；G4 待用户验收。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/hud/enemy_card.gd`（新） | `EnemyCard`（继承 `PanelContainer`）：方案 2 墨条横幅；普通 440 宽、首领 480 宽加朱红竖印“首领”；高度随要点行数；隐藏子 Label 保存“名字\n\n要点”；`drawn` 各部分由绘制调用返回，隐藏时清空 |
| `game/ui/hud/battle_banner.gd`（新） | `BattleBanner`：画面中上墨色横带，标题 + 小字；淡入淡出、暂停停住；三档高度依次避让，均不可用时让位 |
| `game/ui/menus/life_ui.gd` | `_enemy_intro` 改为 `EnemyCard`，滑入目标改为 `settled_x()`；新增 `show_enemy_card()`、`show_battle_banner()`、`_banner_avoided()`；`show_enemy_intro()` 解析为普通卡；`hide_enemy_intro()` 同时清横幅；`_protected_rects()` 加入卡片与横幅 |
| 6 个会话脚本 | **只改调用行**：`tian_session` → 精英卡；`boss_session`、`parasite_session` → 首领卡；`battlefield_session`（1 处）、`rescue_battlefield_session`（2 处）、`final_battle_session`（1 处）→ 横幅。触发条件、时长、文字（名字 + 要点）逐字不变。`two_room_session` 首次遭遇未改（`show_enemy_intro` 即普通卡）；`hide_enemy_intro` 调用未改 |
| `game/tests/test_enemy_cards.gd`（新） | 登记套件 `ENEMY_CARDS_TESTS`，32 项 |
| `game/tests/acceptance/ui009_enemy_cards.gd`、`ui009_battle.gd`（新） | G4 两个入口（各自检 12/0） |
| `game/docs/enemy_cards_ui.md`（新） | 外观、类别、进出、横幅避让、接口、测试 |
| 3 个旧测试 | 见“旧断言改动” |
| `game/tests/test_dialogue_ui.gd` | 补 UI-008 复审的非阻断建议（见下） |

新脚本 `.uid` 一并入库。未改敌人数据、遭遇触发与时长、存档、输入映射。

## 要求对照

| 要求 | 结果 |
| --- | --- |
| 1 介绍卡（方案 2） | 右上角干墨横条 + 纸色名字 + 半透明说明块（类别一行、要点）；首领加朱红竖印；右侧滑入 0.2 秒、停留调用方时长、滑出；暂停时 Tween（`TWEEN_PAUSE_STOP`）与剩余时间都停住；`hide_enemy_intro()` 立即收起 |
| 2 类别 | 无色实体“普通敌人”、天人战士“精英”、渴望俯视 / 寄生同伴者“首领”，由调用行传入，不改敌人数据 |
| 3 战场横幅 | 四处阶段 / 波次提示改走中上横幅，不占右上卡位；淡入淡出；避让 HUD（含最终倒计时、换日纸签、地平线）、对话纸笺、区域名称、交互提示、介绍卡、保存失败提示 |
| 4 接口 | `show_enemy_intro` 保留；新增 `show_enemy_card`、`show_battle_banner`；会话只改调用行 |
| 5 字体与关键色 | UI-001 主题字体；纸色、朱红均为 `DuskStyle` 常量 |

**两处补充判断**：①停靠位置按原型取距右边 40（`RIGHT = 1880`），不再贴边，`test_overlook_boss` 一处断言随之改（见下）；②`hide_enemy_intro()` 同时清横幅——阶段提示原来与卡片共用一个节点，会话在剧情 / 结局时调用它清掉当前提示（如 `rescue_battlefield_session` 进入剧情前、`final_battle_session` 结局时），保留这个效果。

## 旧断言改动（3 处）

| 套件 | 原断言 → 新断言 |
| --- | --- |
| `test_overlook_boss.gd` | 卡片右边缘贴 1920 → 右边缘停在 `EnemyCard.RIGHT`（方案 2 距右 40） |
| `test_battlefield.gd` | 阶段提示时 `_enemy_intro` 可见 → `_battle_banner` 显示中且标题含“首段完成”、介绍卡不可见，玩家仍可操作 |
| `test_ten_clear_presentation.gd` | 新一波时 `_enemy_intro` 文字含“新一波” → 横幅标题含“新一波”、介绍卡不可见 |

其余读 `_enemy_intro` 的旧测试（`test_two_rooms`、`test_tower_room`、`test_tian_room`、`test_hud_layout`、`test_pause_menu`）因保留 PanelContainer、位置滑动与隐藏 Label，未改即通过。

## UI-008 遗留建议（复审非阻断）

`test_dialogue_ui.gd` 补：纸面下沿 41 点贴纸笺底边 ±4、有起伏、横跨纸笺；继续三角三个顶点都在纸笺内、第二点在第一点右 16、第三点在下方（朝下）。变异：下沿下移 30 像素、第三顶点移出纸笺，各 1 项失败。

## 完成标准

1. **自动测试** `ENEMY_CARDS_TESTS` 32/0（`--fixed-fps 60`，每种情况各自读档一个真实 FinalBattleSession，真实遭遇触发，断言读 `drawn`）：
   - 首次遭遇无色实体：普通卡名字 / 类别 / 要点、纸色名字、墨色横条、说明块、无竖印；从右侧进入、停在右上角；暂停 30 帧位置与剩余时间不变；到时滑出并消失；`hide_enemy_intro()` 立即收起。
   - 堑壕天人战士：精英卡、无竖印。
   - 渴望俯视（经连接机关真实进入）与寄生同伴者（清完营地波次后真实进入）：首领卡，竖印文字“首\n领”、朱红、在横条内，卡更宽且停在同一角。
   - 最终战清掉第一波：真实“敌方第2波即将进入”走横幅，在中上、不与介绍卡角位相交，介绍卡不出现；横幅暂停停住、到时淡出、被 `hide_enemy_intro()` 清掉。
2. **防重叠**（同套件）：1920×1080 与 1280×720 下，同时打开对话纸笺、保存失败提示、首领卡、三行的阶段横幅与区域名称，卡片与横幅都在窗口内，与 HUD 各绘制矩形、对话纸笺（含按键行）、区域名称、交互提示、保存失败提示以及彼此都不相交（此时横幅自动落到第三档高度）。
3. **现有测试**：3 处旧断言改动见上；单跑 two_rooms 38/0、tower_room 29/0、tian_room 24/0、tian 43/0、overlook_boss 48/0、parasite_boss 47/0、parasite_support 22/0、battlefield 36/0、ten_clear_presentation 17/0、ten_rescue 58/0、final_battle 29/0、hud_layout 268/0、pause_menu 53/0、area_prompts 60/0、dialogue_ui 52/0、ui_data 54/0；其余见 G2。
4. **变异**（临时改源文件跑 `test_enemy_cards.gd`，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| Boss 不画竖印 | 2 项失败 |
| 波次提示仍走右上卡 | 3 项失败 |
| 暂停时卡片仍移动（Tween 不停） | 6 项失败 |
| 暂停时卡片计时仍走 | 1 项失败 |
| `hide_enemy_intro()` 不收起 | 1 项失败 |
| 横幅不避让 | 2 项失败 |
| 暂停时横幅计时仍走 | 1 项失败 |
| 天人战士按普通敌人显示 | 1 项失败 |

5. **G4**：待用户（见下）。

开发中按渲染截图核对了首领卡、精英卡与横幅的样子（与 EXP-004 方案 2 一致）；验收夹具另用临时脚本确认槽 1 / 槽 2 能真实触发普通卡与精英卡。

## G2 + G3

在实现 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **92/92**（新增套件 +1），G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T035623.201741Z/`（不入库）。交付记录草稿在临时目录，运行中未改工作区。

## G4（用户）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui009_enemy_cards.gd
```

- 槽1 第二个房间：向右几步遇到无色实体 → 普通敌人卡。
- 槽2 堑壕：向前遇到两名天人战士 → 精英卡。
- 槽3 渴望俯视检查点：读档即播放首领介绍 → 首领卡（朱红竖印）。

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui009_battle.gd
```

- 槽1 寄生同伴者检查点：读档即播放首领介绍 → 首领卡。
- 槽2 中心战场前（未救 10）：进入战场救下 10 后 → 中上“新一波敌人进入战场”横幅。
- 槽3 中心战场前（已救 10）：进入战场清掉一波 → “敌方第 2 波即将进入”横幅。

## 说明与未决

- 只有三个存档槽，五种情况分在两个验收入口。
- 战场横幅三档高度都被占时让位不画（计时照走），与 UI-007 交互提示的做法一致；最终战“敌方第 N 波即将进入”只有 1 秒，若恰逢对话打开会被让掉——目前战场中没有会同时打开的对话。
- 敌人立绘、正式文本属 M3。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`42a40876ffbe069d8b1785d0456a27a75bd5db3b`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T03:56:23.201741+00:00；结束：2026-10-23T04:07:11.086211+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际92 / 预期92；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`e665cd540f5490195685b1cb5311c57afe48dfac`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`493e2f2c09db275b1548b4c9a95213367bdde16c0d713d46ee58baa6a390de9e`；工作区范围指纹（原始字节）：`5befde210c9552c311c5716b623ad9dd00f10647e22de82433285a5bee433754`。
全工作区指纹：`66c9d3736211ab583c86b4201431e1ad24dca26adc517f532d3feaeb2e967600`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\001.txt`；SHA256=`cda8b0713a4b32d0ce0cae2915b618b44f359d81fd84af9ab5f0adc44c07e62d`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T035623.201741Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=623.781秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\007.txt`；SHA256=`4f2198ec94fd1dc20c313397ee075566ce1563cdb4f1dda85069371fb053a888`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.329秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\008.txt`；SHA256=`ae967875c6d072f4a338a7fd0a5ff7f485952eefaf69f8c27da6d0ee065c31ba`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.906秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\009.txt`；SHA256=`54c43451af7b932818a5ceafbf70be259264183736ead517c0fe038691d0e79a`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T035623.201741Z\engine.txt` SHA256=`fdb2c18baf75ba14426f2433e14e40500cafdbb2d1490452b50fd29a2a47e874`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

