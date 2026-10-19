"""冻结规则回归检查。运行：python -X utf8 -m unittest discover -s tests -v"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORDS = ROOT / "Words"
FILES = {
    "T0": "T0_V0.1范围冻结.md",
    "T1": "T1_核心玩法与玩家操作.md",
    "T2": "T2_战斗系统.md",
    "T3": "T3_可能性_基础属性_成长_死亡.md",
    "T4": "T4_3天倒计时系统.md",
    "T5.1": "T5.1_地图结构设计规范_V1.0.md",
    "T5": "T5_区域与空间配置规范.md",
    "T5.2": "T5.2_区域架构收束规范.md",
    "T5.3": "T5.3_Room设计收束规范.md",
    "T5.4": "T5.4_关键Node详细设计策划案.md",
}


class PlanningDocumentsTests(unittest.TestCase):
    def setUp(self):
        self.docs = {key: (WORDS / name).read_text(encoding="utf-8")
                     for key, name in FILES.items()}

    def test_document_integrity_and_tables(self):
        for key, content in self.docs.items():
            with self.subTest(document=key):
                self.assertTrue(content.startswith("# 《末日前31天》"))
                self.assertNotIn("\ufffd", content)
                self.assertNotIn("chatgpt-content-reference", content)
                self.assertNotRegex(content, r"(?i)\b(TODO|TBD)\b|填写此处")
                date = {"T5.4": "2026-10-14", "T5.3": "2026-10-11"}.get(key, "2026-10-10" if key.startswith("T5") else {"T4": "2026-10-08"}.get(key, "2026-10-07"))
                self.assertIn(date, content)
                headings = re.findall(r"^## (\d+)\.", content, re.M)
                self.assertEqual(list(map(int, headings)),
                                 list(range(1, len(headings) + 1)))
                width = None
                for line in content.splitlines():
                    if line.startswith("|"):
                        current = len(line.split("|")) - 2
                        if width is None:
                            width = current
                        self.assertEqual(current, width, line)
                    else:
                        width = None

    def test_t0_scope_exclusions_are_complete(self):
        excluded = ["荒漠及后续地图", "虹光坠落之地", "残败研究院", "星舟墓地",
                    "酸沼", "臭雨林", "逆巴别塔", "钉锤营地", "8、11、1、12正式剧情",
                    "破障", "破妄", "星空", "引导", "11枚信物", "完整31天流程",
                    "完整装备系统", "完整声望系统", "正式商店系统", "多结局",
                    "完整支线系统", "大规模收集系统", "最终品质美术", "完整配音",
                    "完整音乐系统"]
        section = self.docs["T0"].split("## 4.")[1].split("## 5.")[0]
        for term in excluded:
            with self.subTest(exclusion=term):
                self.assertIn(term, section)
        self.assertIn("不冻结“一个区域等于一天”", self.docs["T0"])
        self.assertIn("不做完整货币玩法", self.docs["T0"])

    def test_cross_document_controls_and_resource_boundaries(self):
        for key in ("T1", "T2"):
            with self.subTest(document=key):
                content = self.docs[key]
                for rule in ("地面/空中左右闪避", "攻击中可跳跃且不打断攻击", "2.8秒", "最多连续3次", "满血不可",
                             "不恢复生命"):
                    self.assertIn(rule, content)
        # T1 is a current spec: values T3 has frozen are cited, not deferred.
        self.assertIn("留到T3", self.docs["T2"])
        self.assertIn("见T3", self.docs["T1"])
        self.assertNotIn("留到T3", self.docs["T1"])
        self.assertIn("V0.1不做墙跳、贴墙、蹬墙", self.docs["T1"])
        self.assertIn("3秒复活无敌", self.docs["T1"])
        self.assertIn("不作为V0.1任何必经地形的通行条件", self.docs["T1"])
        self.assertIn("同一次攻击动作对同一目标只造成一次伤害", self.docs["T2"])

    def test_t0_t1_are_current_specs_with_change_logs(self):
        for key, last in (("T0", 7), ("T1", 9)):
            with self.subTest(document=key):
                content = self.docs[key]
                self.assertNotRegex(content, r"【20\d\d-")
                self.assertNotRegex(content, r"(?m)^\*\*20\d\d-")
                self.assertIn("现行版更新：", content)
                headings = re.findall(r"^## (\d+)\. (.+)$", content, re.M)
                self.assertEqual(headings[-1], (str(last), "变更记录"))
                log = content.split(f"## {last}. 变更记录")[1]
                self.assertIn("| 日期 | 变更 | 来源 |", log)
                self.assertIn("2026-10-19", log)
        t0, t1 = self.docs["T0"], self.docs["T1"]
        for superseded in ("不依赖墙体能力、空中闪避", "未给出道具清单", "修订前的2倍"):
            self.assertNotIn(superseded, t1)
        self.assertNotIn("空中闪避于2026-10-15", t0)
        for rule in ("渴望俯视", "寄生同伴者", "应急药包", "攻击范围", "闪避速度",
                     "10的生命上限成长不在V0.1正式开放"):
            self.assertIn(rule, t0)
        for rule in ("不超过0.5秒", "前摇与后摇各乘2", "长按跳跃最大高度的50%", "取消攻击时的移动减速",
                     "Q / Back", "消耗1个立即恢复2生命", "-9", "1.3秒", "50%", "死亡菜单"):
            self.assertIn(rule, t1)
        # Growth: help given before 7's gaze is recorded and settled on the first gaze (T3 rescue revisions).
        self.assertIn("获得注视前完成的有效帮助先记录，首次获得注视时统一结算", t1)
        # Ten's rescue: cite the current three-condition revision, never the old two-condition section.
        self.assertIn("2026-10-16追加修订：10一次性救场与协同测试", t1)
        for trigger in ("致命攻击", "两名幸存者均到达后全部倒下", "第二波兜底"):
            self.assertIn(trigger, t1.split("### 4.2")[1].split("### 4.3")[0])
        for stale in ("T2第10节", "幸存者死亡达到一半", "幸存者战士损失达到一半"):
            self.assertNotIn(stale, t1)

    def test_all_six_accepted_t2_revisions_replace_original_rules(self):
        t2 = self.docs["T2"]
        rules = ["暂不实现正式削韧数值系统", "限制同一瞬间真正执行进攻的敌人数",
                 "不直接根据玩家精确HP作弊式选招", "只触发一次特殊救场",
                 "玩家附近单位完整AI、远处简化战斗/演出逻辑",
                 "不做随机战利品系统"]
        for rule in rules:
            with self.subTest(rule=rule):
                self.assertIn(rule, t2)
        self.assertIn("两个条件共享同一事件", t2)
        self.assertIn("玩家再次死亡正常进入死亡复活流程", t2)
        self.assertIn("自身低血量时提高闪避欲望", t2)
        self.assertIn("单个波次结束不等于V0.1结束", t2)
        self.assertNotIn("能，直到战斗结束", t2)
        self.assertNotIn("根据与玩家的距离与玩家当前血量", t2)

    def test_design_freeze_is_not_claimed_as_runtime_validation(self):
        self.assertIn("不表示游戏实现或运行测试已经完成", self.docs["T0"])
        self.assertIn("尚需游戏实现后运行验证", self.docs["T1"])
        self.assertIn("仍须在实现后进行运行验证", self.docs["T2"])
        for goal in ("普通战斗闭环", "三类敌人差异", "群战成立", "V0.1最终战"):
            self.assertIn(goal, self.docs["T2"])

    def test_t3_confirmed_economy_and_growth(self):
        t3 = self.docs["T3"]
        self.assertRegex(t3, r"\| 恢复生命 \| 一次完整恢复消耗3可能性 \|")
        self.assertRegex(t3, r"\| 恢复量 \| 一次完整恢复2生命")
        self.assertIn("10 → 12 → 13 → 14 → 15", t3)
        self.assertIn("再允许3次+1", t3)
        self.assertIn("同一NPC不能反复触发成长计数", t3)
        for enemy, reward in (("无色实体", 2), ("单色实体", 7), ("天人战士", 11)):
            self.assertRegex(t3, rf"\| 击杀{enemy} \| \+{reward}(?: \||；)")
            self.assertIn(f"{enemy}+{reward}", self.docs["T2"])

    def test_t3_combat_baseline_arithmetic(self):
        t3 = self.docs["T3"]
        for enemy, hp in (("无色实体", 13), ("单色实体", 21), ("天人战士", 31)):
            hits = (hp + 4) // 5
            self.assertIn(f"{enemy}生命定位 | {hp}点，理论需要{hits}次普通攻击", t3)
        self.assertIn("第一、第二、第三次分别消耗1、2、3可能性", t3)
        self.assertIn("三次合计消耗6可能性", t3)
        for damage, percentage in ((1, 20), (2, 40), (3, 60)):
            self.assertIn(f"{damage}点，占基础最大生命的{percentage}%", t3)

    def test_t3_death_overdraft_and_persistence(self):
        t3 = self.docs["T3"]
        for rule in ("余额下界为-9", "死亡后负数清零", "非负余额保留死亡时当前可能性的50%",
                     "当前可能性小于3时禁止启动", "不能据此把余额扣到-9以下",
                     "主动攻击不提前解除复活无敌", "已完成NPC事件不回滚",
                     "返回检查点、返回标题、设置", "任务永久失败", "不能返回补救"):
            self.assertIn(rule, t3)

    def test_t3_unresolved_edges_are_visible(self):
        section = self.docs["T3"].split("## 12.")[1].split("## 13.")[0]
        for edge in ("剧情奖励", "透支边界", "连闪计时", "主动中止恢复",
                     "死亡保留", "重复帮助", "保底实体"):
            self.assertIn(edge, section)
        self.assertIn("不将存在未决边界等同于已经证明无软锁", section)
        self.assertIn("游戏运行验收须在实现后完成", self.docs["T3"])

    def test_t4_clock_and_day_transitions(self):
        t4 = self.docs["T4"]
        for rule in ("V0.1一天为半小时", "基础时间自动流逝", "关键事件强制推进日期",
                     "剧情进行时暂停时间", "打开菜单时暂停时间", "15分钟倒计时",
                     "结束与7的相遇剧情，并离开7所处区域", "末日临界阶段"):
            self.assertIn(rule, t4)
        self.assertIn("三天并非固定一张地图对应一天", t4)
        self.assertIn("不自动授予战斗胜利", t4)

    def test_t4_accepted_revisions_and_scope_boundaries(self):
        t4 = self.docs["T4"]
        for rule in ("暗室侵蚀导致敌人更危险", "不直接Game Over",
                     "允许玩家反复往返场景", "不设一次性奖励上限",
                     "时间可感知", "时间推动剧情", "可扩展性"):
            self.assertIn(rule, t4)
        section = t4.split("## 9.")[1].split("## 10.")[0]
        for edge in ("日期推进", "Day2线索BOSS", "临界计时", "超时结算", "刷新额度", "配置与存档"):
            self.assertIn(edge, section)
        self.assertIn("本次不擅自新增制作项", section)
        self.assertIn("T0不做多结局", section)
        self.assertIn("不推定退出游戏后的现实时间继续计时", section)

    def test_t4_world_changes_and_full_game_separation(self):
        t4 = self.docs["T4"]
        for rule in ("单色实体增多，无色实体减少", "更多空缺与陷阱",
                     "更多可帮助NPC与较低敌人难度", "可通过重置敌人补充可能性",
                     "更早到来曾有救助机会", "NPC知道时间推进"):
            self.assertIn(rule, t4)
        self.assertIn("31天扩展方向（不纳入V0.1制作）", t4)
        self.assertIn("不能据此给V0.1新增Boss或角色debuff", t4)
        self.assertIn("不代表上述游戏运行验证已经完成", t4)

    def test_map_structure_levels_and_connections(self):
        content = self.docs["T5.1"]
        self.assertIn("World → Region → Scene → Room → Node", content)
        self.assertIn("房间之间支持无缝衔接", content)
        self.assertIn("数个房间可组成一片较大的连续场景", content)
        self.assertIn("一个Room可以拥有多个Connection", content)
        self.assertIn("删除普通房间通用的“固定进入状态”", content)
        self.assertIn("能力门独立管理", content)
        self.assertIn("时间会改变地图状态", content)

    def test_map_templates_preserve_all_v1_fields(self):
        content = self.docs["T5.1"]
        expected = {
            "Region": "区域名称 区域编号 所属世界位置 区域规模 核心主题 核心情绪 主要玩法 主要敌人 主要NPC 核心事件 区域奖励 时间影响 可回访价值 连接区域".split(),
            "Scene": "场景名称 所属区域 场景功能 空间规模 环境主题 玩家首次体验 地形特点 战斗特点 探索特点 NPC分布 敌人分布 隐藏内容 时间变化 与其他Scene关系".split(),
            "Room": "Room名称 所属Scene Room作用 空间大小 空间形状 地形结构 连接节点数量 加载需求 环境互动 普通敌人 精英敌人 NPC 收集物 解谜 能力门 检查点 剧情触发".split(),
            "Node": "节点名称 节点类型 触发方式 触发条件 触发结果 是否一次性 是否随时间变化".split(),
            "Connection": "连接对象 连接类型 当前状态 解锁条件 是否可回访".split(),
            "Ability Gate": "名称 所在位置 表现形式 玩家首次看到的信息 解锁能力 解锁后奖励 是否影响剧情".split(),
        }
        for template, fields in expected.items():
            with self.subTest(template=template):
                section = content.split(f"### {template}设计表\n", 1)[1].lstrip().split("\n\n", 1)[0]
                rows = [line.split("|")[1].strip() for line in section.splitlines()[2:]]
                self.assertEqual(rows, fields)

    def test_map_entry_rules_and_development_scope(self):
        content = self.docs["T5.1"]
        for kind in ("普通Room", "探索区域", "普通战斗", "NPC区域"):
            self.assertIn(f"| {kind} | 否 |", content)
        for kind in ("剧情演出房", "Boss区域", "结局区域", "时间事件区域", "能力门后区域"):
            self.assertIn(f"| {kind} | 是 |", content)
        self.assertIn("破障仍不纳入V0.1制作范围", content)
        self.assertIn("不能据此自行新增V0.1 Boss", content)
        self.assertIn("不提前填写区域实例", content)
        self.assertIn("不开展美术、加载系统或程序实现", content)

    def test_t5_preserves_configuration_records(self):
        content = self.docs["T5"]
        expected = ((9, "Region", 3), (10, "Scene", 12), (11, "Room", 18), (12, "Node", 9))
        for number, kind, count in expected:
            section = content.split(f"## {number}. {kind}原表配置明细", 1)[1].split("\n## ", 1)[0]
            self.assertEqual(len(re.findall(r"^### \d+\.", section, re.M)), count)
        for region_id in ("Region_HD", "Region_TY", "Region_NSZC"):
            self.assertIn(region_id, content)
        for node in range(10001, 10010):
            self.assertIn(f"Node_{node}", content)
        self.assertIn("基础战斗能力提升，即玩家对基础操作和战斗的掌握，不增加攻击力数值", content)
        self.assertIn("取消原表“每个房间各一个”", content)
        self.assertIn("不能将其视为已解除T0～T4限制", content)

    def test_t52_connection_and_time_rules(self):
        content = self.docs["T5.2"]
        for rule in ("任何层级均可存在Connection", "隐藏属于未发现的Connection",
                     "Connection表现不决定Connection类型", "开放/关闭/变化",
                     "结束指定战斗且存活后开放", "Before Day3、Day3 Event、After Day3",
                     "玩家已完成事件永久保存", "不要求制作三张完整地图"):
            self.assertIn(rule, content)
        self.assertIn("已开启连接永久存在，但时间连接仍支持开放/关闭", content)

    def test_t52_checkpoint_does_not_rollback_permanent_progress(self):
        content = self.docs["T5.2"]
        for rule in ("最后激活的检查点", "自动激活", "V0.1死亡不额外推进时间",
                     "非负保留50%，负数清零", "永久成长与已获得物品仍按T3保留"):
            self.assertIn(rule, content)
        for field in ("位置", "已激活检查点", "剧情状态", "地图状态", "NPC状态", "能力解锁"):
            self.assertIn(f"| {field} | 保存 |", content)
        for field in ("当前生命", "当前可能性"):
            self.assertIn(f"| {field} | 不保存为复活回档值 |", content)
        self.assertIn("| 临时状态 | 不保存 |", content)

    def test_t52_node_ownership_and_persistence(self):
        content = self.docs["T5.2"]
        for rule in ("Node直接属于Room，不跨级", "需要唯一编号", "Node默认不保存，由类型决定",
                     "自动、互动、攻击、条件", "检查点、能力门、触发区域"):
            self.assertIn(rule, content)
        self.assertIn("| 普通敌人状态 | 否，按重置规则处理 |", content)
        self.assertIn("| NPC剧情状态 | 是 |", content)
        self.assertIn("| 机关开启状态 | 是 |", content)
        self.assertIn("不代表T5.3具体房间与节点已全部设计完成", content)

    def test_planning_document_links_resolve(self):
        for key, content in self.docs.items():
            for target in re.findall(r"\]\(([^)]+\.md)\)", content):
                with self.subTest(document=key, target=target):
                    self.assertTrue((WORDS / target).is_file())

    def t53_records(self):
        section = self.docs["T5.3"].split("## 10. Room冻结配置明细", 1)[1]
        records = {}
        for block in re.split(r"\n### \d+\. ", section)[1:]:
            fields = dict(re.findall(r"^- ([^：\n]+)：(.*)$", block, re.M))
            records[fields["编号"]] = fields
        return records

    def test_t53_room_identity_and_scene_membership(self):
        records = self.t53_records()
        self.assertEqual(len(records), 18)
        regions = {"HD": 0, "TY": 0, "NSZC": 0}
        for room_id, fields in records.items():
            region, scene, room_number = room_id.split("_")
            regions[region] += 1
            self.assertEqual(fields["所属Scene"], f"Region_{region}_Scene_{scene}")
            self.assertGreater(int(room_number), 0)
            self.assertEqual(len(fields), 43)
        self.assertEqual(regions, {"HD": 12, "TY": 2, "NSZC": 4})
        self.assertEqual(records["HD_20002_2"]["Room名称"], "逃兵营帐")
        self.assertEqual(records["HD_20003_1"]["Room名称"], "寄生同伴者")

    def test_t53_connections_resolve_and_preserve_parallel_fields(self):
        records = self.t53_records()
        for room_id, fields in records.items():
            targets = fields["连接对象"].split("/")
            for target in targets:
                self.assertIn(target, records, f"{room_id} -> {target}")
            for field in ("连接类型", "表现形式", "是否永久开放", "回访状态"):
                if room_id == "NSZC_10003_1" and field in ("是否永久开放", "回访状态"):
                    # 原表单目标附有重复状态，保留原值并在规范中标明，不能虚构连接。
                    expected_value = "永久/永久" if field == "是否永久开放" else "可/可"
                    self.assertEqual(fields[field], expected_value)
                    self.assertIn("不据重复项虚构第二个连接", self.docs["T5.3"])
                    continue
                self.assertEqual(len(fields[field].split("/")), len(targets), (room_id, field))
            # 原表允许两个连接共用一个开启条件。
            self.assertIn(len(fields["开启条件"].split("/")), (1, len(targets)))
        self.assertIn("类型与条件不一致项", self.docs["T5.3"])
        self.assertIn("不静默改型或新增中心战场Boss", self.docs["T5.3"])

    def test_t53_boss_and_gate_scope(self):
        content = self.docs["T5.3"]
        records = self.t53_records()
        bosses = {key: val["BOSS信息"] for key, val in records.items() if val["BOSS信息"] != "未填写"}
        self.assertEqual(bosses, {"HD_10004_1": "渴望俯视", "HD_20003_1": "寄生同伴者"})
        self.assertIn("不新增防御+反击的弹反系统", content)
        self.assertIn("不自动提高攻击力、开放空中闪避或改写T3基础数值", content)
        gates = [key for key, val in records.items() if val["能力门"] == "是"]
        self.assertEqual(gates, ["NSZC_10001_1", "NSZC_10002_2"])
        for key in gates:
            self.assertEqual(records[key]["解锁条件"], "战斗事件门")
        self.assertIn("任何必经地形不能要求消耗可能性的滑步", content)
        t0_scope = self.docs["T0"].split("## 1.")[1].split("## 3.")[0]
        for boss in ("渴望俯视", "寄生同伴者"):
            self.assertIn(boss, t0_scope)
        self.assertIn("最终战不增加额外Boss", self.docs["T0"])
        self.assertNotIn("不新增Boss", self.docs["T0"])

    def test_t53_room_node_state_separation(self):
        for key, fields in self.t53_records().items():
            with self.subTest(room=key):
                self.assertEqual(fields["Room保存"], "不保存")
                self.assertEqual(fields["Node保存"], "由Node决定")
                self.assertEqual(fields["敌人状态"], "除保有“不可重置”设定的敌人全部重置")
                for state in ("NPC状态", "剧情状态", "能力门状态"):
                    self.assertEqual(fields[state], "保留")
        self.assertIn("默认不保存，由类型和具体配置决定", self.docs["T5.3"])

    def test_t53_nonblocking_fields_and_stage_status(self):
        content = self.docs["T5.3"]
        for term in ("非阻塞补充项", "Connection目标类型", "房间核心目标", "情绪关键词"):
            self.assertIn(term, content)
        self.assertIn("未直接填作所有房间最终目标", content)
        self.assertIn("不等于Node实例、程序、美术或UI制作已完成", content)
        self.assertIn("黄金麦湖", content)

    def t54_records(self):
        section = self.docs["T5.4"].split("## 9. Node最终配置明细", 1)[1]
        records = {}
        for block in re.split(r"\n### \d+\. ", section)[1:]:
            fields = dict(re.findall(r"^- ([^：\n]+)：(.*)$", block, re.M))
            self.assertNotIn(fields["Node编号"], records)
            records[fields["Node编号"]] = fields
        return records

    def test_t54_identity_membership_and_complete_fields(self):
        records = self.t54_records()
        rooms = self.t53_records()
        self.assertEqual(len(records), 27)
        totals = {"HD": 0, "TY": 0, "NSZC": 0}
        for node_id, fields in records.items():
            self.assertEqual(len(fields), 20)
            room_id, serial = node_id.rsplit("_", 1)
            self.assertRegex(serial, r"^N\d{3}$")
            self.assertEqual(fields["所属Room"], room_id)
            self.assertIn(room_id, rooms)
            region, scene, _ = room_id.split("_")
            totals[region] += 1
            self.assertEqual(fields["所属Region"], f"Region_{region}")
            self.assertEqual(fields["所属Scene"], rooms[room_id]["所属Scene"])
        self.assertEqual(totals, {"HD": 13, "TY": 5, "NSZC": 9})
        self.assertEqual(len({f["所属Room"] for f in records.values()}), 11)
        self.assertNotIn("TY_10001_1_N003", records)

    def test_t54_explicit_node_references_resolve(self):
        records = self.t54_records()
        for node_id, fields in records.items():
            for text in fields.values():
                for target in re.findall(r"(?:HD|TY|NSZC)_\d{5}_\d+_N\d{3}", text):
                    self.assertIn(target, records, (node_id, target))

    def test_t54_introduction_and_boss_persistence_are_separate(self):
        records = self.t54_records()
        for key in ("HD_10002_1_N001", "NSZC_10002_1_N001"):
            self.assertEqual(records[key]["是否一次性"], "首次介绍事件一次性")
            self.assertEqual(records[key]["死亡后状态"], "首次介绍完成状态保留；普通敌人按检查点规则重置")
        for boss, gate in (("HD_10004_1_N001", "HD_10004_1_N002"),
                           ("HD_20003_1_N001", "HD_20003_1_N002")):
            self.assertEqual(records[gate]["触发条件"], f"{boss}节点BOSS被击杀")
            for rule in ("保存击败状态", "未击败则战斗重置", "首次演出不重复"):
                self.assertIn(rule, records[boss]["死亡后状态"])

    def test_t54_checkpoints_and_event_days(self):
        records = self.t54_records()
        checkpoints = [fields for fields in records.values() if fields["Node类型"] == "检查点"]
        self.assertEqual(len(checkpoints), 8)
        for fields in checkpoints:
            self.assertEqual(fields["触发方式"], "自动")
            self.assertEqual(fields["Node作用"], "记录复活位置")
        self.assertIn("强制进入第二日", records["HD_20001_1_N001"]["时间变化"])
        self.assertIn("强制进入第三日", records["HD_20003_1_N002"]["时间变化"])
        self.assertIn("不得据原表前一条直接把第三日回退至第二日", self.docs["T5.4"])

    def test_t54_final_battle_and_ending_chain(self):
        records = self.t54_records()
        prefix = "NSZC_10003_1_"
        self.assertEqual(records[prefix + "N002"]["是否一次性"], "是")
        self.assertEqual(records[prefix + "N002"]["死亡后状态"], "保留")
        self.assertIn("秒杀当前全部敌人", records[prefix + "N002"]["发生内容"])
        self.assertIn("玩家死亡后重新进Room", records[prefix + "N004"]["触发条件"])
        self.assertIn("少于15分钟，则以当前时间为准", records[prefix + "N004"]["时间变化"])
        for rule in ("进入失败结算", "触发最终增援", "终止倒计时并结算为胜利"):
            self.assertIn(rule, records[prefix + "N005"]["触发条件"])
        self.assertIn(prefix + "N001", records[prefix + "N006"]["触发条件"])
        self.assertIn("执行完毕", records[prefix + "N006"]["触发条件"])
        self.assertIn("不实现为相互反复调用", self.docs["T5.4"])

    def test_t54_uncertainties_and_scope_remain_visible(self):
        content = self.docs["T5.4"]
        for term in ("关键功能逻辑", "普通批量敌人", "每波次重复2次",
                     "区分首次加入事件与每波增援行为", "不自行建立自动回能系统",
                     "不把“死亡不额外推进时间”解释为免费重置15分钟",
                     "不将早期Node示例里的食物任务混入最终配置"):
            self.assertIn(term, content)
        self.assertIn("空白显示未填写，不等同于否、无或已完成", content)


if __name__ == "__main__":
    unittest.main()
