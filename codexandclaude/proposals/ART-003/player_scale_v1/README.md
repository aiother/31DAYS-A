# ART-003 · 玩家显示比例与镜头 v1

日期：2026-10-30。状态：**用户已决定并已实现**（`game/world/gameplay_camera.gd`，规格见 `game/docs/asset_spec.md` 第 1 节）。用户按参考实机画面调整玩家角色与镜头（采用方案 A 的镜头放大路线）；场景美术、光照与 HUD 尺寸等美术方案出来后另行调整。

## 结论

| 项 | 决定 |
|---|---|
| 放大方式 | 镜头整体拉近（方案 A）。世界坐标、碰撞、跳跃、房间几何均不变 |
| 镜头倍率 | ×1.875（玩家在 1080p 画面中约 210 px，约占屏高 19.5%） |
| 构图 | 玩家站立时脚底位于画面 88% 高度（1080p 下 y≈950），上方留出场景空间 |
| 未采用 | 方案 B（只放大玩家）：低平台净高约 112 px，放大后的玩家头部直接插入平台，且敌人比例关系被破坏，见 `compare/slot2_角色特写.png` |

## 文件

| 路径 | 内容 |
|---|---|
| `reference/reference_gameplay.webp` | 用户提供的参考实机截图（比例与构图依据） |
| `captures/` | Godot 实机截图：镜头 1.0 与 1.5，堑壕第二间（slot2）与无顶深谷起始区（slot1），含占位方块版与隐藏玩家版，`.json` 记录脚底画面坐标与镜头倍率 |
| `captures_ref/` | 按参考比例的实机截图：镜头 1.875，脚底压到 y=950 |
| `compare/` | 合成对比图：基准 / A / B 三联、角色特写、参考对照、单张全图；`sprite_frame3.png` 为抠出的步行第 3 帧 |
| `verify/` | 实现后的验证截图：不覆盖倍率，直接使用游戏镜头 `game/world/gameplay_camera.gd` |
| `walk_review/` | 审阅步行 8 帧时的腿部条带与 1/3/5/7 帧拼图 |
| `tools/` | 截图与合成脚本 |
| `manifest.json` | 全部图像的 SHA-256 |

合成图中的角色来自 `phf/步行逐帧图2.png` 第 3 帧（靴子上的橙点、蓝线是源图的检查标记），碰撞并未随之改变；敌人与场景仍是灰盒占位。

## 复现

截图在独立临时存档中运行，敌人被冻结以免玩家在等待区域横幅淡出时倒下。

```powershell
$T = (Resolve-Path codexandclaude/proposals/ART-003/player_scale_v1/tools).Path -replace "\\", "/"
$G = "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
foreach ($slot in 1,2) { & $G --path game -s res://tests/acceptance/run_acceptance.gd -- --adapter=$T/scale_capture.gd --no-panel --slot=$slot }
foreach ($slot in 1,2) { & $G --path game -s res://tests/acceptance/run_acceptance.gd -- --adapter=$T/ref_capture.gd --no-panel --slot=$slot }
foreach ($slot in 1,2) { & $G --path game -s res://tests/acceptance/run_acceptance.gd -- --adapter=$T/verify_capture.gd --no-panel --slot=$slot }
python codexandclaude/proposals/ART-003/player_scale_v1/tools/compose.py codexandclaude/proposals/ART-003/player_scale_v1 phf/步行逐帧图2.png
python codexandclaude/proposals/ART-003/player_scale_v1/tools/compose_reference.py codexandclaude/proposals/ART-003/player_scale_v1
python -m unittest codexandclaude.tests.test_player_scale_proposal -v
```
