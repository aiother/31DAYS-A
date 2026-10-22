# UI-008 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-008`
基线：`164cd977bcf8496fe217d223c39a42e3ad6ea89e`（第七批任务卡合入后的 master）
实现 SHA：`c439c575c2a065dc5adaff7a163124f8a6e53d5d`（`c828ccc` 实现 + `c439c57` 补加速标记断言）
状态：实现与 G1/G2/G3 完成，待 Codex 审查；G4 用户 2026-10-22 通过。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/dialogue/field_dialogue.gd` | 重写表现：`panel` 改为全屏绘制层，`_draw_slip()` 画方案 D 纸笺（黄昏色纸 0.95、上下撕边、墨字、左下墨色名签纸色字、继续 / 加速标记、纸笺下按键说明行）；`choices` 内两枚墨色按钮（`InkButton`），焦点约束、默认“留下”、暂停时禁用并在恢复后还原焦点；新增 G-08 短提示（`missed_survivor()`、`missed_place()`、`missed_avoided()`、`missed_drawn`）。隐藏的 `text` / `speaker` / `hint` Label 仍为数据模型；类名、信号、`start / advance / show_departure / dismiss / show_notice / active / confirming / line_index` 不变；`quest` 与 `notice` 未动 |
| `game/tests/test_dialogue_ui.gd`（新） | 登记套件 `DIALOGUE_UI_TESTS`，33 项 |
| `game/tests/acceptance/ui008_dialogue.gd`（新） | G4 适配（自检 12/0） |
| `game/docs/dialogue_ui.md`（新） | 规则、避让、测试与 G4 入口、已知事项 |
| `Words/T7核对表.md` | T7-A“NPC对话界面”、T7-C“对话框布局”加修订注（方案 D，不再是黑色半透明，来源 EXP-004 用户选定）；G-08 行加实现注。T7 原件不改（与 EXP-001 选定方案四后的做法一致） |

新脚本的 `.uid` 一并入库。未改会话脚本、`life_ui.gd`、存档、输入映射与任何规则；**旧测试与旧断言一处未改**（保留隐藏 Label 作为数据模型的目的）。

## 要求对照

| 要求 | 结果 |
| --- | --- |
| 1 对话框（方案 D） | `BOX = Rect2(540,120,840,250)` 中上部；纸、撕边、墨字、名签（`speaker`，纸色字）；句尾右下继续三角，按住 E / RB 时“»»”；最后一句后自动关闭；强制剧情隐藏 HUD 行为不变（`test_field_room` 覆盖）。按键说明行暂保留在纸笺下方，按 G4 意见取舍 |
| 2 推进与加速 | 沿用 `DialogueConfig` 速度 30 字/秒、倍率 4；单击补全 / 下一句、按住加速、结束关闭语义不变；暂停时文字停住，返回后继续 |
| 3 离开确认 | 沿用 `show_departure()` 与两个信号；两按钮在纸笺内、互不重叠、不压名签；默认焦点“留下”；上下 / Tab / 十字键只在两者间；暂停时鼠标、Enter、A 都选不中，恢复后焦点回到“留下” |
| 4 G-08 | 条件：`quest_state().state == "已过期"` 且任务 id 等于当前 Room id，且该 Room 的 `Survivor` 交谈目标 `in_range`（无查询时按 160 像素）；对象上方纸签两行文字，4 秒后消失，不锁操作、不开对话；每次进入 Room 一次，离开再回来再出现；交谈时过期台词不变 |
| 5 T7-C 修订 | 见上 |
| 6 `quest` / `show_notice()` | 未改，留给 UI-010 |

**G-08 的两处补充判断**：①要求任务 id 等于当前 Room id，否则 7 所在田野（任务是小镇救助）在小镇救助过期后也会误出提示；②进入 Room 时区域名称正好在画面中央，纸签若放上方会压住它，所以先试对象上方、再试下方，仍与 HUD 绘制矩形、区域名、交互提示、可见保存失败提示相交时**等待**，有空位才出现（UI-007 审查 R1 的“不覆盖”做法）。对话打开时纸签隐藏。

## 完成标准

1. **自动测试** `DIALOGUE_UI_TESTS` 33/0（`--fixed-fps 60`，真实 FinalBattleSession、真实 Room，真实 E / RB / Esc / 键盘 / 手柄 / 鼠标输入，断言读 `drawn` 与 `missed_drawn`，均由绘制调用同时产生）：
   - 7 旁按 E 打开纸笺：纸色、名签文字与颜色、墨字、按键说明行；文字随时间增长；Esc 暂停文字不动、恢复后继续；一次 E 补全并出现继续标记；最后一句后自动关闭、绘制记录清空。
   - 单击与按住：同一条过长句子、同为 12 帧，松开时增长 6 字，按住 RB 增长 24 字（≥3 倍），按住时有“»»”、松开后没有。
   - 离开确认：按钮顺序与默认焦点“留下”；两按钮矩形不相交、在纸笺内、不压名签；方向键 / Tab / 十字键后焦点仍在两者之一；暂停时鼠标点“确认离开”、Enter、A 都不发信号；恢复后焦点回“留下”；Enter 选“留下”发 `departure_cancelled`。
   - G-08（沟壑救助已过期的真实存档）：远处无；靠近出现、文字正确；不开对话、`can_control()` 为真；位置在对象上方（或上方被占时在下方）；约 4 秒后消失；原地不再出现；7 旁不出现；离开再回来再出现；交谈仍给过期台词，且对话中纸签隐藏。另一份救助未过期的存档：靠近不出现。
2. **防重叠**（同套件）：1920×1080 与 1280×720 下，纸笺连同按键说明行在窗口内、不与 HUD 各绘制矩形相交；G-08 纸签在窗口内，与 `missed_avoided()`（HUD 绘制矩形含地平线、区域名、交互提示、`_protected_rects()`）及可见保存失败提示都不相交。对话中区域名与交互提示本就隐藏（UI-007），G-08 纸签也隐藏，故对话框与它们不会同时出现；确认按钮在纸笺内（第 1 项已核）。
3. **现有测试**：旧断言未改，见 G2 + G3。开发中单跑：field_room 50/0、town_rescue 47/0、ravine_rescue 58/0、outskirts_rescue 41/0、ten_rescue 58/0、ten_clear_presentation 17/0、world_day_session 38/0、ravine_depth 71/0、quest_interactions 316/0。
4. **变异**（临时改 `field_dialogue.gd` 跑 `test_dialogue_ui.gd`，按原字节恢复，脚本核对恢复一致）：

| 变异 | 结果 |
| --- | --- |
| 去掉长按加速（倍率恒为 1） | 1 项失败 |
| 确认默认焦点改为“确认离开” | 1 项失败 |
| 暂停时按钮仍可用 | 2 项失败 |
| G-08 不查“已过期”（未过期也出现） | 1 项失败 |
| G-08 出现时锁住操作 | 3 项失败 |
| G-08 同次进入反复出现 | 2 项失败 |

   长按加速变异第一次存活：原断言用较短的 7 的台词，单击与按住都在窗口内打完。已改为过长句子、同帧数比较增长量后杀死。

5. **G4**：用户 2026-10-22 按下方入口验收，回复“G4核验完了，没问题”，通过。

## G2 + G3

在实现 SHA `c439c575c2a065dc5adaff7a163124f8a6e53d5d`、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **91/91**（新增套件 +1），G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处。摘要 `codexandclaude/runs/20261022T100315.171389Z/`（不入库）。

说明：此前一次 full（`20261022T095209.017440Z`）同样全部通过，但运行中新建了本交付记录，content_stable=False，不作证据；本次为移走交付记录后在干净工作区重跑。

## G4（用户）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui008_dialogue.gd
```

