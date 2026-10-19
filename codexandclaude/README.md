# Codex 与 Claude 协作入口

当前阶段：官方 Claude Code 已安装，用户确认已切换手动审批；先做人工触发的只读审查，尚未授权 Claude 修改游戏或开展自动协作。

## 文件入口

- [协作规范](collaboration.md)：职责、冻结范围、Git 和验收规则。
- [Claude 首次只读任务](first_review.md)：用户手工交给 Claude Code 的完整任务。
- [规范验证](tests/test_collaboration.py)：验证入口、任务边界和项目引用。

Claude 可以在整个 `D:\31days` 项目按任务工作；`codexandclaude/` 只存放双方协作规范、交接、审查记录及相关验证，不是它的项目访问边界。游戏源码及游戏测试仍按原工程组织。

首次使用：在 Claude Code 中粘贴本目录 first_review.md 的任务，或要求其读取并执行该文件。审查结果先返回 Claude 会话，由用户转交 Codex；此轮不写审查报告文件。

本轮只读审查结束后再选一个范围明确的 UI 任务，建立独立 Git worktree、明确文件归属和验收，再开始写代码。当前共享工作目录已有用户未提交变更，不允许双方同时编辑。

运行协作规范验证（在项目根目录）：

```powershell
python -X utf8 -m unittest discover -s codexandclaude/tests -v
```

文档验证通过不代表游戏运行、视觉效果、Claude 审查或双 Agent 集成已经验收。
