# UI-007 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-007`
基线：`2ca7ca139fa95e85c6c399e17bfd2065dfd76874`（SYS-009、ENV-007 合入后的 master）
实现 SHA：`80a8a9d3660086adb40851fa7937157bae6d198b`
状态：实现与 G1/G2/G3 完成，待 Codex 审查；G4 待用户验收。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/hud/area_banner.gd`（新） | `AreaBanner`：跨区域（`scene_id` 改变，含读档）在画面正中显示区域名与房间名；暂停 / 对话 / 剧情锁 / 不可控制 / 换日纸签时等待；显示中被对话或剧情打断即消失；新区域替换旧名 |
| `game/ui/hud/interact_prompt.gd`（新） | `InteractPrompt`：读 SYS-009 `interaction_targets()`，取可用且在范围内的最近对象；“E / RB + 动作”纸签放在对象靠玩家一侧（不限距离对象放玩家头顶）；与场景底色反色；限制在窗口内并避开 HUD 实际矩形与区域名称 |
| `game/world/items/room_pickup.gd` | 只加关键物品高亮：`key_item()`（`keyitem:` 开头，与 SYS-009 同规则）、`highlight()`、帧时间驱动的光晕与呼吸圆环 |
| `game/ui/menus/life_ui.gd` | 挂载上面两个节点（在保存纸签之后、所有菜单页之下） |
| `game/tests/test_area_prompts.gd`（新） | 登记套件 `AREA_PROMPTS_TESTS`，45 项 |
| `game/tests/acceptance/ui007_area_prompts.gd`（新） | G4 适配 |
| `game/docs/area_prompts_ui.md`（新） | 规则、位置与反色、已知事项、G4 入口 |

新脚本的 `.uid` 一并入库（ENV-007 的 G3 检查）。未改会话脚本、交互范围与判定、存档、输入映射；旧测试与断言未改。

## 要求对照

| 要求 | 结果 |
| --- | --- |
| 1 区域名称 | 跨区域显示“区域 · 房间”，约 2.6 秒淡出；同区域换房不显示；暂停、对话、剧情锁、换日纸签时延后；显示中被打断即消失（规则写在 `area_prompts_ui.md`）；正中显示，不与 HUD、错误提示、对话框重叠（对话中不显示） |
| 2 交互提示 | 只显示最近的一个可用对象；放在对象靠玩家一侧；反色（暗场景纸色底墨字，场景提供 `base_color()` 时按其亮度切换）；离开范围、不可用、剧情 / 对话 / 暂停时隐藏 |
| 3 关键物品高亮 | `keyitem:` 拾取物光晕与呼吸圆环；拾取后随物体隐藏；拾取判定与范围不变 |
| 4 设备图示 | 现有代码没有“最近使用设备”的信号，按卡上的退路并列显示“E / RB” |
| 5 字体与关键色 | UI-001 主题字体；朱红按键框、金色高亮均为 `DuskStyle` 常量 |

## 完成标准

1. **自动测试** `AREA_PROMPTS_TESTS` 45/0（`--fixed-fps 60`，真实 FinalBattleSession、真实 Room 与 SYS-009 查询，断言读 `drawn`）：读档显示区域名（区域与房间两部分、正中、淡出）；跨区显示、同区不显示；剧情锁等待后显示；暂停等待；新区域替换旧名；提示范围外无、范围内显示按键与动作；玩家在右 / 左时提示在右 / 左；暗场景纸色底墨字；剧情锁、暂停隐藏并恢复；两个可用对象只显示最近者；不可用对象不显示；拾取后消失；7 旁显示“交谈”、对话中隐藏；关键物品闪烁且与 SYS-009 `key_item` 一致、普通拾取不闪、拾取后消失。
   为覆盖单个 Room 里不存在的情形（两个同时可用、贴屏幕边、HUD 角落、不限距离），测试会话在真实查询结果上追加少量模拟目标（会话脚本替换时保留全部已存属性）。
2. **防重叠**：1920×1080 与 1280×720 下，目标贴左边、右边、顶部、在 HUD 角落时提示都在窗口内且不与 HUD 实际矩形相交；不与区域名称暗带相交；不限距离对象的提示在玩家头顶正上方（12 项）。
3. **现有测试**：见 G2 + G3；另跑 campaign 166/0、exploration_room 33/0、environment_batch 116/0、medkit_session 68/0、quest_interactions 316/0、ui_data 54/0、pause_menu 53/0、title_slots 80/0、formal_hud 52/0。
4. **变异**（临时改源文件跑 `test_area_prompts.gd`，按原字节恢复）：

| 变异 | 结果 |
| --- | --- |
| 同区域换房也显示区域名 | 45 项中 1 项失败，退出 1 |
| 提示画在远离玩家一侧 | 45 项中 2 项失败，退出 1 |
| 不可用（剧情锁等）仍显示提示 | 45 项中 3 项失败，退出 1 |
| 关键物品不高亮 | 45 项中 2 项失败，退出 1 |

5. **G4**：待用户（见下）。

开发中按渲染截图修正了三处：提示原先压住玩家头部（改为纸签底边在对象上方 120 像素）；进入新区域时旧区域名仍在（改为直接替换）；提示与区域名称重叠（提示避开区域名暗带）。

## G2 + G3

在实现 SHA、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **90/90**（新增套件 +1），G3 **108/108 + 67/67**，**content_stable=True**（ENV-007 生效，本次可作复用来源），ObjectDB 泄漏 0 处。摘要 `codexandclaude/runs/20261022T081051.291965Z/`（不入库）。

## G4（用户）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui007_area_prompts.gd
```

