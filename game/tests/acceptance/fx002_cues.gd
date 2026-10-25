extends "res://tests/acceptance/fx001_effects.gd"
## FX-002 adapter: the remaining effects in real fights. Slot 1 is the second
## Room of the first day (colourless enemies), slot 2 the trench passage with
## 10 already rescued (Tian and single-colour cues, new-wave arrivals, the
## last wave's allied reinforcements), slot 3 the parasite Boss checkpoint
## (heavy Boss cue and the Boss burst).
func configuration() -> Dictionary:
	return {"id":"FX-002", "marker":"FX002_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:entry(), 2:passage(true), 3:parasite()}, "enter":false,
		"instructions":"FX-002 其余视觉特效 · 独立临时存档（关闭窗口自动清理）\n槽1 第1日第二间：无色实体出招前的珍珠白提示\n槽2 中心战场前（已救10）：进入战场，看天人重击与单色强力攻击的朱红重击提示、普通攻击的珍珠白提示；清一波后新波次敌人的朱红入场、末波友军的青色入场\n槽3 寄生同伴者检查点：Boss 出招前的大号朱红提示，击败时的 Boss 爆散\n看：强弱提示能否一眼分清、提示与提示音同时出现、出招或被打断后提示立即消失；Boss 击败比普通击倒更有分量；暂停时提示停住"}

func self_test() -> void:
	for slot: int in [1, 3]:
		check(session.start_slot(slot, false), "acceptance slot %d loads" % slot)
		await frames(8)
		session = get_tree().current_scene as CheckpointLab
		var director: CombatEffectDirector = session.player.get_node_or_null("EffectDirector") as CombatEffectDirector
		check(director != null and director.has_method("cue_for"), "slot %d player carries the FX-002 cues" % slot)
		await capture("slot%d" % slot)
