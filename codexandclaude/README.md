# Codex 与 Claude 协作入口

两个 Agent 按 V2.2 协作方案人工协作：用户决策并在两边之间转话，Agent 之间只通过本仓库交接，每个任务一人实现、另一人审查。

## 现行依据

- [协作方案 V2.2（试行中）](plan_v2.md)：用户已确认试行；试行期间与协作规范冲突时以本方案为准，阶段 2 复盘后正式并入。
- [协作规范](collaboration.md)：原有职责、冻结范围、Git 与验收规则；与试行方案不冲突的部分继续有效。
- [协作检查入口](env.md)：工具配置与 `env` / `focused` / `full` 三种检查模式。

## 任务

- [任务板](BOARD.md)：所有任务的汇总；权威状态以各任务卡首部为准。
- [待办清单](BACKLOG.md)：尚未立项的事项，按优先级排列，立项时登记任务 ID。
- `tasks/<ID>/`：进行中与近期完成的任务，每个目录含 `task.md`，M/L 级另有 `delivery.md`、`review.md` 及集成记录。
- [archive/](archive/HUD-001/README.md)：已归档的任务，目前为 HUD-001 人工协作试点。

## 运行检查

在自己工作区的根目录执行。纯文档任务只需 G3：

```powershell
python codexandclaude/tools/run_checks.py focused --python-all
```

涉及游戏代码、输入、存档或验证流水线时按方案第 7 节跑全量：

```powershell
python codexandclaude/tools/run_checks.py full --jobs 4
```

文档检查通过不代表游戏运行、视觉效果或人工验收已经完成。

## 范围说明

两个 Agent 都可以按任务在整个 `D:\31days` 项目中工作；`codexandclaude/` 只存放协作规范、任务交接、审查与集成记录及相关检查，不是项目访问边界。游戏源码和游戏测试仍按原工程组织。主目录 `D:\31days` 属于用户，Agent 在各自的 `worktrees/` 中工作。
