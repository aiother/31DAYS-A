# DOC-003 集成与合并后验证

集成者：Codex｜日期：2026-10-19｜结论：用户授权的固定审查提交已合入 master，合并后 G3 通过，DOC-003 已完成。

## 固定提交与范围

- 合并前 master：`42c3652e8714e24dd3cde16a07a0f7b9771f3408`，与实现基线一致，索引为空。
- 实现 SHA：`4bf5b87608ed2385c43680a88c83ecd443a79880`。
- 交付 SHA：`7474a22db01aeb219787417eac410b4bf3c51f1c`。
- 固定审查 SHA／合并后被测 master：`c17b109cb202a550be9ab3ecc7268988a22dc758`。
- 执行 `git merge --ff-only c17b109cb202a550be9ab3ecc7268988a22dc758`，快进成功，无冲突；没有合并可移动分支名。
- 合并范围为六份 Words 文档、两份相关测试及 DOC-003 的任务卡、交付与审查记录；与受保护的 `game/project.godot` 及原有未跟踪文件无重叠。

## 集成验收用例与结果

| 用例 | 预期 | 实测 |
| --- | --- | --- |
| 固定 SHA 集成 | 合并已通过审查的完整提交，包含实现、交付及审查记录 | 符合；master 快进到上述审查 SHA |
| 用户文件保护 | project.godot 合并前后内容一致 | SHA256 一致，见下方 |
| 合并后 G3 | 两组 Python 测试完整通过，入口退出0 | tests/ 81/81、codexandclaude/tests/ 37/37，complete=true、passed=true，入口退出0 |

在主目录 `D:/31days` 的 master 执行：

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

summary.passed=true，被测 SHA 为上述审查 SHA。dirty=true，仅列原有未跟踪的 `.claude/settings.local.json`，未操作或暂存该文件。

工具版本：Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0。命令、工具路径、退出码、套件计数和日志哈希见主目录 `codexandclaude/runs/20261019T170130.332184Z/summary.json` 与同目录日志；原始日志不提交。
按纯文档矩阵仅执行 G3，无需 G2/G4，未调用 Godot。

## 用户文件与收尾

`game/project.godot` 在合并前及合并后验证时 SHA256 均为：
`683572e7c869772b23f73ac50914b3e11dad7821411cbbcc0a9f46526cddc5a7`。

没有覆盖、还原、暂存用户文件，没有使用 stash 或推送远程。BOARD 留给规划维护者串行汇总，任务卡为权威状态。

本证据提交只新增本记录并更新任务卡首部为已完成；提交前再次执行 G3、检查差异和配置文件哈希。最终证据提交 SHA 由交付消息提供，不写入自身记录。
