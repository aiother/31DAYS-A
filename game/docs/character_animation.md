# 角色动画接入（SYS-010）

基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`。本层只显示现有玩法；正式美术、Boss、10、幸存者和特效另行接入。

## 数据流和边界

`PlayerController.animation_state()` / `ColorlessEntity.animation_state()` → `CharacterAnimationState` 纯查询 → `VisualRoot/Animator` → 手动更新的 `AnimationPlayer`。单色与天人继承基础查询，按真实类型投影其 Motion / Attack。

查询在场景 ready 后使用，返回新字典，不推进任何时钟，不扣费、不发信号、不修改状态或配置。字段：

| 字段 | 含义 |
| --- | --- |
| `name` | 通用状态名（下表） |
| `key` | `name[.variant][.combo][.phase]`，映射首先匹配它 |
| `facing` | 玩法当前朝向，转身延迟未结束前仍为旧朝向 |
| `phase` | 攻击和闪避的 `windup` / `active` / `recovery`；其他为空 |
| `progress` | 当前有限阶段的真实进度 0～1；循环和无已知期限的状态为 -1 |
| `variant` / `combo` | 攻击种类与连击段；没有连击为 0 |
| `airborne` | 仅玩家攻击附带，表示真实空中状态 |

驱动在角色物理更新之后读取。攻击、闪避、硬直、死亡阶段由现有剩余时间定位动画；循环动画只用真实物理 delta。普通落地（0.12 秒）、起跳（0.06 秒）、复活（0.25 秒）是动画组件自己的演出窗，来自真实落地 / 复活信号或实际离地观察，**不**延长玩法硬直。重落地使用现有硬直时长。暂停时查询的玩法状态、动画定位和这三个演出窗均冻结。顶点窗口为当前重力一物理步的 1.5 倍，避免 60 Hz 采样跨过零速度；不改速度。

## 状态清单

| 对象 | 状态与细分 |
| --- | --- |
| 玩家移动 | `idle`、`walk`、`run`、`turn.walk/run`；`takeoff` → `rise` → `apex` → `fall` → `land` 或 `hard_land` |
| 玩家攻击 | `attack.horizontal/up/down.1/2.windup/active/recovery`；下击仍由原规则限制为空中动作，运行中攻击使用实际倍率 |
| 玩家闪避 | `dodge.windup/active/recovery`、`poor_dodge.windup/active/recovery`，贫乏状态来自扣费前的原 `poor_dodge` |
| 玩家生命 | `heal` 循环（动作中断即离开）；`hurt`；`downed` → `fade` → `dead`；真实 `respawned` 后 `respawn` |
| 无色实体 | `idle` / `run`（原 CHASE）、`attack.melee/ranged.windup/active/recovery`、`hurt`（STUN）、`dead` |
| 单色 | 上述状态，攻击变体 `melee.light/strong` 或 `ranged.light/strong`；Motion 对应 `dash` / `dodge` |
| 天人 | 上述待机 / 追击 / 受击 / 死亡；Motion 对应 `dash` / `blink`（位移前警示）/ `guard`；攻击 `attack.combo.1/2/3.phase`、`attack.heavy/ranged/counter.phase` |

优先级遵循实际玩法：死亡阶段先于受击；受击先于复活演出与动作；恢复 / 闪避先于攻击；落地硬直先于地面移动。天人的死亡 / STUN 先于 Motion，Motion 先于攻击。查询不新增原状态机不存在的交互或拾取动作。无色派生的保底实体继承基础映射；没有新增生成或奖励行为。

## 映射资源与替换

角色的 `VisualRoot/Animator.mapping` 指向 `CharacterAnimationMap`。默认 `res://animation/placeholder_map.tres` 集中登记通用状态的占位缩放动画，仅作用于 VisualRoot，不移动物理角色、碰撞或判定框。原 PlaceholderSprite 的受击颜色、无敌闪烁、奖励光环、落地等代码反馈保持原样。

