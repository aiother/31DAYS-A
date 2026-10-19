# ENV-001 交付记录

状态：实现与验证完成，待 Claude 独立审查；尚未合入 master。

- 实现者：Codex；日期：2026-10-19。
- 已批准规划提交／实现基线：`6a7b0d8a0343f16c3e12181b1fb7196ea085512c`。
- 实现 SHA：`f6c55516fa800ebe176ca84b050f1e3de275bbef`。
- 分支：`codex/ENV-001`。
- 工作区：`D:/31days/codexandclaude/worktrees/codex`。

## 改动

共八个文件，均在任务卡允许范围内：

| 文件 | 内容 |
| --- | --- |
| `codexandclaude/tools/run_checks.py` | 标准库入口；env、focused、full；工具解析、失败退出、日志及 JSON 汇总 |
| `codexandclaude/tests/test_run_checks.py` | 19 项模拟测试，覆盖失败场景与调用顺序，不要求安装真实工具 |
| `codexandclaude/env.md` | 参数、配置、环境变量、模式用法及证据说明 |
| `codexandclaude/.gitignore` | 忽略各工作区自己的 env.local.json |
| `tests/test_game_project.py` | 仅跳过 res://../ 前缀；回归证明工程内缺资源仍失败、存在资源通过 |
| `tests/test_t6_workbook.py`、`tests/test_t7_workbook.py` | Node 优先读取 DAYS31_NODE，未设置时保留原默认路径；其余断言不变 |
| `codexandclaude/tasks/ENV-001/task.md` | 仅首部状态更新为待审查 |

工具解析顺序为 CLI → 本地配置 → DAYS31_* 环境变量 → 自动发现。路径通过参数数组传递，不使用 shell 拼接。
full 直接调用原 scripts/verify_game.py；专项 Godot 通过子进程调用其 execute()，不复制判定逻辑。
入口另核对全量预期 PASS 条目是否完整、Python 是否报告正数测试及 OK；缺汇总不能算通过。
Windows 外层超时会尝试终止整棵子进程树，保留命令、退出状态及日志。

## 复现与修复证明

创建独立 worktree 后，outputs/ 不存在。原版本执行：

```powershell
& 'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -m unittest discover -s tests -p test_game_project.py
```

10 项中 1 项失败：`../outputs/pursuit_air.json` 被当成必需资源。
修复后的夹具依次验证：工程外输出不存在仍通过；工程内 assets/absent.json 不存在时报错；创建该工程内资源后通过。

运行任何 G2 前，在同一全新工作区执行以下命令（前后均确认 outputs/ 不存在）：

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

结果：tests/ **70/70**，codexandclaude/tests/ **29/29**，退出码 0。
汇总：`codexandclaude/runs/20261019T095549.958306Z/summary.json`。
因此 G3 不再依赖 G2 生成文件，没有复制报告或创建占位文件。

## 验证结果

| 检查 | 命令／结果 |
| --- | --- |
| G1 | 19 项入口测试及资源正反例均包含在通过的 G3 中 |
| 环境模式实测 | `python codexandclaude/tools/run_checks.py env`：通过；系统 Python 启动后正确发现带 openpyxl 的测试 Python |
| Python 专项实测 | `python codexandclaude/tools/run_checks.py focused --python-module tests/test_game_project.py`：11/11，通过 |
| G2＋G3 | `python codexandclaude/tools/run_checks.py full --jobs 4`：73/73 引擎条目（导入、主场景、71 套件），再 70/70＋29/29 Python 测试，进程退出码 0 |
| Godot 专项实测 | `python codexandclaude/tools/run_checks.py focused --godot-script res://tests/test_hud_layout.gd`：导入及 HUD_LAYOUT_TESTS checks=65 failures=0，通过 |
| 实现提交检查 | 在实现 SHA 的干净工作区重跑 `focused --python-all`，70/70＋29/29，通过；汇总 sha 为上述实现 SHA，dirty=false |
| 差异检查 | `git diff --check` 通过；全部被测文件 Git blob 与实现提交一致 |

