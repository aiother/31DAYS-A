# EXP-003 审查（第1轮）

审查者：Codex｜日期：2026-10-21｜结论：**需修改**。
被审交付 SHA：`7dab5ac3753d6b90cd464c85492bb5fa7d0e3e4b`。
实现 SHA：`d83bee80f996ff75c73a87ef08b8627503083324`；基线：`c6a8f937d504b80783b1d917764c3e5352cde4ca`。

## 已核对与独立证据

- 基线到实现只新增 `game/prototypes/EXP-003/`。实现到交付只新增 delivery.md 和更新任务卡首部。未改正式场景、共享脚本、项目配置、输入映射或真实存档；模拟槽保存在内存。截图为12张，目录有 .gdignore。
- 静态检查：A-013 已通关槽继续时提示并停留，新游戏仅覆盖选中槽且先确认；确认默认“返回”；暂停、死亡、结束、最终战超时均提供返回标题路径，死亡四项和最终战超时的重试/返回标题符合 A-014/A-011。原型中的设置与游戏画面为明示占位。
- 编辑器导入退出0，无 ERROR / WARNING；原版冒烟 `EXP003_SMOKE checks=43 failures=0`，退出0，无 ERROR / WARNING。
- 独立 G3：`focused --python-all`，102/102 + 67/67 通过，退出0。摘要：`codexandclaude/runs/20261021T105921.511246Z/summary.json`。当时工作区仅有编辑器自动生成的两个未跟踪测试脚本 UID，已确认来源并移除；没有修改已跟踪实现内容。

## R1（P2）：A-013 提示断言没有读取实际绘制结果

位置：`game/prototypes/EXP-003/slots_base.gd` 的 `say()`、`_draw_header()`，以及冒烟中读取 `drawn["message"]` 的断言。

`say()` 在绘制前直接写 `drawn["message"]`；实际绘制位于 `_draw_header()`。因此该断言只证明发起了提示，不证明“游戏已通关”已画到屏幕。确认框的 `drawn["dialog"]` 同样由 `ask()` 预先写入，需一起核对。用户本轮明确要求冒烟读取实际绘制记录。

独立变异：仅删除 `_draw_header()` 中实际绘制 message 的 `ink_text(...)` 调用（保留 say 和记录）。结果仍为：

```text
EXP003_SMOKE checks=43 failures=0
exit=0
```

这会使选择已通关槽时没有 A-013 所要求的可见提示，但测试仍通过。原始文件已按字节恢复，工作区已跟踪内容无差异。输出：`codexandclaude/runs/exp003-review-mutant-message.txt`（不入库）。

建议：message 和 dialog 仅在对应实际绘制调用处登记本帧画出的文字，并在未画/取消/过期时清除；冒烟等待绘制后检查。复现“去掉提示绘制”和“去掉确认文字绘制”两种变异，相关断言必须失败。不要只把静态字符串表复制进 drawn。

按用户停止条件：确认阻断后结束本轮，不修改实现分支，不合并。其余演示与用户选方案仍待后续，G4 不由本审查代替。


## 第2轮复审：R1 已解决，通过

审查者：Codex｜日期：2026-10-21｜本轮结论：**通过，无阻断项**。
固定交付 SHA：`d27c9d0c2ccaeac1028cb8ca12538290d202761e`。
修正实现 SHA：`b150486100bd3b4af033b350957c3e6a32138e1e`。

### 范围与 R1

- 修正实现到交付只变更 delivery.md 与任务卡首部。相对上轮交付的代码只在原型目录；正式场景、共享脚本、project.godot、输入映射、真实存档没有改动。
- say/ask 不再提前写入被断言的文字。drawn_text/draw_recorded 在执行绘制时返回或登记文字；卡片信息、主界面标题、提示、确认框、已通关印章/文字、各页标题从相应绘制调用取得记录。提示过期清除 message，确认框关闭清除 dialog，游戏页关闭清除 page_title。R1 已解决。
- 用户选定的主界面 A、书签1与天空条2组合与会话原话一致；当前交付记录把组合用于后续正式任务，未擅自扩大本轮原型范围。A-013 的阻止继续与提示、只覆盖所选槽、确认默认返回，以及暂停/死亡/结束/最终战超时返回标题流程仍保留。

### 独立检查

环境：Godot `4.7.2.stable.official.ed1daf0bf`；Python `3.12.14`。
所有命令固定上述交付 SHA，在 Codex 工作区 runs 下的独立临时 worktree 执行，没有切换或修改 Claude 工作区。

- 编辑器导入：`Godot --headless --path game --editor --import`，退出0，无 ERROR/WARNING。
- 独立启动：`Godot --headless --path game --quit-after 30 res://prototypes/EXP-003/preview.tscn`，退出0，无 ERROR/WARNING。
- 冒烟：`Godot --headless --path game --script res://prototypes/EXP-003/tests/smoke_test.gd`，预期/实际均 `EXP003_SMOKE checks=45 failures=0`，退出0。
- 四项变异：删除实际绘制调用后，提示2、确认框文字3、书签已通关印章1、页面标题4项失败，均退出1。源文件逐字节恢复后再次45/0，退出0。
- G3：`python codexandclaude/tools/run_checks.py focused --python-all`，预期/实际102/102 + 67/67，全部完整通过，退出0，起止dirty=false，content_stable=True。
- G3摘要：`codexandclaude/runs/20261021T124453.792776Z/summary.json`；本地临时 worktree 位于 `worktrees/codex/codexandclaude/runs/exp003-r2-worktree`。冒烟、启动和变异原始日志亦保留于其中的 runs，不入库。按探索型矩阵不要求G2。

### 流程说明（非阻断）

实现分支未先快进到上轮审查 SHA b03fd70，上轮 review.md 不在本交付树。本次在审查分支补回上轮原文并追加本节，保留两轮内容；后续修订请按协作规范§5.4先快进审查提交，再追加实现，避免审查记录留在旁支。

未合并 master。用户试玩选定已由交付记录保存；正式实现另按后续批准任务进行。
