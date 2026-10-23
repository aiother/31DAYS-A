# EXP-005 第1轮审查

审查者：Codex｜日期：2026-10-23｜结论：**需修改**（R1、R2、R3，均 P2）。不修改 Claude 实现分支，不合并 master。用户风格挑选待进行，不把它当成本轮审查阻断项。

## 固定对象与边界

- 基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`。
- 实现：`426f4b3953ff563b59526b30bfbde822866dfe9d`（c520700、5738176、426f4b3）。
- 交付：`6dc664eff8be2607bed246baf4c3e8339774126a`，用 `git switch --detach` 固定。
- 实现到交付只有新增 delivery.md 与任务卡首部变化。基线到实现排除 `game/prototypes/EXP-005/` 后 diff 为空；没有修改正式场景、共享脚本、输入映射、存档或流水线。新脚本均带 UID，截图目录有 `.gdignore`。

## R1（P2）：绘制记录与断言不足以证明全部特效实际画出，方向也未覆盖

位置：`game/prototypes/EXP-005/effects.gd` 的 `_draw()`、`_enemy_hurt()`、`_revive()`、`_swing()`；`tests/smoke_test.gd:95-106,139-144,146-157`。

`_draw()` 不论效果函数返回什么，都给字典补上 kind / style / age / life / at 并加入 drawn。多数断言只检查记录存在，或检查这些从 entry 补上的字段。因此元数据存在不能证明画过东西。`_enemy_hurt()` 更是直接 draw_rect 后返回预先生成的 color，删掉绘制仍有相同记录；类似直接画矩形后填颜色、调用 void 绘制后另记颜色的分支也应一并检查。

独立单点变异：

| 变异 | 冒烟结果 |
| --- | --- |
| 只删 `_enemy_hurt()` 的实际 draw_rect，保留返回值 | **60/0，退出 0，存活**（三套靶子受击效果都不画仍通过） |
| `_revive()` 完全不绘制，只 `return {}` | **60/0，退出 0，存活** |
| `_swing()` 的方向角一律改成 0（所有轨迹水平） | **60/0，退出 0，存活** |

现有冒烟没有触发上击；下击只验证 bounce 条目，未核对实际挥砍方向。任务卡要求三种方向和每种特效的实画断言，这些变异不应通过。

建议：把用于断言的颜色与几何取自同一次绘制调用的返回值（矩形、光晕等补本地绘制 helper 即可，不改共享 UI-001）；空绘制不能靠外层补元数据变成有效画出记录。三套风格逐个验证各特效确实有可见图元；水平、上、下使用真实输入分别触发，并从实际轨迹点判断方向。无需引入像素测试，但不能只回显输入方向或条目名。上述三个变异应失败。

## R2（P2）：大部分 settle() 结果被丢弃，永不结束的复活仍通过

位置：`game/prototypes/EXP-005/tests/smoke_test.gd:121-172`（以及布局/性能部分的等待）；`effects.gd` 的 LIFE。

例如复活后的 `await settle()` 没有 check 返回值。超过等待上限会继续，下一套风格又 clear 掉残留，所以“每种按时结束、不残留”的完成标准没有被验证。

独立把 `LIFE["revive"]` 三套寿命都改为 INF，复活永不移除，仍 **60/0、退出 0**。这是与 R1 不同的结束条件缺口。

建议：对每个有限特效、每套风格的结束与残留做实际断言；所有作为通过条件的 settle 返回值必须被检查，不能靠切风格 clear 掩盖失败。使用独立的有限等待上限，避免从被测寿命取 INF 后共同错误。循环类继续验证松键、中断或对应状态结束后消失。保留复活永不结束的变异，修后应失败。

## R3（P2）：手柄不能触发卡中要求的全部特效

位置：`game/prototypes/EXP-005/preview.gd:85-113`，以及 README 操作表。

手柄分支只有 A 跳、X 攻击、B 闪避、Y 恢复、LB/RB 切风格。贫乏模式只由键盘 P 设置，投射物只由 R 产生，受击与复活只由 T/Z 触发；没有手柄可用的按钮或屏幕控件替代。靶子警示不会自行产生可供弹反的投射物。因此只用手柄无法演示贫乏闪避、弹反、玩家受击和复活，不满足任务卡要求 2 的“可用键盘与手柄触发上述动作”。

独立发送 Godot 全部 128 个按钮索引的真实 `InputEventJoypadButton`，结果包含核心动作，但缺 `poor_dodge / reflect / hurt / revive`，poor 标志始终 false、投射物数始终 0；再对照轴处理函数，摇杆也只负责移动与瞄准，没有这些操作的其他路径。现有冒烟只有键盘事件，不验证手柄。

建议：仅在原型内补必要手柄按钮，或可由手柄选择/确认的调试菜单，保留正式输入映射零改动；屏幕与 README 写明操作。用真实手柄按钮/轴事件补回归，让手柄确实走到上述四类特效；无需硬件连接或改正式系统。

## 非阻断建议

- **N1（性能结论）**：独立真实渲染复现未明显掉帧，符合本原型的性能目标；但在 60 FPS 限帧下，与空场相同不能推导“开销远小于一帧”。建议文案写“该硬件/窗口设置下未观察到明显掉帧”，需要比较成本时再测未限帧或 CPU/GPU 绘制耗时。`stress()` 在当帧设置 `_perf_last` 后 `_process` 即可能采第一条，空场与受击的采样起点也宜对齐。
- **N2（正式接口）**：没有专门的 reflected 信号是事实，但不必先断言一定要新增系统接口。`projectile_hurtbox.gd` 把 reflect 成功返回给 PlayerCombat，后者会发 `hit_confirmed(target, damage, impulse)`；接收方可从 target 父节点读取 ColorlessProjectile 的 reflected 与位置。敌人 defeated 回调也能在 queue_free 前读取绑定实例位置（交付已提到）。正式任务先评估复用现有通道，再决定是否增加更清晰的专用事件。

## 成立的部分与独立检查

- 原型严格隔离；模拟数据未连正式玩法；三个风格的笔触与寿命有实际差别。推荐段与中立对比表分开；顿帧/震动只作用模拟场景，正式化对时钟/判定的评估已明确留后续用户裁决。
- 绘制顺序：特效 z_index=1、警示=2，HUD 在 CanvasLayer 10；代码未让效果越到这些层之上。已查看入库截图，HUD 与提示可读；不把仅检查中心点的布局断言扩大解释为所有图元完整边界证明。
- 截图由脚本位置推导输出路径，`.gdignore` 隔离图片导入；交付保留首次 full 的 G3 失败与修正，没有冒称首次运行通过。
- 原始交付冒烟独立 **EXP005_SMOKE_TESTS 60/0**，无 ERROR/WARNING。原型检查通过不代表 R1/R2 的未检查行为已经获得证明。
- 为不干扰同时运行的固定交付 full，变异全部在忽略的 runs 下复制独立原型进行，只重定向脚本/场景路径；同一副本未变异基线 **60/0**。四个单点变异均 **60/0 存活**，没有 SCRIPT ERROR；从未修改被测交付工作树。原始结果 `codexandclaude/runs/exp005-mutations/results.json`，SHA256 `21280bd7bdb5893698f2da8f8851f294e770ccd78c08646ba68c9a3817ee73d2`。
- 手柄探针日志 `codexandclaude/runs/exp005-review-pad.txt`，SHA256 `20eb2a71e703b4b2eb79f9188f296839a1a36c4104abce63f7ca29c60e608857`；原冒烟日志 `exp005-review-smoke.txt`，SHA256 `d744d8823a3e3642b74b8f34ab0ab2c1d42726e78d64b50e8bb94753a5574a46`。

### 真实渲染帧时间

独立执行 `Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-005/tests/perf.gd`（有窗口、无 headless，脚本自行退出）。RTX 3060，OpenGL 3.3 Compatibility，驱动 617.42；保留脚本和设置服务的实际窗口行为，不将命令参数冒称为独立确认的物理像素尺寸。

| 风格 | 空场平均 | 八靶三轮平均 | 三轮最大峰值 |
| --- | --- | --- | --- |
| A | 16.67 ms | 16.11 / 16.11 / 16.11 ms | 16.74 ms |
| B | 16.67 ms | 16.11 / 16.11 / 16.11 ms | 16.76 ms |
| C | 16.67 ms | 16.11 / 16.11 / 16.11 ms | 16.68 ms |

日志 `codexandclaude/runs/exp005-review-perf.txt`，SHA256 `6dd163d6a3c2fbf44296acedbef27dbe80d556c4dc654af219d94bfcd1e0309a`。当前独立测量未发现明显掉帧，不将 headless 计时当作渲染性能。

### G2 + G3

按任务卡在固定交付 SHA、干净工作区独立执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**G2 94/94、G3 108/108 + 67/67 通过，content_stable=True**，引擎 ERROR / WARNING / ObjectDB 泄漏均 0。未沿用 Claude 的摘要。原型不登记到 G2，冒烟是上方单独命令。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`6dc664eff8be2607bed246baf4c3e8339774126a`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-23T18:02:22.543931+00:00；结束：2026-10-23T18:13:00.755879+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`2b333b142eb6a55d438a2488e0716d3d52582b8a`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`2bc79c6fbec896157d6a77c51b2f57a138864c9f1d62dc4404bf5fe005a5e7ff`；工作区范围指纹（原始字节）：`e4a4c77ad0f2c8e30a1a90884b0bda4a5f415cc8f6c85cd062b99dc9f9a1ae53`。
全工作区指纹：`24698d971d27ad681e2e3e7e11374fe559d45b7b1cb762a3a55add6547dcd356`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\001.txt`；SHA256=`11deb57baf517f06f8b69e6285d79a1bd5f8819ef2ff3a1bd60798f7abb797f9`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.219秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261023T180222.543931Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=622.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\007.txt`；SHA256=`9336857787036365246cadb5496f118d6562229acf43311a3aca7ad97a66adbe`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.156秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\008.txt`；SHA256=`ee2ea587761657c794d5586b99a21ccb8353f3bc3a9fcd342660e55290d6f4f8`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.969秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\009.txt`；SHA256=`794afe2dfdf1923c9ed0303ca0c15e69a8e4c7c5810d042107403cbca88f3687`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T180222.543931Z\engine.txt` SHA256=`3167e2f76263ad4aaa2adf3223b52c62e0caf8761cc10998cd40d6b9cab76292`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
