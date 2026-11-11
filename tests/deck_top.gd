extends Node

const Preview = preload("res://scripts/DeckTopPreview.gd")
const A = "res://cards/Blade_Fairy.json"
const B = "res://cards/Gunner_Fairy.json"
var checks = 0
var failures = 0

class DelayedImages extends Node:
	var callback: Callable
	func get_texture_or_load(_path, cb, _owner): callback = cb

func check(label: String, passed: bool):
	checks += 1
	if not passed:
		failures += 1
		push_error("DECK_TOP: " + label)

func shows(deck: Control, path: String) -> bool:
	var cover = deck.get_node("DeckCover")
	if cover.get_meta("top_card", "") != path: return false
	if path == "": return cover.texture == null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return cover.texture == load(data.image_path)

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
		var deck = table.spawn_deck_object({"deck_name": "Fixture", "groups": [{"cards": {A: 1, B: 1}}]})
		check("unconfirmed top", shows(deck, B))
		table._confirm_deck_programmatically(deck, false)
		check("confirmed top", shows(deck, B))
		table._on_deck_left_clicked(deck, false)
		check("draw reveals next", shows(deck, A))
		var card = table.spawn_card_object({"file_path": B})
		table._insert_card_into_deck(card, deck, true, false)
		check("return to top", shows(deck, B))
		var bottom = table.spawn_card_object({"file_path": A})
		table._insert_card_into_deck(bottom, deck, false, false)
		check("return to bottom keeps top", shows(deck, B))
		table._shuffle_deck_programmatically(deck, false)
		check("shuffle actual top", shows(deck, str(deck.get_meta("draw_pile").back())))
		deck.set_meta("draw_pile", [])
		table._update_deck_count_label(deck)
		check("empty clears image", shows(deck, ""))
		check("empty overlay", deck.get_node("DeckOutOverlay").visible)
		var cover = deck.get_node("DeckCover")
		cover.set_meta("preview_revision", 100)
		var delayed = DelayedImages.new()
		add_child(delayed)
		Preview._show_data(cover, 100, {"image_path": "https://example.invalid/old.png"}, delayed)
		deck.set_meta("draw_pile", [A])
		table._update_deck_count_label(deck)
		delayed.callback.call(load("res://card_images/Gunner_Fairy_img.PNG"))
		check("stale download ignored", shows(deck, A))
		delayed.queue_free()
		table.deck_viewer_target = deck
		table.deck_viewer_cards = [B, A]
		table._on_deck_viewer_confirmed()
		check("viewer reorder", shows(deck, A))
		if scene == "res://SCENE/Main.tscn":
			table._on_remote_deck_shuffled(str(deck.name), [A, B])
			check("remote shuffle", shows(deck, B))
			table._on_remote_deck_drawn(str(deck.name))
			check("remote draw", shows(deck, A))
		await get_tree().create_timer(0.4).timeout
		table.queue_free()
		await get_tree().process_frame
	# Stop fixture sound effects before tearing down the headless audio server.
	for child in Global.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			child.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("DECK_TOP_RESULT ", checks - failures, "/", checks)
	get_tree().quit(1 if failures else 0)
