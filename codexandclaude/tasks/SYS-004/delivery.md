# SYS-004 交付记录

实现者：Codex｜审查者：Claude｜分支：`codex/SYS-004`
完整基线：`30dbfcbffb09f91a478e3be5037508b9c1f02ace`（ENV-004合并收尾后的master；包含此前EXP-001）
实现SHA：`2c4d6f399b633316c2322291987873a12e76c4dd`

## 修改行为与范围

按A-013，在真实 `SlotStore.load_slot()` 返回有效主档或备份后，`CheckpointLab.start_slot()`在检查点恢复、新游戏写入、会话重载之前拒绝END的继续请求，界面显示精确提示“游戏已通关”。空槽/损坏槽的原错误处理和新游戏覆盖流程保留。判断只看END，不把WON、TALK、TIMEOUT当作已通关。

- `SlotStore.is_completed()`只读判断现有事件，不改存档格式或原始读取/备份轮换规则。
- `LifeUI`只增加灰盒“已通关”附注，仍保留可点击继续以显示提示；业务拦截在入口层。
- `test_completed_slots.gd`新增真实存档与鼠标菜单回归，第一行独立登记（默认真实时间、60秒超时），同文件提供隔离G4入口。
- 既有final_battle和campaign测试将“已完成槽重载成功”的旧断言改为“拒绝重入、原地结束屏和成长不变”，campaign另比对真实主档/备份字节。campaign属于既有最终战相关回归，不改变通关、战斗或奖励测试流程。
- game/docs的两段现行通关读档说明同步；未改变FinalBattleSession的结束事件写入、结束屏或重试流程。
- 任务卡只更新首部状态与基线。未改project.godot、正式输入、验证工具、BOARD或BACKLOG。

## 完成标准对照

| 要求 | 实现与独立测试 |
| --- | --- |
| END继续拒绝且不写盘 | 点击真实继续按钮，检查提示、选槽模式、暂停、slot/data不变、scene/Room实例ID不变、没有_reload或checkpoint_reload；比较主档/.bak/.tmp完整字节与存在状态 |
| END仍可新游戏 | 同一真实槽点新游戏→确认开始，检查实际会话启动且落盘主档不含END |
| WON可继续 | 独立WON无TALK存档经真实菜单进入，再进入胜利Room、真实interact启动胜利对话、对话完成后进入结束演出 |
| TALK可继续 | 独立WON+TALK无END存档进入真实结束演出；经过真实3.2秒后保存END并显示finished |
| TIMEOUT可进入重试 | 独立TIMEOUT真存档进入超时菜单，明确重试后实际进入最终战 |
| 普通进行中可进入 | 正常进行中真存档进入真实堑壕检查点，未显示已通关 |
| END备份也拦截 | 分别构造损坏主档/缺失主档加有效END备份，继续拒绝且损坏主档或缺失状态与备份字节完全不变 |
| 活跃会话不被换槽 | 已有槽2普通会话，再从菜单点槽1 END继续，保留槽2 data、当前Room和场景实例 |
| 当前完成结束事件流程不变 | 新套件TALK推进及既有test_final_battle/test_campaign真实通关回归覆盖；当前结束屏保留，不因拒绝重入产生重载 |

## 检查与证据

- 新套件正常回归：**COMPLETED_SLOTS_TESTS checks=73 failures=0**，无ERROR/WARNING。
- G1相关专项：导入加六套件（completed_slots、slot_store、final_clock、final_battle、final_retry、campaign）均通过；`codexandclaude/runs/20261020T130824.755902Z/summary.json`。
- 去掉入口拦截的变异：临时删除start_slot三行END分支，新套件 **73项中16项失败**、退出1，无SCRIPT ERROR；finally按原字节恢复。证据 `codexandclaude/runs/sys004/mutation.txt`、同目录mutate.py（忽略）。没有改测试来适应变异。
- 全量：在实现SHA、dirty=false运行 `python codexandclaude/tools/run_checks.py full --jobs 4` → G2 **76/76**（原73套件+新1套件+导入/主场景），G3 **102/102 + 45/45**，complete=true、passed=true、全部子命令退出0。证据 `codexandclaude/runs/20261020T131111.604957Z/summary.json` 及同目录engine.txt/命令日志（忽略）。引擎报告SHA256：`b35570ec0f0d33e63d6b667fbbdf671fab25b848ee3f853c0a04f15d02f61b16`。
- 实现分支已包含EXP-001，所以协作测试45项；ENV-004收尾master已全量75/75及102/102+45/45通过，合并证据见ENV-004/integration.md。
- 工具：Godot4.7.2.stable.official.ed1daf0bf、Python3.12.14/openpyxl3.1.5、Git2.56.0.windows.2、Nodev24.19.0。
- G4入口自测：headless **9/9**；真实窗口+截图 **12/12**，无ERROR/WARNING。三张画面已查看，修正了测试点击的窗口拉伸坐标和验收说明遮挡原指示文字的问题；这不等于用户G4已完成。
- 完整验证后检查两份SVG.import仅有已知行尾差异才恢复，不带入交付。交付记录与状态更新后再跑G3及差异检查。

## G4：待用户一次点击验收

可在本机直接运行（本工作区已检出交付分支；master尚无SYS-004实现）：

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "D:\31days\codexandclaude\worktrees\codex\game" --script res://tests/test_completed_slots.gd -- --acceptance
```

若在审查者工作区运行，将--path换成该工作区game目录即可。不修改project.godot或玩家正式存档：入口在OS缓存目录创建独立`31days_sys004_<PID>_<ticks>`目录，打印绝对路径；在会话_ready前将save_directory设为该临时目录。只准备临时槽1 END及其备份，其他临时槽为空。

1. 进入真实存档选择页，槽1带“已通关”；右下角有临时验收说明。
2. 鼠标点击槽1“继续”：确认左侧出现“游戏已通关”，仍停留在存档选择页。
3. 点击同槽“新游戏”，再点“确认开始”：确认正常进入新游戏起始场景；正常坠落/起身演出属于原流程。
4. 关闭窗口，脚本释放会话并清理临时主档/.bak/.tmp目录；菜单退出也由MainLoop._finalize兜底清理。强制杀进程无法保证退出回调，但遗留目录仍只在独立缓存下，不会触碰正式存档。

可复现入口自测（自动真实鼠标点击并清理）：在上述命令中将--acceptance改成--acceptance-smoke；在引擎参数区（第一个`--`之前）加--headless可无窗口运行。截图自测用--acceptance-smoke --capture，图写入忽略目录 `codexandclaude/runs/SYS-004-g4/`，窗口截图见slots.png、blocked.png、new-game.png。

用户G4结果：**通过**（2026-10-20，用户原话“SYS-004 G4 通过”，见[审查记录](review.md)的G4节）。Claude审查已通过，用户已授权合并；master集成与全量检查结果见[集成记录](integration.md)。
