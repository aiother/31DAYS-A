# EXP-005 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/EXP-005`
基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`（第八批任务卡合入后的 master）
实现 SHA：`426f4b3953ff563b59526b30bfbde822866dfe9d`（`c520700` 原型 + `5738176` 截图目录加 `.gdignore` + `426f4b3` 截图输出路径改由脚本位置推出）
状态：原型完成，**用户已定稿**（2026-10-23：风格 D 融合、普通攻击顿帧 0.10 秒、普通命中不震，见“用户定稿”）；Codex 第1轮审查 R1～R3 已修复（见“第1轮审查修复”），待复审。

## 第1轮审查修复（2026-10-23）

审查记录 [review.md](review.md)（Codex，`e0a85061`，审查对象为首次交付 `6dc664e`）。三项均成立；修复在包含用户三轮反馈与定稿的当前版本上进行（审查记录以非快进合并 `21f8feb` 保留）。

| 编号 | 问题 | 修复 | 回归 |
| --- | --- | --- | --- |
| R1 | 记录元数据由外层补齐，删掉绘制仍通过；挥砍方向未验证 | `effects.gd` 中所有图元都经记录型辅助函数绘制（`_line`、`_poly`、`_dot`、新增 `_rect`、`_glow`、`_ring`），每条记录的 `prims`（图元数）、`color`（最后一个图元的颜色）、`alpha`（最高不透明度）、`centroid`（全部图元点的重心）都来自实际绘制；特效函数内不再有直接的 `draw_*` / `InkDraw.glow` / `rough_circle`（修复脚本对此做了检查）。融合风格的暖光记录也取自 `_glow()` 的返回值 | 四套风格 × 15 种特效逐个生成，在生命中段断言图元数 > 0 且可见；水平（J）、向上（W + J）、空中向下（S + J）用真实按键触发，按实际轨迹点的重心判断方向 |
| R2 | 多数 `settle()` 结果被丢弃，复活永不结束仍通过 | 全部 17 处等待改为带断言的 `ends()`（上限固定 120 帧，与被测寿命无关） | 四套风格 × 13 种有限特效各自在 90 帧内结束且不留残余；两种循环特效在停止后消失 |
| R3 | 手柄无法触发透支闪避、弹反、受击、复活 | 原型内补手柄按键（正式输入映射不变）：Back 切换可能性不足、十字键上 投射物 / 左 受击 / 右 复活 / 下 八靶同时受击、Start 顿帧开关、按下左 / 右摇杆 顿帧缩短 / 加长；画面说明与 README 已写明 | 只用真实手柄按钮事件：Back + B 透支闪避、B 正常闪避、长按 Y 恢复、上 + X 弹反、左 受击、右 复活、下 八靶受击、Start 与摇杆按下调顿帧 |

`EXP005_SMOKE_TESTS` 92 → **297/0**。

**变异**（逐项只改一处，跑冒烟，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| R1：靶子受击不绘制、保留颜色（审查原变异的对应写法） | 4 项失败 |
| R1：复活完全不绘制（`return {}`） | 4 项失败 |
| R1：挥砍方向一律为 0（全部水平） | 8 项失败 |
| R2：复活寿命改为 INF（永不结束） | 22 项失败 |
| R3：去掉手柄 Back（透支闪避） | 2 项失败 |
| R3：去掉手柄十字键右（复活） | 1 项失败 |
| R3：去掉手柄十字键上（投射物 / 弹反） | 2 项失败 |
| R3：去掉手柄十字键左（受击） | 1 项失败 |

审查的四项原变异在首次交付上均 60/0 存活；在修复后的版本上全部被拦下。非阻断 N1、N2 已按建议更正措辞（见“帧时间说明”与“说明与未决”及定稿节的正式实现说明）。

## 用户定稿（2026-10-23）

用户第三次试玩后回复：“这次可以了，EXP-005 定稿，顿帧在普通攻击时设定为0.10秒”。定稿内容：

| 项目 | 定稿 |
| --- | --- |
| 风格 | **D · 融合**：攻击轨迹与命中用 A 墨迹飞溅的画法，下面衬 B 的暖光、命中处一下暖光闪、飞溅浅色为珍珠白；其余全部特效（弹起、弹反、闪避与透支闪避、无敌、可能性消耗与获得、恢复中与完成、受击、靶子受击与击倒、复活）用 B 光痕 |
| 顿帧（卡肉感） | 普通攻击命中时 **0.10 秒**；表现为“刀砍进去被卡住”：这一刀的轨迹停在砍中的位置，与玩家、目标一起停住，目标原地抖动，结束后刀光接着扫完；未命中不卡 |
| 屏幕震动 | 普通命中**不震**，留给以后的重攻击或其他大型战斗效果；受击时轻震（5 像素，首版的一半） |

原型默认值已改为定稿值（顿帧 0.10 秒），冒烟测试按常量取默认值，结果不变。

**给正式实现的说明**（后续批次立项时写入任务卡）：

1. 正式特效挂在 SYS-010 的动画状态与现有信号上。弹反与击倒位置先评估复用现有通道（审查 N2）：投射物弹反成功会经 `PlayerCombat.hit_confirmed(target, damage, impulse)` 发出，接收方可从 target 的父节点读取 `ColorlessProjectile` 的 `reflected` 与位置；敌人 `defeated(reward)` 的回调可在 `queue_free` 前读取实例位置。只有复用不清晰时，再增加专用事件（Codex 系统部分）。
2. 顿帧会让玩家、敌人与判定暂停 0.10 秒，正式化时须评估：是否计入日内时钟与最终战计时、敌人前摇与攻击判定是否同步暂停、多目标同帧命中只卡一次；暂停、计时与存档规则不得因此改变。
3. 震动若以后用于重攻击，届时再定幅度，并考虑在设置中提供开关（A-017 设置项之外，需用户同意后另登记）。
4. 风格 A、B、C 的完整画法仍保留在原型中，供正式实现参照。

### 定稿提交的检查

定稿提交 `88b7da42423767e32490976dfd3a78104266ebd2`（在首次交付 `426f4b3` 之上依次为 `721f411` 第一轮调整、`7918942` 第二轮修复、`88b7da4` 定稿值；均只改 `game/prototypes/EXP-005/` 与本任务记录）。冒烟测试 `EXP005_SMOKE_TESTS` 92/0。起点干净执行 full：**通过**，G2 **94/94**，G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T174616.357992Z/`（不入库）。

