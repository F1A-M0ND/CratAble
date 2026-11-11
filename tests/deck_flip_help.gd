extends Node

const A = "res://cards/Blade_Fairy.json"
const B = "res://cards/Gunner_Fairy.json"
var checks = 0
var failures = 0

func check(label: String, passed: bool):
	checks += 1
	if not passed:
		failures += 1
		push_error("FLIP_HELP: " + label)

func _ready(): call_deferred("run")

func run():
	Global.reset_online_session()
	Global.play_mode = true
	Global.loaded_field_data = {}
	Global.loaded_field_path = ""
	for scene in ["res://SCENE/Main.tscn", "res://scenes/FieldCreator.tscn"]:
		var table = load(scene).instantiate()
		add_child(table)
		await get_tree().process_frame
		var deck = table.spawn_deck_object({"groups": [{"cards": {A: 1, B: 1}}]})
		table._confirm_deck_programmatically(deck, false)
		table._on_deck_right_clicked(deck)
		check("right click menu", table.tabletop_popup_menu.get_item_index(24) >= 0)
		table._on_tabletop_popup_menu_id_pressed(24)
		check("physical flip reverses order", deck.get_meta("draw_pile") == [B, A])
		check("back visible", deck.get_node("DeckBack").visible and deck.get_node("DeckCover").texture == null)
		if scene == "res://SCENE/Main.tscn":
			var id = str(deck.get_meta("component_id"))
			var state = table._capture_current_field_state()
			table._load_field_from_dict(state, true)
			deck = table._find_component(id)
			check("snapshot keeps face and order", deck.get_meta("deck_data").get("pile_face_down", false) and deck.get_meta("draw_pile") == [B, A] and deck.get_node("DeckBack").visible)
		table._flip_deck_programmatically(deck, false)
		check("double flip restores order", deck.get_meta("draw_pile") == [A, B])
		check("top image restored", not deck.get_node("DeckBack").visible and deck.get_node("DeckCover").texture == load("res://card_images/Gunner_Fairy_img.PNG"))
		table._on_remote_deck_flipped(str(deck.name), [B, A], true)
		table._on_remote_deck_flipped(str(deck.name), [B, A], true)
		check("remote duplicate is idempotent", deck.get_meta("draw_pile") == [B, A] and deck.get_node("DeckBack").visible)
		await get_tree().create_timer(0.3).timeout
		table.queue_free()
		await get_tree().process_frame
	Global.main_menu_tab = "HOME"
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	check("help before credit", menu.help_btn.get_index() + 1 == menu.credit_btn.get_index())
	menu.help_btn.pressed.emit()
	await get_tree().process_frame
	check("help page opens", menu.current_page.scene_file_path == "res://scenes/HelpPage.tscn" and Global.main_menu_tab == "HELP")
	menu.credit_btn.pressed.emit()
	menu.help_btn.pressed.emit()
	await get_tree().process_frame
	check("help navigation", menu.current_page.get_child_count() == 1 and Global.main_menu_tab == "HELP")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("output="):
			await get_tree().create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("output="))
	menu.queue_free()
	for child in Global.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			child.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("FLIP_HELP_RESULT ", checks - failures, "/", checks)
	get_tree().quit(1 if failures else 0)
