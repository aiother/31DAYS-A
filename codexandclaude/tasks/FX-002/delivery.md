# FX-002 交付记录：其余视觉特效

状态：复审通过（Codex `89d2a11`）；用户 G4 第 1 次提出外观修改，已改（`6f946ab`），待用户再次 G4 与 Codex 复核｜实现：Claude｜日期：2026-10-25

## 固定对象

- 基线：master `68e8a9993e1327a96720ad506eada8d9184cf33a`（PLN-002 合入后，含 SYS-012）。
- 实现提交：`2c9d96bd7ca776378cfd4d1006de7293dc5418e3`（分支 `claude/FX-002`）。本记录与任务卡首部状态另行提交，不改实现文件。
- 没有引用 DOC-010 分支。

## 改动

| 文件 | 改动 |
| --- | --- |
| `game/effects/combat_effects.gd` | 新增 5 种特效：`windup`（普通出招提示，循环）、`windup_heavy`（强力 / 重击 / Boss 出招提示，循环）、`boss_death`（1.2 秒）、`arrival_enemy` / `arrival_ally`（0.7 秒）。`spawn()` 增加可选 `size`（整体放大倍数，汇总记录带出）；新增 `stop_entry()`（结束单个循环）；被跟随的节点已释放时不再读它（原先会报 “previously freed instance”），循环特效随之结束 |
| `game/effects/combat_effect_director.gd` | 出招提示：无色 / 单色 / 天人接 `attack_started`（与 SYS-011 警示音同一信号）开始；每个物理帧核对前摇状态，前摇结束（进入判定、被打断、被击倒、被移除）即收；两场 Boss 没有该信号，由同一核对在进入前摇的那一帧开始。Boss 击败放 `boss_death`；增援入场见下。导演 `process_physics_priority = 200`，在敌人之后核对 |
| `colorless_visual.gd`、`monochrome_visual.gd`、`tian_visual.gd` | 删去灰盒前摇着色、方向线与强力弧；保留倒地、判定段、格挡、闪烁、冲刺等其余灰盒表现 |
| `parasite_boss.gd` | 删去前摇红圈（整个 `_draw`，只剩注释）；状态与时机不变 |
| `game/tests/test_enemy_cues.gd`（新增，首行登记） | 31 项，见“测试” |
| `game/tests/test_combat_effects.gd` | 只改一条：“全部有限特效 1 秒内结束”改为“在各自寿命（最长者）内结束”，因为 `boss_death` 为 1.2 秒；等待帧数按最长寿命计算，其余不变 |
| `game/tests/acceptance/fx002_cues.gd`（新增） | G4 验收入口 |
| `game/docs/combat_effects.md` | 触发表加 4 行；新增“出招提示的时机（FX-002）”与“日期推进、最终倒计时与低生命”两节 |

`overlook_boss.gd` 的落点地面标记保留：它表示“打在哪里”，不是“何时出招”，不属于被替换的前摇警示。

## 逐条对照任务卡要求

1. **敌人出招提示（G-07 视觉）**
   - 普通提示：暖色光晕 + 珍珠白环 + 沿出招方向的暖色短痕，跟随敌人、脉动。
   - 重提示：朱红光晕 + 两道朱红环 + 朱红短痕 + 朱红点，不含珍珠白；普通提示不含朱红。颜色差异由绘制记录断言（不由种类标签推断）。
   - 判定一致：单色看 `strong_attack`，天人看 `attack_kind == HEAVY`，两场 Boss 一律用重提示（Boss 每一击都重，与 SYS-011 中 Boss 统一使用 `enemy.windup` 并不冲突：音频不区分 Boss，视觉用重提示突出分量）。Boss 提示按 2.5 倍画在身体中心。
   - 时机：与音频同一物理帧开始（测试逐个比对帧号），前摇一结束就收。前摇时长与 AI 未动。
2. **Boss 击败**：两场 Boss 被击败时放 `boss_death`（2.5 倍、1.2 秒，朱红环 + 珍珠白环 + 18 片碎屑），不再放普通 `enemy_death`。胜利流程与存档未动。
3. **战场增援入场**：单位加入**已就绪**的战场房间时（新一波、最后一波友军、残留实体等）放入场特效——敌方朱红、友方青色；房间加载时就放好的单位不放。见“解释与取舍 1”。
4. **日期推进、最终倒计时、低生命**：UI-002 的正式 HUD 已有换日纸签与换日前 3 分钟提示、最终战倒计时（加速与朱红警示）、最后 1 点生命的画面边缘朱红脉动（`game/ui/hud/formal_hud.gd`）。这三项已满足 T6-D1，未重复做，只在 `combat_effects.md` 写明归属。
5. **文档**：已更新。