<!-- 定稿后 full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`88b7da42423767e32490976dfd3a78104266ebd2`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T17:46:16.357992+00:00；结束：2026-10-23T17:57:03.288154+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`a9d6428f25f2bfe33c15cd77307ee52ce4ddac34`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`44eef63c480346e76becb413e68acf55235ff5c11cb85cfa0c9640b3ec7b29d5`；工作区范围指纹（原始字节）：`9c63ba326ec6bd88863c0791f982c22bd6408c83cc966f182fefd42d82fd678b`。
全工作区指纹：`7304750b0f1ba060a357a5bc5dc2af301a5a9329f772c1f00b87b4f589d9a639`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\001.txt`；SHA256=`df22e46687bfadb6019086c850a42b58aed316cdb28c05386d7efefb684fefd7`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T174616.357992Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=623.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\007.txt`；SHA256=`ebc631bd26e7db817f7c30e962db3442447e56368c6dbb1485644fab253a3c8e`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.265秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\008.txt`；SHA256=`14dc2b30c561485160086c22b6a549d07328f77f2c299baff9e2cb215564ea18`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.563秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\009.txt`；SHA256=`a0157b726fed1e3b4f7e652cada8dc9f6c20005d0878e49d0f155ae42b2cdf3b`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T174616.357992Z\engine.txt` SHA256=`52a2232af05dc12a7dd46f28a02264f77170696d3e649969174c41bb5344b21c`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

### 审查修复提交的检查

审查修复提交 `5963898a24d3f9728c6cb1c804a7aaa81a371d69`（只改 `game/prototypes/EXP-005/` 与本任务记录）。冒烟测试 `EXP005_SMOKE_TESTS` 297/0。起点干净执行 full：**通过**，G2 **94/94**，G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T182444.148090Z/`（不入库）。

