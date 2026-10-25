# FX-002 第1轮审查

审查者：Codex｜日期：2026-10-25｜结论：**需修改：R1～R3（P2）**。N1 为非阻断的变异说明精度问题。未修改 Claude 实现，未修改规格，不合并 master；G4 仍待用户。

## 固定对象与范围

- 基线：`68e8a9993e1327a96720ad506eada8d9184cf33a`。
- 实现：`2c9d96bd7ca776378cfd4d1006de7293dc5418e3`；交付：`4ef254d8135cc321197ca2807a3519a5fbad9080`。
- 在独立 Codex 工作区以 `git switch --detach 4ef254d8135cc321197ca2807a3519a5fbad9080` 固定后审查与测试。实现到交付只有 delivery.md 和任务卡首部变化；实现无 DOC-010 内容。
- 代码范围与卡内目录一致，新增文件含 UID，新增套件首行已登记。全局观察挂接未改敌人状态、前摇时长、音频、单位出生或波次规则，但新增入场表现未满足现行 T2 的先后要求，见 R1。

## R1（P2）：同步出现不满足 T2 §11，不能由审查意见直接授权改规格

位置：`game/effects/combat_effect_director.gd:_added / _arrive`（54～73行），交付“解释与取舍 1”。

现行 T2 §11 明确天人“入场特效结束后出现在战场”。现在 ready 回调在真实单位已加入树之后才 spawn 0.7 秒入场特效，单位同步可见；`FinalBattlefieldRoom._begin_wave()` 继续在原时刻开启单位物理处理。测试只确认两帧后存在敌方入场特效及其朱红色，没有检查单位在特效结束前是否已经出现 / 行动。

作者如实说明没有改旧出生时序，这一点成立；但“没有改变旧逻辑”不等于新增特效满足已批准的表现顺序。任务卡要求先协商改时序，不是提前允许忽略 T2；协作规范也要求用户裁决规格差异。不能由审查者直接接受方案(a)，再让 BL-025 反向把 T2 改成实现现状。

**建议优先尝试**：利用既有1秒预警，在原单位出生时刻之前播完0.7秒入场效果，保持原出生 / AI / 波次时刻不变；以真实流程测试先后关系。若需要延后出生、临时不可行动 / 不可受击，或决定接受现在的同步出现，请明确列出差异交用户裁决，按批准结果补范围 / 规格 / 交付依据，不能自行落地。当前对(a)的意见是不予直接认定已满足本条。

## R2（P2）：FX-001 的旧有限寿命上限被同源等待放宽

位置：`game/tests/test_combat_effects.gd:477-481`。

新增 Boss burst 为1.2秒，原来“一秒内全部结束”的统一等待确实需要适配；但现在以被测 `CombatEffects.LIFE` 的最大值决定等待时间，不再保留旧 FX-001 的独立上限，也没有分别验证每种特效在自己的寿命结束。较短效果拖到最长效果结束才清理，同样可能通过。

独立单点变异只把原有 `revive` 寿命从0.86改成 **2.0秒**，新 FX-001 套件仍 **49/0**。其他实现不变；这超过旧测试的1秒边界，却因等待值也随被测配置变长而放行。恢复原文件后基线仍49/0。

请保留原 FX-001 有限效果的独立上限，单独为新 Boss burst / 入场效果验证相应上限与清理；不要从同一个可错误变化的 LIFE 表自动放宽整个验证窗口。“只改一条”的文字范围小，但当前验证力度下降，不能只凭计数不变认定合理。

## R3（P2）：Boss 击败“更大”和提示倍率缺少实际几何回归

位置：`game/tests/test_enemy_cues.gd:221-231`；`game/effects/combat_effects.gd:_draw / _windup_heavy / _boss_death`。

任务卡要求 Boss 击败效果比普通击倒更大、更久，外观从实际绘制核对。当前击败检查只看 boss_death 种类、寿命比 enemy_death 长及含朱红，没有比较真实几何范围。独立副本中，只把 `_boss_death()` 的绘制改成普通 `_enemy_death(e,t)` 再在中心画一个0.5像素朱红点，保留原 boss_death 名称、1.2秒寿命与记录。在相同归一化进度下图元轮廓与普通击倒相同，并未放大（只多一个中心微点），色值存在检查却能满足；副本基线 **31/0**，变异仍 **31/0**，均无解析 / 运行错误。

提示的大小检查也有同类缺口：断言比较 `rows[0]["size"]` 与 `CombatEffectDirector.BOSS_SIZE`，前者在 `_draw()` 直接由 `entry["size"]` 补入，后者也是 spawn 输入；都不是实际图元尺寸。只把 `_windup_heavy()` 的 k 改为1.0、保留 BOSS_SIZE=2.5与记录size=2.5，实际大号提示消失，仍31/0。把 BOSS_SIZE 常量改1.0也31/0。

请从记录型绘制辅助函数返回的真实点 / 范围等几何结果核对 Boss 击败相对普通击倒的大小，以及所声称的大号提示；不能只比 caller 的 size、kind、寿命或“含某色”。当前生产实现确实绘制了大号效果，本项是完成标准的回归缺口，不要求改变正确的外观。

## N1（非阻断）：移除清理变异有冗余兜底，但不是严格等价

作者删除特效层的 `age=INF` 后原套件31/0，可以复现；导演下一物理帧的失效实例清理确实会收尾。因此它不是“永远不收提示”的变异，说明有冗余是合理的。

但两道清理在不同回调阶段运行。审查探针使用真实敌人 AI 进入 WINDUP，在普通 `_process` 中、导演该物理帧已检查之后释放敌人；后置 `_process` 观察特效更新，下一物理帧在导演之前读取上次实际绘制记录：

