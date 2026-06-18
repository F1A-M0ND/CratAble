extends Node

const SUPABASE_URL = "https://oprwntnvhqxuhztuakdx.supabase.co"
const SUPABASE_KEY = "sb_publishable_tF_5v38zwfSWh3S0Dh1Nwg_KRgzF-ay"

# Texture downloading and cache
var texture_cache = {}
var pending_requests = {}
var card_cache = {}

signal texture_loaded(url: String, texture: Texture2D)

func _get_auth_headers(is_json: bool = true) -> PackedStringArray:
	var headers = PackedStringArray([
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY
	])
	if is_json:
		headers.append("Content-Type: application/json")
	return headers

# Generic request function
func request_supabase(path: String, method: HTTPClient.Method, body_data = null, headers_modifier: Callable = Callable(), callback: Callable = Callable()):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = SUPABASE_URL + path
	var is_json = true
	
	var headers = _get_auth_headers(is_json)
	if headers_modifier.is_valid():
		headers = headers_modifier.call(headers)
		
	var request_body = ""
	var is_raw = false
	var raw_data = PackedByteArray()
	
	if body_data != null:
		if typeof(body_data) == TYPE_PACKED_BYTE_ARRAY:
			is_raw = true
			raw_data = body_data
		elif typeof(body_data) == TYPE_STRING:
			request_body = body_data
		else:
			request_body = JSON.stringify(body_data)
			
	http_request.request_completed.connect(func(result, response_code, response_headers, response_body):
		var response_str = response_body.get_string_from_utf8()
		var json = JSON.new()
		var parsed_data = null
		if response_str != "" and json.parse(response_str) == OK:
			parsed_data = json.get_data()
		else:
			parsed_data = response_str
			
		if callback.is_valid():
			callback.call(response_code, parsed_data)
		http_request.queue_free()
	)
	
	var err = OK
	if is_raw:
		err = http_request.request_raw(url, headers, method, raw_data)
	else:
		err = http_request.request(url, headers, method, request_body)
		
	if err != OK:
		print("HTTPRequest error: ", err)
		if callback.is_valid():
			callback.call(0, null)
		http_request.queue_free()

# Texture Downloader with Cache
func get_texture_or_load(url: String, callback: Callable) -> Texture2D:
	if url == "":
		callback.call(null)
		return null
		
	if texture_cache.has(url):
		callback.call(texture_cache[url])
		return texture_cache[url]
	
	if pending_requests.has(url):
		pending_requests[url].append(callback)
		return null
		
	pending_requests[url] = [callback]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(func(result, response_code, headers, body):
		var texture = null
		if response_code == 200:
			var img = Image.new()
			var err = OK
			var ext = url.get_extension().to_lower()
			if ext == "png":
				err = img.load_png_from_buffer(body)
			elif ext == "jpg" or ext == "jpeg":
				err = img.load_jpg_from_buffer(body)
			elif ext == "webp":
				err = img.load_webp_from_buffer(body)
			else:
				# Fallback chain
				err = img.load_png_from_buffer(body)
				if err != OK:
					err = img.load_jpg_from_buffer(body)
				if err != OK:
					err = img.load_webp_from_buffer(body)
					
			if err == OK:
				texture = ImageTexture.create_from_image(img)
				texture_cache[url] = texture
				texture_loaded.emit(url, texture)
			else:
				print("Failed to parse downloaded image bytes from URL: ", url)
		else:
			print("Failed to download image: ", url, " status: ", response_code)
		
		var list = pending_requests.get(url, [])
		pending_requests.erase(url)
		for cb in list:
			if cb.is_valid():
				cb.call(texture)
				
		http_request.queue_free()
	)
	
	var err = http_request.request(url)
	if err != OK:
		print("HTTPRequest error loading URL: ", url, " error: ", err)
		var list = pending_requests.get(url, [])
		pending_requests.erase(url)
		for cb in list:
			if cb.is_valid():
				cb.call(null)
		http_request.queue_free()
	
	return null

# Storage Upload
func upload_card_image(file_name: String, file_data: PackedByteArray, callback: Callable):
	var ext = file_name.get_extension().to_lower()
	var mime_type = "image/png"
	if ext == "jpg" or ext == "jpeg":
		mime_type = "image/jpeg"
	elif ext == "webp":
		mime_type = "image/webp"
		
	# Clean and generate a unique file name to avoid overwrite conflicts
	var clean_name = file_name.get_file().replace(" ", "_")
	var unique_name = str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(randi() % 100000) + "_" + clean_name
	
	var path = "/storage/v1/object/card-images/" + unique_name.uri_encode()
	
	var modifier = func(headers: PackedStringArray) -> PackedStringArray:
		var new_headers = PackedStringArray()
		for h in headers:
			if not h.begins_with("Content-Type:"):
				new_headers.append(h)
		new_headers.append("Content-Type: " + mime_type)
		return new_headers
		
	request_supabase(path, HTTPClient.METHOD_POST, file_data, modifier, func(status, data):
		if status == 200 or status == 201:
			var public_url = SUPABASE_URL + "/storage/v1/object/public/card-images/" + unique_name.uri_encode()
			callback.call(true, public_url)
		else:
			print("Upload image failed, status=", status, " data=", data)
			callback.call(false, "")
	)

