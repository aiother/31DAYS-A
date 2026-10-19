# ENV-003 独立审查记录

审查者：Codex｜日期：2026-10-19｜结论：**通过**。

- 被审实现 SHA：`6cff1950ccd94b946a9e07b8ae2538808684342d`。
- 被审交付 SHA：`f22a23899bfd5ca65ff97bd6cd73a5a26698fa0d`。
- 基线：`3f54a7bedf804b324d8d110fcb98da0af30294c9`。
- 工作区：`D:/31days/codexandclaude/worktrees/codex`。
- 先用 `git switch --detach f22a23899bfd5ca65ff97bd6cd73a5a26698fa0d` 固定并复跑；验证完成后从该交付提交建立 `codex/ENV-003-review`。

## 范围与交接

实现至交付的差异仅为新增 delivery.md，以及 task.md 首部从进行中改为待审查。实现相对基线只涉及任务卡允许的入口、入口测试、env.md 和任务卡。
未修改原引擎验证器、游戏代码或游戏测试。审查期间未修改实现文件；本审查提交只新增本记录并更新任务首部状态。

## 完成标准核对

| 标准 | 结果与证据 |
| --- | --- |
| 按模式解析工具 | required_tools() 按需求取并集；未要求工具不调用 resolve_tool，不校验其版本；汇总 tools_not_required 与实际工具一致。独立核对 env/full、纯 Python、纯 Godot、混合专项五种组合，5/5 通过 |
| 无 Godot 的 G3 | 指定不存在的 Godot 路径，入口仍通过两组 Python 测试；工具列表无 Godot，tools_not_required 为 godot。模拟解析器拒绝 Godot 的测试也通过，证明不会转入自动发现 |
| 仍保留必要工具检查 | env/full 的缺 Godot 测试失败符合预期；纯 Godot 不要求 Node 的测试通过；混合模式要求全部工具 |
| 跳过规则 | skipped 和 expected failures 都返回失败并给出数量及处理提示；除了单元测试，实际构造两类 unittest 子进程进行负例验证，两次入口均退出 1 并保留 summary.json |
| 意外异常证据 | KeyError 注入测试证明 reason 包含异常类型与信息、traceback 包含调用栈、passed=false、返回 1；KeyboardInterrupt 的独立测试证明不会被吞掉 |
| 回归与判定 | 原 19 项和新增 6 项共 25 项通过；G2 仍使用原 verify_game.py 与 execute()，未放宽判定；规则与说明同步到 env.md |

将六个新增测试方法对照基线旧入口运行，独立复现 4 项失败、1 项错误；env/full 工具要求和 KeyboardInterrupt 两项在旧实现本就通过，作为保护性测试保留。此负例验证符合先失败后修复的交付说明。

## 独立复跑结果

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| G1 | bundled Python 执行 `-m unittest discover -s codexandclaude/tests -p test_run_checks.py -v` | 25/25，OK |
| 无 Godot G3 | `python codexandclaude/tools/run_checks.py focused --python-all --godot D:/ENV-003-no-such-godot.exe` | 退出 0，70/70＋35/35；sha=交付 SHA，dirty=false；Godot 未解析 |
| 必需工具负例 | `python codexandclaude/tools/run_checks.py env --godot D:/ENV-003-no-such-godot.exe` | 预期退出 1，Missing/unusable godot，未回退掩盖显式错误 |
| 跳过负例 | focused 运行忽略目录内临时 unittest 夹具（skip、expectedFailure 各一） | 两次预期退出 1，分别记录 skipped=1、expected failures=1 和 not allowed 提示 |
| G2＋G3 | `python codexandclaude/tools/run_checks.py full --jobs 4` | 退出 0；G2 预期 73、实际 73（导入、主场景、71 套件）；G3 70/70＋35/35 |

full 在固定的交付 SHA 上执行，启动时 dirty=false；UTC 11:48:01 至 11:58:34，约 10 分 34 秒。
原始引擎报告逐项核对：71 个登记套件各有且只有一条对应零失败汇总，错误、解析失败、泄漏、非零失败、超时标记均为 0。

### 日志

本工作区的 codexandclaude/runs/ 下保留原始日志，不入库：

- `20261019T114801.058350Z/summary.json`、`engine.txt`：完整 G2＋G3。
- engine.txt SHA256：`66735c217ad06d4c3ad13acfd90a1094bcbf6b5057a3982bdb9d3ac8dd31e5fd`。
- summary.json SHA256：`15f7b615a88242a2fd94c2b49fbe53739c1766d6bf0216dff00c44eade867190`。
- `20261019T114731.314338Z/summary.json`：无 Godot 的 G3。
- `20261019T114735.561646Z/summary.json`：env 缺 Godot 的预期失败。
- `20261019T115024.418112Z/summary.json`、`20261019T115025.480679Z/summary.json`：skip、expectedFailure 的预期失败。
- `ENV-003-review-baseline-regression.txt`：新增测试对照旧实现的负例结果。

工具：Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14＋openpyxl 3.1.5；Git 2.56.0.windows.2；Node v24.19.0。完整路径及命令参数在 summary.json 中。
没有卸载本机 Godot；无 Godot 情况通过无效显式路径及拒绝解析的模拟器验证，实际 G3 没有调用 Godot。
full 经执行权限批准在沙盒外运行。其生成的两份 .svg.import 经确认仅为行尾变化后，在本独立工作区恢复，未提交。

## 流程差异与 master 核对

本轮用户明确说明任务已批准，并要求核对任务卡中的两处流程差异。本审查按本任务的已批准特例处理：基线取 ENV-001 审查 SHA；任务卡与实现同分支。不将它们推广为 V2.2 默认规则。

审查时 master 为 `e19e47437838025ecba21e598a5e6c045e2d8fe5`。它相对基线只增加 ENV-001 的 integration.md 并更新 ENV-001/task.md 首部状态，**没有额外代码变化**；与 ENV-003 的实现文件无重叠。因此没有触发任务卡所述的额外代码适配／基于 master 重检条件。
本次没有合并 master，也没有操作主目录用户未提交文件。

## 交接

无阻断问题，无新增需用户裁决事项，无 G4 要求。审查记录及状态更新按证据规则在提交前跑 G3，不重复 G2。
待用户另行授权后，集成者应合并本审查记录所在的固定审查 SHA；如届时 master 新增代码变化，应重新核对集成候选。合并后仍按验证流水线／协作工具矩阵在 master 跑完整 G2＋G3，并另作证据提交。
