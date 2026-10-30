# 协作检查入口（ENV-001）

在自己的工作区根目录手动执行 `python codexandclaude/tools/run_checks.py ...`。
入口本身只需要 Python 标准库；可用系统 Python 启动，检查会另行发现带 openpyxl 的测试 Python。
不安装依赖、不改 PATH 或全局配置、不执行 Git 写入操作。

## 工具解析

每个工具依次取：命令行 `--godot/--python/--git/--node` → 本地 JSON 配置 →
环境变量 `DAYS31_GODOT/PYTHON/GIT/NODE` → 自动发现。
显式配置错误直接失败，不回退掩盖问题。本地相对路径按工作区根目录解析；裸命令先查 PATH。
Python 自动发现会验证 openpyxl，避免误选不带依赖的系统解释器。
自动发现包括当前 Python、PATH、用户的 Codex bundled runtime、Program Files/Git，
以及 Downloads、D:/DMyself 下的 Godot console 安装位置；其他位置请显式配置。
每种模式只解析和校验需要的工具：`env`、`full` 检查全部四个；`focused` 运行 Python 时需要 Git、Python（含 openpyxl）、Node，
运行 Godot 专项时需要 Git、Python、Godot，两者都有时取并集。未要求的工具记在汇总的 `tools_not_required` 中，
因此没有 Godot 的机器也能跑纯文档任务的 G3。需要 Godot 时，版本必须为 `4.7.2.stable.*`。

默认配置为各工作区自己的 `codexandclaude/env.local.json`（已忽略），可用 `--config` 指定其他文件：

```json
{
  "godot": "D:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe",
  "python": "C:/Tools/Python/python.exe",
  "git": "C:/Program Files/Git/cmd/git.exe",
  "node": "C:/Tools/Node/node.exe"
}
```

字段可省略。路径包含空格时，在命令行上使用引号。入口向测试子进程传入解析得到的
`DAYS31_NODE`；T6/T7 测试优先读取它，未设置时仍回退到原 bundled Node 位置。

## 三种模式

```powershell
# 仅检查环境
python codexandclaude/tools/run_checks.py env
# 专项 Python（可重复 --python-module；使用 unittest 接受的模块名或文件路径）
python codexandclaude/tools/run_checks.py focused --python-module tests/test_game_project.py
# 纯文档任务的 G3：两个 Python 测试目录，不运行 G2
python codexandclaude/tools/run_checks.py focused --python-all
# 专项 Godot：只接受 verify_game.py 已登记的脚本；先导入再测试
python codexandclaude/tools/run_checks.py focused --godot-script res://tests/test_hud_layout.gd
# 全量：原验证器 G2 → tests/ → codexandclaude/tests/（G3）
python codexandclaude/tools/run_checks.py full --jobs 4
```

`--root` 可指定另一个工作区，默认是脚本所在工作区，避免从错误当前目录测试主工程。
`--timeout` 是每条验证命令的外层超时（默认 3600 秒）；原验证器各套件超时保持不变。
专项 Godot 通过子进程直接复用原验证器的 `execute()`，包含原错误标记、汇总及超时判定。
全量仅核对原验证器的退出状态与登记条目是否完整，不重新实现引擎判定。
任一检查失败即停止后续检查并返回非零退出码，保留日志。

## 证据

终端与 `codexandclaude/runs/<UTC时间>/summary.json` 输出同一份汇总：工作区、SHA、dirty/status、
工具路径和版本、命令参数数组、退出码、耗时、日志位置及 SHA256、已执行检查数量与结果。
G2 记录预期/实际条目数（含导入和主场景），G3 记录两个完整发现目录及各自 unittest 计数。
未完成的检查不会标通过；工具或 Git 不可用时 SHA 等尚未获取的字段为 null，原因记在 reason。
入口自身出现意外异常时同样写出汇总并返回非零，reason 记异常类型与信息，traceback 字段记调用栈。

**门禁不接受跳过的测试。** unittest 汇总为 `OK (skipped=N)` 或含 `expected failures` 时判为失败：
跳过通常意味着缺少工具或依赖，计为通过会掩盖问题。遇到时应修复依赖，或移除跳过并让测试真实运行。
每条命令完整输出独立保存；G2 原报告保存为同目录的 engine.txt。
日志不入 Git，交付/审查记录需提交命令、计数和汇总结论。
Godot full/focused 可能生成正常的 `.godot` 缓存和 `outputs/` 测试输出。

### 自动摘要与内容身份（ENV-005）

