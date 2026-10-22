# UI-007 G4 用户验收

状态：**通过**（2026-10-22，用户）。无调整要求。

## 对象

- 分支 `claude/UI-007`，交付 `900ebff2033cef3163d9ef6402aae0fa34b0b4f5`（实现 `80a8a9d3660086adb40851fa7937157bae6d198b`），在 Claude 工作区运行。
- 入口（PowerShell）：

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui007_area_prompts.gd
```

## 内容

按交付记录“G4（用户）”一节：跨区域的区域名称、同区域不显示；靠近珍珠、开关、检查点、NPC 时的交互提示位置与样子；营帐关键珍珠的闪烁；暂停、对话时提示隐藏。

## 结果

用户原话：“没问题”。没有提出修改。灰盒世界提示与正式提示并存属已知事项（见交付记录“说明与未决”），用户未要求在本任务内处理。
