# SYS-011 音频事件接入

基线：48bdf15d249ac44630c9229a4c195c5507f149f9。只增加表现层观察/声音调用，不改变伤害、动作、时钟或存档。

## 入口与映射

`AudioEvents` 是 project.godot 注册的 AudioEventService 自动加载；轻量 GameAudio API 与实现分文件，避免角色/会话脚本依赖环。脚本推荐用 `GameAudio.emit_from(self, &"combat.hit", global_position)`；不依赖自动加载名在 `--script` 编译阶段可见。`GameAudio.service(self).play(event, position, source)` 可返回本次派发记录。

映射集中在 `systems/audio/default_audio_map.tres`（AudioEventMap）：

- `clips`：事件名 → AudioStream。拖入正式 WAV/OGG 即可覆盖，不改玩法代码。null 或不存在的事件静默；在 `placeholders` 内允许临时占位的事件缺流时回退短程序音。
- `placeholders`：允许临时占位的事件列表：C 级短音，以及 A 级恢复开始/完成的阶段占位；A 级标注不代表已满足正式素材品质。三个可能性事件按 A 级保留空槽，不擅自用 C 级占位替代。
- `pitches`：按事件独立配置播放音高，默认单色普通/强力为 1.3/0.7，天人普通/重击为 1.1/0.6，保留旧灰盒听觉线索。正式流也使用该值；若素材已按目标音高制作，可将对应值设为 1，不改游戏脚本。
- `environments`：Region_HD / Region_TY / Region_NSZC → 荒地 / 田野 / 逆时战场环境音，默认 null。
- `music`：exploration / combat / large_battle / story，默认 null。A/B 音频留空，剧情音乐也不强制制作占位。
- `fade_seconds`：背景切换淡入淡出时长，默认 0.35 秒，可调。

建议文件名 `sfx_<event>.wav`、`amb_<region>.ogg`、`bgm_<state>.ogg`。短音效用 PCM WAV；长音乐/环境音用 OGG 并在导入或资源属性中启用循环。程序占位只有 0.1 秒，复用同一短音以验证时机，不代表最终音色。替换只影响该映射键，同类行为可将多个键指向同一资源。

位置参数保留在事件中；当前使用非空间 AudioStreamPlayer，不引入距离衰减。每次实际播放由服务创建独立语音，最多 32 个，超出则停止最早语音。结束/所属场景销毁/Room 切换后释放，不把声音节点挂入视觉树。`history` 是最多 512 条的只读检查记录（事件、实际语音总线/流/音高、帧、位置、可发声与否）；空槽记录不冒称播放。`event_emitted` 在播放器启动后发布。

## 事件与真实来源

| 事件 | 来源 | 槽位 |
| --- | --- | --- |
| player.jump | PlayerController 成功起跳分支 | C 占位 |
| player.land / player.hard_land | landed 的实际 hard 标记 | C 占位 |
| combat.swing | PlayerCombat.attack_started | C 占位 |
| combat.hit / combat.reflect | hit_confirmed；投掷物父节点 reflected 为真时仅反弹，不重复命中音 | C 占位 |
| combat.block | TianWarrior.try_block 成功分支 | C 占位 |
| player.hurt / player.death | PlayerLife.damaged / died | C 占位 |
| enemy.hurt | 普通敌人/Boss hurtbox 成功反馈之后 | C 占位 |
| enemy.death / boss.defeated | 对应 defeated | C 占位 |
| possibility.gain | gained（不根据余额差猜获得） | A 空槽 |
| possibility.spend | 实际滑步/恢复扣费分支 | A 空槽 |
| possibility.shortfall | 既有 shortfall（含透支下限拒绝） | A 空槽 |
| heal.start / heal.done | 实际恢复开始/完成；中断不完成 | A 级，暂用占位 |
| interaction.dialogue | FieldDialogue.advance 接受推进时；补全/下一句/结束 | C 占位 |
| interaction.pickup | SYS-009 item_obtained，成功写盘之后 | C 占位 |
| interaction.mechanism | 落石开关成功保存 | C 占位 |
| interaction.gate | 新连接门成功保存，或真实 Room 通行完成；已开门不重播开门 | C 占位 |
| enemy.windup | 无色 attack_started；两 Boss 实际进入 WINDUP 的调用 | C 占位 |
| enemy.windup.monochrome / enemy.windup.monochrome_heavy | 单色 attack_started 当时的 strong_attack，普通 / 强力独立槽 | C 占位，1.3 / 0.7 |
| enemy.windup.tian / enemy.windup.tian_heavy | 天人 attack_started 当时的 attack_kind，非 HEAVY / HEAVY 独立槽 | C 占位，1.1 / 0.6 |
| ui.focus / ui.confirm / ui.back | Control 真实焦点、按钮 pressed、返回按钮或 ui_cancel；不接管输入 | C 占位 |

GameAudio 监听 SceneTree.node_added，在 ready 后订阅既有信号；节点销毁自动断开。旧 placeholder_visual 的 `_hit_sound` 和三个敌人视觉播放器已删除，绘制部分未变；GrayboxAudio 仅保留兼容生成器，正式播放统一由服务负责。前摇事件直接在同一次物理回调中派发，未等待顿帧结束。

## 背景状态与生命周期

当前活跃 WorldRoom 的 config.region_id 选择环境音。状态优先级：剧情（FieldDialogue/intro/cinematic）→ Boss 两房/中心战场 large_battle → 房内有真实非 IDLE/DEAD 普通敌人时 combat → exploration。无存档会话/返回标题则清空背景槽；离开 Boss 回普通房间按当前状态恢复。只读状态，不设置敌人状态或推动剧情。

背景切换保留旧语音淡出，同时新语音淡入；空槽只将旧背景淡出。背景走 `背景音`，游戏/UI 短音都走 `效果音`，父总线 Master 与 SYS-007 设置照常生效。暂停时现有游戏语音和背景暂停，拒绝新游戏事件，背景淡入淡出也冻结；UI 语音使用 ALWAYS 可照常响应。短音归属所在 Room/场景，来源敌人或按钮被移除不会提前截断；Room 离开或所属场景销毁停止游戏短音，背景按既定过渡淡出，不遗留无限播放的旧场景声音。

## 自检

`Godot --headless --path game --fixed-fps 60 --script res://tests/test_audio_events.gd`：真实玩家、三类敌人、两 Boss、独立临时存档的拾取/机关/门、对话与 UI 输入；检查实际播放器/流/总线、同帧前摇、音乐切换、暂停、缺流静默与资源单键替换。设置读取由现有自定义 SceneTree 隔离机制放到临时目录。

G4 可直接正常新游戏听时机，并用既有设置分别调节效果音/背景音；默认背景槽空，听不到音乐属预期。无需下载正式音频或改用户存档。专项日志中的 headless 不用于判断音色质量。

应用整体退出时，服务清空语音、流和记录缓存并等待混音线程 200 毫秒；正常 Room 切换不等待。正式语音显式使用流式播放。

## 审查补充

四个单色/天人提示槽既可共用同一流加不同音高，也可分别替换为正式流；不会改敌人动作种类或前摇时机。音高记录取自实际 AudioStreamPlayer.pitch_scale，不以标签推断已经听到区别。

_world_exited 的 stop_game 是立即清理；_process 通过场景 WeakRef 失效也会清理，是故意保留的冗余兜底。最终不留声音的用例可被后者兜住，删除前者不一定导致断言失败，不把这种等价变异冒称杀死。

interaction.gate 目前还复用在普通 Room 通行。待正式门音接入时可考虑拆出独立通行事件，避免无门通路响门声；本轮不改触发或游戏流程。
