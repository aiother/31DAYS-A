# T8 技术开发基线（工程实施）

2026-10-14：按用户已确认冻结方案实施。Godot **4.7.2 Stable**；Typed GDScript；Windows PC x64；1920×1080 / 16:9；Compatibility；目标60 FPS、物理60 Hz；Git与Git LFS。

角色物理由CharacterBody2D控制，战斗由Godot Hitbox/Hurtbox控制；Spine仅管Visual。未来采用Spine Professional与官方spine-godot GDExtension，并成对锁定Godot/Runtime及Spine导出数据版本。本次无Spine依赖，使用Sprite2D占位。

地图技术采用TileMapLayer + 模块化PackedScene；本次只交付debug测试场地。Room动态加载/相邻预加载、Resource数据驱动的其他模块、本地分槽版本化存档、关键逐帧AnimatedSprite2D、2D粒子/Shader在后续冻结开发序列接入。不得将空目录计为已实现系统。

开发顺序：工程初始化 → 玩家灰盒 → 基础战斗 → 无色实体 → 生命/死亡 → 可能性/地面滑步/恢复 → 检查点 → 第一个灰盒Room。

本次范围仅前两项与后续结构预留，不新增系统、角色、正式地图。T0–T7原有规则保持；参数未冻结的部分在Resource中标为灰盒调校值。首轮代码与文档、测试逐次提交Git。

实施进度追加（2026-10-15）：基础攻击及无色实体AI/攻击已接入开发场景，具体见`colorless_implementation.md`；未新增敌人种类或正式地图。下一阶段为玩家生命/死亡。上段“仅前两项”记录首次交付范围。
