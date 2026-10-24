# SYS-011 第1轮审查

审查者：Claude｜日期：2026-10-24｜结论：**需修改：R1（P2）**。框架、总线、暂停、背景切换与事件清单整体成立，测试与变异扎实；只有一处把已有的“强 / 重攻击前摇提示音”区分在迁移中丢掉了。未修改 Codex 实现分支，不合并 master。

## 固定对象与边界

- 基线 `48bdf15d249ac44630c9229a4c195c5507f149f9`；实现 `877bb34ea476f7a7f5ab2ae5986afa1519e2f949`；交付 `5e0519a75642ebac110fb2765fc28ecd0ced2082`。审查分支 `claude/SYS-011-review` 从交付 SHA 建立，只新增本记录。
- 改动范围与任务卡“允许修改的文件”一致：新增 `game/systems/audio/`；`project.godot` 只加自动加载；玩家、敌人、会话、对话只增加事件调用；`placeholder_visual.gd` 只删 `_hit_sound` 相关行，视觉部分（奖励圈、着色、判定框）原样留给 FX-001；`test_settings.gd` 的 4 项 `routing()` 改读新服务创建的播放器，断言数量与总线要求不变，理由成立；ROADMAP 只改 §2 音频一行。
- 逐行核对玩法脚本的新增调用：都在既有成功分支之后或之内，不改条件、数值、计时与返回值（起跳、闪避与恢复扣费、恢复完成、天人格挡成功、两 Boss 进入 WINDUP、对话推进、门 / 机关保存成功、Room 通行）。

## R1（P2）：单色、天人“强 / 重攻击”前摇提示音的区分在迁移中丢失

位置：`game/enemies/monochrome_visual.gd`、`game/enemies/tian_visual.gd`（删除的旧警示）；`game/systems/audio/audio_events.gd` `_bind()` 中 `enemy.attack_started` → `enemy.windup`。

基线的旧警示不是单一音：

- 单色：`_warning.pitch_scale = 0.7 if entity.strong_attack else 1.3`；
- 天人：`warning.pitch_scale = 0.6 if actor.attack_kind == TianWarrior.Attack.HEAVY else 1.1`。

也就是强力 / 重击用低音、普通攻击用高音。迁入新入口后，三类敌人的 `attack_started` 一律发同一个 `enemy.windup`（330 Hz、无音高变化），映射资源也只有一个 `enemy.windup` 槽，玩家再也听不出这是强力 / 重击还是普通攻击。

这不只是音色细节：

- T2 §8.2 单色实体的学习内容是“识别长短前摇”，§8.3 天人要“惩罚后摇”，强力 / 重击前摇明显更长、伤害更高（2 / 3 点）；旧提示音的音高差正是给这件事的听觉线索。
- 任务卡要求“现有警示音与命中音迁入新入口，迁入后不重复发声”，以及 G-07“与现有灰盒视觉警示同时”。迁入应保留现有可感知的区分，而不是降为单一音。
- 交付记录说三类前摇“同源、同一物理帧、一次”，这些都成立，但没有提到区分被去掉，测试也只数 `enemy.windup` 次数，不检查强 / 普通的区别。

**请修复**：保留强力 / 重击与普通攻击前摇的听觉区分，并让正式音频以后也能分别替换。做法建议二选一：分成两个事件（如 `enemy.windup` 与 `enemy.windup_heavy`，各有映射槽与占位音），或在同一事件的记录里带上变体并由映射提供两个资源。占位音沿用基线的相对音高关系即可。补回归：单色强力 / 普通、天人重击 / 普通各由真实 AI 或真实动作入口触发，断言事件（或变体）不同且与 `strong_attack` / `attack_kind` 一致；变异“强 / 普通发同一提示”应失败。Boss 前摇是否也区分不作要求。

## 非阻断

- **N1 测试缺口（建议补）**：以下三处代码行为正确，但测试拦不住相反实现：
  - 敌人**被拒绝或零伤害**的命中不应发 `enemy.hurt`（`_enemy_hit` 的守卫）：把守卫改为恒真，套件仍 101/0；
  - 暂停或有焦点时按 Esc 发 `ui.back`（`_input`）：删掉这一路径，套件仍 101/0；
  - `_world_exited()` 中的 `stop_game()`：删掉后套件仍 101/0。这一条目前由短音的场景归属清理兜住，行为上不留残音，可视为冗余保护；如保留，建议补一条只靠它才能通过的检查，或注明它是兜底。
