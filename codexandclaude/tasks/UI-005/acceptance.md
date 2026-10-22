# UI-005 G4 用户验收

状态：**通过**（2026-10-22，用户）。无调整要求。

## 对象

- 分支 `claude/UI-005`，交付 `22a635d017e214f397a3c647539064902fe245ea`（实现 `3caa56735fa748aaae80f984f4f2097dc9ec1537`），在 Claude 工作区运行。
- 入口（PowerShell）：

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui005_outcomes.gd
```

## 内容

按交付记录“G4（用户）”一节：槽1 第1日进入后 F5 倒下看死亡界面四个选项，暂停菜单“返回标题”；槽2 最终战超时（可重试）；槽3 第三日探索超时，主界面 F3 / F4 / F2 切换为无预算超时、V0.1 结束、探索超时。

## 结果

用户原话：“G4没问题”。没有提出修改；结束与超时纸面去掉“保存并退出”的取舍未提异议。
