extends Node

var checks = 0
var failures = 0

func check(label: String, passed: bool):
	checks += 1
	if not passed:
		failures += 1
		push_error("HAND_ORIENTATION: " + label)

func _ready():
	call_deferred("run")

func run():
	Global.reset_online_session()
	Global.loaded_field_data = {}
	Global.loaded_field_path = ""
	Global.play_mode = true
	for scene_path in ["res://SCENE/Main.tscn", "res://scenes/FieldCreator.tscn"]:
		var table = load(scene_path).instantiate()
		add_child(table)
		await get_tree().process_frame
		for role in ["Host", "Guest"]:
			Global.online_player_role = role
			table.field_canvas.rotation_degrees = 180.0 if role == "Guest" else 0.0
			for angle in [0.0, 90.0, 180.0, 270.0]:
				var card = table.spawn_card_object({"name": "Orientation fixture"})
				card.rotation_degrees = angle
				table._add_card_to_hand(card)
				check(role + " immediate hand", is_zero_approx(card.rotation))
				await get_tree().create_timer(0.3).timeout
				check(role + " screen orientation", is_zero_approx(card.get_global_transform().get_rotation()))
				card.queue_free()
				await get_tree().process_frame
			var tapped = table.spawn_card_object({"name": "Active tap"})
			table._toggle_card_tap(tapped, false)
			table._add_card_to_hand(tapped)
			await get_tree().create_timer(0.3).timeout
			check(role + " tap tween cancelled", is_zero_approx(tapped.rotation))
			tapped.queue_free()
			await get_tree().process_frame
			var direct = table.spawn_card_object({"name": "Viewer insertion"}, false)
			direct.rotation_degrees = 180
			table.hand_zone.add_child(direct)
			table._hand_collapsed = true
			table._update_hand_zone_sizing()
			check(role + " collapsed viewer insertion", is_zero_approx(direct.rotation))
			table._hand_collapsed = false
			direct.queue_free()
			await get_tree().process_frame
		table.queue_free()
		await get_tree().process_frame
	Global.reset_online_session()
	print("HAND_ORIENTATION_RESULT ", checks - failures, "/", checks)
	get_tree().quit(1 if failures else 0)