full 汇总：`codexandclaude/runs/20261019T095630.715429Z/summary.json`，UTC 09:56:30 至 10:07:07。
原始引擎报告在同目录 engine.txt，SHA256：
`6ed89d104b7c13881ef6a6f20ca1814c0cdadf42bcd38d28bec17364d05ee840`。
完整报告含 73 个结果条目；未发现失败、错误、解析失败、泄漏或超时标记。
其中 HUD_LAYOUT_TESTS checks=65 failures=0，MENU_CONTROLLER_TESTS checks=30 failures=0，PURSUIT_SURVEY_E_TESTS checks=24 failures=0。

环境／Python 专项／Godot 专项汇总分别位于 runs/ 下：
`20261019T095904.156148Z`、`20261019T095905.374050Z`、`20261019T100808.009229Z`。
实现 SHA 的干净 G3 汇总位于 `20261019T100916.078418Z`。
以上目录均保留完整命令、日志、版本及日志摘要，不提交原始日志。

### 被测工作树与实现 SHA 的对应

按方案“先验证，再提交实现”，首次完整 full 汇总的 sha 是基线 6a7b0d8…，dirty=true，表示当时正在测试尚未提交的实现。
完整验证期间未修改这七个代码／测试／配置／说明文件；提交前后已逐一核对 Git blob，内容完全一致：

| 文件 | 被测／已提交 blob |
| --- | --- |
| codexandclaude/.gitignore | 58e341da45fa2d6dfd91341564ae30936dd71626 |
| codexandclaude/tools/run_checks.py | fe8c2318b4e9a9f26c42eb3b97a192218afbb4e3 |
| codexandclaude/tests/test_run_checks.py | a8c5537d2267c800d4630e7585e6f7fea28aae73 |
| codexandclaude/env.md | d3e6168102999d5061c92a5e45f7c080d519566b |
| tests/test_game_project.py | 7593047813737799723e947cf96a036e2b3dd443 |
| tests/test_t6_workbook.py | ecd8dab24a921d7483d361d6b5ab223ba78865ac |
| tests/test_t7_workbook.py | 56afbe7f0fe985b1b75609f0ed26192f1e4215d8 |

完整验证结束后只更新任务卡状态，并再次通过 G3；提交后又在干净实现 SHA 上通过 G3。
未把预提交 full 伪写成在干净实现 SHA 上运行，也未因记录文件变化重复执行 G2。

## 环境与执行限制

- Godot：`D:/DMyself/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`，4.7.2.stable.official.ed1daf0bf。
- Python：`C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`，3.12.14，openpyxl 3.1.5。
- Git：`C:/Program Files/Git/cmd/git.exe`，2.56.0.windows.2。
- Node：`C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe`，v24.19.0。
- 第一次沙盒内 full 在导入阶段失败：无法读取系统证书及保存用户 Godot 编辑器设置。失败汇总保留于 runs/20261019T095600.268395Z；未计为通过。获得权限后在沙盒外重跑上文 full 并通过。
- Godot 生成的两份 .svg.import 行尾变化没有内容差异，已在本隔离工作区恢复，未提交；没有修改游戏代码、输入或存档。
- 未安装依赖、未改全局配置、未调用 Claude、未推送。无 G4 要求；其他机器仅通过模拟场景覆盖，未进行跨机器实测。

## 规划集成与用户文件保护

master 已从 013458f 快进到批准的 6a7b0d8…，仅增加任务卡；合入后原 G3 为 69/69＋10/10，通过。
主目录三个用户文件与规划合并前 SHA256 一致：

- Words/T6_资源配置填写模板.xlsx：`e369dff6c5ae147e22cf1ee33781df159a07d5191dbe9a267a943b4b0a8fa727`
- Words/T7_UI_UX与存档规格填写模板.xlsx：`fa46e8d4b48e69d46fe631c6e5223963d5222934edbe1867ee20864ec96be908`
- game/project.godot：`239f177c923343f54f6665f0ac11543fcd4db1275ca8e5334c177c9b45314998`

## Claude 审查与后续

从用户转交的交付 SHA detached 检出，先确认它相对实现 SHA 仅新增本交付记录，再按 V2.2 独立审查与复跑。
重点检查资源正反例、路径优先级及 Node 传递、失败退出、完整性统计、原验证器复用和新工作区 G3。
无用户实机操作要求；用户只需转交实现 SHA 与交付 SHA。审查通过后，仍须另获用户授权才可合并实现到 master。
