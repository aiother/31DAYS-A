# ENV-004 交付记录

实现者：Codex｜审查者：Claude｜分支：`codex/ENV-004`
基线：`66ee2b5ff0abaf110186a00760605efde17b4fb7`（已合入用户批准的规划）
实现SHA：`bde78d161469c3c2684d265a6bfae086a4df45cc`

## 行为与范围

采用甲：每个现有 `game/tests/test_*.gd` 第一行增加 `# verify-suite: JSON`，五字段 name/path/marker/fixed_fps/timeout。新增或删除套件只改其文件，不再编辑公共列表及数字。注册表按路径排序；`SUITES`保存完整参数，`TESTS`派生三元组兼容视图供门禁计数和既有消费者使用。

入口逐文件核对登记，拒绝漏登、重复路径/名称/标记、非自身或不存在路径、无效参数。显式排除清单EXCLUDED_TESTS当前为空，未来只有带理由且存在的非独立辅助脚本能排除，不能同时登记。执行完成后按路径多重集合校验缺项/多项/重复，外层G2仍核对所有PASS条目。

`execute()`不再按文件名猜测参数；`execute_suite()`将登记帧率和超时用于full与focused。保留原ERROR/汇总/超时判断。未改任何引擎测试正文、游戏行为、正式存档或输入；73个头部之外的正文与基线逐字节规范化行尾后相同。

相关测试迁移：撤掉固定73断言，以磁盘文件集合对照登记集合和排除清单；档案试点的AST固定数字检查改为实际文件覆盖；专项适配器检查改为调用带元数据的execute_suite。

卡外一项获单独授权：发现tests/test_game_project.py要求套件路径出现在verify_game源码中，用户本会话明确回复“允许同步这一项测试”。只将该方法的路径检查改为检查实际TESTS集合，其余内容未改。任务卡首部记录了此授权；未改BOARD/BACKLOG。

## 检查证据

- 先写测试：旧实现上注册接口缺失导致新专项测试失败（17 tests、23 errors），日志 `codexandclaude/runs/env004/before.txt`；实现后专项18/18。
- 73套件迁移比较：由旧execute的实际subprocess调用提取fixed_fps/timeout，对照新登记，输出 `MIGRATION suites=73 exact_parameters=73 unchanged_bodies=73 failures=0`。原始before.json、after.json、compare.py位于忽略目录runs/env004；下面给出逐套件前后对照。
- 完整门禁：在实现提交、dirty=false上执行 `python codexandclaude/tools/run_checks.py full --jobs 4`。G2 **75/75**（编辑器导入、主场景180帧、原73套件）；G3 **102/102 + 44/44**，complete=true、passed=true，全部子命令退出0。原始证据 `codexandclaude/runs/20261020T122012.297098Z/summary.json`，同目录engine.txt及逐命令日志；不入库。
- Python套件从92增至102（注册/执行完整性新增10项），协作测试44项数量未变。EXP-001未合入基线，因此这里不是原型分支的45项。
- 专项实际适配检查：`python codexandclaude/tools/run_checks.py focused --godot-script res://tests/test_day_clock_session.gd`，导入和专项两项均通过，实际使用该套件登记的fixed_fps=60、timeout=60；证据 `codexandclaude/runs/20261020T123251.408158Z/summary.json`。交付记录及任务卡状态更新后，提交前再跑完整G3和差异检查。
- Godot4.7.2.stable.official.ed1daf0bf、Python3.12.14/openpyxl3.1.5、Git2.56.0.windows.2、Nodev24.19.0。
- full完成后的两个SVG.import纯行尾变化经检查恢复，不计入实现。本实现未新增玩家存档操作，G4不需要。

## 要求的五项故障注入

专项测试在临时项目文件夹或模拟完成列表中引入故障，每项都捕获预期错误，5/5通过；没有留在正式game目录。执行 `python -m unittest tests.test_verification_runner` 可复现全部情况。

| 故障 | 回归方法 | 结果 |
| --- | --- | --- |
| 新增未登记test_*.gd | test_new_unregistered_file_fails | Missing suite metadata，拒绝 |
| 两套件同一路径 | test_duplicate_path_marker_and_name_fail | Duplicate path，拒绝；同时覆盖名称/标记重复 |
| 登记指向不存在文件 | test_missing_and_wrong_owner_paths_fail | file does not exist，拒绝；同时覆盖存在但不属自身文件 |
| 删除现有套件登记 | test_removing_existing_registration_fails | Missing suite metadata，拒绝 |
| 执行集合漏一个 | test_main_fails_if_a_completed_suite_is_missing | main返回1且没有All engine checks passed；另直接覆盖多项/重复 |