## 解释与取舍（审查请重点看）

1. **入场时序（T2 §11）**：T2 §11 写天人“入场特效结束后出现在战场”。本实现**没有改单位出现的时序**：单位在原来的时刻出现，入场特效与它同时开始（0.7 秒）；原有 1 秒波次预警不变。按任务卡要求 3，改时序须先与审查者确认，因此保留现状并在此提出。可选做法：（a）接受现状——预警 1 秒 + 入场特效已足够表达“出现”；（b）后续任务让单位在特效期间不可行动 / 不可被打，或延后 0.7 秒放入。实现者建议（a），T2 §11 的措辞在 BL-025 改写时一并对齐。
2. **Boss 提示由轮询开始**：两场 Boss 没有 `attack_started` 信号，SYS-011 也是在其状态切换处直接发声。导演在敌人之后核对（优先级 200），因此提示与警示音在同一物理帧，测试已证明；不给 Boss 加信号，避免动 Boss 脚本的状态部分。
3. **被移除敌人的提示**：两道保险——`CombatEffects` 在跟随对象释放时结束循环，导演也会清掉实例已失效的提示。变异“被移除敌人的提示继续”因此存活，属于等价变异（见下表）。

## 测试

`ENEMY_CUES_TESTS` 31/0，真实场景、真实 AI 或真实动作入口、60 帧物理：

- 无色：普通提示恰在真实前摇期间显示（逐帧比对，零错位），警示音与 `attack_started` 同帧；前摇被打断、前摇中被击倒、前摇中被释放，提示都随之消失、不报错。
- 单色：强力与普通各出一次招，强力为重提示、普通为普通提示，各自与自己的警示音同帧；重提示不画珍珠白、普通提示不画朱红；图元数量符合。
- 天人：经 `_start_attack(kind)` 触发轻击与重击，提示种类与 `enemy.windup.tian` / `_heavy` 一致且同帧。
- 两场 Boss：在会话同样的物理步内 `start_combat`，提示只在前摇期间出现、为重提示、2.5 倍、与警示音同帧；击败放 `boss_death`（比普通击倒更久、含朱红）且不放 `enemy_death`。
- 入场：真实 `FinalBattlefieldRoom`：加载时不放；`replace_wave()` 放敌方入场；最后一波 `_begin_wave()` 放友方入场。
- 有限特效全部按时结束，不留残余（FX-001 套件）。

验收入口自检 `FX002_ACCEPTANCE_TESTS` 14/0。

相关已有套件逐个复跑全部通过：combat_effects 49/0、audio_events 137/0、colorless 31/0、monochrome 45/0、tian 43/0、overlook_boss 48/0、parasite_boss 47/0、boss_ordinary 48/0、final_battle 29/0、final_retry 72/0、ten_rescue 58/0、character_animation 100/0、enemy_cards 42/0、cinematics 200/0、campaign 166/0、remnant_possibility 269/0。FX-001、SYS-011 的套件结果不变（FX-001 只有上表那一条按寿命等待的调整）。

### 变异

逐项只改一处，在独立的项目副本中跑本套件（不写工作区），结果 `codexandclaude/runs/fx002-mutations.json`（不入库）。全部语法有效：

| 变异 | 结果 |
| --- | --- |
| 强力 / 普通提示画成一样 | 8 项失败 |
| 提示不随前摇结束消失 | 10 项失败 |
| 提示比警示音晚一个物理帧开始 | 9 项失败 |
| Boss 击败只用普通击倒 | 4 项失败 |
| Boss 不轮询（只靠信号） | 4 项失败 |
| Boss 提示按普通大小画 | 2 项失败 |
| 重提示画成珍珠白 | 1 项失败 |
| 房间加载时的单位也放入场特效 | 1 项失败 |
| 被移除敌人的提示继续（只删特效层的结束） | 0 项失败（导演的冗余兜底使延后三帧采样仍通过；不是严格等价，见第1轮审查 N1） |

