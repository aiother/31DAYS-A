# SYS-007 设置接口

`GameSettings` 自动加载在进入树时加载设置，在场景首帧前应用。它不修改物理帧率、输入映射或存档槽。

## 界面接口

- `get_values() -> Dictionary`：返回当前设置的独立副本。
- `set_value(key, value) -> Error`：校验、立即应用并保存；无效参数返回 `ERR_INVALID_PARAMETER`，不改变设置。写入失败返回对应错误；已经应用的运行时值保留，界面可据返回值提示。
- `restore_defaults() -> Error`：立即应用并保存全部默认值。
- `changed(values)`：应用和保存尝试结束后发布当前值的副本；保存结果也可读取 `last_save_error`。
- `bindings() -> Array[Dictionary]`：按 T1 §7 顺序返回 `action`、`name`、`keyboard`、`controller`。键位文字读取实际 `InputMap`，返回数据独立，不提供修改映射的接口。
- `reload_settings()`：重新读取并应用，主要用于隔离测试；不主动重写缺失或损坏的文件。

| key | 类型与允许值 | 默认值 |
| --- | --- | --- |
| master_volume | 有限数值，0～100 | 100 |
| sfx_volume | 有限数值，0～100 | 100 |
| music_volume | 有限数值，0～100 | 100 |
| window_size | Vector2i(1280,720) 或 Vector2i(1920,1080) | 1280×720 |
| fullscreen | bool | false |
| max_fps | int：30、60、120、0（不限制） | 60 |

音量分别作用于 Master、效果音、背景音；后两条总线输出到 Master。三个敌人前摇音和玩家命中音均走效果音。背景音暂时没有播放器。全屏时保留窗口尺寸选择，回到窗口模式时应用；渲染帧率通过 `Engine.max_fps` 应用，物理帧率始终沿用项目的 60。

UI-003 暂停菜单设置页的三个控件仍是总音量、窗口尺寸、全屏，布局不变，回调改用上述接口。现有 F11 切换仍由 movement_lab 处理；设置服务在其后观察模式并保存，避免同一按键切换两次。设置调用位于 PauseMenu.show_settings()；LifeUI 不改动。通过 get_node("/root/GameSettings") 在运行时取得接口，避免自定义 SceneTree 在预加载 UI 时无法解析自动加载全局名。

## 文件与隔离

正常游戏使用 `user://settings.cfg`，内容是 UTF-8 JSON 对象（版本 `version: 1`），六个 key 与接口一致，`window_size` 序列化为 `[1280,720]` 或 `[1920,1080]`。它独立于存档槽。缺失文件、无法读取、JSON 损坏或未知版本使用全部默认值；合法版本中的缺失或越界字段单独使用默认值。解析不向引擎打印 ERROR，不因设置损坏退出。直到用户修改或恢复默认时才写入。

自定义 SceneTree 脚本（自动套件、原型与验收入口）及 `--headless --quit-after` 主场景冒烟自动使用系统缓存下独立的 `31days_settings_<PID>_<ticks>/settings.cfg`，不读取玩家设置，退出时删除本进程生成的文件和目录。需要检验持久化时可显式传 `-- --settings-file=<隔离目录>/settings.cfg`；显式路径由调用者负责清理。不要把该参数指向真实设置文件。

`test_settings.gd` 为每次运行隔离目录，在新引擎进程首帧前核对保存、损坏回退与实际总线/窗口尺寸/帧率（无头显示不支持真实全屏模式，模式断言仅在有窗口运行时执行）；同目录的模拟槽字节在全部操作前后保持不变。测试仅清理本次生成的隔离目录。有窗口运行还验证现有 F11 处理只切换一次，并由设置服务读实际显示模式后即时保存。


续作基线为第五批规划合入后的 master；SYS-007 的原始失败检查点保留在 codex/SYS-007，本轮在 codex/SYS-007-r2 重新应用同一设置实现并适配已合入的 UI-003。新套件在脚本常量中预加载真实 UI 场景，直接覆盖此前的编译顺序缺口。
