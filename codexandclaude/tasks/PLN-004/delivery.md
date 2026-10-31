# PLN-004 交付记录

- 实现分支：`claude/PLN-004`（worktree `codexandclaude/worktrees/claude-batch12`），基线 master@cc42d35（第十二批批准提交）。
- **实现 SHA**：`9133ca9e85424b7ad68f6ddf04dbd08454e90279`。
- 三份规划文档的汇总基线：master@cc42d35。

## 规格改动表

| 文件 | 改动 | 来源 |
| --- | --- | --- |
| `Words/T6_素材来源与规格决定.md` | 第 4.4 节新增“动画路线”：玩家与关键敌人（两场 Boss）全逐帧，其余敌人与 NPC 骨骼 + 少量关键帧；玩家动作表 13 行做法改为逐帧（空中攻击、互动两行原本只写复用，未改）；NPC 与敌人段后补做法；第 4.2 节新增“逐帧序列”命名；变更记录一行 | 用户 2026-10-30：“二者混合……只有玩家和部分关键敌人的动画会考虑全部逐帧，大批量的敌人杂兵将会用骨骼动画处理”；批准第十二批时：“名单没问题” |
| `game/docs/asset_spec.md` | 第 2 节新增逐帧序列命名行；第 3 节开头新增“全逐帧对象”规则（不绑骨骼、画布同尺寸、脚底中点锚点、效果层与染色遮罩另出；骨骼规则只适用于其余角色）；变更记录一行 | 同上 |
| `game/docs/art_style.md` | 第 6.2 节附加骨骼一句改为“玩家动画全逐帧，部件名只作形体、分层与染色遮罩参考”；变更记录一行 | 同上 |
| `game/docs/character_animation.md` | 新增“纯逐帧对象”约定：片段只写 Sprite 的 frame / frame_coords / texture / visible 轨道（驱动已允许），不需要 Skeleton2D，不改驱动代码 | 同上；SYS-010 允许属性清单 |

## 状态变更表

| 对象 | 原状态 | 新状态 | 依据 |
| --- | --- | --- | --- |
| ART-002 任务卡与任务板行 | 暂停 | 已取消（由 ART-003 取代） | 用户 2026-10-29 废弃原玩家方案 |
| ART-003 提案 | `proposals/ART-003.md` | `tasks/ART-003/proposal.md`（首部写明结论：选定 A「初页」；图片相对链接改指 `../../proposals/ART-003/`，测试链接改为 `../../tests/`） | 协作规范第 3.2 节；第十二批批准 |
| `phf/README.md` 中 `run_12_v1/` | 历史（露手、灰底版） | 废案（用户 2026-10-30 未通过；v2、v3 已删除） | 用户 2026-10-30 |
| PLN-004 任务板行 | 已批准 | 进行中（交付后待审查） | — |
| 第十一批 | 进行中 | 收尾：PLN-003、ART-001 完成；ENV-008 转入第十二批；ART-002 取消 | 各任务卡首部 |
| BL-006 | 待立项 | 已立项 CLN-002 | 第十二批 |
| BL-061 | 已立项 ART-002 | 已立项 ART-003 | 第十二批 |
| BL-063 | 已立项 ART-002 | 已立项 ART-003（玩家部分） | 第十二批 |
| BL-127 | 待立项 | 已立项 SYS-013（镜头部分；HUD 尺寸随 BL-130） | 第十二批 |
| BL-128 | 待立项 | 已立项 SYS-013 | 第十二批 |
| BL-129 | 待立项 | 已立项 CLN-002 | 第十二批 |
| BL-062 | 待立项 | 待立项（事项补动画路线） | 用户 2026-10-30 |
| BL-064 | 待立项 | 待立项（注明 A-021 与前置原型 EXP-006） | A-021、第十二批 |

路线图快照“美术”一行按当前 master 重写；第 6 节“美术资源”一行改为 ART-001 完成、ART-003 试做（Codex 生成逐帧图）。没有新增待办事项（BL-132 未使用）。

## 与任务卡的偏差

- `Words/待决事项总表.md`：A-021 行“出处”里的提案路径随移动改为 `codexandclaude/tasks/ART-003/proposal.md`。只改路径，不改内容；该文件不在允许列表，因提案移动必须同步。
- `codexandclaude/tests/test_player_redesign_concepts.py`：提案路径常量改为新位置（允许列表里写的是 `test_player_scale_proposal.py`，实际受影响的是这个文件；`test_player_scale_proposal.py` 引用的素材目录未移动，无需改）。

## 检查证据

- G3：`python codexandclaude/tools/run_checks.py focused --python-all`，被测 SHA `9133ca9`，工作区干净（`dirty False`），内容稳定（`content_stable True`），通过；摘要 `codexandclaude/runs/20261031T043632.285427Z/summary.json`（运行目录不入库）。`tests/` 189 项、`codexandclaude/tests/` 83 项全部通过。
- 新增测试 `tests/test_art_spec.py::test_animation_route_is_frame_by_frame_for_player_and_bosses`：锁定 T6 动画路线、玩家动作表无“骨骼”、逐帧命名、asset_spec / art_style / character_animation 三处说法、ART-002 已取消、`run_12_v1` 废案。
- 变异检查：把 T6 待机一行临时改回“骨骼循环”，新测试失败；还原后通过。

## 交给审查者（Codex）

1. 按任务卡第 7 条，一并只读审查以下四个未经交叉审查的提交，结论写入审查记录：`7ab726a`、`3aa4e36`（玩家规格改为「初页」）、`be52c38`（看板刷新）、`94a4a1f`（A-021 裁决与世界风格改写）。
2. 审查重点：动画路线与用户原话一致；T6、asset_spec、art_style、character_animation 四处说法一致；状态变更都有记录支持。

## 未验证项

- 没有游戏代码改动，未跑 G2；`character_animation.md` 关于纯帧片段“不改驱动代码”的结论依据 SYS-010 已允许的属性清单，实际播放由 ART-003 接入时验证。