附加覆盖：新增只改自身文件、JSON/schema/参数异常、排除理由及存在性、独立运行参数与文件名无关、并行必须先导入/主场景且报告顺序稳定、focused参数复用。原有失败/错误/泄漏/超时判定测试保留。

## 审查者留意

1. 报告及提交调度顺序从旧手写列表改为路径排序，**集合、名称、路径、标记及运行参数不变**。没有用登记表长度证明完整性，磁盘覆盖检查独立存在。
2. 元数据第一行使用JSON，字段和错误信息见env.md。EXCLUDED_TESTS只用于明确的辅助脚本例外，普通新增可运行套件不改该清单。
3. TESTS是兼容视图，实际执行使用完整SUITES；full与focused都经execute_suite。未同时维护第二份注册源。
4. 本交付只做分散登记，不做BL-104证据汇总或BL-105通用G4入口。EXP-001审查分支与本分支独立，未带入原型实现。SYS-004仍等ENV-004审查、获授权合入master后再开工。

## 73套件前后对照

下表每行名称、路径、标记以及参数均已自动比较，迁移前=迁移后。null表示真实时间、不加--fixed-fps；timeout单位秒。原测试正文仅增加首行注释。

| 名称（前=后） | 路径（前=后） | 结果标记（前=后） | fixed_fps前→后 | timeout前→后 |
| --- | --- | --- | --- | --- |
| attack jumping and airborne dodge regression | `res://tests/test_air_actions.gd` | `AIR_ACTION_TESTS checks=` | null→null | 60→60 |
| all-Room flying monochrome detours and recovery | `res://tests/test_air_pursuit.gd` | `AIR_PURSUIT_TESTS checks=` | 60→60 | 180→180 |
| battlefield allied combat reinforcement and checkpoint reset | `res://tests/test_battlefield.gd` | `BATTLEFIELD_TESTS checks=` | null→null | 60→60 |
| Boss ordinary monochrome lifecycle and summon separation | `res://tests/test_boss_ordinary.gd` | `BOSS_ORDINARY_TESTS checks=` | null→null | 60→60 |
| Boss pressure and summoned colorless enemies | `res://tests/test_boss_pressure.gd` | `BOSS_PRESSURE_TESTS checks=` | null→null | 60→60 |
| deserter camp exploration and persistent pearl | `res://tests/test_camp_room.gd` | `CAMP_ROOM_TESTS checks=` | null→null | 60→60 |
| deserter camp waves and formal checkpoint | `res://tests/test_camp_waves.gd` | `CAMP_WAVES_TESTS checks=` | null→null | 60→60 |
| continuous new-game campaign through all Rooms and ending | `res://tests/test_campaign.gd` | `CAMPAIGN_TESTS checks=` | null→null | 60→60 |
| checkpoint and resume integration | `res://tests/test_checkpoints.gd` | `CHECKPOINT_TESTS checks=` | null→null | 60→60 |
| colorless enemy regression | `res://tests/test_colorless.gd` | `COLORLESS_TESTS checks=` | null→null | 60→60 |
| basic combat regression | `res://tests/test_combat.gd` | `COMBAT_TESTS checks=` | null→null | 60→60 |
| permanent combat range growth physical hits reflection migration and slots | `res://tests/test_combat_growth.gd` | `COMBAT_GROWTH_TESTS checks=` | null→null | 60→60 |
| combat tuning revision | `res://tests/test_combat_revision.gd` | `COMBAT_REVISION_TESTS checks=` | null→null | 60→60 |
| connection Room and permanent mechanism | `res://tests/test_connection_room.gd` | `CONNECTION_ROOM_TESTS checks=` | null→null | 60→60 |
| natural day clock migration rollover and final budget handoff | `res://tests/test_day_clock.gd` | `DAY_CLOCK_TESTS checks=` | null→null | 60→60 |
| natural day session pause persistence story rollover and timeout retry | `res://tests/test_day_clock_session.gd` | `DAY_CLOCK_SESSION_TESTS checks=` | 60→60 | 60→60 |
| permanent dodge growth migration physical movement and slot isolation | `res://tests/test_dodge_growth.gd` | `DODGE_GROWTH_TESTS checks=` | null→null | 60→60 |
| protected enemy actions and future stagger interrupt hook | `res://tests/test_enemy_interrupts.gd` | `ENEMY_INTERRUPTS_TESTS checks=` | null→null | 60→60 |
| enemy melee approach regression | `res://tests/test_enemy_melee_approach.gd` | `ENEMY_MELEE_TESTS checks=` | null→null | 60→60 |
| four-Room environmental hazards real traversal permanent switches and save recovery | `res://tests/test_environment_batch.gd` | `ENVIRONMENT_BATCH_TESTS checks=` | 60→60 | 60→60 |
| exploration Room and persistent pearl placeholder | `res://tests/test_exploration_room.gd` | `EXPLORATION_ROOM_TESTS checks=` | null→null | 60→60 |
| golden wheat field dialogue and rescue departure | `res://tests/test_field_room.gd` | `FIELD_ROOM_TESTS checks=` | null→null | 60→60 |
| final waves support permanent victory and ending | `res://tests/test_final_battle.gd` | `FINAL_BATTLE_TESTS checks=` | null→null | 60→60 |
| final clock migration bounds and validation | `res://tests/test_final_clock.gd` | `FINAL_CLOCK_TESTS checks=` | null→null | 60→60 |
| final timer death load timeout and explicit retry | `res://tests/test_final_retry.gd` | `FINAL_RETRY_TESTS checks=` | null→null | 60→60 |
| graybox HUD rows and save error prompt stack without overlap across viewports | `res://tests/test_hud_layout.gd` | `HUD_LAYOUT_TESTS checks=` | null→null | 60→60 |
| frozen keyboard mouse and controller bindings with real arrow input | `res://tests/test_input_bindings.gd` | `INPUT_BINDINGS_TESTS checks=` | null→null | 60→60 |
| medkit automatic supplies real Q Back input restrictions rollback and death reload | `res://tests/test_medkit_session.gd` | `MEDKIT_SESSION_TESTS checks=` | null→null | 60→60 |
| medkit inventory version-one compatibility bounds and slot persistence | `res://tests/test_medkit_store.gd` | `MEDKIT_STORE_TESTS checks=` | null→null | 60→60 |
| controller confirmation and keyboard compatibility through real pause menus | `res://tests/test_menu_controller.gd` | `MENU_CONTROLLER_TESTS checks=` | null→null | 60→60 |
| monochrome enemy movement attacks dodge and reflection | `res://tests/test_monochrome.gd` | `MONOCHROME_TESTS checks=` | null→null | 60→60 |
| monochrome trench integration rewards and persistence | `res://tests/test_monochrome_room.gd` | `MONOCHROME_ROOM_TESTS checks=` | null→null | 60→60 |
| reverse-time battlefield outskirts and optional spike branch | `res://tests/test_outskirts.gd` | `OUTSKIRTS_TESTS checks=` | null→null | 60→60 |
| outskirts enhanced dodge spike challenge persistence and retry | `res://tests/test_outskirts_challenge.gd` | `OUTSKIRTS_CHALLENGE_TESTS checks=` | null→null | 60→60 |
| outskirts optional rescue deferred growth abandonment and slot isolation | `res://tests/test_outskirts_rescue.gd` | `OUTSKIRTS_RESCUE_TESTS checks=` | null→null | 60→60 |
| overlook Boss battle and permanent victory | `res://tests/test_overlook_boss.gd` | `OVERLOOK_BOSS_TESTS checks=` | null→null | 60→60 |
| parasite Boss lifesteal reflection and third-day victory | `res://tests/test_parasite_boss.gd` | `PARASITE_BOSS_TESTS checks=` | null→null | 60→60 |
| parasite flying support and resource rewards | `res://tests/test_parasite_support.gd` | `PARASITE_SUPPORT_TESTS checks=` | null→null | 60→60 |
| permanent pearl growth additive reach real hits reflection legacy saves and slots | `res://tests/test_pearl_growth.gd` | `PEARL_GROWTH_TESTS checks=` | null→null | 60→60 |
| enemy downward platform pursuit safe ledge descent and replanning | `res://tests/test_platform_descent.gd` | `PLATFORM_DESCENT_TESTS checks=` | null→null | 60→60 |
| platform detours around wide overhangs and real ravine video regression | `res://tests/test_platform_detour.gd` | `PLATFORM_DETOUR_TESTS checks=` | null→null | 60→60 |
| TileMap wall backsteps same-level obstacles and moving target regression | `res://tests/test_platform_obstacles.gd` | `PLATFORM_OBSTACLES_TESTS checks=` | null→null | 60→60 |
| enemy multi-platform pursuit overhang wall and cliff safety | `res://tests/test_platform_pursuit.gd` | `PLATFORM_PURSUIT_TESTS checks=` | null→null | 60→60 |
| player physics regression | `res://tests/test_player.gd` | `PLAYER_TESTS checks=` | null→null | 60→60 |
| player life and death regression | `res://tests/test_player_life.gd` | `PLAYER_LIFE_TESTS checks=` | null→null | 60→60 |
| possibility dodge and healing regression | `res://tests/test_possibility.gd` | `POSSIBILITY_TESTS checks=` | null→null | 60→60 |
| all-Room rounded platform contact perturbations | `res://tests/test_pursuit_contacts.gd` | `PURSUIT_CONTACTS_TESTS checks=` | 60→60 | 180→180 |
| dynamic pursuit recovery and multi-platform video regression | `res://tests/test_pursuit_recovery.gd` | `PURSUIT_RECOVERY_TESTS checks=` | 60→60 | 60→60 |
| all-Room pursuit survey A | `res://tests/test_pursuit_survey_a.gd` | `PURSUIT_SURVEY_A_TESTS checks=` | 60→60 | 600→600 |
| all-Room pursuit survey B | `res://tests/test_pursuit_survey_b.gd` | `PURSUIT_SURVEY_B_TESTS checks=` | 60→60 | 600→600 |
| all-Room pursuit survey C | `res://tests/test_pursuit_survey_c.gd` | `PURSUIT_SURVEY_C_TESTS checks=` | 60→60 | 600→600 |
| all-Room pursuit survey D | `res://tests/test_pursuit_survey_d.gd` | `PURSUIT_SURVEY_D_TESTS checks=` | 60→60 | 600→600 |
| all-Room pursuit gate-state survey E | `res://tests/test_pursuit_survey_e.gd` | `PURSUIT_SURVEY_E_TESTS checks=` | 60→60 | 600→600 |
| ravine checkpoint and persistent second-day event | `res://tests/test_ravine_day.gd` | `RAVINE_DAY_TESTS checks=` | null→null | 60→60 |
| ravine depth clear rescue and pearl persistence | `res://tests/test_ravine_depth.gd` | `RAVINE_DEPTH_TESTS checks=` | null→null | 60→60 |
| ravine monochrome composition physical pursuit rewards and reset | `res://tests/test_ravine_monochrome.gd` | `RAVINE_MONOCHROME_TESTS checks=` | null→null | 60→60 |
| ravine survivor rescue and deferred growth | `res://tests/test_ravine_rescue.gd` | `RAVINE_RESCUE_TESTS checks=` | null→null | 60→60 |
| remnant possibility five encounters threshold timing isolation rewards and cleanup | `res://tests/test_remnant_possibility.gd` | `REMNANT_POSSIBILITY_TESTS checks=` | null→null | 60→60 |
| falling debris collision damage scheduler and rubble attacks | `res://tests/test_rockfall.gd` | `ROCKFALL_TESTS checks=` | null→null | 60→60 |
| versioned slot persistence regression | `res://tests/test_slot_store.gd` | `SLOT_STORE_TESTS checks=` | null→null | 60→60 |
| starting Room and persistent Nodes | `res://tests/test_start_room.gd` | `START_ROOM_TESTS checks=` | null→null | 60→60 |
| real input Ten clear aftermath and distinct reinforcement arrival | `res://tests/test_ten_clear_presentation.gd` | `TEN_CLEAR_PRESENTATION_TESTS checks=` | null→null | 60→60 |
| Ten aggression mobility physical dash and repeated attacks | `res://tests/test_ten_mobility.gd` | `TEN_MOBILITY_TESTS checks=` | null→null | 60→60 |
| Ten rescue interception cinematic persistence and cooperation | `res://tests/test_ten_rescue.gd` | `TEN_RESCUE_TESTS checks=` | null→null | 60→60 |
| Tian warrior combos guard counter blink and shared attacks | `res://tests/test_tian.gd` | `TIAN_TESTS checks=` | null→null | 60→60 |
| Tian first introduction freedom rewards and save retries | `res://tests/test_tian_room.gd` | `TIAN_ROOM_TESTS checks=` | null→null | 60→60 |
| vertical tower Room and checkpoint return | `res://tests/test_tower_room.gd` | `TOWER_ROOM_TESTS checks=` | null→null | 60→60 |
| town rescue and first permanent growth | `res://tests/test_town_rescue.gd` | `TOWN_RESCUE_TESTS checks=` | null→null | 60→60 |
| trench traversal checkpoint and pearl persistence | `res://tests/test_trench.gd` | `TRENCH_TESTS checks=` | null→null | 60→60 |
| second trench negative-resource route and permanent passage | `res://tests/test_trench_passage.gd` | `TRENCH_PASSAGE_TESTS checks=` | null→null | 60→60 |
| adjacent Rooms and first encounter | `res://tests/test_two_rooms.gd` | `TWO_ROOM_TESTS checks=` | null→null | 60→60 |
| NPC deadline migration and ordinary enemy day configuration | `res://tests/test_world_day_rules.gd` | `WORLD_DAY_RULES_TESTS checks=` | null→null | 60→60 |
| NPC deadline real sessions cross-day save rollback legacy rescue and dynamic spawns | `res://tests/test_world_day_session.gd` | `WORLD_DAY_SESSION_TESTS checks=` | null→null | 60→60 |

73套件参数分布：{(None, 60): 63, (60, 60): 3, (60, 180): 2, (60, 600): 5}。
