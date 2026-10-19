# ENV-001 集成与合并后验证

集成者：Codex｜日期：2026-10-19｜结论：用户授权的固定审查提交已合入 master，合并后 G2＋G3 全量通过。

## 固定提交与范围

- 合并前 master：`6a7b0d8a0343f16c3e12181b1fb7196ea085512c`。
- 实现 SHA：`f6c55516fa800ebe176ca84b050f1e3de275bbef`。
- 交付 SHA：`bb6082f3075d455d4c7270f79d9c04a4dc3b30b1`。
- 用户授权的审查 SHA／合并后被测 master：`3f54a7bedf804b324d8d110fcb98da0af30294c9`。
- 执行 `git merge --ff-only 3f54a7bedf804b324d8d110fcb98da0af30294c9`，快进成功。没有合并可移动的分支名。
- 合并前检查了完整差异：共 10 个文件，均为任务实现、交付或审查材料，不涉及用户未提交的三个文件。
- 核对实现提交是审查提交的祖先，实现代码及测试与被审版本一致；交付至审查提交仅增加审查记录并更新任务首部状态。

## 合并后完整验证

在主目录 `D:/31days`、master 上执行：

```powershell
python codexandclaude/tools/run_checks.py full --jobs 4
```

Godot 导入需要访问系统证书及用户编辑器设置，经执行权限批准后在沙盒外运行。
原验证器未修改，G2 按原逻辑执行；入口随后完整运行两个 Python 测试目录。

| 检查 | 结果 |
| --- | --- |
| G2 引擎 | 预期 73、实际 73 个通过条目：导入、主场景及 71 个登记套件 |
| G2 汇总核对 | 71 个登记套件各有对应的完整零失败汇总行；错误、解析失败、泄漏、非零失败及超时标记均为 0 |
| G3 工程 Python | tests/ 70/70，OK |
| G3 协作 Python | codexandclaude/tests/ 29/29，OK |
| 总进程 | 退出码 0，summary.passed=true |

开始 UTC：2026-10-19 11:30:12；结束 UTC：2026-10-19 11:42:50，约 12 分 38 秒。
本任务无 G4 要求。

### 被测工作区状态

汇总中的 sha 为上述审查 SHA，dirty=true：主目录保留用户原有的两份 xlsx、game/project.godot 未提交修改，以及未跟踪的 .claude/。
本轮验证的是这个实际工作树，没有把它描述成干净提交的验证；未暂存、还原或覆盖这些用户文件。
完整验证期间未修改实现代码，未增加待提交的集成文档。

### 工具版本与路径

- Godot 4.7.2.stable.official.ed1daf0bf：`D:/DMyself/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`。
- Python 3.12.14、openpyxl 3.1.5：`C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`。
- Git 2.56.0.windows.2：`C:/Program Files/Git/cmd/git.exe`。
- Node v24.19.0：`C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe`。

### 日志与摘要

主目录下保留以下忽略文件，不提交原始日志：

- `codexandclaude/runs/20261019T113012.280266Z/summary.json`：工具、命令、退出码、耗时、工作树状态、完整性及计数。
- 同目录 `engine.txt`：原始引擎报告；001.txt～009.txt 为工具／Git／验证命令日志。
- `codexandclaude/runs/ENV-001-master-full-console.txt`：入口终端汇总。

engine.txt SHA256：`09100eac69ef6fd5d1d8322001eba45aa86dac8dfd170b8e539cb010d89c0244`。
summary.json SHA256：`6da115815ec218b765629067a558386ff624cfe4bc2685cc1f2759bf19e2e9e9`。

## 用户文件保护

以下 SHA256 在合并前、合并后及完整回归结束后均一致：

| 文件 | SHA256 |
| --- | --- |
| Words/T6_资源配置填写模板.xlsx | e369dff6c5ae147e22cf1ee33781df159a07d5191dbe9a267a943b4b0a8fa727 |
| Words/T7_UI_UX与存档规格填写模板.xlsx | fa46e8d4b48e69d46fe631c6e5223963d5222934edbe1867ee20864ec96be908 |
| game/project.godot | 239f177c923343f54f6665f0ac11543fcd4db1275ca8e5334c177c9b45314998 |

没有使用 stash、reset 或备份恢复绕过用户改动，也没有推送远程。

## 证据提交

完整回归通过后，仅新增本记录并更新 task.md 首部为已完成。按 V2.2 的证据／纯文档规则，提交前运行 G3，不因证据更新再次触发 G2。
本记录不包含自身提交 SHA；该 SHA 在最终交付消息及 Git 历史中查询。
Claude 审查中的三项非阻断建议保留在 review.md，本次未扩大范围实施。
