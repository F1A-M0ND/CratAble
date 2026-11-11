extends Label

# Only the caption faces the reader. The piece and its hit area keep their saved angle.
func track():
	set_notify_transform(true)
	if not resized.is_connected(_align): resized.connect(_align)
	_align()

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():
		_align()

func _align():
	var parent := get_parent() as CanvasItem
	if not parent or not is_inside_tree(): return
	var basis := parent.get_global_transform_with_canvas()
	if is_zero_approx(basis.determinant()): return
	var angle := basis.affine_inverse().basis_xform(Vector2.RIGHT).angle()
	if pivot_offset != size / 2: pivot_offset = size / 2
	if not is_zero_approx(angle_difference(rotation, angle)): rotation = angle