三种模式每次都在summary.json同目录生成`evidence.md`，可整段复制到交付或审查记录，不自动修改记录、不自动提交。摘要包含入口及实际子命令（JSON参数数组）、SHA、干净状态、工具版本、计数与完整性、时间、失败原因、日志及报告哈希。Python的预期数明确标为unittest发现数（未另行枚举），不把实际数冒充独立预期；env成功只表示环境探测成功，不能当作G2/G3。未完成、少执行、缺汇总、超时或异常均输出不通过。没有基线失败证据时不猜测新旧归因。

summary.json旧字段不变，新增`evidence_schema`、`finalized`、`planned_checks`、`invocation`、`content`、`content_end`、`content_stable`。两份内容快照分别在检查前后采集：提交SHA/树哈希、已提交范围指纹、原始工作区全量/范围SHA256、原始Git二进制diff SHA256（总差异、暂存、未暂存）、每个未跟踪文件路径/模式/内容SHA256。删除、重命名、符号链接也进入指纹。工作区指纹覆盖已跟踪及Git未忽略的未跟踪文件；不遍历忽略的缓存、输出、其他worktree或仓库外文件。

提交范围指纹是按路径排序的Git blob身份与模式清单的SHA256；工作区指纹是原始文件字节SHA256清单的SHA256。两者分开记录，避免把Windows CRLF检出或LFS展开字节冒充提交blob。采集只读，不改Git索引或运行clean过滤器。起止快照不一致时保留实际门禁结果及两份快照，但不能将该运行作为复用来源；这不是对中间每次瞬时写入的监控。不在检查运行时编辑交付记录。Git不可读、未合并索引或子模块不能提供可靠指纹时失败，不降级成可复用。

### 证据复用（ENV-005）

```powershell
# 两个固定提交的内容条件比较（不证明曾有成功测试）
python codexandclaude/tools/check_evidence.py --source-ref <实现SHA> --target-ref <交付SHA>
# 成功运行的原始摘要与目标提交比较
python codexandclaude/tools/check_evidence.py --source-summary codexandclaude/runs/<UTC时间>/summary.json --target-ref HEAD
```

可用`--root`指定工作区、`--git`指定Git。输出JSON含固定解析后的SHA、树、范围、指纹、全部变化路径、非记录变化路径，以及按关卡的`gate_reuse`、`reusable_gates`、`rerun_gates`。顶层`reusable`表示全部来源关卡都满足复用内容条件：只有它为true才退出0，部分可复用也退出1，必须逐关读取结论。缺失/旧格式摘要、失败或未完整运行、缺少最终汇总、脏来源、内容中途变化、源指纹与提交不符，均不可复用。若目标是当前HEAD，当前工作区也必须干净，避免用提交替代未提交内容。

默认固定排除范围只含`codexandclaude/runs/**`，以及`codexandclaude/tasks/<大写领域-数字>/{delivery,review,integration,acceptance}.md`这些直接位于任务目录的记录文件。**不排除task.md、proposal.md、Words、env.md、任务目录中的脚本、嵌套目录或任何代码/测试/配置。** 不提供任意扩大排除范围的参数；范围版本不一致拒绝复用。排除的记录仍在全工作区指纹、脏状态及未跟踪哈希中保留。

复用必须同时满足：来源摘要成功且完整、起止均干净且稳定、同一范围内没有任何非记录路径差异；另外由使用者核对工具版本、实际命令参数与外部依赖一致。忽略文件、本地配置、环境变量、仓库外资源并未由内容指纹证明相同，无法核对则重跑。比较命令只证明内容条件，不自动跳过门禁、不补做未运行关卡、不代替另一方独立审查及用户授权。

**只改记录时G2可复用，G3必须重跑。** G3的协作Markdown链接检查实际读取被排除的记录文件，不能因代码范围指纹相同就沿用G3。记录变化时其他非G2专项关卡也保守标为须重跑；没有任何路径变化时，才允许所有已通过来源关卡满足复用内容条件。非记录文件或测试有变化时，各关卡均不可复用。摘要比较只列出来源实际执行的关卡，不会将仅有G3的来源当作G2证据；两提交比较则列G2/G3内容条件，仍须有效原始摘要。交付记录应写明“G2可复用、G3已重跑”并记录这次G3结果。

资源检查只忽略完整引用前缀 `res://../` 的工程外运行时输出；工程内资源不存在仍失败。
ENV-001 首次验收须在没有 outputs/ 的新工作区只跑 G3，证明它不再依赖 G2。

## 引擎套件登记（ENV-004）

