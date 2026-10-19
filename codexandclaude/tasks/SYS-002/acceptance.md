# SYS-002 G4 验收入口（S 级小任务）

状态：入口经 Claude S 级审查通过；SYS-002 用户 G4 已于 2026-10-19 通过，见下表。

批准依据：用户在会话中的原话“让 Codex 做一个 G4 验收入口”，并明确本任务只改以下两份文件。基线为已获 Claude 审查通过的固定 SHA `70b1ae17bb4bb45f422fb09dcb0b03a3f4c38823`，分支 `codex/SYS-002-g4`。

范围：`codexandclaude/tools/sys002_acceptance.gd`、本文件。未修改 game/、SYS-002 实现/测试、verify_game.py 或计数，不合并 master。目标是方便实机验收，不代替用户 G4。

## 启动

在包含本分支的 Codex 工作区执行以下 PowerShell 命令。保留 `--`，后面的参数属于验收入口：

```powershell
Set-Location 'D:\31days\codexandclaude\worktrees\codex'
$godot = 'D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path game --script ../codexandclaude/tools/sys002_acceptance.gd -- --encounter=camp
```

将最后一项参数替换为下列值即可直接进入对应的真实 Room 和战斗。无需从头跑流程：

| 参数 | 场景 |
| --- | --- |
| `--encounter=camp` | 营帐围攻，等待原有首波预警结束后显示 READY |
| `--encounter=overlook` | 渴望俯视，跳过首次演出，Boss 与原有杂兵正常战斗 |
| `--encounter=parasite` | 寄生同伴者，跳过首次演出，Boss 与原有杂兵正常战斗 |
| `--encounter=rescue` | 中心战场救场前段，真实救场触发与后续过场仍保留 |
| `--encounter=final` | 救场后最终战，正常启动最终计时与波次 |
| `--encounter=trench` | 堑壕排除项，面板应显示无生成器、数量0 |

默认余额3、上限10；参数示例：

```powershell
& $godot --path game --script ../codexandclaude/tools/sys002_acceptance.gd -- --encounter=parasite --balance=-8 --maximum=13
```

余额按正式资源范围接受整数 `-9..上限`，上限使用正式可取值 `10、12、13、14、15`（11不是现行成长可取值）。无效参数退出2，不创建验收存档。临时夹具补齐上限所需的既有成长来源标记，初始生命5；这是局部战斗重现，不用于验收正常剧情推进。上限15的夹具包含寄生同伴者已击败/成长来源，若在寄生同伴者重现战中按E重试进度，原游戏会按已击败记录开启通路；需要验证该场持续战斗时使用默认10或13/14。

使用真实 FinalBattleSession、真实 Room、正常键盘/鼠标/手柄输入与物理帧。没有手动调用生成器 tick，没有改间隔、实体属性、伤害、AI或时间倍率。首次预警和后续战斗/救场/死亡均正常运行。死亡后沿原检查点规则恢复；要重新进入所选场景可退出后重跑启动命令。

## 调试键与角落面板

- **F6**：可能性+5，按当前上限截断；**F7**：可能性-5，按正式透支下界-9截断。只在当前验收进程注册键事件，不修改 InputMap 或 project.godot；资源保存只进入临时槽。
- 其他操作沿用游戏：A/D或左右方向键移动、Space跳跃、J/鼠标左键攻击、W/S上下瞄准、K闪避、L长按恢复；Esc正常暂停/继续。手柄绑定不变。
- 右上角常驻只读面板显示余额/上限、是否严格低于一半、实际生成器倒计时、当前在场保底实体数；暂停/剧情时标记冻结。数量只读保底容器，不包含Boss原有召唤物。
- 临时槽每次使用独立 `user://tests/sys002_acceptance_<PID>_<时间>` 目录；初始化前已指定该目录，不读取或覆盖正式槽。关闭窗口直接退出并清理；通过游戏菜单正常退出也在脚本 finalize 清理。操作系统强制杀进程/断电无法保证执行清理，残留仍只在该临时命名目录。

## 用户 G4 检查（来自 SYS-002 review.md 的四项）

1. **生成与击杀收益**：至少选一场强制战斗，保持余额低于上限一半（可用F7），按真实时间等10～15秒。观察空中保底实体生成，跳跃或向上攻击击杀，确认余额+2；勿把普通无色实体/既有Boss支援误计为保底。
2. **上限与回升**：低资源下观察同时最多3只。先记录现有数量，再用F6提高到一半或以上，等超过15秒，确认不再新生成且旧实体保留。若战斗中又消耗到一半以下，计时会重新开始，可再次用F6保持高资源。
3. **暂停与结束清理**：在倒计时中按Esc暂停，观察秒数冻结；等一段时间后继续，无一次性补发。实际结束战斗或死亡时，保底实体应消失且不额外加可能性。救场会按原规则补满可能性，不能把该剧情补满当作保底清理奖励。另用 trench 入口等待，确认始终无生成器、数量0。
4. **高处平台观察**：营帐可沿现有平台向上跳；渴望俯视可等Boss按原机制召出平台，再登高。保持低资源，在较高平台等待多个真实生成周期，记录面板计时、站位和是否长时间不生成。头顶空间不足时可能32次候选全部失败；此时应等下周期，不穿墙。此项只记录实际体验，不由入口改变候选范围或把角色直接传送到高处。

