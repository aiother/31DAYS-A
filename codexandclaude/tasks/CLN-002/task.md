# CLN-002：仓库清理（旧 worktree 与分支）

状态：待批准（第十二批草稿，可选）｜级别：S｜实现：Claude｜审查：Codex
工作区：主目录（只做 Git 管理操作，不改文件内容）｜基线：本任务卡合入后的 master 最新提交｜依赖：无

## 目标

清掉已结束任务留下的 worktree 与分支，降低磁盘占用与误用旧分支的风险；废弃但未合并的分支先打 tag 归档，保证历史可找回。

## 依据

- 待办 BL-006（清理已合并的任务分支）、BL-129（旧 worktree 与废弃分支）。
- 2026-10-30 仓库盘点：`codexandclaude/worktrees/` 约 1.1 GB，8 个 worktree（4 个嵌套在 Codex 的 runs 下）；159 个分支已合并进 master；未合并的废弃分支有 `claude/ART-002`、`claude/player-redesign`、`claude/player-reset`、`claude/M3-asset-sources`（内容已由 PLN-003 入库）等。

## 要求

1. 先列清单交用户确认：每个 worktree 与分支的去留、理由、对应任务。**用户逐项确认前不删除任何东西。**
2. 未合并的分支一律先打 tag（`archive/<分支名>`）再删除分支；已合并的分支直接删除。
3. 删除 worktree 用 `git worktree remove`，不手动删目录；Codex 正在使用的 worktree 不动。
4. tag 只留在本地，不推送（协作规范 V2.4 只推送 master）。

## 允许修改的文件

- 不改任何受版本管理的文件；只操作分支、tag 与 worktree。
- `codexandclaude/tasks/CLN-002/`（清单与交付记录）。

## 完成标准

1. 用户确认的清单与实际操作一致；每个删掉的未合并分支都有对应 tag。
2. `git worktree list`、`git branch` 前后对比写入交付记录。

## 检查

- 只读核对：`git tag -l 'archive/*'` 与删除清单逐项对应；G3 不需要（没有文件改动）。

## 回滚方案

已合并分支可从 master 历史重建；未合并分支从 `archive/*` tag 恢复。

## 不在范围内

- 改写历史、清理远程、删除 tag。
