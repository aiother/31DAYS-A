extends "res://tests/acceptance/ui004_title.gd"
## UI-006 adapter: the formal settings page from the title and from the pause
## menu, on the UI-004 slots. Test runs use a throwaway settings file; pass
## --settings-file=<path> (read by SettingsService) to keep one across runs and
## check that changes were saved.
func configuration() -> Dictionary:
	var config: Dictionary = super.configuration()
	config["id"] = "UI-006"
	config["marker"] = "UI006_ACCEPTANCE_TESTS"
	config["instructions"] = "UI-006 独立临时存档（关闭窗口自动清理）\n主界面 → 设置：逐项调整，Esc / Back / 返回 回到主界面\n继续游戏 → 槽1 → Esc 暂停 → 设置：同一个设置页，返回回到暂停\n方向键 / 十字键移动，左右调整，Enter / A 切换，鼠标可拖滑条\n按键列表：移到列表上用上下或滚轮滚动\n恢复默认需确认（默认焦点在返回）\n设置文件：" + str(get_node("/root/GameSettings").get("file_path"))
	return config

## SettingsService reads --settings-file itself; the harness only needs to
## let it through.
func parse_options(arguments: PackedStringArray) -> Dictionary:
	var rest: PackedStringArray = []
	for argument: String in arguments:
		if not argument.begins_with("--settings-file="):
			rest.append(argument)
	return super.parse_options(rest)

func self_test() -> void:
	var settings: Node = get_node("/root/GameSettings")
	var title: TitleScreen = session.ui.get("_title") as TitleScreen
	await click(title.button("设置"))
	var menu: PauseMenu = session.ui.get("_pause") as PauseMenu
	check(menu.visible and menu.standalone and menu.settings_page.visible, "acceptance title opens the settings page")
	await capture("settings-title")
	(menu.settings_page.rows["sfx_volume"] as SettingRow).commit(70.0)
	check(settings.call("get_values")["sfx_volume"] == 70.0, "acceptance change goes through the service")
	await click(menu.settings_page.back_button)
	check(title.visible and not menu.visible, "acceptance returns to the title")
	await click(title.button("继续游戏"))
	await click((session.ui.get("_slots") as SlotSelect).cards[0])
	await frames(3)
	check(session.has_session(), "acceptance slot 1 entered")
	session.ui.call("show_pause")
	await frames(2)
	await click(menu.button("设置"))
	check(menu.settings_page.visible and not menu.standalone and menu.settings_page.drawn["rows"]["sfx_volume"]["text"] == "70", "acceptance pause opens the same page with the saved value")
	await capture("settings-pause")
	settings.call("restore_defaults")
	await click(menu.settings_page.back_button)
	session.ui.call("resume_game")
