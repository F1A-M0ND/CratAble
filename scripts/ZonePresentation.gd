extends RefCounted

static func apply(zone: Control, playing: bool, choose_empty_deck: bool = false):
	var label = zone.get_node_or_null("VBoxContainer/Label")
	if not label: return
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.custom_minimum_size.y = 60
	var settings = zone.get_meta("zone_settings", {})
	var deck = zone.get_meta("zone_type", "Card Zone") == "Deck Zone"
	var name = "เด็ค" if deck else "การ์ด"
	var text = ("เลือก" if settings.get("purpose", 0) == 1 else "พื้นที่วาง") + name
	if playing:
		if deck and choose_empty_deck and settings.get("purpose", 0) == 0:
			label.text = "เลือกเด็ค"
			zone.tooltip_text = "คลิกเพื่อเลือกเด็ค หรือลากเด็คมาวาง"
		else:
			label.text = text
			zone.tooltip_text = "คลิกเพื่อเลือก" + name if settings.get("purpose", 0) == 1 else "ลาก" + name + "มาวางในพื้นที่นี้"
	else:
		label.text = text + "\nคลิกขวาเพื่อตั้งค่า"
		zone.tooltip_text = "Shift+คลิก เลือกเพิ่ม · Ctrl+C / Ctrl+V คัดลอกและวาง"
