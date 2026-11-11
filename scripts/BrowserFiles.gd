extends Node
## Browser-owned picker; only selected files are copied into user://.
const MAX_BYTES = 12 * 1024 * 1024
const MAX_SIDE = 4096
var _js_callback
var _completion: Callable
var _owner: WeakRef

func pick_image(owner: Node, completion: Callable):
	if not OS.has_feature("web"):
		return
	_completion = completion
	_owner = weakref(owner)
	if _js_callback == null:
		_js_callback = JavaScriptBridge.create_callback(_on_file)
	JavaScriptBridge.eval(r"""
	window.cratablePickImage = function(callback) {
		if (window.cratableCancelPicker) window.cratableCancelPicker();
		const input = document.createElement('input');
		input.type = 'file'; input.accept = '.png,.jpg,.jpeg,.webp';
		input.style.display = 'none'; document.body.appendChild(input);
		let done = false;
		const finish = (name, bytes, error) => {
			if (done) return; done = true;
			input.remove(); window.cratableCancelPicker = null;
			callback(name, bytes, error);
		};
		window.cratableCancelPicker = () => finish('', null, '');
		input.oncancel = () => finish('', null, '');
		input.onchange = async () => {
			const file = input.files[0];
			if (!file) { finish('', null, ''); return; }
			if (!/\.(png|jpe?g|webp)$/i.test(file.name)) {
				finish('', null, 'Please choose PNG, JPG or WebP.'); return;
			}
			if (file.size > 12582912) {
				finish('', null, 'Image must be 12 MB or smaller.'); return;
			}
			try { finish(file.name, await file.arrayBuffer(), ''); }
			catch (_) { finish('', null, 'Unable to read this file. Please try again.'); }
		};
		input.click();
	};
	""", true)
	JavaScriptBridge.get_interface("window").cratablePickImage(_js_callback)

func _on_file(args: Array):
	if args.size() < 3 or _owner == null or _owner.get_ref() == null:
		return
	var result = {"path": "", "error": str(args[2])}
	if args[1] != null and result.error == "":
		result = import_image(str(args[0]), JavaScriptBridge.js_buffer_to_packed_byte_array(args[1]))
	if _completion.is_valid():
		_completion.call(result.path, result.error)

func import_image(filename: String, bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return {"path": "", "error": "Image must be between 1 byte and 12 MB."}
	var img = Image.new()
	var error = ERR_FILE_UNRECOGNIZED
	match filename.get_extension().to_lower():
		"png": error = img.load_png_from_buffer(bytes)
		"jpg", "jpeg": error = img.load_jpg_from_buffer(bytes)
		"webp": error = img.load_webp_from_buffer(bytes)
	if error != OK or img.is_empty():
		return {"path": "", "error": "This image is invalid. Use PNG, JPG or WebP."}
	if img.get_width() > MAX_SIDE or img.get_height() > MAX_SIDE:
		return {"path": "", "error": "Image dimensions must be 4096 pixels or smaller."}
	if DirAccess.make_dir_recursive_absolute("user://imported_images") != OK:
		return {"path": "", "error": "Unable to create browser image storage."}
	var hash_context = HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(bytes)
	var path = "user://imported_images/" + hash_context.finish().hex_encode() + ".png"
	if img.save_png(path) != OK:
		return {"path": "", "error": "Unable to save image. Browser storage may be full."}
	return {"path": path, "error": ""}

func show_error(owner: Node, message: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Image import"
	dialog.dialog_text = message
	owner.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