槽1 开局（向右走过最初几个区域）、槽2 瓦砾塔检查点（附近有珍珠房间）、槽3 巢都沟壑入口（前方营帐有会闪的关键珍珠）。请看：跨区域时的区域名、同区域不出现；靠近珍珠、开关、检查点、NPC 时的提示位置与样子；关键珍珠的闪烁；对话、暂停时提示隐藏。

## 说明与未决

- **灰盒提示仍在**：拾取物上方的“E / RB · 拾取××”、落石开关和药包补给的灰盒提示、右上角说明文字都由其他脚本绘制，且有旧断言（`test_exploration_room`、`test_environment_batch`、`test_medkit_session`）依赖，不在本卡允许修改范围，本任务不动；正式提示与它们会同时出现。建议另立小任务统一移除（Claude 起草）。
- **灰盒房间名**：部分 Room 的 `display_name` 仍是“瓦砾塔Room2 / Room3”，区域名称照实显示；改名属数据整理。
- 反色目前总是“纸色底墨字”，因为所有 Room 都是暗色灰盒；正式美术的 Room 提供 `base_color()` 后会自动切换。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`80a8a9d3660086adb40851fa7937157bae6d198b`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-22T08:10:51.291965+00:00；结束：2026-10-22T08:21:48.744111+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际90 / 预期90；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`f416d8699b3e98bc628334139316a45f7f66db21`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`8fa6ff37d17c10a86aa1a43cdd8e3040f70aa3dad110ddf189f1f9badcba5653`；工作区范围指纹（原始字节）：`82b5f9cbeba7a1c11fe1dcbce6b718f50a4126d961fe09328797802593297aff`。
全工作区指纹：`10eb99378c770d50f1142e1fc290ea397ffaaad3c3585e1d5c63d956f33867c0`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\001.txt`；SHA256=`808cc9e29b6fe7dc7b5e506633381724fb1a68481ba0887a4f7557626db013de`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261022T081051.291965Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=632.656秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\007.txt`；SHA256=`f347a002fc5567c131e8c32d5fcb4022af5a8aa7316a65b03fc2ddfe2cfe49e7`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\008.txt`；SHA256=`aee3cc0c04d9ba3890478bccdf01992e0f4728ce5cd710a3c1c1bce0350e4203`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=19.156秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\009.txt`；SHA256=`ce5ca2cf60ad4d74e555f1156fb9cdb6fab0de0336908678f575c13344ca9dab`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T081051.291965Z\engine.txt` SHA256=`d34f4011004a6e9956b7d6f9a28787d346a2114a4aeef8de50e9ec2f76763809`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
