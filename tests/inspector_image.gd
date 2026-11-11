extends Node

var checks = 0
var failures = 0

func check(label: String, passed: bool):
	checks += 1
	if not passed:
		failures += 1
		push_error("INSPECTOR_IMAGE: " + label)

func _ready(): call_deferred("run")

func run():
	var inspector = get_node("/root/CardInspector")
	var first = load("res://card_images/Blade_Fairy_img.PNG")
	var second = load("res://card_images/Gunner_Fairy_img.PNG")
	var cached_url = "https://example.invalid/cached.png"
	SupabaseService.texture_cache[cached_url] = first
	inspector.show_card({"name": "Cached image", "image_url": cached_url})
	check("cached image appears immediately", inspector.card_image.texture == first)
	inspector.show_fullscreen()
	check("fullscreen uses image", inspector.zoom_image.texture == first)
	inspector.hide_card()
	inspector.show_card("res://cards/Gunner_Fairy.json")
	check("local imported resource", inspector.card_image.texture == second)
	check("fullscreen reset on reopen", not inspector.fullscreen_viewer.visible)
	inspector.hide_card()
	SupabaseService.card_cache["qa-inspect"] = {"name": "Cached row", "image_url": cached_url, "stats": {"atk": 4}}
	inspector.show_card("qa-inspect")
	check("cached database row", inspector.card_image.texture == first)
	inspector.hide_card()
	# Queue a texture response without making any network request.
	var slow_url = "https://example.invalid/delayed.png"
	SupabaseService.pending_requests[slow_url] = []
	inspector.show_card({"name": "Slow image", "image_url": slow_url})
	var callback = SupabaseService.pending_requests[slow_url][0].callback
	callback.call(first)
	check("async image while open", inspector.card_image.texture == first)
	inspector.hide_card()
	inspector.show_card("res://cards/Gunner_Fairy.json")
	callback.call(first)
	check("previous image cannot overwrite new card", inspector.card_image.texture == second)
	inspector.hide_card()
	callback.call(first)
	check("closed inspector ignores old callback", inspector.card_image.texture == second)
	SupabaseService.pending_requests.erase(slow_url)
	SupabaseService.texture_cache.erase(cached_url)
	SupabaseService.card_cache.erase("qa-inspect")
	await get_tree().create_timer(0.4).timeout
	print("INSPECTOR_IMAGE_RESULT ", checks - failures, "/", checks)
	get_tree().quit(1 if failures else 0)
