# FX-001 交付记录：正式战斗反馈特效

状态：已交付，待 Codex 审查；用户 G4 通过（2026-10-24，保持 0.10 秒）｜实现：Claude｜日期：2026-10-24

## 固定对象

- 基线：master `48bdf15d249ac44630c9229a4c195c5507f149f9`（第九批规划合入后）。
- 实现提交：`cf30d1e34e4d67d80c2781a83add2115732673ef`（分支 `claude/FX-001`）。本记录与任务卡首部状态另行提交，不改实现文件。
- 没有引用 SYS-011 分支；音效不在本任务内。

## 改动

| 文件 | 改动 |
| --- | --- |
| `game/effects/combat_effects.gd`（新增，`CombatEffects`） | 按 EXP-005 定稿风格 D 画全部特效：攻击轨迹与命中用墨迹飞溅、下衬暖光、命中暖光闪、珍珠白飞溅；其余用光痕。画法自原型 `effects.gd` 移植（只保留 D 用到的画法）。所有图元经记录型辅助函数绘制；`drawn` 只在被读取时汇总（见“性能”） |
| `game/effects/combat_effect_director.gd`（新增，`CombatEffectDirector`） | 挂在 `Player/EffectDirector`。读真实信号与状态放特效、发起顿帧、震屏、目标抖动；不改伤害、成本、AI |
| `game/effects/hit_stop.gd`（新增，`HitStop`） | 顿帧计数：被顿住的角色在自己的物理步开头跳过本帧；一帧内只减一次（子类与父类都调用时不重复） |
| `game/effects/combat_effect_config.gd` + `default_combat_effects.tres`（新增） | 可调参数集中处：顿帧 0.10 秒、抖动 4 像素、普通命中震动 0、受击震动 5 像素、震动 0.2 秒 |
| `game/player/player.tscn` | 增加 `EffectDirector` 节点 |
| `game/player/player_controller.gd` | 物理步开头加顿帧判断；停住期间的按键处理（`_held_step()`）；跳跃改读 `jump_pressed`（含停住期间按下的跳跃）。其余分支不变 |
| `colorless_entity.gd`、`monochrome_entity.gd`、`tian_warrior.gd`、`overlook_boss.gd`、`parasite_boss.gd` | 各自物理步开头加一行 `if HitStop.held(self, delta): return`，其余不变 |
| `game/player/placeholder_visual.gd` | 去掉被取代的灰盒反馈：获得可能性绿色扩散圈（及 `_last_balance` 推断）、闪避与恢复整体着色、攻击判定框矩形。保留受击变红、保护期闪烁、落地反馈、倒地与复活动作；命中音 `_hit_sound` 未动（留给 SYS-011） |
| `Words/T2_战斗系统.md` | §14 补写“命中顿帧”“屏幕震动”两条；§16 变更记录加一行（来源：用户定稿 EXP-005） |
| `tests/test_planning_documents.py` | 只在 T2 现行版测试中加 §14 的 7 条断言 |
| `game/tests/test_combat_effects.gd`（新增，首行登记） | 38 项，见“测试” |
| `game/tests/acceptance/fx001_effects.gd`（新增） | G4 验收入口（三个独立临时存档） |
| `game/docs/combat_effects.md`（新增） | 特效清单与触发、顿帧与震动规则和配置入口、新增角色如何接入顿帧、如何换成美术资源 |

旧测试与旧断言没有修改。

## 逐条对照任务卡要求