- `clips: Dictionary[String, Animation]`：内嵌或引用 Animation 资源。
- `paths: Dictionary[String, String]`：可选 Animation 路径；不存在时先检查，不尝试加载。
- `fallback: Animation`：可选占位；未设或无效则使用驱动内置的轻微呼吸动画。
- 查找顺序：详细 `key`，再通用 `name`，最后 fallback。同一键优先 clips，其次 paths。路径存在但不是合法 Animation 时也会回退。

例如只给 `attack.up.2.active` 配正式资源，其他攻击仍沿用通用 `attack`。更改一个角色时先复制映射资源，避免修改共享实例。`animation/tests/idle_override.tres` 是实际可加载的单状态替换范例，回归验证它只替换待机，行走仍是原资源。运行时换映射或换 Animation 实例会立即生效；不要原地修改正在播放的 Animation，改完资源后重新载入场景。

Animation 轨道路径以 **VisualRoot** 为根；允许视觉子树中 Node2D 的 `position`、`rotation`、`scale`、`modulate`、`visible`，以及 Sprite 的 `frame`、`frame_coords`、`texture`。拒绝绝对路径、`..`、方法 / 音频轨道、不存在的节点或属性及其他属性，回退占位，不执行回调。资源的数值类型须符合目标属性（正式美术接入时另作资源验证）。停止一个资源时还原其跟踪的视觉属性，再播放下一资源，避免上一姿态泄漏到下一状态。

## 骨骼与关键逐帧约定

正式资源放在 VisualRoot 内独立的 `Art` 子树，保留 Animator 与现有 GameplayRoot 路径。可在 Art 下放 Skeleton2D / Bone2D / Polygon2D 绑定，在关键爆发帧放 Sprite2D，通过同一个 Animation 的骨骼节点 position / rotation / scale 和 Sprite2D frame / texture / visible 轨道混用。约定关键逐帧只覆盖对应肢体或阶段，骨骼继续负责其余姿态；切换时显式设置双方 visible，避免双重轮廓。可在资源接入任务中新增 Art 节点并隐藏旧占位 Sprite；不需要修改玩法脚本。

资源文件使用 `对象_状态_变体_连段_阶段.tres`，映射键使用上述小写点分格式。例如 `player_attack_up_2_active.tres` → `attack.up.2.active`。通用循环动画可用 `player_idle.tres`。骨骼与逐帧片段共用同一阶段长度；有限阶段被真实进度 seek，视觉片段长度不会改变命中时机。任何音效、位移、伤害、无敌帧或获得物品事件都不得放入动画回调。

## 验证与观察

```powershell
Godot --headless --path game --fixed-fps 60 --script res://tests/test_character_animation.gd
python codexandclaude/tools/run_checks.py full --jobs 4
```

新套件使用真实玩家场景、真实输入和真实物理帧覆盖阶段顺序；敌人以真实 AI、伤害与动作入口验证。替换 / 缺失 / 越出视觉子树 / 方法回调资源分别检查。暂停检查同时核对玩法字段、观察器时钟与 AnimationPlayer 定位。

可选 G4 入口：`Godot --path game --script res://tests/acceptance/sys010_animation.gd`。它复用现有移动实验室，不创建存档会话、不使用 SlotStore、不写正式设置；关闭窗口即结束。屏幕只读显示当前查询，原冻结键位不变。验收进程内 F1 / F2 / F3 替换一只无色 / 单色 / 天人，F4 尝试受击，F5 尝试致死，F6 复活并补足资源，F8 暂停；受击和致死仍遵守原有无敌 / 保护时间，不绕过规则。开局生命 1、余额 10，可先长按恢复，再闪避到资源不足。检查动作与查询同步、正常和贫乏闪避不同、受击/奖励等原反馈仍在、暂停时动画冻结；跳跃和重落地可用现有平台观察。入口自检加 `--headless --fixed-fps 60` 与末尾 `-- --self-test`，检查实验室与三类真实敌人可启动。用户 G4 尚未进行。

本层占位缩放幅度小，不代表最终造型或角色比例；正式美术质量由后续资源任务验收。