| 版本 | 同一物理帧释放后 / 特效更新后的提示条目 | 下一物理帧前读到的提示绘制记录 |
| --- | --- | --- |
| 固定交付基线 | 0 | 0 |
| 仅删除特效层循环结束 | 1 | 1 |

释放与后置观察的物理帧号均为7，探针无脚本错误；差异是一个渲染间隙的提示残留。现有用例释放后等3帧才检查，错过该窗口。**当前原实现两道清理都在，探针显示正确清理，所以不把它列为生产缺陷。** 请将“等价变异”改为“冗余兜底使延后三帧采样仍通过”，或补更细采样后准确记录差异，不声称所有观察时点等价。

## 五项重点的其余结论

1. **同帧与结束路径**：无色 / 单色 / 天人使用 attack_started，SYS-011 与导演订阅同一信号；单色在发信号前确定 strong_attack，天人在发信号前确定 attack_kind。Boss 在状态切换处直接发声，导演物理优先级200在演员之后读状态。新套件对真实 WINDUP、判定转换、打断、死亡、释放及 Boss 轮询作检查；相关时机变异被拦下，未见前摇状态或AI改变。移除窗口的说明精度见 N1。
2. **强弱 / Boss**：单色 strong_attack、天人 HEAVY 与 SYS-011 完全同源。Boss 的 generic enemy.windup 不表示“普通轻击”，而是其原有统一音频事件；全部用大号重视觉提示，不要求新增音频分槽，本取舍可接受。真实几何大小回归仍须补 R3。
3. **入场**：意见见 R1，暂不能接受“以后改写 T2 对齐当前实现”作为完成依据。
4. **FX-001 断言**：增加1.2秒效果需要适配合理，但新的全局最大值等待不够，见 R2。
5. **等价变异**：三帧后清理冗余成立，严格等价不成立，见 N1。

保留渴望俯视落点标记合理：它表示落点位置，非被替换的前摇提示。日期推进、最终倒计时与低生命交给既有 FormalHud，未重复世界效果，符合卡上允许的核对后说明。

## 独立检查与变异

固定交付核心专项：ENEMY_CUES **31/0**、COMBAT_EFFECTS **49/0**、AUDIO_EVENTS **137/0**；验收入口自检 **FX002_ACCEPTANCE_TESTS 14/0**。自检使用临时存档，不代表用户 G4 已通过。

基线及变异均真实 Godot 物理 / 绘制帧；临时源改动运行后按原始字节恢复，没有修改 Claude 分支。结果 `codexandclaude/runs/fx002-review-mutations.json`、`fx002-review-probes.json`、`fx002-review-shape-probe.json`，各日志 `fx002-review-*.txt`（本工作区忽略文件）。

| 变异 | 新套件 / 旧套件结果 |
| --- | --- |
| 重提示改用普通绘制 | 31项，2失败 |
| 不随前摇结束停止 | 31项，11失败 |
| 提示延后一物理帧 | 31项，9失败 |
| Boss 只放普通击倒 | 31项，4失败 |
| Boss 不轮询 | 31项，4失败 |
| 重提示光晕误用珍珠白 | 31项，1失败 |
| 加载时也放入场效果 | 31项，1失败 |
| 旧 revive 延到2秒 | **49/0，存活（R2）** |
| Boss 击败退回普通几何，仅中心留微小朱红点 | **独立副本31/0，存活（R3）** |
| Boss 提示实际绘制忽略倍率 | **31/0，存活（R3）** |
| BOSS_SIZE 常量改1.0 | 31/0，同源预期也跟变 |
| 仅删特效层释放清理 | 31/0；细帧探针发现短暂残留（N1） |

## 独立 full

固定交付 SHA 上 G2 **99/99**、G3 **110/110 + 67/67** 全部通过，起止干净、content_stable=True，WARNING / ObjectDB 泄漏 0。此分支不含 DOC-010，故 Python tests 为110而非111。完整门禁通过不替代上述规格及测试语义问题。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`4ef254d8135cc321197ca2807a3519a5fbad9080`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-25T13:34:07.577690+00:00；结束：2026-10-25T13:45:18.879970+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际99 / 预期99；完整=True；通过=True。
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`b90c33cab1c359ada4b4bbc42fe1dd1803288615`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`91613de60c0ae3845245c0db7de00339d0636a34ab4ab6be15a36756bba9a3b6`；工作区范围指纹（原始字节）：`09301690a79d8aa7d8f27fce92beaebea960da980c61854c88039f7cc07d1a71`。
全工作区指纹：`a2aa650196e71a073a98cda7f3c341ee1f2f1050d5337298fe9dcfd94a9616a8`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\001.txt`；SHA256=`17f2ad03343757f18b5343b78e729ae55bebb0684107bec49da3a869195afb7f`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261025T133407.577690Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=656.454秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\007.txt`；SHA256=`40fd48d6f5d31ae80a70a822daeb086f77c91f48fd460125193dcafc77d6aed7`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=2.984秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\008.txt`；SHA256=`79d6586149232c8a44999a7d91d37b3983317fcbcb40efeb8e667587bbcd03af`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.453秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\009.txt`；SHA256=`facddf748bd6da9f95967f99036078f004b7fa6a90c8bbf374cff4105f9fcd54`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T133407.577690Z\engine.txt` SHA256=`4accb811b632ad4f3df1ed88c2b3e590aea8ae6ce67529a35af38e314c01a61b`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


审查记录只新增本文件；提交后另跑 G3，结果随最终回报。等待 R1 的规格差异处理及 R2 / R3 修订，不合并 master。
