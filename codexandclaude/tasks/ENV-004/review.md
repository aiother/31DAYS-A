# ENV-004 审查记录

审查者：Claude｜日期：2026-10-20｜结论：**通过**（无阻断项；3 条非阻断建议）

## 固定对象

- 基线：`66ee2b5ff0abaf110186a00760605efde17b4fb7`
- 实现：`bde78d161469c3c2684d265a6bfae086a4df45cc`
- 交付／被审 SHA：`622fcb7f43e02a58f9f6818e7f05ec93270649af`，在 Claude 工作区 `git switch --detach 622fcb7` 后审查，检查期间工作区干净；审查分支 `claude/ENV-004-review` 建在该提交上，只新增本记录。

## 范围

`git diff --stat 66ee2b5 622fcb7` 共 82 个文件：73 个 `game/tests/test_*.gd` 各只在第一行新增 `# verify-suite:` 登记（逐行检查 diff，没有其他增删）；其余为 `scripts/verify_game.py`、`tests/test_verification_runner.py`、`codexandclaude/tools/run_checks.py`、`codexandclaude/tests/test_run_checks.py`、`codexandclaude/tests/test_collaboration.py`、`codexandclaude/env.md`、任务卡首部与交付记录，均在任务卡允许范围内。`tests/test_game_project.py` 的一处同步超出原卡，但交付记录与任务卡首部写明了用户在会话中的单独授权，改动只把源码字符串检查换成实际登记集合检查，接受。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 新增或删除只改自身文件 | 成立。登记在测试文件第一行，`discover_suites()` 扫描 `game/tests/**/test_*.gd`；不再有公共列表或固定总数 |
| 2 路径唯一、文件存在、标记唯一、漏登即失败 | 成立。名称、路径、标记三项去重；路径必须指向自身文件且存在；未登记且未排除的 `test_*.gd` 报 `Missing suite metadata`；排除清单要求理由、文件存在且不能同时登记，目前为空 |
| 3 实际执行集合与登记一致 | 成立。`validate_executed()` 用多重集合比较；虽然执行列表来自同一套件列表，但它能拦住结果在收集环节丢失（实现者用替换 `as_completed` 的测试证明）；外层 `run_checks.py` 仍按登记名称核对全部 PASS |
| 4 不以登记表长度自证完整 | 成立。完整性来自磁盘文件对照（`test_verification_runner`、`test_collaboration` 各一处），不是数登记表 |
| 5 运行参数随登记 | 成立。`execute()` 不再按文件名推断；`execute_suite()` 用登记的 `fixed_fps`、`timeout`，full 与 focused 都走它 |
| 6 迁移前后逐项相同 | 成立，见下方独立对照 |
| 7 `run_checks.py` G2 预期数与 focused 路径校验可用 | 成立。focused 适配器改用 `SUITES` 与 `execute_suite()`，并有测试断言 |

## 独立核对

**迁移对照**：从 `66ee2b5` 读取旧 `TESTS`，按旧 `execute()` 的文件名规则推出每个套件的帧率与超时，与新 `SUITES` 比较：旧 73 个、新 73 个，路径集合相同，名称、标记、`fixed_fps`、`timeout` 全部一致，差异为零。唯一变化是顺序：旧列表为手写顺序，新为路径排序（交付记录已声明）。

**变异检查**（复制真实 `game/tests` 到临时目录后注入，不碰工作区）：

| 变异 | 结果 |
| --- | --- |
| 新增未登记的 `test_zz_new.gd` | 拒绝：Missing suite metadata |
| 两个套件登记同一路径 | 拒绝：Duplicate suite path |
| 登记指向不存在的文件 | 拒绝：Registered file does not exist |
| 删除 `test_player.gd` 的登记行 | 拒绝：Missing suite metadata |
| 执行集合少一个 | 拒绝：Incorrect execution set |
| （观察，不属卡要求）把 `test_player.gd` 改名为 `player_regression.gd` | **未拒绝**，套件数从 73 静默变为 72，见非阻断 N1 |

**完整门禁**：在交付 SHA、dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **75/75**（编辑器导入、主场景180帧、73 套件），G3 `tests` **102/102**、`codexandclaude/tests` **44/44**，complete=true、passed=true，全部子命令退出0。摘要 `codexandclaude/runs/20261020T123603.972943Z/summary.json`，engine.txt SHA256 `C33F0960…E455`（不入库）。运行后两个 SVG.import 出现已知纯行尾变化，已 `git restore`。

工具：Godot 4.7.2 stable（控制台版）、Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## 非阻断建议

- **N1 改名漏网**：固定总数取消后，把套件改名成不以 `test_` 开头会让它静默退出门禁（上表最后一行）。建议补一条轻量检查：`game/tests/` 下任何含 `# verify-suite:` 头或 `extends SceneTree` 的 `.gd` 若不叫 `test_*.gd` 就报错；或在 G2 报告里输出套件数与上次 master 的差值。可记入待办。
- **N2 G2 变慢**：本次全量用时约 14 分钟（12:36→12:50），此前同样 `--jobs 4` 约 11 分钟。原因很可能是路径排序把 5 个 600 秒上限的 `test_pursuit_survey_*` 排到队尾，并行池最后只剩它们在跑。建议提交调度时按 `timeout` 从大到小（同值再按路径）排序，报告仍按路径输出；属于性能，不影响正确性。
- **N3 env.md 结构**：新增的“引擎套件登记（ENV-004）”小节插在“## Git 与提交（V2.3）”标题之后、原有 Git 条目之前，使“仓库所有权”“提交说明”等 Git 条目看上去属于登记小节。建议把它移成独立的 `##` 小节。

## 结论

通过。审查 SHA 为本记录提交，见会话交接。SYS-004 可在 ENV-004 获授权合入 master 后按新登记方式开工。
