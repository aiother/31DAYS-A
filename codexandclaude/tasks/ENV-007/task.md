# ENV-007：检查工具小修（内容稳定、改名漏检、调度顺序）

状态：已完成（2026-10-22，审查通过，master full 通过）｜级别：S｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：无

## 目标

修三处让每次检查多花时间或留下隐患的小问题：EXP-003 原型测试缺 `.uid` 导致每次 full 都“运行前后内容不稳定”（BL-115）；测试套件改名后静默退出门禁（BL-108）；G2 调度把长套件排在队尾（BL-109）。

## 依据

- 待办 BL-115（本卡起草时新增）、BL-108（ENV-004 审查 N1）、BL-109（ENV-004 审查 N2）。
- ENV-005 / ENV-006 的证据与复用规则：`content_stable=False` 的运行不能作复用来源。

## 现状（起草时核对 master@2183e77）

- `game/prototypes/EXP-001/tests/`、`EXP-002/tests/` 的 `capture.gd.uid`、`smoke_test.gd.uid` 已入库；`EXP-003/tests/` 的两个 `.uid` 未入库，编辑器导入每次重新生成，SYS-007、SYS-008、UI-004、UI-005、UI-006 的每次 full 都因此 `content_stable=False`，交付与审查记录每次都要解释并手动删除。
- `scripts/verify_game.py` 的 `discover_suites()` 只收 `game/tests/` 下 `test_*.gd`，改名为其他名字的套件不再执行也不报错（BL-108）。
- G2 按路径顺序提交，5 个 600 秒上限的 survey 套件排在队尾，`--jobs 4` 全量约多出 1.5～3 分钟（BL-109）。

## 要求

1. **内容稳定**：把 `game/prototypes/EXP-003/tests/` 的两个 `.uid` 用编辑器生成的值入库，使干净工作区的 full 在本机得到 `content_stable=True`；检查其他原型与 `game/` 下是否还有同类缺失并一并补齐（交付记录列出）。不改原型脚本内容。
2. **改名漏检**：`game/tests/` 下（含子目录，`acceptance/` 除外）带登记首行或 `extends SceneTree` 但文件名不是 `test_*.gd` 的脚本，G2 报错并列出；验收适配与非测试辅助脚本不误报。
3. **调度顺序**：G2 按登记的 `timeout` 从大到小提交，报告与日志仍按路径排序；不改任何套件的超时与内容。
4. 不改变通过 / 失败判定、证据格式与复用规则。

## 允许修改的文件

- `game/prototypes/EXP-003/tests/*.gd.uid`（新增），以及第1条核对出的其他缺失 `.uid`（只新增 `.uid`）。
- `scripts/verify_game.py`；`codexandclaude/tools/` 下与 G2 调用相关的脚本（如需要）。
- `tests/`、`codexandclaude/tests/` 中对应的 Python 测试。
- `codexandclaude/tasks/ENV-007/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 完成标准

1. 干净工作区连续两次 full 均 `content_stable=True`（交付记录贴两次自动摘要）。
2. Python 测试：改名套件被报出、验收适配与辅助脚本不误报；调度按 timeout 降序提交而报告按路径；现有判定不变。
3. 变异检查：去掉改名检查、调度恢复路径顺序，相应测试失败。
4. G2 + G3 通过。

## 检查

- G1：新增 / 修改的 Python 测试。
- G2 + G3：全量两次，交付记录贴自动摘要。
- G4：不需要。

## 回滚方案

`git revert` 本任务提交即可。

## 不在范围内

- 其他检查工具改进；游戏代码。