任务卡要求的 4 项（强 / 普通画成一样、不随前摇结束消失、与音频不同帧、Boss 击败只用普通击倒）都被拦下。开发中曾发现两处检查过松并已收紧：加载时不放入场的检查原先在检查前清了记录；重提示颜色原先只查“含朱红”，现在要求重提示不含珍珠白、普通提示不含朱红。

## 全量检查

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`2c9d96bd7ca776378cfd4d1006de7293dc5418e3`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T13:09:35.034470+00:00；结束：2026-10-25T13:21:02.863589+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际99 / 预期99；完整=True；通过=True。
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`c0854de1378c16cb2beb5e5ef85abc638341a684`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`0e4665b39e50bbe14dfc8f36d37713045fb70ad54edb793c3b789c823413c8c2`；工作区范围指纹（原始字节）：`b07875ce3492d906f0808d91441b7aef5d36098f0d432c65f23356addbf649e1`。
全工作区指纹：`1f2739dbb574e0ab1fb7d583613ec75eecbdf960fe7ac081f5d69ce6e164249f`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\001.txt`；SHA256=`1e49081127c484e2eeca4caa48015ef8eae88b0b2f095354e3812e1473e013d7`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.0秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261025T130935.034470Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=664.422秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\007.txt`；SHA256=`3ba95e0f974af4c379bb0294ae1c4e84a8a69a57db4e4daeba2402bb79926c23`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.156秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\008.txt`；SHA256=`2686c33d44fb88e071071e9a5276cd4fc375932246002226c9e857fe341e2d1d`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.406秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\009.txt`；SHA256=`3533978246f7e3581eef7711df8f7d5040aa848250466b4669b20dbd12446c19`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T130935.034470Z\engine.txt` SHA256=`9c580f6ccc462ef8214965dfbe5cf83763fa784e5479bac6d29e53ad14b0d156`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 用户 G4

入口：`game/tests/acceptance/fx002_cues.gd`（通用 G4 启动器，三个独立临时存档，关闭窗口自动清理）：

- 槽1 第1日第二间：向右遇到无色实体，看普通出招提示；
- 槽2 中心战场前（已救 10）：进入战场打天人与单色，看重击 / 强力提示与普通提示能否一眼分清；打完一波看下一波敌人的朱红入场与最后一波友军的青色入场；
- 槽3 寄生同伴者检查点：Boss 战，看 Boss 出招提示与击败爆散。

请看：出招提示是否易读、强弱是否分得清；Boss 击败是否够分量；增援入场是否合适（并请对“解释与取舍 1”的入场时序给出决定）。

## 第1轮审查修复（2026-10-25）

审查记录 [review.md](review.md)（Codex，`40ef4d2`，被审 `4ef254d`，已快进并入本分支）。R1～R3 均成立。修复提交 `59761103a2ddd4d3a563413a8a3de57e098df6b3`。

| 编号 | 问题 | 修复 | 回归 |
| --- | --- | --- | --- |
| R1 | 入场特效与单位同时出现，不符合 T2 §11“入场特效结束后出现在战场” | 采用审查建议的做法：战场波次的入场特效在**原有 1 秒预警内**播放——救场后的第 1 波（`RescueBattlefieldSession` 的 REINFORCEMENTS 预警）与波间预警后的第 2、3 波（含末波 4 名幸存者）。单位出现前 0.8 秒在各自落点开始，0.7 秒播完，单位出现时特效已结束，出现时不再补放。**出现时刻、AI、波次、预警时长都没有改**；两个战场 Room 只新增“下一波单位落在哪里”（与原放置共用同一位置函数）和“离下一波还有多久”两个只读入口 | 真实 `FinalBattlefieldRoom`：经 `advance_wave()` 的真实预警到 Room 自己的 `_begin_wave()`，第 2、3 波各断言：每个出现的单位（含末波友军）恰有一个入场特效在其落点；特效先于单位至少 42 帧开始；单位出现那一帧没有存活的入场特效；出现后不再补放。真实救场会话（`test_ten_rescue`）：REINFORCEMENTS 预警内 3 个入场特效全部结束后第 1 波才出现，位置一一对应 |
| R2 | FX-001 的“1 秒内结束”被改成按 `LIFE` 最大值等待，`revive` 改为 2 秒仍通过 | 测试里写死上限，不读被测的 `LIFE` 表：FX-001 的全部有限特效 1 秒、Boss 爆散 1.5 秒、入场 0.8 秒（须在 1 秒预警内播完）；逐帧记录每种特效最后存活的帧，逐种对照 | `revive` 2 秒、Boss 爆散 2 秒两个变异都被拦下 |
| R3 | Boss 击败与 Boss 提示的“更大”只比了 `size` 参数、寿命与颜色，没有比实际几何 | 绘制记录新增 `span`：本帧全部图元实际覆盖范围的边长（点、线、多边形按坐标，圆点与光晕按半径 / 光晕范围计入）。不改任何外观，`centroid` 计算不变 | Boss 爆散全寿命内最大 `span` ≥ 同套件真实普通击倒的 2 倍；Boss 提示最大 `span` ≥ 单色真实重提示的 2 倍。审查的三个变异（Boss 爆散画成普通击倒加一个点、重提示忽略 size、`BOSS_SIZE` 改 1.0）都被拦下 |

**没有预警的增援**（每波首名天人阵亡后的两批幸存者、保底实体、其他 Room 的波次）：没有可利用的提前量，仍在加入已运行的 Room 时当场播放。T2 §11 的“入场特效结束后出现”针对开始波次的天人战士；幸存者是“随后补充增援”，其他 Room 不在 T2 §11 内，因此不涉及规格差异。若用户希望这些也先播后出，需要延后出现时刻，属于改时序，须另行裁决。

**N1**：采纳。变异表中那一项改为“冗余兜底使延后三帧采样仍通过”，不再称等价；审查的细帧探针表明，只删特效层的收尾时会残留一个渲染间隙。当前实现两道清理都在。

`ENEMY_CUES_TESTS` 31 → **42/0**；`COMBAT_EFFECTS_TESTS` 49 → **50/0**；`TEN_RESCUE_TESTS` 58 → **59/0**；验收入口自检 14/0。相关套件复跑全部通过：final_battle 29/0、final_retry 72/0、audio_events 137/0、boss_ordinary 48/0、overlook_boss 48/0、parasite_boss 47/0、cinematics 200/0、ten_clear_presentation 17/0。

**变异**（17 项：本轮 9 项 + 原有 8 项重跑；每项只改一处，各自在独立项目副本中跑相关套件；结果 `codexandclaude/runs/fx002-r1-mutations.json`，不入库；全部语法有效）：

| 变异 | 结果 |
| --- | --- |
| [R1] 入场不提前播（提前量 0） | cues 4 项、ten_rescue 1 项失败 |
| [R1] 提前播过后单位出现时又补放一次 | cues 4 项失败 |
| [R1] 救场后第 1 波不提前播 | ten_rescue 1 项失败 |
| [R1] 提前播的位置偏离落点 | cues 2 项、ten_rescue 1 项失败 |
| [R2] `revive` 寿命 2 秒 | 2 项失败 |
| [R2] Boss 爆散寿命 2 秒 | 2 项失败 |
| [R3] Boss 爆散画成普通击倒加一个朱红点 | 2 项失败 |
| [R3] 重提示忽略 size | 2 项失败 |
| [R3] `BOSS_SIZE` 改 1.0 | 4 项失败 |
| 强力 / 普通提示画成一样 | 8 项失败 |
| 提示不随前摇结束消失 | 12 项失败 |
| 提示比警示音晚一个物理帧开始 | 9 项失败 |
| Boss 不轮询（只靠信号） | 4 项失败 |
| Boss 击败只用普通击倒 | 6 项失败 |
| 房间加载时的单位也放入场特效 | 28 项失败 |
| 重提示画成珍珠白 | 1 项失败 |
| 只删特效层对被移除敌人提示的收尾 | 0 项失败（冗余兜底，见 N1） |

全量检查（修复提交上）：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`59761103a2ddd4d3a563413a8a3de57e098df6b3`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T14:02:29.112226+00:00；结束：2026-10-25T14:13:56.068146+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际99 / 预期99；完整=True；通过=True。
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`4edd24fae0c3f074502140985ec7cb3feb99067b`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`28ac751b2b993215107f24ca76f636328fcbb8034316e1e217b213d3f90d3cbb`；工作区范围指纹（原始字节）：`1672ee9bc9f984d07b4a567a784be5f656bb2138ea29fcd17a895e54447687ef`。
全工作区指纹：`2d13af96254693fbd256d149205f0245168aedcbf510efa968f2d364f5530d11`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\001.txt`；SHA256=`e9976ae5d370a26acede363525bdd878be4d14bd66448ef55f09f36a0f3ec7d1`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261025T140229.112226Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=662.906秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\007.txt`；SHA256=`ab8f8610cbdda96fec34e0e749a5435fc887f45403a5dd42cf627555b4bb3c82`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.157秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\008.txt`；SHA256=`ed0aa94b3bcdc0cfc625efb9ceb2cd710711501298310b9fd8889616207d6bcf`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=19.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\009.txt`；SHA256=`dea41aa27039208f92b5835d3308d2c824e076273252c6317d16704f8455d51a`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T140229.112226Z\engine.txt` SHA256=`c8ea3f875f7030ab9dc08d95a86608e39be05521ed1cc361889b2fb687889c6d`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 用户 G4 第 1 次（2026-10-25）与外观修改

