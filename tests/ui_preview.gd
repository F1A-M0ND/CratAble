extends Node
func _ready():
	call_deferred("run")
func run():
	Global.reset_online_session()
	Global.play_mode = true
	Global.loaded_field_path = ""
	Global.loaded_field_data = {}
	var table = load("res://SCENE/Main.tscn").instantiate()
	add_child(table)
	await get_tree().create_timer(0.5).timeout
	table.field_canvas.size = Vector2(1500, 950)
	table.field_canvas.position = Vector2(300, 40)
	table.field_canvas.scale = Vector2(0.7, 0.7)
	var zone = table._spawn_zone("Card Zone", false)
	zone.position = Vector2(200, 170)
	var zone2 = table._spawn_zone("Card Zone", false)
	zone2.position = Vector2(450, 170)
	var dice = table._on_add_dice_pressed(false)
	dice.position = Vector2(1080, 180)
	var count = table._on_add_counter_pressed(false)
	count.position = Vector2(1050, 300)
	count.set_value(20, false)
	for i in range(3):
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://cards/Blade_Fairy.json"))
		var card = table.spawn_card_object(data)
		card.position = Vector2(250 + i * 200, 500)
		print("CARD_GEOMETRY ", card.size, " ", card.scale, " ", card.expand_mode)
		var hand = table.spawn_card_object(data)
		table._add_card_to_hand(hand)
	table._set_components_locked(table.field_canvas, true)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	for c in table.field_canvas.get_children():
		if c.get_meta("component_category", "") == "card": print("AFTER_GEOMETRY ", c.size, " ", c.scale, " ", c.expand_mode)
	var output = "user://ui_preview.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("output="): output = arg.trim_prefix("output=")
	var image = get_viewport().get_texture().get_image()
	image.save_png(output)
	print("UI_PREVIEW_SAVED")
	get_tree().quit()
