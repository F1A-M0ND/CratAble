extends Control

@onready var progress_bar = $VBoxContainer/ProgressBar
@onready var status_label = $VBoxContainer/StatusLabel

var total_images_to_load = 0
var images_loaded = 0

func _ready():
	status_label.text = "Connecting to database..."
	progress_bar.value = 0
	
	# Delay slight to let UI render
	await get_tree().create_timer(0.5).timeout
	
	_start_loading()

func _start_loading():
	status_label.text = "Fetching metadata..."
	
	# ใช้ Dictionary เพราะ GDScript closure จับ local var แบบ copy
	# แต่ Dictionary ส่งผ่าน reference ทำให้ทุก lambda เห็นค่าเดียวกัน
	var done = {"cards": false, "decks": false, "fields": false}
	
	var check_all = func():
		if done["cards"] and done["decks"] and done["fields"]:
			_on_metadata_loaded()
	
	SupabaseService.fetch_all_cards(func(status, data):
		done["cards"] = true
		check_all.call()
	)
	
	SupabaseService.fetch_all_decks(func(status, data):
		done["decks"] = true
		check_all.call()
	)
	
	SupabaseService.fetch_all_fields(func(status, data):
		done["fields"] = true
		check_all.call()
	)

func _on_metadata_loaded():
	# Gather all unique image URLs from card_cache
	var urls_to_load = []
	for uuid in SupabaseService.card_cache:
		var row = SupabaseService.card_cache[uuid]
		var url = row.get("image_url", "")
		if url != "" and not urls_to_load.has(url):
			urls_to_load.append(url)
			
	total_images_to_load = urls_to_load.size()
	images_loaded = 0
	
	if total_images_to_load == 0:
		_finish_loading()
		return
		
	status_label.text = "Downloading assets (0/" + str(total_images_to_load) + ")"
	
	for url in urls_to_load:
		SupabaseService.get_texture_or_load(url, func(tex):
			images_loaded += 1
			_update_progress()
		, self)

func _update_progress():
	if total_images_to_load > 0:
		progress_bar.value = float(images_loaded) / float(total_images_to_load) * 100.0
	status_label.text = "Downloading assets (" + str(images_loaded) + "/" + str(total_images_to_load) + ")"
	
	if images_loaded >= total_images_to_load:
		_finish_loading()

func _finish_loading():
	status_label.text = "Ready!"
	progress_bar.value = 100
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		Global.switch_scene("res://scenes/MainMenu.tscn")
	)