## 入口自测与交付

脚本内 `--smoke-test` 为入口自测：正常输入F6/F7、实际帧计时、Esc暂停/恢复、面板位置、真实槽有效性及退出删除；不代表上述四项已由用户验收。无头模式自测命令：

```powershell
& $godot --headless --path game --script ../codexandclaude/tools/sys002_acceptance.gd -- --encounter=camp --smoke-test
python codexandclaude/tools/run_checks.py focused --python-all
```

实现者自测：六个选项默认3/10全部启动通过；另测 parasite -8/15、camp -9/13、final 7/13，合计9/9退出0、无错误/解析失败/泄漏。非法场景、越界负余额、非法上限、带多余等号的整数参数4/4按预期退出2；所有启动自测结束后临时验收目录残留0。真实窗口 camp 自测22项通过，截图已人工检查：右上面板完整可读、不遮左侧HUD或操作提示。初轮自测曾误将没有物理回调的Room判作禁用，另有快速退出的音频释放延迟；仅在本启动脚本修正检查与等待释放后，复跑通过。

原始日志在本工作区 `codexandclaude/runs/SYS-002-g4/`（忽略目录），summary.json 为9组启动结果；windowed-camp.txt 与 preview-camp.png 为窗口自测和渲染证据。工具版本：Godot 4.7.2.stable.official.ed1daf0bf、Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。提交前 G3 实测结果与实现 SHA 在下方交付补记中追加。

## 用户验收结果

| 日期/验收人 | 场景、余额/上限、站位 | 第1项生成/+2 | 第2项上限/回升 | 第3项暂停/清理 | 第4项高处观察 | 结论/问题 |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-10-19／用户 | 使用本验收入口（Claude 提供 camp、overlook、trench 启动命令） | 通过 | 通过 | 通过 | 通过，未反映长时间不生成 | 用户在会话中反馈“没问题”；四项按通过记录，由 Claude 代为填写 |

## S 级交付补记

实现者：Codex｜日期：2026-10-19｜实现 SHA：`0a1f1ff9fc954fcbafc7a769c6212c7f543beee5`。

- 修改清单严格为本文件和 `codexandclaude/tools/sys002_acceptance.gd`；相对固定基线，game/、scripts/、tests/ 的 diff 为空；未修改主目录、未合并或推送。
- 六入口及3组资源参数9/9通过，4组非法参数全部按预期拒绝；实际窗口自测22/22，临时目录残留0。原始启动日志与截图见上方路径，不入库。
- 提交前 G3：81/81＋37/37，退出0，日志 `codexandclaude/runs/20261019T184641.538698Z/summary.json`；被测 SHA 为基线、dirty=true，仅上述两份新文件。
- 干净实现 SHA 的 G3：81/81＋37/37，退出0，summary.passed=true、dirty=false；日志 `codexandclaude/runs/20261019T184716.909184Z/summary.json`。
- 本交付提交只追加这段记录，提交前再跑G3与差异检查；交付 SHA 通过回复提供，不写入自身记录。用户G4仍未验证，不能据启动自测标为验收通过。

## Claude S 级审查：通过

审查者：Claude｜日期：2026-10-19｜被审实现 SHA `0a1f1ff9fc954fcbafc7a769c6212c7f543beee5`，交付 SHA `442f62eb85d977598d9706401a9beffa13ec8d83`；以 `git switch --detach` 固定交付 SHA 后审查。

- **范围**：相对基线 `70b1ae1` 只新增 `codexandclaude/tools/sys002_acceptance.gd` 与本文件；实现到交付只追加本文件的交付补记。game/、scripts/、tests/ 与 SYS-002 实现、测试均未改动。
- **存档隔离**：临时目录在 session 加入场景树前写入 `save_directory`；死亡或读档时游戏经 `CheckpointLab._reload` 把目录写入场景树元数据，新 session 在 `_ready` 中读回，因此重载后仍只写临时目录。实测：无头运行 camp、trench 自测前后，正式存档目录 `user://saves` 的文件名、大小与修改时间完全一致，`user://tests/sys002_acceptance_*` 残留为 0。
- **真实时钟与输入**：脚本不调用生成器 `tick`、不改间隔与实体属性；F6/F7 由进程内节点监听，不修改 InputMap 或 project.godot；角落面板只读显示生成器状态。
- **入口实测**：`--encounter=camp --smoke-test` 21/21、`--encounter=trench --smoke-test` 19/19，均退出 0，trench 确认无生成器；`--encounter=nowhere` 退出 2 且不建存档。其余四个入口未逐一复跑，依据实现者自测记录。
- **非阻断观察**：死亡重载后，新 session 会重新连接自己的窗口关闭处理，此后关闭窗口时游戏原有的关闭流程与验收脚本的清理都会执行（可能先出现游戏的退出确认）；两者都只涉及临时目录，不影响正式存档。

结论：可以交给用户按上方四项进行 G4。本小任务不授权合并 master；最终合并对象为包含 SYS-002 实现、审查、本验收入口与用户验收结果的固定提交。