每个可独立执行的 `game/tests/test_*.gd` 在**第一行**用一个 JSON 注释登记，例如：

```gdscript
# verify-suite: {"name":"example regression","path":"res://tests/test_example.gd","marker":"EXAMPLE_TESTS checks=","fixed_fps":null,"timeout":60}
extends SceneTree
```

新增或删除套件只改它自己的文件；不要再改公共列表或固定总数。五个字段必须齐全，不接受额外字段：name为唯一非空报告名称（不能使用导入/主场景的名称），path必须是自身文件的规范res://路径，marker为唯一的`大写字母数字下划线 checks=`前缀；timeout为正整数秒，fixed_fps为null（真实时间）或正整数。运行参数跟随该行，不根据文件名推断。名称/路径/结果标记均不可重复。

`verify_game.discover_suites()`按路径排序扫描tests下所有`test_*.gd`，漏掉登记、无效元数据、指向不存在的文件或其他文件均失败。非独立运行的同名辅助脚本必须在`verify_game.EXCLUDED_TESTS`中以`res://路径: 排除理由`显式说明；排除项必须存在且不能同时登记，目前清单为空。普通辅助脚本宜使用不以`test_`开头的文件名。

`SUITES`携带完整参数，`TESTS`只是由它派生的三元组兼容视图，供门禁统计及现有消费者使用。执行入口逐个收集实际完成的套件路径，核对多重集合：漏执行、多执行、重复执行均失败；G2外层仍核对全部PASS名称和成功汇总，不能用注册表长度代替文件覆盖检查。专项入口也通过`execute_suite()`使用相同运行参数。

ENV-004只迁移73个原有套件的头部注释，未改测试逻辑；报告及提交调度顺序改为路径排序，套件集合、名称、结果标记、固定帧率和超时保持不变。新增套件后数量自动变化，文件覆盖与执行集合检查持续生效。

## Git 与提交（V2.3）

- **远程**：`origin` = `https://github.com/aiother/31DAYS-A.git`（私有，2026-10-30 建立），只跟踪 `master`。凭据由 Git 自带的 Git Credential Manager 保存，首次推送弹出 GitHub 授权窗口，由用户确认。推送 `git -c safe.directory=D:/31days push origin master`，LFS 图片随推送上传；核对用 `git ls-remote origin` 与 `git lfs push --dry-run origin master`（无输出即无遗漏）。规则见 [collaboration.md](collaboration.md) 第 9 节。
- **仓库所有权**：`.git` 属于 Codex 的沙盒用户。Claude 侧每次 Git 调用都临时放行，例如 `git -c safe.directory=D:/31days -c safe.directory=D:/31days/codexandclaude/worktrees/claude ...`；不修改全局配置。
- **提交说明**：多行、含英文引号或特殊字符的说明，写入 UTF-8 文本文件后用 `git commit -F <文件>`。Windows PowerShell 5.1 把含英文双引号的字符串作为参数传给 git 时会拆坏参数，导致提交失败或说明错乱。说明文件放在系统临时目录等不会被误暂存的位置；简单单行说明仍可用 `-m`。暂存始终使用显式路径。
- **换行符**：工作区检出为 CRLF。用脚本按多行文本替换时，先确认换行符一致，否则替换会静默失败；多行替换优先用编辑工具。
- **导入生成物**：Godot 全量或专项运行会让两份 `.svg.import` 出现仅换行符变化（`git diff --ignore-cr-at-eol` 为空），检查后用 `git restore` 还原，不提交。

## 通用 G4 验收启动器（ENV-006）

独立验收进程从入口启动，不改项目主场景或正式按键。默认适配 SYS-004：

```powershell
# 用户点击验收；关闭窗口自动清理临时存档
Godot --path game --script res://tests/acceptance/run_acceptance.gd
# 无头自测，注入实际鼠标事件；不替代物理帧或推进计时器
Godot --headless --path game --script res://tests/acceptance/run_acceptance.gd -- --self-test
# 有渲染的截图自测；headless 不支持截图，会明确失败
Godot --path game --script res://tests/acceptance/run_acceptance.gd -- --self-test --capture
```

旧 SYS-004 命令 `--script res://tests/test_completed_slots.gd -- --acceptance` / `--acceptance-smoke` / `--capture` 仍兼容，转交同一个适配器；普通已通关槽回归测试不改逻辑。