1. **特效清单**：攻击轨迹（三方向、两段连击、跑攻同一画法，跟随玩家）、命中、下攻击弹起、投射物弹反、闪避与透支闪避、无敌（循环）、可能性消耗、可能性获得（画在来源位置）、恢复中（循环）与完成、玩家受击、敌人受击、敌人击倒、复活，共 15 种。可能性不足：HUD 的发红（A-018）已表达，世界里不再重复画；透支闪避本身用朱红残影。
2. **顿帧**：
   - 普通攻击被敌人受击区接受（`hit_confirmed`）时，玩家与该敌人各开始 0.10 秒；同一次攻击命中多个敌人，玩家只停一次，每个被命中的敌人各停一次；未命中不停。
   - 停住期间角色跳过自己的物理步：身体与全部计时冻结，结束后从原处继续。测试量得：命中的一次攻击正好比未命中长 6 帧（60 帧/秒），目标硬直 18 帧照常走完（共 24 帧）。
   - 刀光停在命中处、目标原地抖动 4 像素，结束后放回原位。
   - 其他敌人、友军、投掷物照常；日内时钟照常（测试在真实会话中量得停住 7 帧内时钟走了 0.117 秒）；最终战计时由同一处会话计时派生（`FinalBattleSession._clock_tick` 中 `FinalClock.tick` 取 `DayClock.tick` 的第三日增量），因此同样不受影响。暂停菜单打开时没有物理帧，顿帧一并冻结（测试证明）。
3. **屏幕震动**：普通命中不震（配置 0）；玩家受击震 5 像素、0.2 秒衰减，偏移长度始终不超过设定值，结束时回到原值。入口与幅度集中在配置资源；没有加设置开关。
4. **替换灰盒反馈**：见改动表。受击变红与保护期闪烁保留；另外受击 / 复活保护期间也显示无敌光晕，可读性不降。
5. **规格同步**：T2 §14 与 §16 已写。
6. **文档**：`game/docs/combat_effects.md`。

## 解释与取舍（审查请重点看）

1. **“有效目标”**：以玩家攻击被敌人受击区接受为准，限于三类普通敌人与两场 Boss。投射物弹反、碎石堆、训练靶等非角色目标不停；友军命中敌人也不触发顿帧（任务卡只写普通攻击）。命中即击杀时同样停（目标若被立即移除，只有玩家停）。
2. **停住期间的按键**：任务卡要求“动作计时冻结，不缩短也不重复”，同时不能吞掉玩家输入。做法：
   - 攻击：照常进入攻击缓冲；因为停住期间攻击时间不走，效果等同于在命中那一刻按下（测试证明缓冲成立、阶段剩余时间不变）。两段连击的 0.5 秒窗口按攻击时间计，停住期间不计入，连击照常衔接（测试证明）。
   - 闪避：立即生效（取消攻击，T2 §2 允许闪避取消攻击），停止结束后执行。
   - 跳跃：记下，停止结束后的第一帧执行（测试证明）。
3. **命中当帧设下的速度**（击退、下攻击弹起）保留到停止结束后生效，不丢失。
4. **敌人的反应**：顿帧不改 `set_physics_process`（会话有多处用它控制敌人，混用会互相覆盖），所以单色的后撤闪避、天人的格挡这些依赖 `is_physics_processing()` 的判断不受影响。
5. **光晕画法**：原型的光晕是 UI-001 的 16 层叠圆。实测 8 个敌人同时被击倒（每个命中、受击、击倒、获得共 32 个特效）时，平均帧时间从 16.7 毫秒升到 19.8 毫秒、95 分位 28.8 毫秒，主要是叠圆的填充开销。改为一张共享径向渐变贴图、每个光晕一个四边形，衰减曲线按 16 层叠加的透明度调过。同时把 `drawn` 汇总改为读取时才计算。把原型风格 D 与正式实现在同一寿命进度下逐个并排截图对照（临时脚本，未入库），看不出风格差异。
6. **获得特效只认 `gained` 信号**，不再像灰盒那样按余额差推断；余额被直接赋值（如验收入口）后闪避不会再出现获得光圈。这修掉了 SYS-010 G4 时用户看到的现象。

## 测试

`COMBAT_EFFECTS_TESTS` 38/0，真实 `enemy_lab` 场景与 `final_battle_session`、真实输入（`Input.action_press`）、60 帧物理：

