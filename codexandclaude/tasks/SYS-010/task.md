# SYS-010：角色动画接入框架

状态：已批准（2026-10-23 用户批准）｜级别：L｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：无（不需要正式美术资源）

## 目标

完成待办 BL-060 的框架部分：建立“游戏状态 → 动画状态”的统一接入层，并接到玩家与三类普通敌人现有的状态机上，用占位动画跑通，使 M3 的正式动画资源（BL-061、BL-062，用户提供）到位后只需替换资源、不改玩法代码。T6 规定的形式为 2D 骨骼加关键逐帧。

## 依据

- 待办 BL-060；T6-B1（动画清单与状态划分）、T6-E（2D 骨骼加关键逐帧）；路线图 M3（BL-060 先于角色动画接入）。
- 现有状态机：`PlayerController`（地面 / 空中、`landed`、`facing_changed`）、`PlayerCombat.Phase`（IDLE / WINDUP / ACTIVE / RECOVERY，`attack_started(direction, combo_step)`）、`PlayerPossibility.State`（DODGE_* / HEALING，`poor_dodge`）、`PlayerLife.State`（ALIVE / DOWNED / FADING / DEATH_MENU，`damaged`、`respawned`）；`ColorlessEntity.State`（IDLE / CHASE / WINDUP / ACTIVE / RECOVERY / STUN / DEAD）、`MonochromeEntity.Motion`、`TianWarrior.Motion` 与 `Attack`。

## 现状（起草时核对 master@ae8a9c5）

- 项目中没有 `AnimationPlayer`、`AnimationTree`、`Skeleton2D` 或粒子节点；角色外观全部由代码绘制：`player/placeholder_visual.gd`（117 行，受击变红、奖励光环、无敌闪烁、闪避着色、落地处理）、`enemies/colorless_visual.gd`、`monochrome_visual.gd`、`tian_visual.gd`、`allies/ten_visual.gd`。
- 动画所需的状态散在多个组件与信号里，没有统一的“当前该播哪个动画”的查询。

## 要求

1. **动画状态查询**：为玩家提供一个只读、无副作用的当前动画状态（建议 `animation_state() -> Dictionary`，含状态名、朝向、阶段进度等）。状态至少覆盖 T6-B1 / BL-060 列出的划分：待机、跑步；跳跃分起跳、上升、顶点、下落、落地（含重落地）；普通攻击按连击段与方向（上 / 下 / 水平），各分前摇、判定、后摇；闪避分可能性充足与不足（`poor_dodge`）；恢复为循环；受击；倒地、消散、复活。三类普通敌人同样提供（无色实体按 `State`，单色、天人按各自 Motion 与 Attack）。
2. **动画驱动层**：一个可复用的组件（例如 `CharacterAnimator`），读取上述状态并驱动 `AnimationPlayer` / `AnimationTree`；状态名到动画资源的映射集中在一个资源或配置里，缺资源时退回占位，不报错。
3. **占位动画**：用现有代码绘制的外观做最简占位（例如按状态的姿态位移、缩放或颜色），证明映射与切换正确；现有 `placeholder_visual.gd` 等的受击、无敌、奖励反馈保持。
4. **不改玩法**：不改移动、战斗、判定、时机、数值、AI 与存档；动画只读状态，不反向驱动判定（判定时机仍由现有状态机决定）。
5. **文档**：`game/docs/` 新增动画接入说明：状态清单、映射资源格式、如何替换为骨骼 / 逐帧资源、骨骼与逐帧混用的约定、命名规则，供用户与 Claude 后续接入资源使用。

## 允许修改的文件

- 新增 `game/animation/`（或 `game/core/animation/`）下的驱动组件、映射资源与占位资源。
- `game/player/` 与 `game/enemies/` 中三类普通敌人的脚本与场景：只增加状态查询方法与挂载动画组件；不改现有逻辑分支。
- `game/player/placeholder_visual.gd`、`enemies/*_visual.gd`：仅为接入动画组件所需的最小改动。
- `game/tests/` 新增测试（首行登记，`.uid` 一并提交）；新增 `game/tests/acceptance/` 下的验收适配（可选）；`game/docs/` 说明。
- `codexandclaude/tasks/SYS-010/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 完成标准

1. 自动测试（真实玩家与敌人场景、真实输入或真实物理帧）：每一种动画状态都能由真实动作触发并被查询到，切换顺序正确（如起跳 → 上升 → 顶点 → 下落 → 落地；攻击前摇 → 判定 → 后摇；可能性不足的闪避与充足的区分；恢复循环中断）；暂停时状态与动画不推进。
2. 映射缺资源时退回占位且无错误；替换某一状态的资源后只该状态改变（用测试资源证明）。
3. 现有全部测试通过，旧断言不改；若必须改，交付记录逐条说明。玩法相关套件（玩家、战斗、三类敌人、Boss、战役）结果不变。
4. 变异检查：去掉“可能性不足”区分、跳跃顶点判定错误、暂停仍推进动画、状态查询有副作用（例如改动玩家状态），相应测试失败。
5. G2 + G3 通过；G4（用户）：用验收入口观察占位动画随动作切换（可选，若提供验收适配）。

## 检查

- G1：新增套件、`test_player*`、战斗与三类敌人相关套件、`test_campaign.gd`。
- G2 + G3：全量，交付记录贴自动摘要。

## 回滚方案

`git revert` 本任务提交即可移除动画层，玩法不受影响。

## 不在范围内

- 正式美术与动画资源（BL-061、BL-062，用户提供）；Boss、10、幸存者的动画接入（框架验证后另立任务）；角色比例（BL-063）；特效（BL-065、EXP-005）；音频（BL-066）。
