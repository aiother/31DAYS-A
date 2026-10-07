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
                self.assertIn("2026-10-07", content)
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
                for rule in ("仅地面", "2.8秒", "最多连续3次", "满血不可",
                             "不恢复生命", "留到T3"):
                    self.assertIn(rule, content)
        self.assertIn("V0.1不做墙跳、贴墙、蹬墙", self.docs["T1"])
        self.assertIn("3秒复活无敌", self.docs["T1"])
        self.assertIn("不作为V0.1任何必经地形的通行条件", self.docs["T1"])
        self.assertIn("同一次攻击动作对同一目标只造成一次伤害", self.docs["T2"])

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


if __name__ == "__main__":
    unittest.main()