- **触发**：水平 / 上（W）/ 空中下（S）攻击按实际轨迹重心判断方向；融合风格的暖光底存在；命中、敌人受击、弹反、下攻击弹起、击倒、受击（真实敌人近战）、闪避、透支闪避、无敌、消耗、获得（位置等于来源）、恢复循环与完成、中断恢复只收循环、复活；每种特效都画出真实图元；全部有限特效 1 秒内结束、不留残余。
- **顿帧**：未命中不停；命中只停一次；攻击正好长 6 帧；目标硬直不缩短；刀光被定住；目标抖动且停后仍在硬直中就回到原位；未被命中的敌人 6 帧中 6 帧都在移动；两个目标同一刀只停玩家一次、两者都停；暂停冻结顿帧；停住期间按攻击被缓冲且攻击时间不走；之后的连击照常；停住期间按跳跃随后起跳；真实会话中日内时钟照常走。
- **震动**：普通命中相机偏移始终为零且无震动记录；受击震动峰值不超过 5 像素（4.58）；结束后归零。
- 配置值等于定稿；玩家外观不再有灰盒奖励光圈。

验收入口自检 `FX001_ACCEPTANCE_TESTS` 14/0（无存档以外的写入）。

相关已有套件在实现上逐个复跑全部通过（玩家、战斗、可能性、生命、三类敌人与各自房间、两场 Boss、Boss 杂兵、敌人打断、近战接近、四个平台追击、战斗成长、战斗修订、敌人介绍卡、角色动画）；全量见下。

### 变异

逐项只改一处，在独立的项目副本中跑本套件（不写工作区），结果 `codexandclaude/runs/fx001-mutations.json`（不入库）。全部语法有效：

| 变异 | 结果 |
| --- | --- |
| 未命中也顿帧（攻击开始即停） | 5 项失败 |
| 每命中一个目标玩家就停一次 | 1 项失败 |
| 顿帧期间日内时钟停走 | 1 项失败 |
| 顿帧时所有敌人都停 | 1 项失败 |
| 普通命中也震屏（配置 3） | 2 项失败 |
| 按余额差推断获得（灰盒逻辑） | 2 项失败 |
| 目标抖动后不放回原位 | 1 项失败 |
| 刀光不被定住 | 1 项失败 |
| 停住期间按的跳跃被丢弃 | 1 项失败 |
| 受击震动加倍（10 像素） | 2 项失败 |
| 中断的恢复也放完成特效 | 1 项失败 |
| 目标不停（只停玩家） | 2 项失败 |

任务卡要求的 6 项（未命中也顿帧、多目标停多次、时钟停走、其他敌人也停、普通命中震屏、余额直接赋值误放获得光圈）都在其中。开发中曾有两项变异存活（目标不放回原位、相机不复位）：前者因为测试只在硬直结束后检查（那时动画层会复位外观），已改为停止后 3 帧、仍在硬直中检查；后者是冗余代码（衰减到 0 时偏移本来就回到原值），已删掉那两行冗余复位，并换成“受击震动加倍”变异。

## 性能

测量条件：这台机器、1280×720 窗口、垂直同步开（上限 60 帧 / 16.7 毫秒），`enemy_lab` 场景，GUI 版 Godot 4.7.2。每组生成后量 40 帧：

| 场景 | 平均 | 95 分位 | 最大 |
| --- | --- | --- | --- |
| 无特效基线（240 帧） | 16.67 | 16.79 | 17.05 |
| 8 个敌人同时击倒（32 个特效） | 16.66 | 16.80 | 16.82 |
| 15 种各一个 | 16.66 | 16.77 | 16.78 |
| 13 种有限特效各 8 个（104 个，极端） | 15.87 | 16.89 | 17.03 |

单位毫秒。在该硬件与窗口设置下未观察到掉帧；受限帧所限，不能据此比较各特效的实际开销。

## 与 SYS-011 合并时注意