试玩复审通过的实现 `79d2115`。用户反馈（原话）：

> 为什么是复用的玩家攻击命中的效果？怪物应该有自己的攻击效果提示，入场特效不要跟攻击预警效果重复，而且boss出招提示的地方提示的攻击方位是错误的，包括boss死亡效果，应该是爆散效果而不是用那个攻击预警效果放大，做出差异化而且要符合敌人的特性

逐条处理（修改提交 `6f946abd3807ca0b4e28024ae3f1d8ae80c9c980`；只改外观与外观所需的读数，出招时机、强弱判定、入场时序、AI 都不变）：

| 反馈 | 原因 | 修改 |
| --- | --- | --- |
| 出招提示像玩家命中特效 | 原提示是“暖光晕 + 圈 + 笔划”，与玩家命中的暖光、珍珠白同一套 | 每个提示改为“眼部闪光（前摇内闪两次，T2 §14“闪烁”）+ 该敌人自己的出招标记”，标记随前摇进度展开；不再用暖光（SUN）。各敌人的样子见 `game/docs/combat_effects.md`：无色——灰白爪痕 / 投掷点线；单色——紫色冲刺箭头，强力为朱红三箭头加通道线；天人——连击每下一道金色斩痕，重击为朱红过顶弧线落到地面裂纹，远程为金色箭线；渴望俯视——会眯起、看向落点的“眼”、俯冲虚线与收拢的落点括号；寄生同伴者——嘴部肿囊与一轮几发就几条、伸向玩家的触须 |
| Boss 提示方位错误 | 导演把两场 Boss 的方向固定写成向下（`Vector2.DOWN`），提示又画在身体中心 | 导演每帧按 Boss 真实出招位置更新：渴望俯视用 `impact_x` 与地面高度（落点），寄生同伴者用 `_fire()` 的出射点与玩家胸口 |
| 入场特效与出招提示重复 | 原入场也是“光晕 + 收拢圈” | 敌方改为从地面撕开的墨色竖裂隙，友方改为落下的青色光柱与地面波纹；都没有眼部闪光 |
| Boss 死亡是放大的预警 | 原 `boss_death` 与重提示同一套圈与光晕 | 两场 Boss 各自的爆散：渴望俯视——闪白、朱红裂纹、墨色碎片带重力四散、墨烟；寄生同伴者——暗红触须甩开、血滴下落、被它吸走的可能性（青）向上逸出 |

