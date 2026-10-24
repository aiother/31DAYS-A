# FX-001 第1轮审查

审查者：Codex｜日期：2026-10-24｜结论：**需修改：R1、R2（均 P2）**。未改 Claude 分支或实现，未合并 master；本分支只提交本审查记录。用户 G4 已通过且确认保留 0.10 秒，本审查不替用户改变该数值。

## 固定对象与范围

- 基线 `48bdf15d249ac44630c9229a4c195c5507f149f9`；实现 `cf30d1e34e4d67d80c2781a83add2115732673ef`；首次交付 `80003a709b592fe160085fe9bf1744031c191a47`；最终被审 `e4c41067e747ab45bc2e30ba3febbb82cf526183`。
- 自 `git switch --detach e4c41067e747ab45bc2e30ba3febbb82cf526183` 固定后建立 `codex/FX-001-review`。实现至最终交付只改 delivery.md 和任务卡首部；G4 补充提交本身也同步改了卡首部（不是只有 delivery.md），均是记录，无代码变化。
- 实现范围符合任务卡：新增 effects、测试/UID/验收与说明；player.tscn 挂导演，控制器和五类敌人增加冻结入口；placeholder_visual 删除视觉反馈，保留命中音；T2 只改 §14/§16，规划测试只加对应断言。未改旧断言、伤害、成本、攻击范围、AI 决策或存档。

## R1（P2）：同一次攻击先后命中两个目标会再次顿住玩家

位置：`game/effects/combat_effect_director.gd::_stop()` 与 `game/effects/hit_stop.gd::start()`；`test_combat_effects.gd::hit_stop_cases()` 只有同帧多目标。

`HitStop.start(player, seconds)` 仅防止“正在停住时”重启。第一次 0.10 秒结束后，同一刀仍可处于 ACTIVE；若另一目标此时首次进入判定，第二次 hit_confirmed 会再 start，玩家和刀光再次停止。这违背新写入的 T2 §14、接入说明和交付记录的“同一次攻击命中多个敌人只停一次”。任务卡对同帧的最低要求已满足，但实现及规格声称的同次攻击去重不成立。

**独立实证**：真实 enemy_lab / PlayerController / 两个 ColorlessEntity，真实 attack 输入和 60 FPS 物理帧。第一目标在玩家右侧 70；第二目标初始右侧 190，target 指向玩家、正常追击（仅夹具将投掷冷却设大，避免干扰），不在攻击途中移动其坐标。第一次命中后，后者在停住期间继续接近，恢复后被同一刀打中：

```text
first stop count=1 attackid=1 phase=2 remaining=0.1
released attackid=1 phase=2 remaining=0.1
delayed target health=8 stop count=2 attackid=1
```

另以第一停结束后才把第二目标放进有效段的窄探针得同样结果。原始日志/脚本（不入库）：`codexandclaude/runs/fx001-review-chasing-target.{gd,txt}`、`fx001-review-late-target.{gd,txt}`。

**请修改**：按玩家 `attack_id` 记录这一刀是否已让玩家/刀光顿过，第二目标仍各自获得其应有的顿帧与抖动，玩家与轨迹不再追加一次。补同帧与先后进入两种路径，断言同一 attack_id 的玩家停止总时长/次数不增加；下一刀仍正常开始新顿帧。不要只测正在停住时 start 返回 false。

## R2（P2）：关键颜色的错误外观仍能通过全部 38 项测试

位置：`game/effects/combat_effects.gd::_ghosts()`、`_swing()`；`test_combat_effects.gd::swing_cases()` / `player_cases()`。

目前 poor_dodge 只核对“记录种类是 poor_dodge，不是 dodge”，暖色底只核对 `glow.a > 0`。这些无法证明实际残影是朱红、刀光下衬是暖光。独立单点变异，每次单独进程、恢复原字节，没有 SCRIPT ERROR：

| 变异 | 结果 |
| --- | --- |
| `_ghosts()` 的实际 tint 从 `LIFE if poor else POSSIBILITY_GLOW` 改为恒为 `POSSIBILITY_GLOW`（透支残影变为普通青色；裂痕未改） | **38/0，存活** |
| `_swing()` 下衬传给 `_poly` 的颜色从 SUN 改为 LIFE（暖光变朱红） | **38/0，存活** |
| 不让命中目标进入 HitStop（复现已有目标不停变异） | 38 项中 3 项失败 |
| 普通命中调用 `_kick(3.0)`（复现已有普通命中震屏变异） | 38 项中 1 项失败 |

原实现颜色未见错误，但卡上要求的两个闪避外观与融合暖光缺少真实绘制回归，不应只靠名称/布尔字段放行。请从实际 `_glow` / `_dot` / `_poly` 返回的绘制参数记录并核对普通/透支残影、暖光色值；不要由 `kind` 或 `poor` 标签补色。保留存在性和三方向几何检查，并使上述两项变异失败。

结果与原始日志（不入库）：`codexandclaude/runs/fx001-review-mutations.json`、`fx001-review-mutant-*.txt`。

## 六条解释与取舍

