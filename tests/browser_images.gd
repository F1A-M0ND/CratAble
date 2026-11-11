extends Node
var count = 0
var failures = 0
func check(label: String, condition: bool):
	count += 1
	if not condition:
		failures += 1
		push_error(label)

func _ready():
	var image = Image.create(32, 48, false, Image.FORMAT_RGB8)
	image.fill(Color.ORANGE)
	var formats = {"png": image.save_png_to_buffer(), "jpg": image.save_jpg_to_buffer(), "webp": image.save_webp_to_buffer()}
	for extension in formats:
		var result = BrowserFiles.import_image("ภาพ ทดสอบ." + extension, formats[extension])
		check(extension + " accepted", result.error == "" and FileAccess.file_exists(result.path))
		var restored = Image.load_from_file(result.path)
		check(extension + " reloads dimensions", restored != null and restored.get_size() == Vector2i(32, 48))
		check(extension + " bounded path", result.path.begins_with("user://imported_images/") and result.path.ends_with(".png"))
		DirAccess.remove_absolute(result.path)
	check("empty rejected", BrowserFiles.import_image("x.png", PackedByteArray()).error != "")
	check("unsupported format rejected", BrowserFiles.import_image("x.svg", "<svg/>".to_utf8_buffer()).error != "")
	var large = PackedByteArray()
	large.resize(BrowserFiles.MAX_BYTES + 1)
	check("byte limit", BrowserFiles.import_image("x.png", large).error != "")
	var wide = Image.create(4097, 1, false, Image.FORMAT_RGB8)
	check("pixel limit", BrowserFiles.import_image("x.png", wide.save_png_to_buffer()).error != "")
	var editor = load("res://scenes/CardEditor.tscn").instantiate()
	add_child(editor)
	await get_tree().process_frame
	check("desktop editor loads", editor.file_dialog != null and not OS.has_feature("web"))
	print("BROWSER_IMAGES_RESULT ", count - failures, "/", count)
	get_tree().quit(0 if failures == 0 else 1)
