extends Control

var deck_viewer_ref: Node = null
var columns: int = 4
var h_separation: float = 15.0
var v_separation: float = 15.0

# Insert indicator state
var insert_indicator_index: int = -1  # ตำแหน่งที่จะแทรก (-1 = ไม่แสดง)

func update_layout(animate: bool = true, skip_index: int = -1):
	var children = get_children()
	var num_children = children.size()
	
	var max_height = 0.0
	var row = 0
	var col = 0
	
	for i in range(num_children):
		var child = children[i]
		if not child is Control or child.is_queued_for_deletion():
			continue
		
		if i == skip_index:
			child.visible = false
			continue
		else:
			child.visible = true
		
		var card_size = child.custom_minimum_size
		if card_size == Vector2.ZERO:
			card_size = child.size
			
		var target_x = col * (card_size.x + h_separation)
		var target_y = row * (card_size.y + v_separation)
		var target_pos = Vector2(target_x, target_y)
		
		if animate:
			var prev_tween = child.get_meta("layout_tween", null)
			if prev_tween and prev_tween.is_valid():
				prev_tween.kill()
			
			var tween = get_tree().create_tween()
			child.set_meta("layout_tween", tween)
			tween.tween_property(child, "position", target_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			child.position = target_pos
		
		col += 1
		if col >= columns:
			col = 0
			row += 1
			
		var end_y = target_y + card_size.y
		if end_y > max_height:
			max_height = end_y
			
	custom_minimum_size.y = max_height

func set_insert_indicator(index: int):
	if insert_indicator_index != index:
		insert_indicator_index = index
		queue_redraw()
		if index != -1:
			Global.play_sfx("res://SFX/Draw sfx.ogg", -12.0, 2.0)

func _draw():
	if insert_indicator_index < 0: return
	
	var children = get_children()
	var visible_children = []
	for c in children:
		if c is Control and c.visible and not c.is_queued_for_deletion():
			visible_children.append(c)
	
	if visible_children.is_empty(): return
	
	# หาตำแหน่ง x ของเส้นตัวชี้
	var line_x: float = 0.0
	var line_y_top: float = 0.0
	var line_y_bottom: float = 0.0
	
	# คำนวณตำแหน่งจาก grid layout
	var card_size = visible_children[0].custom_minimum_size
	if card_size == Vector2.ZERO:
		card_size = visible_children[0].size
	
	var col = insert_indicator_index % columns
	var row_idx = insert_indicator_index / columns
	
	if col == 0 and insert_indicator_index > 0:
		# แทรกหลังช่องสุดท้ายของแถวก่อน → ขึ้นหัวแถวใหม่
		line_x = 0
	else:
		line_x = col * (card_size.x + h_separation) - h_separation / 2.0
	
	line_y_top = row_idx * (card_size.y + v_separation)
	line_y_bottom = line_y_top + card_size.y
	
	# ถ้า index เกินจำนวน children → วาดหลังใบสุดท้าย
	if insert_indicator_index >= visible_children.size():
		var last = visible_children[visible_children.size() - 1]
		var last_col = (visible_children.size() - 1) % columns
		var last_row = (visible_children.size() - 1) / columns
		line_x = (last_col + 1) * (card_size.x + h_separation) - h_separation / 2.0
		line_y_top = last_row * (card_size.y + v_separation)
		line_y_bottom = line_y_top + card_size.y
	
	# วาดเส้นตั้งสีทอง
	var color = Color(1.0, 0.85, 0.2, 1.0)
	draw_line(Vector2(line_x, line_y_top + 4), Vector2(line_x, line_y_bottom - 4), color, 3.0)
	
	# วาดสามเหลี่ยมชี้ลง ▼ ด้านบน
	var tri_size = 10.0
	var tri_points = PackedVector2Array([
		Vector2(line_x - tri_size, line_y_top - 2),
		Vector2(line_x + tri_size, line_y_top - 2),
		Vector2(line_x, line_y_top + tri_size)
	])
	draw_colored_polygon(tri_points, color)