参数：`--self-test`（兼容 `--acceptance-smoke`）、`--no-panel`、`--slot=1..3`、`--checkpoint=<ID>`、`--capture`、`--capture-dir=<目录>`、`--adapter=res://<适配脚本.gd>`。未知参数或非法槽位会失败。截图默认保存到忽略目录 `codexandclaude/runs/<任务ID>-g4/`，分别为 slots、blocked、new-game；可用 capture-dir 改输出目录。

适配脚本继承 `res://tests/acceptance/acceptance_harness.gd`，提供 `configuration()`：

- `scene`：继承 CheckpointLab 的会话 PackedScene；正式主入口可用 FinalBattleSession 场景。
- `snapshots`：槽编号到真实存档字典的映射；值也可以是按保存顺序排列的字典数组，用来准备主档和备份。
- `enter`：true 则加载指定 slot 的检查点，false 留在真实选槽界面；检查点由存档决定，也可用 checkpoint 参数覆盖。
- `id`、`instructions`：输出目录标识和说明；`marker` 可选，决定自测汇总前缀。

可覆盖 `status_fields()` 返回只读显示字段；可覆盖异步 `self_test()`，用基类 `check()`、`click()`、`frames()`、`capture()` 实现该任务的实际操作检查。UI-002 自己提供其适配，不需复制目录创建、参数处理、面板或清理代码。默认面板读当前日、余额、生命，不写状态。

启动器在 OS 缓存目录新建 `31days_acceptance_<进程>_<唯一时间>/`，在场景 ready 前设置 save_directory，随后核对 store.directory，确认隔离后才写夹具。退出或关闭窗口清理该进程生成的平面槽文件和目录；截图留在上述输出目录。重定向失败会在写夹具前终止，正式玩家存档不参与。不能把启动器注入已运行的玩家会话；它只用于独立验收进程。

### 导入行尾（BL-113）

`.gitattributes` 固定 `*.import text eol=lf`，覆盖 SVG 和字体导入描述；不改 Godot 输出、测试或证据稳定性判定。新检出会直接得到与 Godot 相同的 LF 字节。已有 CRLF 检出的工作区采用该已提交规则后，文件可能仍为 `i/lf w/crlf`，且 Git 状态干净。`git checkout-index --force` 加 `git add --renormalize` 不保证重写这些工作树字节，不能把“暂存为空”当成迁移完成。

在仓库根目录先运行 `git ls-files --eol -- '*.import'`，只选出其中 `w/crlf` 的文件。逐个核对 `eol: lf` 属性已生效、该文件无暂存修改，并将工作树与 `git show HEAD:<文件>` 的原始字节仅归一 CRLF 后比较；含实质编辑就停止，保留原文件。确认后才删除这个明确文件并重新检出。以下是 PowerShell 单文件示例；将 `$importPath` 换成刚查到的一个路径，每个文件重复执行（Python 通过 subprocess 读取 Git 原始字节，避免 PowerShell 管道重编码）：

```powershell
$importPath = 'game/assets/characters/player_placeholder.svg.import'
$importRule = git check-attr eol -- $importPath
if ($LASTEXITCODE -ne 0 -or -not $importRule.EndsWith(': eol: lf')) { throw 'LF 属性未生效，停止' }
git diff --cached --quiet -- $importPath
if ($LASTEXITCODE -ne 0) { throw '该文件有暂存修改，停止' }
@'
from pathlib import Path
import subprocess
import sys
path = sys.argv[1]
committed = subprocess.check_output(['git', 'show', 'HEAD:' + path])
working = Path(path).read_bytes()
same_content = working.replace(b'\r\n', b'\n') == committed.replace(b'\r\n', b'\n')
sys.exit(0 if same_content else '存在实质编辑，停止；未删除文件')
'@ | python - $importPath
if ($LASTEXITCODE -ne 0) { throw '内容核对失败，停止；未删除文件' }
Remove-Item -LiteralPath $importPath -ErrorAction Stop
git checkout -- $importPath
if ($LASTEXITCODE -ne 0) { throw '重新检出失败，停止并报告' }
git ls-files --eol -- $importPath
git status --short
```

全部目标处理后，再运行 `git ls-files --eol -- '*.import'`，确认所有已跟踪导入描述均为 `w/lf`；原本干净的工作区应仍然 `git status --short` 无输出。不要删除整目录、刷新无关文件的索引或使用全局重置；其他既有用户改动照常保留。重新检出失败时先报告，不继续运行导入或检查。

原先“检查后还原导入生成物”的做法仅适用于采用该规则之前的旧提交。新规则下，正常导入不应再改变这些文件的原始字节，full 的 `content_stable` 应为 true；若仍为 false，查看起止快照，不能忽略变化或手改摘要。
