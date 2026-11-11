extends ScrollContainer

const SECTIONS = [
	["01 / เริ่มเล่น", "PLAY → LOCAL เล่นบนเครื่องนี้ หรือ ONLINE เพื่อสร้างห้องและเข้าห้อง\nเลือกสนามและเด็คก่อนเริ่ม หากห้องมีรหัสผ่านให้กรอกรหัสให้ตรงกัน ใช้ Exit Lobby เพื่อออกจากโต๊ะ\nCratAble เตรียมอุปกรณ์ให้ผู้เล่นตกลงกติกากันเอง"],
	["02 / สร้างอุปกรณ์ใน CUSTOM", "CARD EDITOR — ตั้งชื่อ ใส่รูป และข้อมูลการ์ด แล้วบันทึก\nDECK BUILDER — เลือกการ์ดและจำนวนแต่ละใบ แล้วบันทึกเด็ค\nFIELD CREATOR — วางพื้นที่การ์ด/เด็ค ลูกเต๋า ตัวนับ และบันทึกสนาม เปิดโหมดทดสอบเพื่อลองเล่น"],
	["03 / ควบคุมโต๊ะ", "ลากเมาส์ซ้ายเพื่อย้ายการ์ดหรืออุปกรณ์ที่อนุญาตให้ย้าย\nเลื่อนล้อเมาส์บนสนามเพื่อซูม หรือใช้ Ctrl + = / Ctrl + -\nกดล้อเมาส์ค้างแล้วลากเพื่อเลื่อนมุมมองสนาม\nลากจุดหมุนเพื่อหมุนวัตถุ กด Shift ค้างเพื่อหมุนทีละ 15°"],
	["04 / การ์ดและการ์ดในมือ", "คลิกขวาที่การ์ดเพื่อเปิดคำสั่ง Tap / Untap (เอียง 90°), Face Up / Face Down (หงาย/คว่ำ), Send to Hand (เข้ามือ), Send to Deck (Top / Bottom) (คืนบน/ใต้กอง)\nลากการ์ดจากมือไปวางบนสนาม การ์ดในมือจะหันอ่านได้ตามผู้ถือ\nกดแถบ Hand Zone เพื่อยุบหรือขยายพื้นที่มือ"],
	["05 / เด็คและการพลิกกอง", "เลือกเด็คที่ช่อง Deck Select แล้วเด็คจะพร้อมใช้ ช่องเลือกจะหายไป\nคลิกซ้ายที่เด็คเพื่อจั่ว 1 ใบเข้ามือ คลิกขวาเพื่อเปิดเมนู:\nDraw Card — จั่ว / Shuffle Deck — สับกอง\nLook at Top Cards — ดูการ์ดด้านบนตามจำนวน / View All Cards in Deck — ดูและจัดลำดับทั้งกอง\nFlip Deck Face Down / Face Up — พลิกทั้งกอง: กลับหงาย–คว่ำพร้อมสลับลำดับบน–ล่างเหมือนพลิกกองจริง\nกองหงายแสดงการ์ดใบบนสุด กองคว่ำแสดงหลังการ์ด กองว่างแสดง Deck Out"],
	["06 / ลูกเต๋า ตัวนับ และพื้นที่วาง", "คลิกลูกเต๋าเพื่อสุ่มค่า D6 (1–6)\nตัวนับแนวนอน: คลิกครึ่งขวาเพื่อเพิ่ม ครึ่งซ้ายเพื่อลด แนวตั้ง: ด้านบนเพิ่ม ด้านล่างลด\nกดตัวนับค้างเพื่อกำหนดค่าโดยตรง หรือคลิกขวาค้างเพื่อกลับค่าเริ่มต้น\nคลิกขวาที่พื้นที่วางการ์ดเพื่อดูหรือสับการ์ดในพื้นที่นั้น คำสั่งที่ใช้ได้ขึ้นกับชนิดพื้นที่และการตั้งค่าของสนาม"]
]

var lesson = 0
var topic_buttons: Array = []
var lesson_title: Label
var lesson_body: Label
var progress_label: Label
var feedback: Label
var practice: Control
var step_labels: Array[Label] = []

func label(text: String, font_size: int, color: Color = Color("f5f9ff")) -> Label:
	var item = Label.new()
	item.text = text
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	return item

