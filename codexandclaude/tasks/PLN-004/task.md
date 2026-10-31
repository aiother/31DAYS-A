# PLN-004：规划刷新（第十一批收尾）与动画路线入规格

状态：已交付，待 Codex 审查（2026-10-30 用户批准，第十二批；实现 `9133ca9`，见 [delivery.md](delivery.md)）｜级别：M｜实现：Claude｜审查：Codex
工作区：worktrees/claude｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：无；第十二批中最先做

## 目标

把路线图、待办清单、任务板对齐到第十一批与 2026-10-29～30 批次外改动之后的 master；把用户 2026-10-30 定下的动画路线写进规格；正式终止 ART-002、把 ART-003 提案转入任务；并请 Codex 补审当天未经交叉审查的规格改写。做法沿用 PLN-001～PLN-003。

## 依据

- 用户 2026-10-30 动画路线：“二者混合，我希望有很好的动画效果全部走逐帧，但是成本太高，所以只有玩家和部分关键敌人的动画会考虑全部逐帧，大批量的敌人杂兵将会用骨骼动画处理”。
- 用户 2026-10-30：“跑步动画到目前位置没有符合我认可的，所以全部都是废案，都是不通过”（`phf/run_12_v1`～`v3`；Codex 清理记录 `codexandclaude/proposals/ART-003/run_cleanup_2026-10-30.md`，`0adc71f`）。
- 用户 2026-10-29 废弃原玩家方案（ART-002 依据失效）；2026-10-30 选定 ART-003 方案 A「初页」并裁决 A-021（`Words/暗室设定.md`）。
- 任务板“批次外改动”一节（`be52c38`）。
- 协作规范 V2.4 第 3.2、4、5 节。

## 现状（起草时核对 master@0adc71f6ec00524bebb94aac32cb2a8c7288c97d）

- 三份规划文档汇总基线为 master@3aa4e36（`be52c38`）；之后有 A-021 裁决（`94a4a1f`）与跑步清理（`0adc71f`）。
- `Words/T6_素材来源与规格决定.md` 第 4 节动作表把玩家待机、行走、跑步写为“骨骼循环”，攻击等为“骨骼 + 关键帧”，与新路线不符。
- ART-002 状态为“暂停”；ART-003 只有提案 `codexandclaude/proposals/ART-003.md`，没有任务卡。
- `phf/README.md` 仍把 `run_12_v1/` 写为“历史（露手、灰底版）”，未标废案。
- 以下提交没有经过交叉审查：`7ab726a`、`3aa4e36`（玩家规格改为「初页」）、`be52c38`（看板刷新）、`94a4a1f`（A-021 裁决与世界风格改写）。

## 要求

1. **三份文档汇总基线统一**更新到本任务的基线 SHA；第十一批收尾（PLN-003、ART-001 完成，ENV-008 转入第十二批，ART-002 终止）写入“批次进展”。
2. **动画路线入规格**：
   - `Words/T6_素材来源与规格决定.md` 第 4 节：玩家全部动作改为全逐帧；新增“关键敌人全逐帧、杂兵与 NPC 骨骼 + 少量关键帧”的分级；变更记录补一行。
   - **关键敌人名单**（用户 2026-10-30 批准时确认：“名单没问题”）：两场 Boss（渴望俯视、寄生同伴者）全逐帧；天人战士、无色实体、单色实体与 7、10、幸存者走骨骼 + 少量关键帧。
   - `game/docs/asset_spec.md` 第 2、3 节：补全逐帧序列的命名（如 `<对象>_frames_<状态>_<两位序号>.png` 或单张序列图的规则）、锚点与交付尺寸要求；`art_style.md` 第 6.2 节玩家附加骨骼一句改为“逐帧时不使用骨骼，部件表留作参考”。
   - `game/docs/character_animation.md`：写明 SYS-010 驱动可直接用纯帧片段（Sprite2D frame / texture 轨道），不改代码。
3. **ART-002 终止**：任务卡首部改为“已取消（2026-10-29 原玩家方案废弃；由 ART-003 取代）”，任务板同步；分支 `claude/ART-002` 只作历史。
4. **ART-003 立项**：按协作规范第 3.2 节，把 `proposals/ART-003.md` 移入 `tasks/ART-003/proposal.md`，修正其中的图片相对路径；`proposals/ART-003/` 下的素材目录保持原位（规格与测试引用这些路径）。
5. **废案标注**：`phf/README.md` 中 `run_12_v1/` 改为“废案（用户未通过）”。
6. **待办清单**：BL-061、BL-063 改为“已立项 ART-003”；逐条核对 BL-127～BL-131 与本批任务卡的对应；新事项编号从 BL-132 起。
7. **补审范围**：Codex 审查本任务时，一并审查第“现状”节列出的四个提交（只读审查，问题记入审查记录；需要改的由本任务修正）。

## 允许修改的文件

- `codexandclaude/ROADMAP.md`、`codexandclaude/BACKLOG.md`、`codexandclaude/BOARD.md`。
- `Words/T6_素材来源与规格决定.md`（第 4 节与变更记录）。
- `game/docs/asset_spec.md`、`game/docs/art_style.md`（只限动画路线相关句子）、`game/docs/character_animation.md`。
- `phf/README.md`。
- `codexandclaude/proposals/ART-003.md` → `codexandclaude/tasks/ART-003/proposal.md`（移动并修正链接）。
- `codexandclaude/tasks/ART-002/task.md`（首部状态）。
- `tests/test_art_spec.py`、`tests/test_phf_index.py`、`codexandclaude/tests/test_player_scale_proposal.py`（只为新规则补断言或跟随移动的路径）。
- `codexandclaude/tasks/PLN-004/task.md`（首部状态）、`delivery.md`（新增）。

## 完成标准

1. `tests/` 与 `codexandclaude/tests/` 全部通过，包括三份文档基线一致、路线图覆盖全部未完成 P1/P2 待办。
2. 交付记录附**状态变更表**、**规格改动表**（每条注明用户原话来源）（关键敌人名单已在批准时确认）。
3. 审查记录包含对四个补审提交的结论。
4. G3 通过。

## 检查

- G3：`python codexandclaude/tools/run_checks.py focused --python-all`。
- 审查重点：动画路线与用户原话一致；T6、asset_spec、art_style、character_animation 四处说法一致；补审的四个提交与用户裁决一致。

## 回滚方案

`git revert` 本任务提交即可恢复三份规划文档、规格与提案位置。

## 不在范围内

- 任何代码与素材改动；ART-003 的具体制作；UI 重设计（BL-130）。
