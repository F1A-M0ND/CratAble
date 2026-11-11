extends Control

# Small vector illustrations stay sharp and require no image downloads.
var motif: String = "cards"
var accent := Color("79cfff")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw():
	var c := size * 0.5
	var s := minf(size.x / 360.0, size.y / 176.0)
	draw_set_transform(c, 0.0, Vector2.ONE * s)
	for i in range(3):
		draw_arc(Vector2.ZERO, 62.0 + i * 24.0, 0.18, 5.9, 56, Color(accent, 0.08), 1.0, true)
	if motif == "online":
		draw_circle(Vector2.ZERO, 53, Color("283b7e"))
		draw_arc(Vector2.ZERO, 53, -2.8, 1.1, 48, accent, 2.0, true)
		draw_arc(Vector2.ZERO, 30, -PI, PI, 40, Color(accent, 0.36), 1.0, true)
		draw_line(Vector2(-52, 0), Vector2(52, 0), Color(accent, 0.36), 1.0, true)
		for p in [Vector2(-88, 28), Vector2(84, -30)]:
			draw_line(p, Vector2.ZERO, Color(accent, 0.55), 1.5, true)
			draw_circle(p, 9, accent)
			draw_circle(p, 4, Color("0d1128"))
	elif motif == "field" or motif == "local":
		var table := StyleBoxFlat.new()
		table.bg_color = Color("172444")
		table.border_color = accent
		table.set_border_width_all(2)
		table.set_corner_radius_all(12)
		draw_style_box(table, Rect2(-99, -56, 198, 112))
		for x in [-53, 17]:
			_card(Vector2(x, -34), Vector2(36, 48), Color("344893"), accent)
			_card(Vector2(x, 26), Vector2(36, 18), Color("172444"), Color(accent, 0.4))
		draw_circle(Vector2(77, 30), 8, accent)
	else:
		var count := 3 if motif == "deck" else 2
		for i in range(count):
			draw_set_transform(c + Vector2((i - 1) * 38, (1 - i) * 8) * s, deg_to_rad((i - 1) * 13), Vector2.ONE * s)
			_card(Vector2(-37, -55), Vector2(74, 110), Color("263768") if i < count - 1 else Color("4266b8"), accent)
			draw_circle(Vector2(0, -13), 19, Color("0e1839"))
			draw_arc(Vector2(0, -13), 21, -2.7, 0.4, 30, accent, 2, true)
			draw_line(Vector2(-20, 28), Vector2(20, 28), Color(accent, 0.7), 2, true)
			draw_line(Vector2(-14, 36), Vector2(14, 36), Color(accent, 0.35), 2, true)
	draw_set_transform(Vector2.ZERO)

func _card(pos: Vector2, extent: Vector2, fill: Color, edge: Color):
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(7)
	draw_style_box(box, Rect2(pos, extent))
