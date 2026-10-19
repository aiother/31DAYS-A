# SYS-002 交付记录

实现者：Codex｜日期：2026-10-19｜结论：实现及自动验证完成，待 Claude 独立审查，G4 未进行，未合入 master。

- 基线：`fdfc4c2b3eff199c9234af6f3103a04de05db93e`，包含 SYS-001 固定审查提交、用户 G4 与 master 全量验证证据，SYS-001 任务卡已完成。
- 实现 SHA：`87b0dbeadb3cf768c7c1eae936c819cc24289b22`。
- 分支：`codex/SYS-002`；工作区：`D:/31days/codexandclaude/worktrees/codex`。

## 实际修改的文件

| 文件 | 修改 |
| --- | --- |
| game/enemies/remnant_possibility_config.gd、game/enemies/remnant_possibility_config.gd.uid | 新配置 Resource 脚本及 UID，导出批准的灰盒初值与实现调参入口。 |
| game/data/enemies/remnant_possibility.tres | 新配置实例，使用脚本默认值。 |
| game/enemies/remnant_possibility_entity.gd、game/enemies/remnant_possibility_entity.gd.uid | 新无伤害飞行实体脚本及 UID，继承现有无色实体受击、单次死亡信号和表现；独立复制属性配置，覆盖普通追击/攻击 AI 为缓慢漂移。 |
| game/enemies/remnant_possibility_entity.tscn | 继承现有无色实体场景，保留真实攻击可命中的 hurtbox；不改普通实体场景。 |
| game/systems/combat/remnant_possibility_spawner.gd、game/systems/combat/remnant_possibility_spawner.gd.uid | 新 Room 组件及 UID，负责资格、阈值、随机计时、批次数量、碰撞位置、暂停与生命周期。 |
| game/world/boss_session.gd | 只增加一行绑定组件；后续 session 继承该入口，组件只在批准的战斗房间创建。 |
| game/tests/test_remnant_possibility.gd、game/tests/test_remnant_possibility.gd.uid | 新269项运行时检查及 UID，含五场接入、实际四方向攻击、物理帧生成及正常读档。 |
| scripts/verify_game.py | 只登记新套件，原验证判断不变。 |
| tests/test_verification_runner.py | 仅将套件计数和唯一性计数72同步为73。 |
| game/docs/remnant_possibility_implementation.md | 新实施说明，包含接入、资源及边界处理。 |
| codexandclaude/tasks/SYS-002/task.md | 只更新首部状态。 |
| codexandclaude/tasks/SYS-002/delivery.md | 本记录。 |

没有修改 ColorlessEntity 的普通行为、Boss/既有召唤物属性、原波次、存档结构、输入配置、策划主文档或其他任务。

## 规则与隔离

- 正式 FinalBattleSession 中营帐围攻、渴望俯视、寄生同伴者、中心战场救场前段、救场后最终战均接入；两间堑壕和普通房间排除。独立 RescueBattlefieldSession 同样通过继承接入；旧 BattlefieldRoom 首段预览场景不是 RescueBattlefieldRoom，不新增该预览的机制。
- 使用 `balance * 2 < maximum`：当前上限的严格50%，含负数、支持奇数成长上限；条件成立后10～15秒随机计时，1～2只且不超在场3只。余额回升到不低于一半时重置计时，已有实体保留。
- 实体位于独立容器，不加入原 Enemies、Boss 支援、普通杂兵或友军列表，因此不占原进攻/召唤名额、不改变敌人剩余数、波次完成或胜利判断。73个现有与新增套件全量通过。
- 生命13、不随日期变化；只漂移、不调用攻击 AI、不造成伤害。击杀经原单次死亡信号和 session 奖励路径支付+2，当前上限截断、负余额偿还和已有自动保存均复用。
- 暂停、剧情、对话/确认及加载过渡冻结；死亡、战斗结束、胜利或 Room 离树无奖励清理。正常读档重建组件，实体和倒计时不保存，不新增存档字段。

## 实现中需审查的边界处理

1. 生成位置为玩家上方160～240、水平±240，整个身体必须在当前 Room bounds 内；胶囊查询世界/玩家/敌人碰撞，同批实体另做直接重叠检查，防止物理 broadphase 尚未同步。32次仍无合法位置则本次不生成该只，下周期重试，不穿墙或移出批准范围。
2. 漂移速度24、振幅(24,12)、位置尝试32次均做成可调参数，只作用于新实体；它们是灰盒实现细节，不调整原有敌人。
3. 营帐波间保持同一场围攻；最终战波间预警也保留已有实体。10救场过场开始后，首段已停止，清理首段实体；之后最终战重新开始计时，避免把保底计入剧情清场/奖励或带入新波次计数。
4. 组件以 ALWAYS 模式观察死亡/结束，但在暂停和剧情时不扣计时、停用实体漂移/受击；实体自身为 PAUSABLE。此处理不推进原游戏时钟或战斗时序。

