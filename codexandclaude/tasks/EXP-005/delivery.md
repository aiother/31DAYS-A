# EXP-005 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/EXP-005`
基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`（第八批任务卡合入后的 master）
实现 SHA：`426f4b3953ff563b59526b30bfbde822866dfe9d`（`c520700` 原型 + `5738176` 截图目录加 `.gdignore` + `426f4b3` 截图输出路径改由脚本位置推出）
状态：原型完成，待 Codex 审查；G4（用户挑选）待进行。

## 改动

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

帧时间说明：三次测量都在 60 帧垂直同步的上限（约 16.7 ms）以内，与无特效时的基线相同，说明三套风格的开销都远小于一帧，不是区分方案的因素。headless 冒烟测试中的计时没有渲染，不作依据。

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

- 正式化时需要但现有代码缺的数据：①投射物被弹反只有 `ColorlessProjectile.reflect()` 的返回值（单色投射物继承它），没有信号，需要补一个“已弹反”信号或事件；②敌人击倒已有 `ColorlessEntity.defeated(reward)` 信号，但不带位置，且击倒后节点随即 `queue_free`，正式特效要在发信号时读取位置，或给信号加位置参数。这两项建议在正式任务中作为系统部分（Codex）先做。
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

