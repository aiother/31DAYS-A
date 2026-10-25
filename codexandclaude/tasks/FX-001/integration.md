# FX-001 集成记录

日期：2026-10-24（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 用户授权与固定合入

用户本轮明确“用户授权合入 FX-001”，指定复审 SHA `14569ff42ca39d68f7851b95dc7393ab56c1a256`，要求与已在 master 的 SYS-011 联合 full。本次合入在该授权之后执行。

- 合入前 master：`6af7804399644ca936ebe78ab65fee6a0210c2ba`（SYS-011 已集成）。主目录工作区干净，无 `game/project.godot` 或其他重叠未提交改动。
- 固定目标：`14569ff42ca39d68f7851b95dc7393ab56c1a256`，含实现 `cf30d1e34e4d67d80c2781a83add2115732673ef`、首次交付、用户 G4、首轮审查、修复 `633561c586b3374df600a54b9a2c45877506604b` 与记录 `338bd3d7e28b8a40610230b92bd53d2f39f53476`、两轮审查记录。
- 先执行 `git merge-tree --write-tree 6af7804399644ca936ebe78ab65fee6a0210c2ba 14569ff42ca39d68f7851b95dc7393ab56c1a256`，无冲突（树 `4981c25543bbb3103f9c23136ff6fba8a74f07e1`）。
- 实际执行 `git merge --no-ff 14569ff42ca39d68f7851b95dc7393ab56c1a256 -F <说明文件>`；只使用固定 SHA，不合并可移动分支名。Git 自动合并共享脚本，没有冲突，没有额外手工改游戏代码。
- 合并提交／联合被测 SHA：`71dbea3228636bed739f964dccfedc62118fa663`；两个父提交为上述原 master 与固定复审目标。

## 共享文件与规则核对

合入后逐项检查，并以只读断言验证：

1. `placeholder_visual.gd` 同时移除 SYS-011 的 `_hit_sound` 及 FX-001 的 `_reward_flash` / `_last_balance` 与相关灰盒视觉；没有恢复任一方删除的旧反馈。角色占位形象和动画保留。
2. `player_controller.gd` 保留 `HitStop.held()`、`_jump_held_press` 和 `if jump_pressed ...` 条件；唯一的 `GameAudio.emit_from(self, &"player.jump", global_position)` 位于实际执行起跳的分支内。顿帧中记录跳跃输入，停止结束后真正起跳时才发声音。
3. Boss/天人脚本的顿帧入口与音频事件调用均自动保留；R1 按 attack_id 为玩家/刀光去重，每个目标仍分别停止；R2 真实绘制颜色记录随修订保留。未改变基础 0.10 秒、伤害、资源成本、输入映射、存档或设置。

## 用户 G4 与历史证据

用户 G4 于 2026-10-24 通过，最终保留 0.10 秒。此前临时试过未提交的 0.08 秒，已恢复，用户决定为以后攻速类增益留提升空间；详见 [delivery.md](delivery.md) 的 G4 节。本次不重做或冒称重新完成用户验收，也不把以后攻速方向当作 V0.1 新规则。

修复首次 full 的调查 A 退出泄漏与随后的干净重跑已由交付如实保留；复审独立 full 通过。本次不复用任何分支的 full，直接验证 SYS-011 + FX-001 的真实合并提交。

## master 联合 full

在真实合并提交的干净工作区执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**G2 97/97、G3 109/109 + 67/67 全部通过**，退出 0，起止干净，**content_stable=True**。引擎报告 ERROR / WARNING / SCRIPT ERROR / ObjectDB 泄漏均 0。摘要 `codexandclaude/runs/20261025T060216.739599Z/summary.json`。

同一次联合 full 的关键套件：

| 套件 | 结果 |
| --- | --- |
| `AUDIO_EVENTS_TESTS`（SYS-011） | **137/0** |
| `COMBAT_EFFECTS_TESTS`（FX-001） | **49/0** |

其余登记套件也完整执行并通过；不是拼接两条独立分支的证据。

## 收尾范围

证据提交只新增本 integration.md、把 FX-001 任务卡首部及 BOARD 中对应行改为已完成；完成前后的历史交付和审查记录原样保留。收尾文档变更另跑 G3，通过后提交，不重新修改游戏代码。

BL-065 本次只完成战斗反馈部分，其他非战斗反馈仍待后续规划，不将整个待办关闭；BACKLOG / ROADMAP 的批次刷新与其他任务状态不在本次改动中，汇总基线保持 master@519a7f6。

## 联合 full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`71dbea3228636bed739f964dccfedc62118fa663`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-25T06:02:16.740132+00:00；结束：2026-10-25T06:13:34.774521+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际97 / 预期97；完整=True；通过=True。
- G3:tests：实际109 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`4981c25543bbb3103f9c23136ff6fba8a74f07e1`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`65f646f995caf10b0be3c1560c421f8c34a232ad46c79427a7b83ea821135ba2`；工作区范围指纹（原始字节）：`ed1ac99549f8e46525f3cfabd06d4bf7cf75d70e87e724725d6d0c3404a58224`。
全工作区指纹：`e32867b4655030e68a20f6a03e7050f3d33b34adf5efc3c8f3bcbf3e351fdf44`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\001.txt`；SHA256=`57482e3a3b8cadd7bed11bef316c143f323296a4a46987fb8f510f57b4a8dbc8`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.359秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261025T060216.739599Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=661.938秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\007.txt`；SHA256=`344df270aa7d6a5fc5b4f3d560266e7e0ac5a28f392c71d6577da87f389913b7`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.219秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\008.txt`；SHA256=`29c4f261ecee150ae6fec4165cc24488e6b5c9c596bba85024986c4101b4ac50`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.937秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T060216.739599Z\009.txt`；SHA256=`a87487d4e8b0a6b2692ad228ada0b709a382a9f04677ccdf8fdb7a91dddf4306`。
- 报告 `D:\31days\codexandclaude\runs\20261025T060216.739599Z\engine.txt` SHA256=`8eee536554a30b17612dc9afe5670285bc7ac7d03f21bbbb0b89d74461de37d4`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