## 复现与检查结果

| 检查 | 命令与实测 |
| --- | --- |
| 开发前失败测试 | 先新增真实 Boss 房间接入检查，在未实现组件时运行 focused 入口：`REMNANT_POSSIBILITY_TESTS checks=1 failures=1`，退出1。日志 runs/20261019T175744.315794Z/007.txt。 |
| G1＋G3 | `python codexandclaude/tools/run_checks.py focused --python-all --godot-script res://tests/test_remnant_possibility.gd`：导入通过，新套件269/269，G3 81/81＋37/37，退出0；runs/20261019T180258.739557Z/summary.json。 |
| 完整 G2＋G3 | `python codexandclaude/tools/run_checks.py full --jobs 4`：预期75、实际75条目（导入、主场景180帧、73套件），全部通过；73个套件均 failures=0，错误/解析失败/泄漏/非零失败标记0；G3 81/81＋37/37，summary.passed=true，入口退出0。 |
| 干净实现 SHA 的 G3 | 提交后 `python codexandclaude/tools/run_checks.py focused --python-all`：sha=实现 SHA、dirty=false，81/81＋37/37，退出0；runs/20261019T181617.794192Z/summary.json。 |

新专项用真实 FinalBattleSession 的房间与独立测试槽；计时边界采用确定性手动推进，另验证实际物理帧自动生成。覆盖五场接入、重复绑定、严格50%、成长上限13、负数生成与偿还、周期边界、批次/存活限制、同批重叠、位置边界/阻挡、四方向实际攻击及单次命中、奖励保存和上限截断、暂停剧情/确认、Boss支援/围攻/战场计数隔离、死亡/胜利/离开/读档清理、堑壕排除与存档键不变。

完整回归时间 UTC 2026-10-19 18:04:03 至18:14:45。原始命令、工具路径、退出码、报告和日志哈希在本工作区 `codexandclaude/runs/20261019T180403.333083Z/summary.json` 与同目录 engine.txt；终端汇总为 runs/SYS-002-full-console.txt，不提交原始日志。engine.txt SHA256：`d764ee45a4e1278c755b1d0fb1d01bb7eb9d9ead3bf99c073a258916494aadb4`。

工具：Godot 4.7.2.stable.official.ed1daf0bf、Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。Godot 在沙盒外执行，避免用户日志和系统证书权限干扰。

## 被测内容与提交对应

按先验证再提交实现，完整回归汇总 sha 为基线、dirty=true。14个实现/测试/配置/说明文件在完整回归期间至提交均未变化，已将 runs/SYS-002-tested-blobs.json 的每个 Git blob 与实现 SHA 中对应文件逐一核对，全部相同。关键文件 blob：生成器 `9a71e4a2b0ec0ae5de182c121aa18025811b3d8d`，实体 `e506566f12631f96c6ef0c5c63551bebe736dc77`，新测试 `ad4cc2b63595ac4d7760cec64fa57a31e86d8aff`。

两份 SVG .import 的导入换行变化已恢复为基线，不提交生成物。全量后仅更新任务状态与交付证据，提交前再跑 G3 和差异检查，不重复 G2。

主目录 game/project.godot 未改，SHA256 仍为 `cd15b68c92683351ad95d8fb49a3388847b328665b91c735cf64709a7c79e270`，即 SYS-001 已合入配置。没有推送、操作 Claude 工作区或合并 SYS-002。

## 用户验收与 Claude 审查

G4 尚未进行，自动检查不能代替实机观察。Claude 审查通过后，用户使用独立测试槽，在至少一场批准的强制战斗中：

1. 把可能性耗到当前上限一半以下，等待10～15秒，观察空中保底实体生成；击杀确认+2。
2. 持续低资源时观察同时最多3只；回升到一半或以上后等待超过15秒，确认无新生成、旧实体仍保留。
3. 暂停再恢复、结束战斗或死亡，确认没有暂停时补发或结束后额外奖励。验收结果需后续记录入库。

请 Claude 以 `git switch --detach <交付SHA>` 固定审查，确认实现 SHA 至交付 SHA 只有本记录和任务卡状态变化；重点复核上述四项边界、五场接入与对原有规则的隔离，并独立复跑 G1、G2＋G3。审查和 G4 通过后仍需用户授权合并固定审查 SHA；L级按矩阵在 master 再跑全量并提交用户验收及集成证据。