导演为外观新增读取：敌人种类、攻击类型、前摇开始时的剩余时间、朝向、连击段数 / 一轮发数、出招落点或瞄准点（每物理帧更新）。绘制记录新增 `box` 与 `points`（测试用，只在读取时汇总）。

**回归**（`ENEMY_CUES_TESTS` 42 → **56/0**，其余套件不变：combat_effects 50/0、ten_rescue 59/0）：

- 无色提示只有灰白与墨色，不含朱红、暖光、单色紫、天人金，爪痕伸到出招方向 45 像素外；单色普通提示含紫色；天人普通提示为金色、重击只有朱红。
- 两场 Boss：前摇每一帧检查绘制出的几何——渴望俯视的俯冲虚线全部落在 Boss 到落点的线段上、落点括号以落点为中心；寄生同伴者的触须全部从真实出射点指向玩家（±0.4 弧度）。Boss 身上的标记按 Boss 大小绘制（渴望俯视的眼 ≥120 像素宽，寄生同伴者嘴部 ≥80 像素）。
- Boss 爆散：渴望俯视含墨色碎片、不含寄生同伴者的暗红与青色；寄生同伴者含暗红触须与青色逸出；两者都不用普通击倒的暖光；范围仍 ≥ 普通击倒 2 倍。
- 入场：敌方裂隙、友方光柱的高度都 ≥ 宽度 2 倍，且没有提示的珍珠白闪光。

