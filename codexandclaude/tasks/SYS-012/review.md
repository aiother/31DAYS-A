
## 第2轮复审（2026-10-25）

审查者：Claude｜结论：**通过**，无阻断项。不合并 master（由 Codex 在用户授权后集成）。

### 固定对象

- 修正实现 `1ef4c71771732641675dbf8983ba1ffbb3090286`；交付 `ede964fa911493ff999bb5af942a41546a1d5616`。复审分支 `claude/SYS-012-review-r2` 从交付 SHA 建立（已包含第1轮审查 `d12f8dc`），只新增本节。
- `b8186b8..1ef4c71` 只改 `game/tests/test_cinematics.gd`、`game/docs/cinematics.md` 与 review.md；游戏脚本与目录无差异，第1轮核对过的接线与玩法不变。

### R1 核对

- 新增独立的期望表 `EXPECTED_POLICY`（锁操作、藏 HUD、停表、剧情音乐四列），按重构前各会话的旧行为填写，不取目录默认值；覆盖目录全部 13 段，另加“普通对话”一项。
- `policy()` 先从实际效果取值——`scripted_control_locked`、正式 HUD `is_visible_in_tree()`、日内时钟与最终战预算是否走动、`AudioEvents.music` 是否为 story——再要求它们同时等于独立期望和 `cinematic_state()`。这正是第1轮要求的“从实际效果核对，不只读目录”。
- 新增外围用例：真实强化闪避过尖刺、制造写盘失败进入 `world.save`，E 重试释放；并用旧公共属性 `intro_active` 进入 `legacy.lock` 并释放。
- 期望表与基线代码逐行对照无误：`final.win` 不锁操作、不藏 HUD、停表（胜利后停表）、不进剧情音乐；`ending`、`ending.finished`、`final.talk`、`seven.*`、`ten.rescue` 藏 HUD；普通对话停表、进剧情音乐但不锁操作不藏 HUD。

**成立。**

### N1～N3

- N1：留给 PLN-002 登记（开场写盘失败保持锁定并可重试），同意。
- N2、N3：接入说明已补“兼容属性仅供旧客户端，新代码直接调用 `cinematics`”与“单一播放实例，嵌套需显式处理”。

### 审查方变异（复跑）

第1轮的 10 项变异在交付 SHA 上逐项复跑，每项在独立项目副本中只改一处、跑 `test_cinematics.gd`（结果 `codexandclaude/runs/sys012-r2-claude-mutations.json`，不入库）。基线 200/0。

| 变异 | 第1轮（三个主套件） | 本轮（test_cinematics） |
| --- | --- | --- |
| 开场写盘失败仍解锁 | 5 项失败 | 5 项失败 |
| 7 首见不藏 HUD | 存活（仅旧套件拦下） | 1 项失败 |
| 最终胜利段播放剧情音乐 | **全部存活** | 1 项失败 |
| 最终胜利段锁操作 | **全部存活** | 1 项失败 |
| 普通对话不再停表 | 存活（仅旧套件拦下） | 1 项失败 |
| 普通对话不再选剧情音乐 | 1 项失败（audio_events） | 1 项失败 |
| Boss 忽略入口提交 | 2 项失败 | 2 项失败 |
| 外围保存锁不再停表 | 存活（仅旧套件拦下） | 1 项失败 |
| 允许 `request_skip()` | 10 项失败 | 14 项失败 |
| 结局段不藏 HUD | **全部存活** | 1 项失败 |

10 项全部由新套件直接拦下，无解析错误。

### 独立 full

在交付 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **98/98**，G3 **110/110 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处；本任务套件 200/0。摘要 `codexandclaude/runs/20261025T082757.556551Z/`（不入库）。变异均在独立项目副本中进行，full 起点无源码差异。

<!-- 第2轮复审 full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`ede964fa911493ff999bb5af942a41546a1d5616`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T08:27:57.557544+00:00；结束：2026-10-25T08:39:22.109602+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际98 / 预期98；完整=True；通过=True。
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`5449b59fe378a88cded8a5b7296f34d6864c44c4`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`a4456f3689b6ed3086dc5220999933364e1f10f94c26d2a7d7e59e17f1733d57`；工作区范围指纹（原始字节）：`1afb86cdd1c8161929077da78b0c1a257845f45a1d983a32914ea3a1e9c00a83`。
全工作区指纹：`b64148d38360fb49803d2d08ebd224ed3d712aba034b107d372b58af5c5b1c0c`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\001.txt`；SHA256=`81c273f82c02efafe68161e02d33f72ccb28e128a60d62a9ff70ab9d8602fd18`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261025T082757.556551Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=661.265秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\007.txt`；SHA256=`e8474a1a82eb0bd26ca38d3b108341d90cfd31f87ed3047084a0709fd1b5411f`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.141秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\008.txt`；SHA256=`8b88748fb1b4ad8db3c27ea5efd4901e0fea2f15f4390342423d061216e6e8cb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\009.txt`；SHA256=`801b4e5f48c7ce07ae7221f7203db579c8829793264f064fd366e7ae86ed5850`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T082757.556551Z\engine.txt` SHA256=`73ee563e0ec34249a49b72c21bb95d0f236883d952e85cbbc539163ef0cee32b`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

### G4

任务卡列为可选，尚未进行；是否进行由用户决定。建议走一遍时留意最终胜利后能自由移动去找 10、结局时 HUD 隐藏。