- 槽1 开局：向右到田野，看与 7 的对话纸笺（撕边、墨字、左下名签）；单击补全 / 下一句，按住加速；对话中 Esc 暂停，文字停住。
- 槽2 巢都沟壑入口（沟壑救助已过期）：走到救助房间的幸存者附近，上方出现 G-08 短提示约 4 秒，期间可正常移动；交谈仍是过期台词。
- 槽3 巢都沟壑入口（救助未过期）：进入沟壑深处，不清敌往回走，出现“留下 / 确认离开并放弃救助”，默认在留下；暂停时点不了。
- 请顺带告诉我：纸笺下方“E / RB 继续 · 长按加速”这行要不要保留。

## 说明与未决

- 按键说明行：G4 时用户未提出修改，按现状保留在纸笺下方（卡上要求 1）。
- `quest` 左侧任务文字与 `show_notice()` 中央提示仍为灰盒，UI-010 接管。
- 名签沿用各 `DialogueConfig.speaker`，现有多为“× · 临时台词”，正式台词属 M3。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`c439c575c2a065dc5adaff7a163124f8a6e53d5d`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-22T10:03:15.171389+00:00；结束：2026-10-22T10:13:59.555813+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际91 / 预期91；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`2d75aeea33c2654554efe447f693e118a318bb87`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`002e64e6b88a4fb137efc220c778f55838d19ee811ef1d99d53274eb808b3874`；工作区范围指纹（原始字节）：`2a5908cd2a5fb33470127dd130cfb2479bf1e3c0d23dc66661d632bc4bd16cde`。
全工作区指纹：`89c0ffcc13d24886e6bda84b6953631b96ce3177e6da19e099cfa5bd2da77085`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\001.txt`；SHA256=`9bdf26bca4e795be068f323f24becbcb020f71a88ba15b98bc969ae0cf349dd9`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.296秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261022T100315.171389Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=620.843秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\007.txt`；SHA256=`93910e0911825c0d8f4109d2d580f9eed322b1e6cda996ceccae8a032aad616c`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.234秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\008.txt`；SHA256=`6b8c31398fed7887ef3081512bef8a3f022f9c7f01abf3cffb31052ca5f9ce95`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.532秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\009.txt`；SHA256=`aa28bd753d7f552542df59e8b2c899be60e2ddf6277d0502145e5f6428dca4d8`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T100315.171389Z\engine.txt` SHA256=`ac09a154e9b5a0a754a66ee2723123a98c882ef7ee06c3b346ca0e0e8460f4b4`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

