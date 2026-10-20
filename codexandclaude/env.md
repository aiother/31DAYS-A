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

资源检查只忽略完整引用前缀 `res://../` 的工程外运行时输出；工程内资源不存在仍失败。
ENV-001 首次验收须在没有 outputs/ 的新工作区只跑 G3，证明它不再依赖 G2。

## Git 与提交（V2.3）

- **仓库所有权**：`.git` 属于 Codex 的沙盒用户。Claude 侧每次 Git 调用都临时放行，例如 `git -c safe.directory=D:/31days -c safe.directory=D:/31days/codexandclaude/worktrees/claude ...`；不修改全局配置。
- **提交说明**：多行、含英文引号或特殊字符的说明，写入 UTF-8 文本文件后用 `git commit -F <文件>`。Windows PowerShell 5.1 把含英文双引号的字符串作为参数传给 git 时会拆坏参数，导致提交失败或说明错乱。说明文件放在系统临时目录等不会被误暂存的位置；简单单行说明仍可用 `-m`。暂存始终使用显式路径。
- **换行符**：工作区检出为 CRLF。用脚本按多行文本替换时，先确认换行符一致，否则替换会静默失败；多行替换优先用编辑工具。
- **导入生成物**：Godot 全量或专项运行会让两份 `.svg.import` 出现仅换行符变化（`git diff --ignore-cr-at-eol` 为空），检查后用 `git restore` 还原，不提交。