# --- CARDS CRUD ---
func insert_card(card_name: String, image_url: String, card_type: String, stats: Dictionary, callback: Callable):
	var body = {
		"name": card_name,
		"image_url": image_url,
		"card_type": card_type,
		"stats": stats
	}
	var modifier = func(headers: PackedStringArray) -> PackedStringArray:
		headers.append("Prefer: return=representation")
		return headers
	request_supabase("/rest/v1/cards", HTTPClient.METHOD_POST, body, modifier, func(status, data):
		if status == 200 or status == 201:
			if typeof(data) == TYPE_ARRAY and data.size() > 0:
				var row = data[0]
				if typeof(row) == TYPE_DICTIONARY and row.has("id"):
					card_cache[row["id"]] = row
			elif typeof(data) == TYPE_DICTIONARY and data.has("id"):
				card_cache[data["id"]] = data
		if callback.is_valid():
			callback.call(status, data)
	)

func update_card(uuid: String, card_name: String, image_url: String, card_type: String, stats: Dictionary, callback: Callable):
	var body = {
		"name": card_name,
		"image_url": image_url,
		"card_type": card_type,
		"stats": stats
	}
	var modifier = func(headers: PackedStringArray) -> PackedStringArray:
		headers.append("Prefer: return=representation")
		return headers
	request_supabase("/rest/v1/cards?id=eq." + uuid.uri_encode(), HTTPClient.METHOD_PATCH, body, modifier, func(status, data):
		if status == 200 or status == 201:
			if typeof(data) == TYPE_ARRAY and data.size() > 0:
				var row = data[0]
				if typeof(row) == TYPE_DICTIONARY and row.has("id"):
					card_cache[row["id"]] = row
			elif typeof(data) == TYPE_DICTIONARY and data.has("id"):
				card_cache[data["id"]] = data
		if callback.is_valid():
			callback.call(status, data)
	)

func fetch_all_cards(callback: Callable):
	request_supabase("/rest/v1/cards?select=*", HTTPClient.METHOD_GET, null, Callable(), func(status, data):
		if status == 200 and typeof(data) == TYPE_ARRAY:
			for row in data:
				if typeof(row) == TYPE_DICTIONARY and row.has("id"):
					card_cache[row["id"]] = row
		if callback.is_valid():
			callback.call(status, data)
	)

func delete_card(uuid: String, callback: Callable):
	request_supabase("/rest/v1/cards?id=eq." + uuid.uri_encode(), HTTPClient.METHOD_DELETE, null, Callable(), func(status, data):
		if status == 200 or status == 204:
			card_cache.erase(uuid)
		if callback.is_valid():
			callback.call(status, data)
	)

# --- DECKS CRUD ---
func insert_deck(deck_name: String, cards_data: Dictionary, callback: Callable):
	var body = {
		"name": deck_name,
		"cards_data": cards_data
	}
	var modifier = func(headers: PackedStringArray) -> PackedStringArray:
		headers.append("Prefer: return=representation")
		return headers
	request_supabase("/rest/v1/decks", HTTPClient.METHOD_POST, body, modifier, callback)

func update_deck(uuid: String, deck_name: String, cards_data: Dictionary, callback: Callable):
	var body = {
		"name": deck_name,
		"cards_data": cards_data
	}
	request_supabase("/rest/v1/decks?id=eq." + uuid.uri_encode(), HTTPClient.METHOD_PATCH, body, Callable(), callback)

func fetch_all_decks(callback: Callable):
	request_supabase("/rest/v1/decks?select=*", HTTPClient.METHOD_GET, null, Callable(), callback)

func delete_deck(uuid: String, callback: Callable):
	request_supabase("/rest/v1/decks?id=eq." + uuid.uri_encode(), HTTPClient.METHOD_DELETE, null, Callable(), callback)

# --- FIELDS CRUD ---
func insert_field(field_name: String, canvas_settings: Dictionary, components_layout: Array, callback: Callable):
	var body = {
		"name": field_name,
		"canvas_settings": canvas_settings,
		"components_layout": components_layout
	}
	var modifier = func(headers: PackedStringArray) -> PackedStringArray:
		headers.append("Prefer: return=representation")
		return headers
	request_supabase("/rest/v1/fields", HTTPClient.METHOD_POST, body, modifier, callback)

func update_field(uuid: String, field_name: String, canvas_settings: Dictionary, components_layout: Array, callback: Callable):
	var body = {
		"name": field_name,
		"canvas_settings": canvas_settings,
		"components_layout": components_layout
	}
	request_supabase("/rest/v1/fields?id=eq." + uuid.uri_encode(), HTTPClient.METHOD_PATCH, body, Callable(), callback)

func fetch_all_fields(callback: Callable):
	request_supabase("/rest/v1/fields?select=*", HTTPClient.METHOD_GET, null, Callable(), callback)

func delete_field(uuid: String, callback: Callable):
	request_supabase("/rest/v1/fields?id=eq." + uuid.uri_encode(), HTTPClient.METHOD_DELETE, null, Callable(), callback)