**变异**（25 项，结果 `codexandclaude/runs/fx002-g4-mutations.json`，不入库）：

| 变异 | 结果 |
| --- | --- |
| [R1] 入场不提前播（提前量 0） | cues 4 项失败、ten_rescue 1 项失败 |
| [R1] 单位出现时又补放一次 | cues 4 项失败 |
| [R1] 救场后第 1 波不提前播 | ten_rescue 1 项失败 |
| [R1] 提前播的位置偏离落点 | cues 2 项失败、ten_rescue 1 项失败 |
| [R2] `revive` 寿命 2 秒 | combat_effects 2 项失败 |
| [R2] Boss 爆散寿命 2 秒 | combat_effects 2 项失败 |
| [R3] Boss 爆散画成普通击倒加一个点 | cues 6 项失败 |
| [R3] Boss 提示忽略大小 | cues 1 项失败 |
| [G4] 渴望俯视提示不对准落点 | cues 1 项失败 |
| [G4] 寄生同伴者提示不对准玩家 | cues 1 项失败 |
| [G4] 无色提示改回玩家命中外观 | cues 2 项失败 |
| [G4] 所有敌人共用一种提示 | cues 8 项失败 |
| [G4] 敌方入场画成重提示 | cues 1 项失败 |
| [G4] 友方入场画成提示 | cues 2 项失败 |
| [G4] Boss 死亡画成放大的重提示 | cues 3 项失败 |
| [G4] 两场 Boss 爆散相同 | cues 1 项失败 |
| [R3] `BOSS_SIZE` 改 1.0 | cues 2 项失败 |
| 强力 / 普通提示画成一样 | cues 11 项失败 |
| 提示不随前摇结束消失 | cues 10 项失败（冗余兜底，见第1轮审查 N1） |
| 提示比警示音晚一个物理帧 | cues 9 项失败 |
| Boss 不轮询（只靠信号） | cues 6 项失败 |
| Boss 击败只用普通击倒 | cues 8 项失败 |
| 房间加载时的单位也放入场特效 | cues 37 项失败 |
| 单色强力提示画成珍珠白 | cues 1 项失败 |
| 只删特效层对被移除敌人提示的收尾 | cues 0 项失败（冗余兜底，见第1轮审查 N1） |

全量检查（修改提交上）：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`6f946abd3807ca0b4e28024ae3f1d8ae80c9c980`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T15:12:47.269228+00:00；结束：2026-10-25T15:24:23.278212+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际99 / 预期99；完整=True；通过=True。
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`2d8163f88e3b4aa75402f1d1d32c23b6fa9360a8`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`a94812651eb2cb9251c7b720d5c67eb70a294c26a6a7566a9d3ed121ef83b766`；工作区范围指纹（原始字节）：`17ded86b115bf17f666a74e3dd22aa1147c110989cd5475fd799c8bf2520ec35`。
全工作区指纹：`70742f119f2362a70dcf589edac28d6019cb632602ce7a1fc43f8b6873e0f838`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\001.txt`；SHA256=`4be6a06f0ca18afdf6dd74b9f34c5524f26fdbecdb09d355709a17b341483418`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.329秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261025T151247.269228Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=671.813秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\007.txt`；SHA256=`7c2e2c68aaf683a8ade437e548103a502b1396da5921d984df43bacb261966ac`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.234秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\008.txt`；SHA256=`5f9b8901ac458440d96fa9ae66f07eda5dd3c2eadc061b32f67a614931d867b1`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=19.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\009.txt`；SHA256=`a6cc5d705ec964b7a54474a3b4c1a3df5cf0385411e8557206d21fb3e28d80c8`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T151247.269228Z\engine.txt` SHA256=`ed4d15a047299b498c6db01019c3ba4025950d993971ee1ec40de1cfd7917edf`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

请用户再做一次 G4（入口与槽位不变）。