<!-- 审查修复后 full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`5963898a24d3f9728c6cb1c804a7aaa81a371d69`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T18:24:44.148090+00:00；结束：2026-10-23T18:36:57.754655+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`7db5a8cce217cca9611f358a2240b99a4860d5c4`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`b94d042c98d4d92ae48447e38b2ad803551beafc3cd8105dd7d46f81b814e6c4`；工作区范围指纹（原始字节）：`47ba23479885065d00ba2fd0ba7f22eedfc3f50a3b4e8527646efdbb57fa53f4`。
全工作区指纹：`608a55d91e36e398adac0f63e8c57104a28a9fd3170a8aabc61196932b32eac6`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\001.txt`；SHA256=`e920be0ed5e1fbffdf620ff89666251f137993a77be7f0d1ec4bcf8bee8a3d4f`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.422秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T182444.148090Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=708.797秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\007.txt`；SHA256=`d89365058cd84eb4c2c0ec29d7558ac03d13f3261990d53e3792a63a51e347f8`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\008.txt`；SHA256=`d7ff1db1485842f46c061272a03b86b18d7196d7804d86dbe43f7cd3b012237b`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=19.187秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\009.txt`；SHA256=`67be47351bb88793a81d8d92a17b6a8099373d4b284960b78ef0bc5a5794ae7d`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T182444.148090Z\engine.txt` SHA256=`169885087557e6fcb7a4927f968948fc066dc604fcdc4f9360616a87f12c148f`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 用户第二轮反馈与修复（2026-10-23）

用户意见：停顿应卡在攻击命中的那一瞬间，像刀砍中人被肉的阻力挡住、卡顿一下再继续；现在的卡肉感很怪，只有跳跃攻击时能感到下落停了一下。另报告 bug：跳跃攻击后角色直接向上飞出画面。

**卡肉感**：原因是第一轮的顿帧只冻结了玩家、靶子与计时，而攻击轨迹照常播放，刀光没有停在靶子上；站在地上攻击时玩家本来不动，几乎感觉不到，只有空中下落被冻住时才看得出。修改：`effects.gd` 新增 `hold(kind, seconds)`，冻结最新一条该类特效（不长龄、不移动），记录带 `held`；命中时对当前这一刀调用它，时长等于顿帧，于是刀光停在砍中的位置、与玩家和靶子一起停住，结束后从卡住处扫完。未命中的挥砍不会被卡住。

**向上飞出的 bug**：向下攻击在空中发出，但命中判定在发出后约 0.08 秒才检查；若这期间角色已落地，`on_floor` 已为真，命中弹起把竖直速度设为向上，而重力只在不在地面时生效，于是角色带着向上速度一直飞出画面。修复两处（任一处单独即可防住，两处一起更稳）：弹起时显式离地；每帧按位置与速度重新判断着地（在地面且不向上运动才算着地）。

回归（冒烟测试 86 → **92/0**）：

| 用例 | 内容 |
| --- | --- |
| 刀光卡住 | 命中那一刻这一刀被卡住；顿帧期间刀光年龄、玩家位置不变，靶子在顿帧中；顿帧结束后刀光继续扫；未命中的挥砍从不被卡住 |
| 落地前的向下攻击 | 跳起后在落地前约 30 像素按下“下 + 攻击”，仍命中并弹起；150 帧内最高只到地面上方约 105 像素，最后回到地面 |

验证：把两处修复都撤回（即原代码），落地用例失败，角色飞到地面上方 1900 像素，复现了用户遇到的 bug；只撤回其中一处，用例仍通过（另一处单独已能防住）。撤回刀光卡住，卡肉感 3 条用例全部失败。均按原字节恢复。

## 用户首轮反馈与调整（2026-10-23）

用户试玩后的意见（原话摘要）：喜欢风格 A 的攻击动作和攻击效果，但风格 B 更契合主题，希望把 A 的攻击动作与攻击效果融入 B，其他部分都用 B；卡肉感不明显；震动偏强，可削减一半左右，若能把卡肉感做得更明显，震动可以留给以后的重攻击或其他战斗效果。

据此在原型中调整（只改 `game/prototypes/EXP-005/`）：

| 项目 | 调整 |
| --- | --- |
| 风格 D · 融合（新增，默认） | 攻击轨迹与命中用 A 的画法，下面衬 B 的暖光（轨迹下一道 28 像素宽的低透明暖色弧，命中处一下暖光闪），飞溅的浅色由纸色改为珍珠白以贴近 B；其余 13 种特效全部用 B。`effects.gd` 新增 `look_for()`，绘制记录带 `look`（实际所用画法）与 `glow` |
| 顿帧 | 默认 0.07 → **0.12 秒**；`[` / `]` 在 0.04～0.20 秒间调整；顿帧期间被打中的靶子左右抖动 4 像素 |
| 震动 | 幅度减半（命中 6 → 3 像素，受击 10 → 5 像素）；**普通命中默认不震**（V 打开“普通命中也震动”以便对比），受击始终轻震 |

测试：冒烟测试 60 → **86/0**（四套风格全流程；新增：开场默认融合、长顿帧、普通命中不震；D 的轨迹与命中为 A 画法且带暖光、闪避 / 消耗 / 受击为 B 画法；`]` / `[` 调整与上下限；0.12 秒顿帧约 7 帧（实测 8 帧）、期间靶子抖动、结束后释放；普通命中不震、受击仍震且幅度不超过新上限）。截图新增 `style_d_*.png` 三张；真实渲染帧时间四套风格均在 60 帧上限内（D：八靶同时受击后平均 16.11 ms、峰值 ≤ 16.71 ms）。

请用户再次试玩确认融合效果与顿帧时长（可用 [ / ] 找到合适值后告知）。

## 改动（首次交付）

全部新增在 `game/prototypes/EXP-005/`，未改正式场景、共享脚本、`project.godot`、输入映射或存档：

| 文件 | 内容 |
| --- | --- |
| `effects.gd` | 特效层：15 种特效 × 3 套风格；每个特效是一条“种类、位置、寿命”记录，循环类（恢复中、无敌）直到停止；`drawn` 由各绘制调用的返回值组成 |
| `preview.gd`、`preview.tscn`、`run_preview.cmd` | 可玩场景：简化玩家、8 个靶子（带红色前摇警示）、可弹反的投射物、顿帧与震动开关、八靶同时受击测帧时间、HUD 示意 |
| `README.md` | 运行方式、操作、三套风格说明、测试命令 |
| `tests/smoke_test.gd` | 冒烟测试 60 项 |
| `tests/capture.gd`、`screenshots/` | 截图脚本与 9 张截图（每套风格三张：攻击、移动与资源、结果）；目录有 `.gdignore`，与 EXP-004 相同 |
| `tests/perf.gd` | 真实渲染下的帧时间测量 |

## 覆盖的特效

攻击轨迹（水平 / 上 / 下）、命中、靶子受击闪白、向下攻击弹起、投射物弹反、闪避（可能性充足）、透支闪避（可能性不足）、无敌期间（循环）、可能性消耗、可能性获得、恢复中（循环）、恢复完成、玩家受击、靶子击倒、复活。即卡上要求 1 的全部条目。

## 方案对比

| | A 墨迹飞溅 | B 光痕 | C 极简几何 |
| --- | --- | --- | --- |
| 笔触 | 纸色干笔弧线（四层宽度递减，带笔毛边）、朱红与纸色飞溅点、纸色笔触碎裂；闪避是横向墨痕，透支闪避是朱红断痕 | 白芯暖光弧线、星形闪光加光晕、发光残影、光点；击倒是碎光片 | 细线弧、小叉、方框收缩、虚线圈 |
| 与现有界面的关系 | 与正式 UI 的纸面墨线同源（`InkDraw`），在深色场景上用纸色而不是墨色 | 与 HUD 的金色光晕、可能性青色光同源 | 最接近现在的灰盒，几乎不改变画面 |
| 时长 | 最长（命中 0.40 秒，击倒 0.80 秒，复活 1.0 秒） | 中等（命中 0.30 秒） | 最短（命中 0.18 秒） |
| 画面占用 | 中：飞溅点散得开，多敌人同时受击时最热闹 | 中到大：光晕范围大，叠加时最亮 | 小：不遮挡任何东西 |
| 可读性 | 方向感最强（飞溅顺着打击方向） | 命中瞬间最醒目 | 最弱，快节奏时容易看漏 |
| 帧时间（真实渲染，八靶同时受击后 30 帧） | 平均 16.11 ms，峰值 ≤ 16.73 ms | 平均 16.11 ms，峰值 ≤ 16.72 ms | 平均 16.11 ms，峰值 ≤ 16.70 ms |

帧时间说明（按审查 N1 更正）：三次测量都在 60 帧垂直同步上限（约 16.7 ms）以内，与无特效时的基线相同；即**在这台机器、这个窗口设置下未观察到明显掉帧**，满足本原型的性能目标。由于限帧，不能由此推出各风格的实际开销大小；需要比较成本时再测未限帧或绘制耗时。headless 冒烟中的计时没有渲染，不作依据。

截图：`game/prototypes/EXP-005/screenshots/style_{a,b,c}_{strikes,movement,outcomes}.png`。

## 推荐（写在对比表之外）

**推荐 A 墨迹飞溅为主，命中瞬间借 B 的短暂光晕。** 理由：A 与已选定的样张二（纸面、墨线、朱红）是同一套语言，正式化后 HUD、对话、菜单与战斗特效风格一致；飞溅顺着打击方向，能把“打中了、往哪打的”说清楚。A 单独用时命中瞬间稍弱，在命中帧加一圈很短（约 0.1 秒）的暖光可以补上醒目度。C 太弱，适合作为“特效强度：低”的设置选项，而不是默认。

**顿帧与震动的建议**：

- **顿帧**：建议采用，命中时 0.06～0.08 秒（原型为 0.07 秒），只在玩家打中敌人时触发、受击不触发。正式化时须单独评估：顿帧期间游戏时钟是否计时、是否影响敌人前摇与判定的时间（原型只冻结模拟、特效继续播放）；暂停与日内时钟的规则不能因此改变。
- **屏幕震动**：建议采用但幅度小（原型命中 6 像素、受击 10 像素，0.2 秒衰减），并在设置里提供开关（属于 A-017 设置项之外的新增，需要用户同意后另登记）。

## 完成标准

1. **冒烟测试** `EXP005_SMOKE_TESTS` 60/0（`--fixed-fps 60`，真实按键事件，断言读 `drawn`）：三套风格各自——按 1 / 2 / 3 切换；J 攻击出轨迹、命中与受击闪白且可见；第三下击倒出爆散与获得；所有一次性特效按时结束、不留残余；K 闪避出残影与消耗；无敌期间显示并随之结束；P 后闪避变为朱红透支闪避；长按 L 出恢复循环、按满出完成且循环停止、中途松开只停循环不出完成；T 受击、Z 复活；空中向下攻击靶子出弹起；R 后攻击投射物出弹反。另：H / V 打开时命中冻结至少 3 帧并震动、关闭时都没有；警示层与 HUD 层在特效之上；两种分辨率下特效都在画面内、远离 HUD；G 八靶同时受击且记录帧时间。
2. **不遮挡**：靶子前摇警示画在比特效高一层（`z_index` 2 对 1），HUD 示意在 CanvasLayer 10；1920×1080 与 1280×720 下特效记录的位置都在画面内、离 HUD 区域 60 像素以外（同套件）。帧时间见上。
3. **截图与对比**：见上。
4. **现有测试**：原型不进入 G2 登记；full 见下。
5. **G4**：待用户（见下）。

## G2 + G3

在实现 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **94/94**（原型不登记为套件，数量不变），G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T122322.504565Z/`（不入库）。

过程说明：在 `5738176` 上的第一次 full（`20261023T121140.581165Z`）G2 94/94 通过，但 G3 的 `test_all_resource_references_resolve` 失败——截图脚本里写了字面的 `res://prototypes/EXP-005/screenshots/` 目录路径，资源引用检查要求它能解析到文件。改为与 EXP-004 相同、由脚本自身路径推出 `screenshots/`（`426f4b3`），G3 随即通过，截图重新生成；第一次运行不作证据。

冒烟测试：`Godot --headless --path game --fixed-fps 60 --script res://prototypes/EXP-005/tests/smoke_test.gd` → `EXP005_SMOKE_TESTS checks=60 failures=0`。

## G4（用户挑选）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" res://prototypes/EXP-005/preview.tscn
```

（也可以双击 `game/prototypes/EXP-005/run_preview.cmd`。）

- 1 / 2 / 3 切换风格；J 攻击、K 闪避、长按 L 恢复、P 切换可能性不足、R 投射物（攻击弹反）、T 受击、Z 复活、G 八靶同时受击。
- H / V 分别开关顿帧和屏幕震动，比较有无的手感。
- 请选定：风格（A / B / C，或组合，例如“A 加 B 的命中光”）；顿帧是否采用；震动是否采用。

## 说明与未决

- 正式化需要的数据（按审查 N2 更正）：弹反与击倒位置都可先从现有通道取得——弹反成功经 `PlayerCombat.hit_confirmed` 发出，可从 target 父节点读到投射物的 `reflected` 与位置；`defeated(reward)` 回调可在 `queue_free` 前读取实例位置。正式任务先评估复用，再决定是否增加更清晰的专用事件。
- 场景级特效（日期推进、最终倒计时、战场增援、Boss 专属演出）不在本原型范围，按卡片另行处理。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`426f4b3953ff563b59526b30bfbde822866dfe9d`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T12:23:22.505565+00:00；结束：2026-10-23T12:34:08.641893+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`828786fd49c1d3b27bb0712c3ee7d38febd18fa3`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`c21d1de781b14df27673301dbac02102ad0e272a6ac2ad88594b42b0dbc1c787`；工作区范围指纹（原始字节）：`ac4909d63e970b183a7f3de2152f94eb75abacb1372d4b74eb9b1dba52ea7952`。
全工作区指纹：`8068591eef85cfe5bd4274de5ec471be7c68924a9384828db7675f09c123dcb5`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\001.txt`；SHA256=`144afe936a5142ff94f61ec0219f72bd9e3ab3d88f962df91d35c26e3c36dc84`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T122322.504565Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=622.094秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\007.txt`；SHA256=`fbff6a3b04156331aa69e1544ca5ff3b7c7fca3741f68ec95ba2a423161a9a1c`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.359秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\008.txt`；SHA256=`6c3d39a0003dc5d6a948930c65c17830379b9094a66caa4fe7b13617f6194bae`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.828秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\009.txt`；SHA256=`b7435607dc2ca1511f38ef68efcec21c96a00a492f82f871993637722636ba3b`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T122322.504565Z\engine.txt` SHA256=`287cb9e53afd2e3613fefdd7f973a313eaa069a0d69e06c6df5f90a4d2b3452b`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