- `placeholder_visual.gd`：本任务删的是奖励圈、着色、判定框；SYS-011 删的是命中音。两处改动在 `_ready()` 中相邻，后合入的一方可能需要手工合并：保留双方的删除即可。
- `player_controller.gd`：本任务把跳跃条件改为 `if jump_pressed and not _jump_consumed ...`；SYS-011 在同一分支里加了一行起跳音。合并时保留新条件和那一行音效调用。另外起跳音应在实际起跳时发出：停住期间按下的跳跃在停止后第一帧才执行，音效也随之在那一帧发出，这正是想要的。

## 用户 G4

入口：`game/tests/acceptance/fx001_effects.gd`（通用 G4 启动器，三个独立临时存档，关闭窗口自动清理）：

- 槽1 第1日第二间：向右遇到无色实体；
- 槽2 中心战场前（未救 10）：进入战场打天人与单色；
- 槽3 寄生同伴者检查点：Boss 战。

请看：普通攻击命中时“刀被卡住”约 0.1 秒（玩家与目标同停、目标抖动、刀光停在命中处后扫完），没打中不卡；普通命中不震屏，受击轻震；闪避（可能性不足时为朱红残影）、恢复、获得可能性、击倒、复活都有特效；满可能性后闪避不再出现获得光圈；暂停时特效与顿帧一起停住。手感应与 EXP-005 定稿一致。

## 用户 G4（2026-10-24）

结论：**通过，保持 0.10 秒**。

- 第 1 次试玩（0.10 秒，实现 `cf30d1e`）：用户反馈“卡肉感稍稍重了一点……整体感受下来还可以”。
- 第 2 次试玩（临时把配置改为 0.08 秒，未提交，试玩后已恢复）：用户反馈“舒服了非常多”。
- 用户决定：“先用 0.10s 的这个数值状态，因为……完整版会出现一些增加攻击速度手感的增益玩法，我们需要为这个玩法保留一个提高窗口”。即基础顿帧保持 0.10 秒，以后的攻速类增益可以把顿帧缩短（例如到 0.08 秒）来体现手感提升。

因此实现、T2 §14 与测试都保持 0.10 秒，不做改动。“攻速增益可缩短顿帧”是以后的玩法方向，不在 V0.1 规格内；建议下次规划刷新时登记待办（顿帧时长已集中在 `CombatEffectConfig.hit_stop_seconds`，增益接入时只需按角色状态取不同时长）。

## 检查

在实现 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **96/96**（新增本任务套件，基线 95），G3 **109/109 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处；本任务套件 38/0。摘要 `codexandclaude/runs/20261024T075511.593290Z/`（不入库）。变异与性能测量都在 full 之前、在独立副本或临时脚本中进行，full 起点无源码差异。

<!-- full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`cf30d1e34e4d67d80c2781a83add2115732673ef`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-24T07:55:11.594289+00:00；结束：2026-10-24T08:06:55.629254+00:00。

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

提交树：`7f387547d495a2576c7a110049748ecea3e13af1`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`442fd34b8dae925875b59c8e5e3fa0f9d13624a760bcb335017c8e982831f5e1`；工作区范围指纹（原始字节）：`bf66efabee81c5b7afa22b1813a280620f5eda84339a107ee508179684d6e6af`。
全工作区指纹：`296927bb378b8f2b275bf24b6b1a7fd3e137760fbaa85b34faba9d135a84497f`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\001.txt`；SHA256=`8f1fc2546c1aa7210a09c207da5542c490da804b46b77f665feffcda77f25493`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261024T075511.593290Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=680.563秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\007.txt`；SHA256=`49db64ffbfd1638f9174c6eccefc3e451c800b693a0902e05be41a84e9e80a2d`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\008.txt`；SHA256=`65cdf15aed7c6012de65494d54b0bff52909f8eb68cb15b611918f5d22b0ee3a`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.078秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\009.txt`；SHA256=`c37c93a61bec5d59a23e5dfa957886f4f708612da4ffd82bf61bb27eb2b128b2`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261024T075511.593290Z\engine.txt` SHA256=`19eccf4640d54e83e43c48a257a32d0091081c664cac56bbaef9270b104d814b`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
