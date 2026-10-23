# SYS-010 第1轮审查

审查者：Claude｜日期：2026-10-23｜结论：**需修改**（R1、R2、R3，均 P2）。不合并 master。

## 固定对象与范围

- 基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`（第八批任务卡合入后的 master）。
- 实现：`bc03e8aefb852584da2f1ea7a5ced6240b162b4d`；交付：`f1fde4129e32e5a3af728988c2a5a321e50b54f5`（只新增 delivery.md、改任务卡首部）。审查分支 `claude/SYS-010-review` 从交付 SHA 建立，审查期间只新增本记录。
- 改动 19 个文件，均在卡上允许范围内：新增 `game/animation/`（状态投影、驱动组件、映射资源、占位与测试用资源）；`player_controller.gd`、`colorless_entity.gd` 各只加一个 `animation_state()`；`player.tscn`、`colorless_entity.tscn` 只在 VisualRoot 下挂 `Animator`；单色、天人、保底实体经继承获得；原视觉脚本零改动；新套件、无存档验收入口、文档。
- **不改玩法**核对：两处玩法脚本只新增只读方法；`CharacterAnimationState` 为纯函数（只读字段与 `Input`），`CharacterAnimator` 只写视觉子树、不连回玩法；新套件 100 次查询前后核对玩法字段。玩家、战斗、三类敌人、保底实体与战役套件结果不变（见 G1）。

## 已核对、成立的部分

- 状态划分覆盖卡上要求 1 的全部项：待机 / 步行 / 跑步 / 转身；起跳 → 上升 → 顶点 → 下落 → 落地 / 重落地；攻击按方向 × 连击段 × 前摇 / 判定 / 后摇；闪避分充足与不足；恢复循环；受击、倒地、消散、死亡、复活；三类敌人的待机、追击、攻击、硬直、死亡，单色与天人的 Motion 和招式。
- 起跳、普通落地、复活的短演出窗只在观察器里，没有写回玩法；顶点是采样窗，不改重力。
- 暂停门禁、缺资源回退、无效轨道回退、映射集中在资源里，均成立。
- 交付记录的四项变异与我在本记录中复跑的 11 项均被拦下（见下表）。

## 阻断问题

### R1（P2）：映射解析顺序“详细键优先、通用名次之”没有回归

位置：`game/animation/character_animation_map.gd:7`（`for key in [state.key, state.name]`）；`game/tests/test_character_animation.gd` 第 161～173 行的资源替换用例。

这是映射资源的核心契约（文档与交付记录都写明“详细键优先，通用名次之”），也是完成标准 2“替换某一状态的资源后只该状态改变”能成立的前提：正式资源会同时提供通用的 `attack` 与细分的 `attack.horizontal.1.windup` 等键。现有替换用例只用了通用名 `idle`，没有任何一个状态同时具备详细键和通用名。

**变异**：把解析顺序改为先通用名、后详细键（只改这一行），新套件 **77/0 存活**。此时只要资源里有通用的 `attack`，所有细分攻击动画都会被它盖掉。

请补一个用例：同一映射同时提供某状态的通用名与详细键（例如 `attack` 与 `attack.horizontal.1.windup`），断言该细分状态播放详细键的片段、其他未提供详细键的攻击阶段回落到通用名；必要时把用于测试的资源放在 `game/animation/tests/` 下。

### R2（P2）：单色敌人轻击 / 重击变体与实际招式的对应没有回归

位置：`character_animation_state.gd`（`variant += ".strong" if mono.strong_attack else ".light"`）；测试第 234 行只断言观察到的键集合中同时含 `attack.melee.light.windup` 与 `attack.melee.strong.windup`。

**变异**：把两个变体对调（`strong_attack` 为真时报告 `light`），新套件 **77/0 存活**——因为只检查两个键都出现过，没有检查出现时 `strong_attack` 的真实值。卡上要求 1 明确单色按 Attack 细分，正式资源会据此给轻重击不同姿态；对调后重击会播轻击动画。天人的招式对应（重击 / 远程对调）同类变异能被拦下（6 项失败），单色缺这一层。

请在采样时同时记录 `strong_attack`，断言 `strong` 键只在重击时出现、`light` 键只在轻击时出现。

### R3（P2）：驱动层声称的三项行为没有回归

位置：`game/animation/character_animator.gd`。交付记录“需要审查者留意”第 2、3 条与文档都把它们作为框架行为写明，但单点变异全部存活：

| 声称的行为 | 单点变异 | 新套件 |
| --- | --- | --- |
| 有限阶段按真实进度 `seek`（第 99～100 行） | 改为一律 `advance(delta)`，不再按进度定位 | 77/0 存活 |
| 换状态时还原上一段片段改过的视觉属性（第 81～84 行） | 去掉还原（只保留 `visual.transform = _rest`） | 77/0 存活 |
| 轨道属性只允许显示类白名单（第 54 行） | 删去白名单判断，任何属性都可写 | 77/0 存活 |

第一项决定正式攻击动画的前摇 / 判定 / 后摇能否与判定时机对齐（卡上“动画只读状态，判定时机仍由现有状态机决定”的落点）；第二项决定逐帧资源改了子节点 `frame`、`modulate` 等属性后换状态会不会残留；第三项是交付记录所说“视觉轨道安全边界”的一部分。另外“允许 `..` 父级路径”的变异虽被拦下，但靠的是运行时 SCRIPT ERROR 使套件无法产出标记，不是断言检出。

请为这四点各加确定性断言：①用一个有限阶段（例如攻击前摇）在已知进度时核对 `AnimationPlayer.current_animation_position` 等于 `progress × length`；②用一个会改子节点属性（例如 `PlaceholderSprite:frame` 或某个测试子节点的 `position`）的片段，切到别的状态后断言该属性已恢复；③④对含非白名单属性、含 `..` 路径的片段断言 `safe()` 为假并回退占位、且没有运行时错误。

## 非阻断说明

- **N1 朝向**：现有占位朝向靠 `Sprite2D.flip_h` 与绘制时的 `facing`，与驱动层不冲突。但驱动在切换状态时把 VisualRoot 的 transform 重置为初始值；若正式美术以翻转 VisualRoot 的 `scale.x` 表示朝向，会被冲掉。建议文档写明“朝向由资源接入任务在 VisualRoot 下的子节点处理，或由驱动按 `facing` 统一施加”，二选一。
- **N2 跑步判定**：玩家 `run` / `walk` 读的是当前是否按住 `run` 键，而不是控制器实际采用的跑步状态；被击退或剧情移动时按住跑键会显示成跑步。不影响本任务的完成标准，正式资源接入时可改为读控制器的实际速度档。
- **N3 证据来源**：交付记录的 full 在提交前的工作区运行（dirty=True，交付记录已如实说明不作复用来源）；本记录下方的 full 在固定交付 SHA、干净工作区上运行，可作为本轮证据。

## 独立检查

**G1**（交付 SHA，各套件按首行登记的 fixed_fps；无 SCRIPT ERROR、WARNING、ObjectDB 泄漏）：

| 套件 | 结果 |
| --- | --- |
| test_character_animation（60） | 77/0 |
| test_player（实时） | 29/0 |
| test_player_life（实时） | 33/0 |
| test_possibility（实时） | 41/0 |
| test_combat（实时） | 41/0 |
| test_combat_growth（实时） | 67/0 |
| test_combat_revision（实时） | 15/0 |
| test_colorless（实时） | 31/0 |
| test_monochrome（实时） | 45/0 |
| test_monochrome_room（实时） | 17/0 |
| test_ravine_monochrome（实时） | 21/0 |
| test_tian（实时） | 43/0 |
| test_tian_room（实时） | 24/0 |
| test_remnant_possibility（实时） | 269/0 |
| test_campaign（实时） | 166/0 |

验收入口自检 `sys010_animation.gd --self-test`：4/0。

**审查方变异**（逐项只改一处，跑新套件，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| 单色轻 / 重对调 | **存活**（R2） |
| 天人重击 / 远程对调 | 杀死，6 项失败 |
| 映射先通用名后详细键 | **存活**（R1） |
| 轨道允许 `..` 父级路径 | 套件因 SCRIPT ERROR 无标记退出（见 R3） |
| 轨道属性不限白名单 | **存活**（R3） |
| 不安全片段不回退占位 | 杀死，11 项失败 |
| 换状态不还原视觉属性 | **存活**（R3） |
| 玩家受击不报告 | 杀死，2 项失败 |
| 恢复报告为待机 | 杀死，1 项失败 |
| 跑步 / 步行对调 | 杀死，3 项失败 |
| 转身不报告 | 杀死，1 项失败 |
| 攻击上 / 下对调 | 杀死，4 项失败 |
| 敌人硬直报告为待机 | 杀死，3 项失败 |
| 起跳不报告 | 杀死，1 项失败 |
| 复活不报告 | 杀死，1 项失败 |
| 一律 `advance`、不按进度定位 | **存活**（R3） |

## 独立 full

在交付 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **95/95**，G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T093157.634892Z/`（不入库）。变异在 full 之前进行并已按原字节恢复，full 起点无源码差异。full 通过不抵消上面三处测试缺口。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`f1fde4129e32e5a3af728988c2a5a321e50b54f5`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T09:31:57.635884+00:00；结束：2026-10-23T09:43:13.203539+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际95 / 预期95；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`e2aacdc74b123b33483b5fbfbbdf6a12da0d2ae2`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`de7e64457b44f1fc5640fd94c2d42d7f7ef46082401fbb0439c0557971a030fe`；工作区范围指纹（原始字节）：`482432072f99727e616a35ee22ad60ffd2e4a9ccae6b8bbbec1d258e48dd8cbe`。
全工作区指纹：`243b70010bee8d187d44dcfe447caf8417dc67a86aea2251835a98ada92c0b1b`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\001.txt`；SHA256=`c31075853e5dc0c9ef6b2f820756f01fa345930a3642cf3e101e9538134f018c`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.0秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T093157.634892Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=651.719秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\007.txt`；SHA256=`c984eb6c88de28db939649ff7eb135938a78ba0fa27dc7b22855cdcaf37292f9`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\008.txt`；SHA256=`a28713ca7b265fbb4c20f4b171b9c7fd4f802e9d059a6491029232c87ebd0824`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.688秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\009.txt`；SHA256=`5578b5f02950f90fdd12046347d0a7c6430f2dd30bb896293d331cc986a2df7d`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T093157.634892Z\engine.txt` SHA256=`e12ef3b54b70c47a25bdcdefde32b856122a685b206229c7ae08c325cb0f66dc`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
