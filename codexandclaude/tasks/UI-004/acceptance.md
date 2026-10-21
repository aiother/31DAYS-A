# UI-004 G4 用户验收

状态：**通过**（2026-10-21，用户）。无调整要求。

## 对象

- 分支 `claude/UI-004`，交付 SHA `5136b691a69eb0d05608e68c92fa6cef0914c3d7`（实现 `8d2d4c96d993801e3f2c6ea6eda8879eaf5d7135`），在 Claude 工作区运行。
- 入口（PowerShell）：

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui004_title.gd
```

交付记录里的 G4 命令未给 `--` 加引号，在 PowerShell 下可能被吞掉；以上为实际使用的写法。

## 内容

独立临时存档：槽1 第2日进行中、槽2 已通关、槽3 无法读取；F2 切换槽3为空 / 无法读取，F3 清空全部临时存档。按交付记录“G4（用户）”一节试主界面方案 A、书签与天空条、已通关印与提示、覆盖确认默认“返回”，以及键盘 / 手柄 / 鼠标操作。

## 结果

用户原话：“没问题”。主界面与存档选择符合 EXP-003 所选方案，没有提出修改。

过渡项（主界面“设置”暂用 UI-003 暂停菜单的设置页）不在本次验收范围内，留给 UI-006。
