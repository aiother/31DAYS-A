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
        # T1 and T2 are current specs: values T3 has frozen are cited, not deferred.
        self.assertNotIn("留到T3", self.docs["T2"])
        self.assertIn("见T3", self.docs["T2"])
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
        # Ten's rescue: T2 is a current spec (DOC-008), its rule lives in T2 section 10;
        # T1 cites that section, never the old revision title or the two-condition wording.
        rescue = t1.split("### 4.2")[1].split("### 4.3")[0]
        self.assertIn("见T2第10节", rescue)
        for trigger in ("致命攻击", "两名幸存者均到达后全部倒下", "第二波兜底"):
            self.assertIn(trigger, rescue)
        for stale in ("2026-10-16追加修订：10一次性救场与协同测试", "幸存者死亡达到一半", "幸存者战士损失达到一半"):
            self.assertNotIn(stale, t1)

    def test_t2_is_current_spec_with_change_log(self):
        t2 = self.docs["T2"]
        self.assertIn("现行版更新：", t2)
        self.assertNotRegex(t2, r"【20\d\d-")
        self.assertNotRegex(t2, r"(?m)^\*\*20\d\d-")
        self.assertNotRegex(t2, r"(?m)^## 20\d\d-")
        headings = re.findall(r"^## (\d+)\. (.+)$", t2, re.M)
        self.assertEqual(headings[-1], ("16", "变更记录"))
        # Sections 1-15 keep their numbers and titles (other documents cite "T2 §N").
        self.assertEqual([title for _, title in headings[:15]],
                         ["战斗总体", "玩家攻击", "命中规则", "玩家受击", "闪避战斗规则", "恢复战斗规则",
                          "敌人公共AI", "三类敌人", "友军AI与战场计算", "10特殊救场", "逆时战场流程与胜负",
                          "敌人死亡与奖励", "战斗场景", "战斗反馈", "设计验收与后续测试"])
        body, log = t2.split("## 16. 变更记录")
        self.assertIn("| 日期 | 变更 | 来源 |", log)
        for date in ("2026-10-07", "2026-10-14", "2026-10-15", "2026-10-16", "2026-10-17",
                     "2026-10-18", "2026-10-19", "2026-10-23"):
            self.assertIn(f"| {date} |", log)
        self.assertIn("DOC-008", log)
        # T1 cites this revision by its original title.
        self.assertIn("2026-10-16追加修订：10一次性救场与协同测试", log)
        for stale in ("留到T3", "后续配置更新", "修订标记", "幸存者战士死亡达到一半", "幸存者战士损失达到一半",
                      "幸存者死亡达到一半", "秒杀威胁单位", "未冻结恢复生命量", "救场无敌时长未确定",
                      "波次数量、各波单位数量与增援间隔尚未冻结", "前摇0.3秒/后摇0.65秒",
                      "两个条件共享同一事件", "仅地面", "旧档不自动生效", "需新增专用存档字段"):
            with self.subTest(stale=stale):
                self.assertNotIn(stale, body)

        def section(number):
            return body.split(f"\n## {number}. ")[1].split(f"\n## {number + 1}. ")[0]

        checks = {
            2: ("不超过0.5秒", "前摇与对应段后摇均乘2", "长按跳跃最大高度的50%", "下攻击不可弹反",
                "永久扩大20%", "各永久扩大5%", "140%", "不叠乘",
                # Save compatibility of the range growth (DOC-008 review R1).
                "消费原有的待领取标记", "已领取与待领取两种状态互斥", "不额外回血、补可能性或推进日期",
                "原有的永久拾取记录重建，不新增存档字段；旧档自动生效"),
            3: ("不会被玩家普通攻击打断", "致死优先终止动作"),
            4: ("1、2、3点", "伤害1-2点（见T3"),
            5: ("1、2、3可能性", "1.3秒", "前摇较大、无敌帧减少", "-9"),
            6: ("开始时扣除3可能性", "2.8秒", "当前可能性小于3时禁止启动", "一次性恢复2生命",
                "全部损失且不恢复生命", "提前松键与滑步取消同样不退还"),
            7: ("切换场景前持续追击", "950", "安全落差上限默认320", "960像素", "32像素", "480/600",
                # Active routes pause and expire (DOC-008 review R2).
                "执行中的追击路线支持暂停", "冻结移动与路线超时计时", "路线超时后退出并重新规划",
                "全身碰撞、连续支撑及可达跳跃弧线"),
            8: ("15/17", "生命21、击杀+7", "生命31、击杀+11", "含地面与空中实例，不新增地图"),
            9: ("不可被击败，每击10伤害", "移动420", "前摇0.18秒、后摇0.32秒"),
            10: ("有效致命伤，在扣血前优先拦截", "两名幸存者均到达后，存活严格少于50%（即全部倒下）",
                 "第二波（2天人+1单色）作为兜底", "三个条件共享同一次事件NSZC_10003_1_N002",
                 "清除当前全部敌人", "补满可能性，不回血", "无额外救场无敌"),
            14: ("普通攻击命中敌人（含两场Boss）时，玩家与被命中的敌人同时停住0.10秒", "同一次攻击命中多个敌人只停一次",
                 "未命中或只弹开投掷物不停", "不缩短也不重复任何阶段", "日内时钟与最终战计时照常流逝",
                 "普通命中不震屏", "玩家受击时轻震（5像素）"),
            11: ("2天人+1单色、3天人+1单色、4天人+2单色", "15分钟与第三日剩余时间的较小值",
                 "同帧归零与击杀时胜利优先", "可确认重试", "单个波次结束不等于V0.1结束"),
        }
        for number, rules in checks.items():
            text = section(number)
            for rule in rules:
                with self.subTest(section=number, rule=rule):
                    self.assertIn(rule, text)

    def test_user_decisions_of_2026_10_19_are_written_into_specs(self):
        t0, t1, t3, t54 = (self.docs[key] for key in ("T0", "T1", "T3", "T5.4"))
        # A-001 currency
        currency = t0.split("### 3.2")[1].split("### 3.3")[0]
        for rule in ("不能获取", "没有消费用途", "不在UI显示", "后续版本", "不做完整货币玩法"):
            self.assertIn(rule, currency)
        self.assertNotIn("仍待决", currency)
        # A-010 frozen key table, arrows bound to the correct directions
        keys = t1.split("## 7.")[1].split("## 8.")[0]
        self.assertIn("| 动作 | 键盘 | 手柄 |", keys)
        for row in ("| 向左移动 | A / ← |", "| 向右移动 | D / → |", "| 跳跃 | Space | A |",
                    "| 攻击 | J / 鼠标左键 | X |", "| 闪避 | K | B |", "| 恢复（长按） | L | Y |",
                    "| 跑步（按住） | Shift | LB |", "| 互动 | E | RB |", "| 使用药包 | Q | Back |",
                    "| 暂停 | Esc | Start |", "| 全屏切换 | F11 | — |", "| 调试重置 | R | — |"):
            self.assertIn(row, keys)
        self.assertNotIn("PageUp", t1)
        self.assertNotIn("未冻结完整键位表", t1)
        # A-002 remnant possibility entities
        remnant = t3.split("## 11.")[1].split("## 12.")[0]
        for rule in ("低于当前可能性上限的50%", "每10-15秒", "1-2个", "同时最多3只", "+2",
                     "营帐围攻", "渴望俯视", "寄生同伴者", "中心战场", "最终战", "不含堑壕"):
            self.assertIn(rule, remnant)
        self.assertNotIn("V0.1仍不新增Boss", t3)
        self.assertNotIn("精确触发条件、数量选择、奖励", t3)
        # A-003 reinforcement recovery source
        self.assertIn("友军击杀", t54)
        self.assertNotIn("来源与量未给出", t54)
        self.assertNotIn("未提供周期或额外发放量", t54)

    def test_t7_decisions_of_2026_10_19_are_written_into_specs(self):
        # A-012: same-frame victory now wins wherever the 2026-10-17 final-battle revision appears.
        for key in ("T2", "T4", "T5.3", "T5.4"):
            with self.subTest(document=key):
                self.assertNotIn("同帧归零与击杀超时优先", self.docs[key])
                self.assertIn("同帧归零与击杀时胜利优先", self.docs[key])
        # A-014: death menu options.
        self.assertNotIn("死亡菜单包括返回检查点、返回标题、设置；", self.docs["T3"])
        # A-017: settings scope; custom key binding deferred.
        keys = self.docs["T1"].split("## 7.")[1].split("## 8.")[0]
        for rule in ("全屏/窗口", "帧率", "按键列表", "自定义按键推迟到V0.1之后"):
            self.assertIn(rule, keys)
        self.assertNotIn("玩家自定义按键按T7提供", self.docs["T1"])
        # A-011: timeout shows the "未来已失" screen with retry and return to title.
        t4_force = self.docs["T4"].split("| 是否强制失败 |")[1].split("\n")[0]
        for rule in ("未来已失", "重试", "返回标题"):
            self.assertIn(rule, t4_force)
        self.assertNotIn("具体V0.1状态映射待明确", self.docs["T4"])
        t54_edges = self.docs["T5.4"].split("## 7.")[1].split("## 8.")[0]
        self.assertIn("未来已失", t54_edges)
        # A-013: a finished save cannot be entered again.
        self.assertIn("游戏已通关", t54_edges)
        # A-016: countdown display.
        countdown = self.docs["T5.4"].split("### 6.4")[1].split("### 6.5")[0]
        for rule in ("只是视觉表现", "不被消耗", "真实剩余"):
            self.assertIn(rule, countdown)

    def test_all_six_accepted_t2_revisions_replace_original_rules(self):
        t2 = self.docs["T2"]
        rules = ["暂不实现正式削韧数值系统", "限制同一瞬间真正执行进攻的敌人数",
                 "不直接根据玩家精确HP作弊式选招", "只触发一次特殊救场",
                 "玩家附近单位完整AI、远处简化战斗/演出逻辑",
                 "不做随机战利品系统"]
        for rule in rules:
            with self.subTest(rule=rule):
                self.assertIn(rule, t2)
        self.assertIn("三个条件共享同一次事件", t2)
        self.assertNotIn("两个条件共享同一事件", t2)
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
                     "从检查点继续、返回标题、设置、退出游戏", "任务永久失败", "不能返回补救"):
            self.assertIn(rule, t3)

    def test_t3_unresolved_edges_are_visible(self):
        t3 = self.docs["T3"]
        section = t3.split("\n## 12. ")[1].split("\n## 13. ")[0]
        # Still open: kept in section 12.
        for edge in ("保底实体", "资源不足的闪避", "随日期的内容变化"):
            self.assertIn(edge, section)
        self.assertIn("不将存在未决边界等同于已经证明无软锁", section)
        self.assertIn("游戏运行验收须在实现后完成", t3)
        # Settled (B-001 to B-003): written as rules in their sections, no longer open.
        for settled in ("剧情奖励：", "透支边界", "连闪计时", "主动中止恢复", "死亡保留", "重复帮助"):
            self.assertNotIn(settled, section)

    def test_t3_is_current_spec_with_change_log(self):
        t3 = self.docs["T3"]
        self.assertIn("现行版更新：", t3)
        self.assertNotRegex(t3, r"【20\d\d-")
        self.assertNotRegex(t3, r"(?m)^\*\*20\d\d-")
        self.assertNotRegex(t3, r"(?m)^## 20\d\d")
        headings = re.findall(r"^## (\d+)\. (.+)$", t3, re.M)
        # Sections 1-13 keep their numbers and titles (other documents cite "T3 §N").
        self.assertEqual([title for _, title in headings],
                         ["系统目标与资源循环", "基础属性与透支额度", "可能性获取与上限", "可能性消耗与连闪",
                          "恢复系统", "玩家受伤", "玩家输出与敌人生命", "成长系统", "7的注视与任务选择",
                          "死亡系统与复活保护", "资源防卡死", "实现前需明确的边界", "设计验收与验证重点", "变更记录"])
        body, log = t3.split("## 14. 变更记录")
        self.assertIn("| 日期 | 变更 | 来源 |", log)
        for date in ("2026-10-07", "2026-10-15", "2026-10-16", "2026-10-17", "2026-10-18",
                     "2026-10-19", "2026-10-21", "2026-10-24"):
            self.assertIn(f"| {date} |", log)
        self.assertIn("DOC-009", log)
        self.assertIn("修订前的2倍", log)
        for stale in ("V0.1永久属性成长只开放可能性上限", "V0.1不新增Boss", "不新增正式削韧数值系统或Boss",
                      "原表数值填写10", "结算口径见第12节", "原表没有明确", "自然日期不会自动判NPC死亡",
                      "仍待接入", "尚未交付", "尚未实现", "仍未接入", "珍珠仍为持久占位", "实施标记",
                      "以本轮确认数值为准", "覆盖原表恢复5生命", "本轮明确采用"):
            with self.subTest(stale=stale):
                self.assertNotIn(stale, body)

        def section(number):
            return body.split(f"\n## {number}. ")[1].split(f"\n## {number + 1}. ")[0]

        checks = {
            2: ("近战攻击范围", "闪避速度", "140%", "10的生命上限成长不正式开放", "从顶部顺时针填充",
                "只改变显示方式，不改变消耗、透支下限或其他规则"),
            3: ("每位NPC只发一次", "首次见7的剧情（TY_10001_1_N002）结束后补满可能性，此时不获得注视",
                "返回7完成注视结算（TY_10001_1_N005）时获得注视，上限10→12", "余额不额外补满",
                "不另发固定+10，两种奖励不叠加", "单个死亡实例只结算一次"),
            4: ("1.3秒从上一次实际滑步发动起计算，无效按键不重置计时", "扣费会低于-9时拒绝本次滑步",
                "到达-9后不能继续滑步", "720→900", "旧存档已有击败记录时自动补发一次", "保存失败不启用"),
            5: ("提前松键均不退还已扣3可能性", "5.1 应急药包", "每次消耗1个恢复2生命", "满血时不消耗",
                "不扣可能性、不提供无敌", "携带上限3、初始0，死亡保留", "旧存档不补发", "整体回滚"),
            7: ("长按跳跃最大高度的50%", "15/17生命", "渴望俯视与寄生同伴者两场Boss战"),
            8: ("麦秆镇幸存者", "HD_20001_2", "HD_20001_3", "NSZC_10001_1", "各发一次+4、各计一次成长",
                "同一NPC不能用两种帮助方式各领一次", "先提升上限，再把+4资源按新上限截断",
                "上限的+1延迟到首次获得注视时统一结算", "余额为零或负数时同样发放", "保存失败整体回滚并可重试"),
            9: ("返回7完成注视结算（TY_10001_1_N005）时立即永久生效",
                "首次见7的剧情（TY_10001_1_N002）只补满可能性，不获得注视",
                "清敌前可确认永久放弃并撤回", "死亡与读档不视为主动放弃", "80像素宽尖刺窄道",
                "保留本次闪避消耗及连闪计时", "不新增Room或检查点，沿用HD_20003_1_N003",
                "gate:NSZC_10001_1:spikes_cleared", "进入第3日时过期", "第3日剩余时间归零时过期",
                "过期的救助不发+4、不提高上限", "已见过、尚未救助且未主动放弃的NPC永久保留一次救助机会"),
            10: ("Boss未击败时死亡重置该场Boss战，击败后永久保留击败记录", "正常退出后重进保留资源，不执行死亡扣减，也不发放复活无敌",
                 "恢复本日30分钟", "不补满、不执行死亡扣减", "不赠送30分钟", "3→1、5→2"),
        }
        for number, rules in checks.items():
            text = section(number)
            for rule in rules:
                with self.subTest(section=number, rule=rule):
                    self.assertIn(rule, text)
        # Save-compatibility rules in both directions (DOC-008 review lesson).
        # Review R1: the gaze comes at the return to 7 after the rescue, never at the first scene.
        self.assertNotIn("完成7剧情后立即永久生效", body)
        for wrong in ("N002）结束后立即获得注视", "N002）结束后获得注视", "N002）结束后即获得注视", "首见即获得注视"):
            with self.subTest(wrong=wrong):
                self.assertNotIn(wrong, body)
        for wrong in ("旧存档补发药包", "药包死亡清空", "过期仍发+4", "注视前帮助立即提高上限"):
            with self.subTest(wrong=wrong):
                self.assertNotIn(wrong, body)

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
        section = t4.split("\n## 9. ")[1].split("\n## 10. ")[0]
        # Still open (A-004, A-005): kept in section 9.
        for edge in ("随日期的敌人构成与地形变体", "世界变化的其他表现"):
            self.assertIn(edge, section)
        self.assertIn("本次不擅自新增制作项", section)
        self.assertIn("T0不做多结局", section)
        self.assertIn("不推定退出游戏后的现实时间继续计时", section)
        # Settled by B-007..B-010: written as rules, no longer open edges.
        for settled in ("Day2线索BOSS", "临界计时：", "超时结算：", "刷新额度", "配置与存档："):
            self.assertNotIn(settled, section)

    def test_t4_is_current_spec_with_change_log(self):
        t4 = self.docs["T4"]
        self.assertIn("现行版更新：", t4)
        self.assertNotRegex(t4, r"【20\d\d-")
        self.assertNotRegex(t4, r"(?m)^\*\*20\d\d-")
        self.assertNotRegex(t4, r"(?m)^## 20\d\d")
        self.assertNotIn("后续配置更新", t4)
        headings = re.findall(r"^## (\d+)\. (.+)$", t4, re.M)
        self.assertEqual([title for _, title in headings],
                         ["时间系统目标", "时间核心与暂停", "V0.1三天结构", "时间压力与资源刷新", "世界变化",
                          "剧情时间与玩家认知", "31天扩展方向（不纳入V0.1制作）", "T4设计验收",
                          "实现前需明确的衔接边界", "变更记录"])
        body, log = t4.split("## 10. 变更记录")
        self.assertIn("| 日期 | 变更 | 来源 |", log)
        for date in ("2026-10-08", "2026-10-14", "2026-10-15", "2026-10-16", "2026-10-17",
                     "2026-10-18", "2026-10-19", "2026-10-21", "2026-10-25"):
            self.assertIn(f"| {date} |", log)
        self.assertIn("DOC-010", log)
        # B-005: the sentence contradicting the date batch is gone.
        for stale in ("自然日期不会自动判NPC死亡", "不新增Boss范围存在冲突", "触发10剧情时启动15分钟倒计时",
                      "具体时间阶段修正未给出数值", "仍需明确", "尚未实现", "待细则落实", "未随本轮扩展",
                      "同帧归零与击杀超时优先", "仅事件日期"):
            with self.subTest(stale=stale):
                self.assertNotIn(stale, body)

        def section(number):
            return body.split(f"\n## {number}. ")[1].split(f"\n## {number + 1}. ")[0]

        checks = {
            2: ("剧情进行时暂停时间", "打开菜单时暂停时间", "普通对话、救助放弃确认、死亡动画与死亡菜单期间也停表",
                "普通战斗与不锁操作的敌人首见介绍卡照常计时", "不计算玩家离线的现实时间",
                "日期至少为第2日", "日期至少为第3日", "不重复补时，也不倒退", "保存失败整体回滚（含时钟）",
                "`day_remaining`", "每0.5秒", "这只是画面表现", "不改变计时规则、预算或存档字段"),
            3: ("寄生同伴者（HD_20003_1）", "最终战正式开战时启动最终战15分钟倒计时",
                "最终战预算取15分钟与第3日剩余的较小值", "暂停、剧情、死亡菜单期间不扣时",
                "死亡与正常读档不回补最终战预算", "同帧归零与击杀时胜利优先", "最终胜利保存后永久开放唯一返回路并停止计时",
                "不自动授予战斗胜利"),
            4: ("恢复本日30分钟", "不补满、不执行死亡扣减", "继续保持超时状态与0余量", "不重复救场与补满",
                "原预算为0时只能换槽或新游戏", "不赠送30分钟", "Esc与通用继续入口不能绕过明确的重试确认"),
            5: ("15/17", "110%/120%", "90%/80%", "跨日不修改已生成单位", "进入第3日立即过期",
                "外围救助在第3日剩余归零时过期", "已见过、尚未救助且未主动放弃的NPC永久保留一次救助机会"),
        }
        for number, rules in checks.items():
            text = section(number)
            for rule in rules:
                with self.subTest(section=number, rule=rule):
                    self.assertIn(rule, text)
        # Stage words: the final budget starts at the formal start, not at the 10 scene.
        self.assertIn("**正式开战**专指最终战开始计算最终战预算的时刻，不是进入逆时战场或触发10剧情的时刻", body)
        for wrong in ("进入逆时战场时启动", "触发10剧情时启动", "死亡与正常读档回补", "超时优先"):
            with self.subTest(wrong=wrong):
                self.assertNotIn(wrong, body)
        # Stage order (DOC-010 R1): rescue before the formal start, the three
        # cooperative waves after it, inside the final budget.
        flow = re.search(r"^临界流程：([^。\n]+)", section(3), re.M)
        self.assertIsNotNone(flow)
        stages = [stage.strip() for stage in flow.group(1).split("→")]

        def stage_of(word):
            found = [i for i, stage in enumerate(stages) if word in stage]
            self.assertEqual(len(found), 1, word)
            return found[0]

        start = stage_of("正式开战")
        self.assertLess(stage_of("10救场"), start)
        self.assertGreater(stage_of("三波协同战斗"), start)
        self.assertIn("最终战预算内", stages[stage_of("三波协同战斗")])
        self.assertIn("救场后的三波协同战斗就是计时的最终战", section(3))
        for wrong in ("不计入最终战预算", "协同战斗全部完成", "开战前另计的协同"):
            with self.subTest(wrong=wrong):
                self.assertNotIn(wrong, body)

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
                     "结束指定战斗且存活后开放", "按天划分",
                     "第1日、第2日、第3日（至最终胜利前）、最终胜利后",
                     "玩家已完成事件永久保存", "不要求制作多张完整地图"):
            self.assertIn(rule, content)
        # A-009 (2026-10-19): per-day states replace the three Day3-centred nodes.
        for stale in ("Before Day3", "Day3 Event", "After Day3"):
            self.assertNotIn(stale, content)
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
                     "区分首次加入事件与每波增援行为", "不另设自动回能或周期发放",
                     "不把“死亡不额外推进时间”解释为免费重置15分钟",
                     "不将早期Node示例里的食物任务混入最终配置"):
            self.assertIn(term, content)
        self.assertIn("空白显示未填写，不等同于否、无或已完成", content)


if __name__ == "__main__":
    unittest.main()
