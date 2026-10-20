# ENV-005 审查记录

审查者：Claude｜日期：2026-10-20｜结论：**需修改**（R1，P2）；另 2 条非阻断建议

## 固定对象

- 基线：`43e7dc2a5c8f9376b9b28db9053ebfddd6ed9c46`（规划合入后的 master）
- 实现：`a3bc05e74ed9af67b329b729e280ad561f078803`（含 `2a35e35`）
- 交付／被审 SHA：`2acfa8c4553e34ccfe09621c18c5483051952a7b`，在 Claude 工作区 `git switch --detach 2acfa8c` 后审查；审查分支 `claude/ENV-005-review` 建在该提交上，只新增本记录。
- 实现到交付：只新增 `delivery.md`，与交付记录所述一致。

## 范围

7 个文件：`run_checks.py`、新增 `check_evidence.py`、`test_run_checks.py`、新增 `test_check_evidence.py`、`env.md`、任务卡首部、交付记录。均在任务卡允许范围内；未改游戏、验证入口、套件登记或协作规范。`summary.json` 旧字段保留，只新增字段。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 生成可粘贴的 `evidence.md` | 成立。我的全量运行生成的摘要与 `summary.json` 一致：SHA、干净状态、命令、工具版本、各关卡实际数/预期数/完整/通过、日志与报告哈希、时间；Python 预期数如实标为“unittest 发现数（未独立枚举）” |
| 2 不干净时记录内容哈希并醒目标注 | 成立（交付记录中的早期脏运行样例；测试覆盖未跟踪字节、暂存改名与删除） |
| 3 内容指纹与记录排除范围 | 成立。排除范围固定且很窄：`runs/**` 与 `tasks/<ID>/{delivery,review,integration,acceptance}.md`；`task.md`、`proposal.md`、规格与代码都在范围内；不提供扩大参数 |
| 4 复用判断保守 | **部分不成立，见 R1** |
| 5 未完成或缺汇总写“不通过” | 成立（下方变异） |
| 6 兼容 | 成立。三种模式都生成摘要；旧字段未删 |

## R1（P2）：记录文件会影响 G3，但复用结论把 G3 一并判为可复用

`check_evidence.py` 把 `tasks/<ID>/delivery.md` 等记录视为与测试无关，只要其他路径相同就输出 `reusable: true`，理由写“仅限源摘要已通过的关卡”，而源摘要里包括 G3。`env.md` 也写“只追加记录时可引用原有 G2/G3”。

但现有 G3 会读这些记录：`codexandclaude/tests/test_collaboration.py` 的 `test_markdown_links_resolve_within_collaboration_directory` 遍历 `codexandclaude/` 下所有 `.md`（只排除 `worktrees`、`runs`），检查每个链接能否解析。SYS-004 收尾时 Codex 就遇到过记录文档临时断链导致 G3 失败。

**实证**：在交付 SHA 上临时提交一处只改 `tasks/ENV-005/delivery.md`、加入一个断链的提交（`589e32d`，游离提交，未入任何分支，审查后已切回交付 SHA）：

- `check_evidence.py --source-summary <你的干净 full 摘要> --target-ref 589e32d` → `reusable: true`；
- 同一提交上运行上述链接测试 → `FAILED (failures=1)`。

也就是说，工具会对一个 G3 实际不通过的提交给出“可复用（含 G3）”的结论。`env.md` 里“纯记录 Markdown 链接仍需人工核对，不能证明正确则跑 G3”依赖人工，违背了要求4“规则须保守”。

**建议修法**（任选其一，或更好的方案）：

1. 复用结论按关卡给出：记录路径有变化时，G2 可复用，G3 标为“须重跑”；无任何变化时两者都可复用。`env.md` 同步改为“只改记录时 G2 可复用，G3 必须重跑”（G3 只需十余秒）。
2. 或者让排除记录的变化一律使 G3 不可复用，摘要中明确写出。

补一条回归：只改记录且引入断链时，结论不得包含 G3 可复用。

## 独立检查

**完整门禁**：在交付 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **76/76**，G3 `tests` **102/102**、`codexandclaude/tests` **61/61**，passed=true、finalized=true。摘要 `codexandclaude/runs/20261020T144103.793952Z/`（不入库）。该运行 `content_stable=False`，原因见 N1。