1. **有效目标范围：接受。** 三类普通敌人与两 Boss 才对角色 start；投射物提前走 reflect 返回，非角色与友军不触发玩家 hit_confirmed 的角色顿帧。被击倒且立即移除时只剩玩家停住符合该解释。去重部分需按 R1 补齐。
2. **停住期间按键：总体接受。** tick(0) 不推进原动作时间，攻击进入现有缓冲；闪避即时取消攻击但阶段时间要等解除停止才走；跳跃记下后在控制器恢复时执行。没有用全局时间缩放或暂停树改变其他角色/时钟。现有测试覆盖攻击与跳跃，闪避路径建议另补（N1）。
3. **命中当帧速度保留：实现理由成立。** 不改 velocity、不调用 move_and_slide；目标硬直和下攻击弹起在停止后继续。建议把两者的停止前后速度/位移做成明确回归，当前“bounce 有画出”不足以独立证明速度保留（N1）。
4. **不用 set_physics_process：接受。** 角色自行提前 return，不覆盖会话启停权限或改写 is_physics_processing；子类/父类可重复调用而一帧只扣一次。与单色后撤/天人格挡的已有门禁相容。
5. **共享渐变光晕：接受。** 共享纹理及少量四边形不改变触发/生命周期；record 由真正 draw_texture_rect 的参数产生。性能数据标明硬件/分辨率/受限帧窗口，不把稳定 60 帧冒称精确 GPU 成本；用户已在该实现验收外观。未重新做主观并排截图，不冒称复现实现者的临时截图比较。
6. **gained 唯一来源：接受。** 没有余额差推断，信号的来源位置用于 gain；测试真实 gain 与余额直写后闪避两条路径，修复 SYS-010 观察且不新增玩法。

## SYS-011 合并点与非阻断建议

- 对 SYS-011 最新交付 `4ee5e698d3b6a14c671f376aa523412b9f3b96e6` 做只读 `git merge-tree --write-tree`，退出 0，无冲突（树 `db2c40d3fb350ae905a17aa7dc625d73e37da4ba`）。这不是合入 master 或联合运行证据。
- 试算树的 placeholder_visual 已同时删除旧命中音与旧视觉反馈；控制器保留 `jump_pressed` 新条件、停止后实际起跳分支内的 `GameAudio.emit_from(... player.jump ...)`。交付中的两条提醒成立。真正集成后仍须跑联合 full，不能用无文本冲突代替运行验证。
- **N1（非阻断）**：建议补真实最终战预算在顿帧中流逝、停住时闪避取消、击退/下攻击速度保留的断言。日内时钟实测通过，最终战由相同第三日时钟增量派生的解释在代码上成立；但当前 clock_case 尚未进入最终战，不能称独立覆盖两种计时。
- **N2（非阻断）**：用户关于以后攻速增益缩短顿帧的方向仅记录，不视为本卡批准新增增益系统或改变基础 0.10 秒；后续可由规划者登记待办。

## 独立检查与证据

- 编辑器重新导入通过；原新增专项 `COMBAT_EFFECTS_TESTS` **38/0**。
- 实际绘制坐标探针确认 CombatEffects 由于中间为普通 Node 的 EffectDirector，global_transform 为单位矩阵，世界坐标绘制没有重复叠加玩家位移；未把这一疑点作为问题报告。早期探针误用不存在的 `get_parent_item`，修正探针后重跑，未改源码。

- 验收入口独立无头自检：`FX001_ACCEPTANCE_TESTS` **14/0**；临时目录由入口自动清理。用户 G4 结果依据 e4c4106 中已有记录，不把此自检当作用户实机验收。
- 固定最终交付 SHA 的干净工作区独立 full --jobs 4：**G2 96/96、G3 109/109 + 67/67，通过，content_stable=True**。引擎报告 ERROR、WARNING、SCRIPT ERROR、ObjectDB 泄漏均 0。full 中新增专项仍为 38/0，相关玩家、敌人、Boss、时钟与战役等套件全部实际执行。摘要 `codexandclaude/runs/20261024T100540.108316Z/summary.json`。
- 上述通过不覆盖 R1 的追加场景或 R2 的存活变异；请修正并交付固定 SHA 复审，不直接合并。

变异结果 SHA256：`f3b907caacdc1c4ab90f5c3c8d547b5e8e478b6d4988642c2a7f300d8a626569`；真实追击探针 SHA256：`ec7afc8d06dfd1ec4b35610a09c67d2c153ec8e38d5396e64e25363804d19a2a`。

### full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`e4c41067e747ab45bc2e30ba3febbb82cf526183`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-24T10:05:40.109314+00:00；结束：2026-10-24T10:18:01.824040+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际96 / 预期96；完整=True；通过=True。
- G3:tests：实际109 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`9d347950e56a93ddb2ed6dfa4db84a285e439a47`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`65964b8a7fd60f60e7aa8d5cdc7644c69fe3673ad2c99824a4cb3e1c13e73d84`；工作区范围指纹（原始字节）：`14f80125ad93b3e0d1823874ce0e0c97a732d4a71051559b90e571b4aa9269b7`。
全工作区指纹：`9e50a474e92d9529e66a2f1aa6f7f9d73bdd9729ad11212e60bb6d56e23eb216`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\001.txt`；SHA256=`f87ea519e5baac683397e0d70e22c08dcb89762cc63ac6881a06e208936db9d2`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.063秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.406秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261024T100540.108316Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=722.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\007.txt`；SHA256=`d5ee724e2c5f2759aab7c3bd58814c209825a4737c0a7dcbdb8c0d19f1316fd9`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\008.txt`；SHA256=`5b2be3f1c758741744833b08f572aaf27abdd68320b83d1f5569205409ad4399`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=14.25秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\009.txt`；SHA256=`20c51d14859b49a672c85b5de589cef6dec332f496c485a2e13fbf2c331a6e84`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261024T100540.108316Z\engine.txt` SHA256=`9bb72afcaee7947b0aa0d63f33e2084428c0c9920c172f371d057a4a018d4e5e`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