- **N2 等级标注**：`game/docs/audio_events.md` 把 `heal.start / heal.done` 标为“C 占位”，但 T6-D2 的“可能性音效”行写的是“获取、消耗、恢复”，属于 A 级。任务卡允许 A 级“可以静默”，并不禁止临时占位；建议文档改为“A 级，暂用占位”，与 `possibility.*` 的说明口径一致，免得以后准备素材时漏掉恢复音。
- **N3 Room 通行音**：`two_room_session._change_room()` 每次 Room 切换都发 `interaction.gate`，文档也写明“真实 Room 通行完成”。不阻断；只是以后正式门音到位时，没有门的通路也会响门音，届时可能需要拆成单独事件。

## 审查方变异（独立复跑）

在交付 SHA 上逐项只改一处，单独进程跑 `test_audio_events.gd`，按原字节恢复并核对（结果 `codexandclaude/runs/sys011-claude-mutations.json`，不入库）。全部语法有效，没有靠解析失败杀死：

| 变异 | 结果 |
| --- | --- |
| 重落地报告为普通落地 | 2 项失败 |
| 闪避扣费不报告 `possibility.spend` | 8 项失败 |
| 剧情状态永不进入 story | 1 项失败 |
| 环境音忽略区域 | 6 项失败 |
| 删除天人格挡音 | 2 项失败 |
| 背景音轨改走效果音总线 | 1 项失败 |
| 删除恢复完成音 | 2 项失败 |
| 被拒绝 / 零伤害命中也发敌人受击音 | **存活**（N1） |
| 删除 Esc 返回音 | **存活**（N1） |
| Room 退出不调用 `stop_game()` | **存活**（N1，由场景归属清理兜住） |

基线同一套件 101/0。Codex 交付中的 6 项变异（G-07 订阅、总线、暂停、缺资源严格关卡、Boss 大型战斗、短音生命周期）的设计与结论成立；R1 的“强 / 普通区分”不在其中。

## 独立 full

在交付 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **96/96**，G3 **109/109 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261024T072224.010291Z/`（不入库）。变异在 full 之前进行并已按原字节恢复，full 起点无源码差异。

<!-- 第1轮审查 full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`5e0519a75642ebac110fb2765fc28ecd0ced2082`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-24T07:22:24.010291+00:00；结束：2026-10-24T07:33:37.855571+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际96 / 预期96；完整=True；通过=True。
- G3:tests：实际109 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`87a99a0b5889b925f5782476dfd9a7dc672321c0`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`16dcc97b534af725de5976b137789aaa1147d32453a9b4598c8a73f7d2e8976c`；工作区范围指纹（原始字节）：`c4d1e5fbc44c6e3cfeee1bf6349bd4a37bdae142baf8d98c4de4e414a5fda6b4`。
全工作区指纹：`7505dd72af70408361261371885c00a1d650c06f37a55225e9e82609450e7b41`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\001.txt`；SHA256=`b61a4d1307fedca410eaa7b149afea0a4a2e04c959d3b7042974b6bbf04d93c7`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.296秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261024T072224.010291Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=650.515秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\007.txt`；SHA256=`58b51b9f3ed32c8676da9db05d8882d812853c940a069a2ef259719edda4ba40`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.235秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\008.txt`；SHA256=`691737fd7894ce56eebd4ce7c534b580424549fcb8ab7ded23853cfdbe4c7000`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\009.txt`；SHA256=`dea534f87009bec998b1008e9943ead3334809f3934e2c744e1491a5b4d7e581`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T072224.010291Z\engine.txt` SHA256=`8cd040af2261c4eb9bcde274e0be27127b92d3f500bcd98d5e7a4e6dc9d6208a`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## G4

用户听感 G4 可选，尚未进行；建议 R1 修复后再听，届时可顺便听单色、天人强弱前摇是否分得清。