**变异与正例**（以你的干净稳定 full 摘要 `20261020T142147.717485Z` 为来源，目标为交付 SHA）：

| 情况 | 结果 |
| --- | --- |
| 正例：干净稳定的 full 摘要 → 只增加记录的交付提交 | exit 0，可复用 |
| 某关少执行一项 | exit 1，不可复用：G2少执行或多执行 |
| 缺少最终汇总 | exit 1，不可复用：缺少最终汇总 |
| 不干净的来源 | exit 1，不可复用：不干净的运行不能作为复用来源 |
| 非记录路径变化（`2a35e35` → 交付） | exit 1，不可复用：存在非记录路径变化 |
| （额外）我的不稳定 full 摘要作来源 | exit 1，不可复用：运行期间内容不稳定 |
| （额外）目标为 HEAD 且工作区有 SVG.import 改动 | exit 1，不可复用：当前目标工作区不干净 |

工具：Godot 4.7.2 stable（控制台版）、Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## 非阻断建议

- **N1 SVG.import 换行抖动让本机全量运行永远不能作复用来源**：在 Claude 工作区，G2 的编辑器导入每次都会改写 `game/assets` 下两个 `.svg.import` 的换行，结束快照与开始不同，`content_stable=False`。工具判为不可复用是正确的，但这使 Claude 侧的 full 运行实际上无法作为来源。建议另立小任务从根上消除这类抖动（例如用 `.gitattributes` 固定 `*.import` 的换行，或在导入步骤后自动规范化），可记入待办。
- **N2 正例演示的前提**：交付记录中“只增加记录可复用”的演示，在 R1 修复后应改为“G2 可复用、G3 已重跑”的形式，避免读者把它理解为整份证据可直接沿用。

## 结论

需修改：处理 R1 后提交新的实现与交付 SHA，我复核 R1 回归与上述变异即可。

## 复审（2026-10-20）：**通过**

- 修订实现：`f64af76e6cf4d1d8bbd738efe2c61b7833259b46`；交付／被审：`eb0b445685c0ac6bfd8693256e03fbcbaaf953e3`，已包含本记录首轮审查提交 `b15bdbb`。在 Claude 工作区 `git switch --detach eb0b445` 后复审；复审分支 `claude/ENV-005-review-r2` 只追加本节。
- 修订范围：`b15bdbb..f64af76` 只改 `check_evidence.py`、`test_check_evidence.py`、`env.md` 与任务卡首部；`f64af76..eb0b445` 只改交付记录。

### R1：已解决

- `compare()` 改为按关卡给出 `gate_reuse`、`reusable_gates`、`rerun_gates`：无任何变化时所有已通过关卡可复用；只有记录变化时 G2 可复用、G3 及其他非 G2 关卡须重跑；有非记录变化时全部不可复用。顶层 `reusable` 只在全部来源关卡可复用时为 true，部分可复用退出 1。
- `env.md` 与摘要中的复用限制改为“只改记录时 G2 可复用，G3 必须重跑”，并说明原因（G3 的链接检查读取被排除的记录）。
- **复现首轮实证**：在交付 SHA 上临时提交只改 `tasks/ENV-005/delivery.md` 并加入断链的游离提交（`8437051`，未入任何分支，结束后已切回交付 SHA，工作区干净），以你的 f64af76 干净 full 摘要 `20261020T151018.804241Z` 为来源比较：`reusable_gates=[G2]`、`rerun_gates=[G3]`，G3 理由“须重跑：记录变化会影响G3及其他非G2检查”，顶层 `reusable=false`，退出 1；同一提交上链接测试 `FAILED (failures=1)`。即工具不再对 G3 实际不通过的提交给出 G3 可复用。

### 独立检查

在交付 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **76/76**，G3 `tests` **102/102**、`codexandclaude/tests` **64/64**，passed=true、finalized=true。摘要 `codexandclaude/runs/20261020T152856.080924Z/`（不入库）。两个 SVG.import 的已知纯行尾变化已恢复（同首轮 N1，本机 full 仍不能作复用来源，记入待办，不阻断）。

### 结论

通过。N1（SVG.import 换行抖动）由规划维护者记入待办；N2 已按 R1 修复在交付记录中改为“G2 可复用、G3 已重跑”。合并需用户授权。