func _ready():
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 64)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)
	content.add_child(label("HOW TO PLAY  /  คู่มือ CratAble", 17, Color("73ceff")))
	var heading = label("PLAY LAB", 64)
	heading.add_theme_font_override("font", preload("res://scripts/PlatformStyle.gd").display_font())
	content.add_child(heading)
	content.add_child(label("ลองเล่นให้คุ้นมือ แล้วสร้างเกมในแบบของคุณ", 26, Color("aabbd4")))
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	content.add_child(columns)
	var panel = _glass_panel(Color("101a2c"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_stretch_ratio = 0.95
	columns.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(label("เริ่มด้วย 3 การกระทำ", 30))
	progress_label = label("ลองให้ครบ  /  0 จาก 3", 20, Color("73ceff"))
	box.add_child(progress_label)
	var steps = HBoxContainer.new()
	steps.add_theme_constant_override("separation", 12)
	box.add_child(steps)
	for step in ["01  ลากไปวาง", "02  คลิกขวา → พลิก", "03  ทอยลูกเต๋า"]:
		var step_panel = _glass_panel(Color("192840"), 12, 12)
		step_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steps.add_child(step_panel)
		var caption = label(step, 18, Color("aabbd4"))
		step_panel.add_child(caption)
		step_labels.append(caption)
	practice = preload("res://scripts/TutorialPractice.gd").new()
	box.add_child(practice)
	feedback = label("ลากการ์ดไปวางในกรอบสีฟ้า แล้วลองคลิกขวาที่การ์ด", 21, Color("b9c9df"))
	feedback.custom_minimum_size.y = 68
	box.add_child(feedback)
	practice.progressed.connect(func(message):
		feedback.text = message
		var count = practice.completed.count(true)
		progress_label.text = "ลองให้ครบ  /  %d จาก 3%s" % [count, "  ✓ พร้อมเล่นแล้ว!" if count == 3 else ""]
		for i in range(step_labels.size()):
			step_labels[i].add_theme_color_override("font_color", Color("73ceff") if practice.completed[i] else Color("aabbd4"))
	)
	var reset = Button.new()
	reset.text = "เริ่มฝึกใหม่"
	reset.custom_minimum_size.y = 48
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(practice.reset_practice)
	box.add_child(reset)
	box.add_child(label("พื้นที่ทดลองนี้ไม่เปลี่ยนการ์ดหรือสนามที่บันทึกไว้", 17, Color("8195b3")))
	var guide = VBoxContainer.new()
	guide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide.size_flags_stretch_ratio = 1.05
	guide.add_theme_constant_override("separation", 18)
	columns.add_child(guide)
	guide.add_child(label("เลือกเรื่องที่อยากรู้", 30))
	var topics = HFlowContainer.new()
	topics.add_theme_constant_override("h_separation", 8)
	topics.add_theme_constant_override("v_separation", 8)
	guide.add_child(topics)
	for i in range(SECTIONS.size()):
		var button = Button.new()
		button.text = SECTIONS[i][0]
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 19)
		button.toggle_mode = true
		button.pressed.connect(func(): show_lesson(i))
		topics.add_child(button)
		topic_buttons.append(button)
	var lesson_panel = _glass_panel(Color("111729"))
	guide.add_child(lesson_panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	lesson_panel.add_child(column)
	lesson_title = label("", 26, Color("73ceff"))
	lesson_body = label("", 21)
	lesson_body.add_theme_constant_override("line_spacing", 8)
	column.add_child(lesson_title)
	column.add_child(lesson_body)
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	column.add_child(nav)
	for direction in [-1, 1]:
		var button = Button.new()
		button.text = "← หัวข้อก่อนหน้า" if direction < 0 else "หัวข้อถัดไป →"
		button.add_theme_font_size_override("font_size", 18)
		button.custom_minimum_size.y = 48
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): show_lesson(posmod(lesson + direction, SECTIONS.size())))
		nav.add_child(button)
	content.add_child(label("โต๊ะและอุปกรณ์จาก CratAble  /  กติกาจากคุณ", 18, Color("8195b3")))
	preload("res://scripts/PlatformStyle.gd")._style_controls(content)
	show_lesson(0)

func _glass_panel(color: Color, radius: int = 24, padding: int = 28) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = preload("res://scripts/PlatformStyle.gd").glass(color, radius)
	style.border_color = Color(0.45, 0.70, 1.0, 0.18)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, padding)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func show_lesson(index: int):
	lesson = index
	lesson_title.text = SECTIONS[index][0]
	lesson_body.text = SECTIONS[index][1]
	if index == 1:
		lesson_body.text += "\n\nเฉพาะ Field Creator ตอนแก้ไขสนาม\nคลิก / Shift+คลิก / ลากครอบ — เลือกวัตถุ\nCtrl+C / Ctrl+V / Ctrl+D — คัดลอก / วาง / ทำสำเนา\nDelete — ลบ   •   Ctrl+A — เลือกทั้งหมด   •   Esc — ยกเลิกเลือก\nCtrl+Z / Ctrl+Shift+Z หรือ Ctrl+Y — Undo / Redo\nShift+ลาก — ลากแนวตรง   •   Alt+ลาก — ปิดการดูดแนว\nคำสั่งแก้ไขหยุดทำงานใน Test Mode และโหมดเล่น"
	for i in range(topic_buttons.size()):
		topic_buttons[i].set_pressed_no_signal(i == index)
		topic_buttons[i].add_theme_color_override("font_color", Color("73ceff") if i == index else Color("f5f9ff"))
	preload("res://scripts/InteractionMotion.gd").reveal(lesson_body)
