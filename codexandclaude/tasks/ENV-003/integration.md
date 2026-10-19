# ENV-003 集成与合并后验证

集成者：Codex｜日期：2026-10-19｜结论：固定审查提交已合入 master，合并后 G2＋G3 全量通过。
用户本轮要求先完成 ENV-003，再合入已批准的 ENV-002 规划提交。

## 合并

- 合并前 master：`e19e47437838025ecba21e598a5e6c045e2d8fe5`。
- 已通过审查的固定 SHA：`be6f6bb7a8c3b2f8a312a518edbb1ca3efacc80b`。
- 执行 `git merge --no-edit be6f6bb7a8c3b2f8a312a518edbb1ca3efacc80b`，三方合并成功，无冲突。
- 合并提交／被测 master：`246908c49b25c680f49e9af376145e1a5ce69b44`。
- 合并前按共同基线核对文件清单，ENV-003 仅涉及入口、入口测试、env.md 及自己的任务记录，与用户三个未提交文件没有重叠。
- master 上原有 ENV-001 集成记录与已完成状态均保留，没有被旧基线覆盖。

## 合并后完整验证

在 `D:/31days` 的 master 执行：

```powershell
python codexandclaude/tools/run_checks.py full --jobs 4
```

为允许 Godot 访问系统证书和用户编辑器设置，经执行权限批准后在沙盒外运行。
开始 UTC 12:07:58，结束 UTC 12:18:32，约 10 分 34 秒，进程退出码 0。

| 检查 | 结果 |
| --- | --- |
| G2 | 预期 73，实际 73 个通过条目：导入、主场景和 71 个登记套件 |
| 原始报告核对 | 71 个登记套件各有一条对应的零失败汇总；错误、解析失败、非零失败、泄漏与超时标记均为 0 |
| G3 tests/ | 70/70，OK |
| G3 codexandclaude/tests/ | 35/35，OK |
| 入口 | summary.passed=true，sha 为上述合并提交 |

dirty=true：工作区保留用户原有两份 xlsx 和 game/project.godot 修改。本次记录的是这个实际工作树，未将其描述为干净提交的测试。
验证期间未修改实现文件，未提前合入 ENV-002。

工具版本：Godot 4.7.2.stable.official.ed1daf0bf，Python 3.12.14＋openpyxl 3.1.5，Git 2.56.0.windows.2，Node v24.19.0。
完整工具路径、参数数组、退出码、计数、耗时与各命令日志摘要在主目录 `codexandclaude/runs/20261019T120758.992848Z/summary.json`。
同目录 engine.txt 是原验证器报告；入口终端汇总另保留于 `codexandclaude/runs/ENV-003-master-full-console.txt`。原始日志不提交。

- engine.txt SHA256：`bd8cc0b40c30c407a7f1ce41711aa7b609e927312dc8262f3a88ca8705084e46`。
- summary.json SHA256：`c64655dbf1ffa45fcdb972f04e7b0d16a2acbdc0a63b262e8bc8f5d7a993d87d`。

## 用户文件保护与收尾

以下文件在合并前与完整回归后 SHA256 均一致：

| 文件 | SHA256 |
| --- | --- |
| Words/T6_资源配置填写模板.xlsx | e369dff6c5ae147e22cf1ee33781df159a07d5191dbe9a267a943b4b0a8fa727 |
| Words/T7_UI_UX与存档规格填写模板.xlsx | fa46e8d4b48e69d46fe631c6e5223963d5222934edbe1867ee20864ec96be908 |
| game/project.godot | 239f177c923343f54f6665f0ac11543fcd4db1275ca8e5334c177c9b45314998 |

未暂存用户文件，未使用 stash、reset 或覆盖恢复；未推送远程。本任务无 G4 要求。
完整验证通过后，只新增本记录并更新任务首部为已完成，按证据规则提交前跑 G3，不因记录更新重复 G2。
本记录不包含自身提交 SHA；其提交完成后再接续 ENV-002 规划集成。
