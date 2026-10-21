# 正式设置界面（UI-006）

BL-047 / A-017 落地：总音量、效果音、背景音、窗口尺寸、全屏、帧率上限、只读按键列表与恢复默认。所有改动经 SYS-007 的 `GameSettings`（`SettingsService`）接口，立即生效并保存到独立设置文件；界面不读写文件或总线。

## 结构

- `game/ui/menus/settings_page.gd`（`SettingsPage`）：整页（1000×800，与 UI-003 的二级页同尺寸）。左列六行设置与“恢复默认”，右列按键列表（`SettingsPage.KeyList`），左下“返回”。每帧写入 `drawn` 供测试读取。
- `game/ui/menus/setting_row.gd`（`SettingRow`）：一行可聚焦的墨线设置项，四种：滑条（0～100，步长 5）、选项（循环）、开关、动作。`commit(value)` 等同玩家选择并发出 `changed`。
- `game/ui/menus/pause_menu.gd`：`show_settings(from_title = false)` 打开同一个 `SettingsPage`（第一次使用时创建并保留）。暂停中打开时在右侧盖住时钟；`from_title` 时隐藏暂停选项、不画时钟，设置页居中在变暗的主界面上。
- `game/ui/menus/life_ui.gd`：主界面“设置”把暂停菜单移到主界面之上并以 `from_title` 打开；返回时移回主界面之下，焦点回到主界面“设置”。暂停中打开则返回暂停菜单的“设置”。

## 操作

| 输入 | 作用 |
| --- | --- |
| 上 / 下（方向键、十字键） | 在各项间移动：总音量 → … → 帧率上限 → 按键列表 → 恢复默认 → 返回 |
| 左 / 右 | 调整滑条（±5）、切换选项；开关也可左右切换 |
| Enter / A | 切换开关、选项下一项、执行“恢复默认” |
| Esc / Back（及 Start、B） | 关闭确认框；否则返回打开设置的地方 |
| 鼠标 | 点或拖滑条到位置；点选项左侧退一项、右侧进一项；点开关切换；滚轮滚动按键列表 |

打开时焦点在“返回”，与 UI-003 其他二级页一致。按键列表获得焦点后，上下键先滚动，到头后再把焦点交给上一项 / 下一项；只画完整落在列表内的行，滚动条显示当前位置。列表来自 `bindings()`，按 T1 §7 冻结顺序共 15 项（含“调试重置”），下方注明“自定义按键将在后续版本提供”。

“恢复默认”先弹确认（默认焦点“返回”），确认后调用 `restore_defaults()` 并刷新各行。`GameSettings.changed`（例如 F11）也会刷新显示。

## 测试与验收

- `game/tests/test_settings_page.gd`：真实会话，测试进程自动使用隔离设置文件；真实键盘、手柄、鼠标；每项改动核对接口值、设置文件与实际总线 / 帧率；按键列表逐项与 `bindings()` 一致；两种窗口尺寸下各项在纸面内且不重叠；从暂停与主界面打开都回到原处。
- G4：

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path game --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui006_settings.gd --settings-file=$env:TEMP\31days_ui006_settings.cfg
```

`--settings-file` 指向一个临时设置文件，关掉再开同一命令可确认已保存；验收结束后删除该文件即可。不带它时测试进程用一次性设置文件，关闭即删除。
