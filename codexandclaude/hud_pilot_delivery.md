# HUD-001 交付记录：灰盒 HUD 与错误提示防重叠

工作区 D:\31days\codexandclaude\worktrees\claude-hud，分支 claude/hud-layout-pilot，起始 HEAD 21861a7f05a703f0acdb3abca229fe47b2d2a58c（游戏代码基线 36d05826ba24eea9423204eaca6de956b48a33af + 协调者准备提交）。开始时 git status 仅有被忽略的 .godot、outputs、runs、__pycache__。提交哈希见会话回复。

## 复现（修复前）

先新增 game/tests/test_hud_layout.gd，在未修改的 life_ui.gd 上运行：

```
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_hud_layout.gd
```

流程：以独立临时目录 user://tests/hud_layout_<usec> 启动主场景 FinalBattleSession 新游戏（结束时删除），停止玩家与敌人物理，设置恢复中/滑步状态、珍珠 2、药包 2，由 LifeUI._process 实际生成五行 HUD；调用既有 save_failed(message) 显示提示。等待 3 帧后，以 viewport.get_final_transform() × get_global_transform_with_canvas() 换算控件矩形与已排版行数 × 行高的文字区域，断言二者不相交。

结果 HUD_LAYOUT_TESTS checks=65 failures=10，退出码 1。关键测量（屏幕像素）：

| 用例 | HUD 文字区域 | 错误文字区域 | 重叠 |
| --- | --- | --- | --- |
| 恢复中五行 1920×1080 | y 258–440（5 行，高 182） | y 410–441 | 是，30 px |
| 滑步五行 1920×1080 | y 258–440 | y 410–441 | 是 |
| 空闲四行 1920×1080 | y 258–403（高 145） | y 410–441 | 否 |
| 恢复中五行 1280×720（缩放 0.6667） | y 172–293.3 | y 273.3–294 | 是 |
| 长中文提示 1920×1080 | — | 单行宽 2002 px，超出窗口右边界 | 是 |

结论：四行时恰好不重叠，第五行（恢复/滑步）出现后与固定 y=410 的错误提示重叠；长提示不换行并溢出窗口。

## 修复

仅修改 game/ui/menus/life_ui.gd：

- 新增左上角 VBoxContainer（位置 64,258，宽 900，间距 8，mouse_filter=IGNORE），_health 与 _error_label 依次放入，取代两个固定坐标。
- 错误提示 autowrap（WORD_SMART），空文本时隐藏，不占位；_select_slot 清空改为调用 save_failed("")。
- 字体大小 24/22、颜色、低生命变色、左上起点、CanvasLayer 层级与子节点绘制顺序保持不变；未改 public 方法、信号、调用方、状态计算或存档错误处理。

修复后同一测试 HUD_LAYOUT_TESTS checks=65 failures=0，退出码 0。测量：

| 用例 | HUD 文字区域 | 错误文字区域 |
| --- | --- | --- |
| 恢复中/滑步五行 1920×1080 | y 258–440 | y 448–479 |
| 空闲四行 1920×1080 | y 258–403 | y 411–442 |
| 长中文提示 1920×1080 | y 258–440 | y 448–547，3 行，宽 900 |
| 长中文提示 1280×720 | y 172–293.3 | y 298.7–364.7，3 行，宽 600 |
| 恢复中五行 1280×720 | y 172–293.3 | y 298.7–319.3 |

测试还覆盖：四行/五行双向切换、错误清空（隐藏且 HUD 原位）与重现、窗口内完整显示且控件不裁切文字、HUD 原点 (64,258)、字号与颜色、低生命变色、HUD 与提示祖先链均不拦截鼠标、根视口缩放与 1280×720/1920×1080 一致。

## 验证（修复后，均在本工作区）

| 命令 | 结果 |
| --- | --- |
| Godot --headless --editor --path game --import --quit | 退出码 0 |
| Godot --headless --path game --script res://tests/test_hud_layout.gd | HUD_LAYOUT_TESTS checks=65 failures=0 |
| python -X utf8 scripts/verify_game.py ... --jobs 4 --report codexandclaude/runs/hud_engine_validation.txt | 72 项 PASS、0 FAIL；70 个套件 failures=0；无 SCRIPT ERROR/ERROR/Parse Error/泄漏；退出码 0 |
| python -X utf8 -m unittest discover -s tests -v | 69 项 OK |
| python -X utf8 -m unittest discover -s codexandclaude/tests -v | 8 项 OK |

登记：scripts/verify_game.py 新增 HUD 套件（期望摘要 HUD_LAYOUT_TESTS checks=），tests/test_verification_runner.py 两处数量 69→70，保留实际文件存在检查。

## 未授权文件与生成物

- 编辑器导入后 game/assets/characters/player_placeholder.svg.import 与 game/assets/environments/gray_tile.svg.import 显示为已修改，git diff 无内容差异（仅换行符规范化提示）。不在授权清单，未提交、未清理，交协调者处理。
- outputs/pursuit_air.json、codexandclaude/runs/hud_engine_validation.txt、game/.godot 为被忽略生成物，未提交。

## 未验证项

- 人工视觉验收全部未进行：恢复中五行 HUD 与提示同时可读、1280×720、1920×1080 与全屏实际显示，均无实际截图或人工检查。
- 暂停/设置/存档槽菜单交互与手柄操作无人工回归（自动回归套件已全部通过，但不能替代人工）。
- 真实磁盘写入失败与真实恢复同步出现的场景未人工制造；测试通过 save_failed() 注入提示。
- 中文换行使用默认字体与 TextServer 的 WORD_SMART 规则，实际字形断行观感未人工确认。

人工验收未完成，不能视为可最终合并。
