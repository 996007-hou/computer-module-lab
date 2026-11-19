extends VBoxContainer

const INK = "263342"
const MUTED = "536575"
const GREEN = "216e68"

var feedback: Label
var label_sizes: Dictionary = {}

func build_intro(title: String, hint: String):
 add_theme_constant_override("separation", 14)
 add_child(make_label(title, 24))
 add_child(make_label(hint, 15, MUTED, true))

func make_label(value: String, font_size: int = 16, color: String = INK, wrap: bool = false) -> Label:
 var label = Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", Color(color))
 if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label_sizes[label] = font_size
 return label

func update_reading_size(extra_room: float):
 add_theme_constant_override("separation", 14 + roundi(extra_room * 5))
 for label in label_sizes:
  label.add_theme_font_size_override("font_size", roundi(label_sizes[label] * (1.0 + extra_room * 0.18)))
 feedback.custom_minimum_size.y = 46 + roundi(extra_room * 8)

func add_row(parent: Control = null) -> HBoxContainer:
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 10)
 (self if parent == null else parent).add_child(row)
 return row

func make_button(parent: Control, title: String, action: Callable) -> Button:
 var button = Button.new()
 button.text = title
 button.custom_minimum_size.y = 38
 button.pressed.connect(action)
 parent.add_child(button)
 return button

func add_feedback():
 feedback = make_label("", 16, GREEN, true)
 feedback.custom_minimum_size.y = 46
 add_child(feedback)

func tile_style(tone: String) -> StyleBoxFlat:
 var box = StyleBoxFlat.new()
 box.bg_color = Color({"active":"e4f3f0", "waiting":"fff2dc", "info":"eaf1fa", "idle":"ffffff"}[tone])
 box.border_color = Color({"active":"9bcfc3", "waiting":"e7cba1", "info":"b9cce1", "idle":"dce4ec"}[tone])
 box.set_border_width_all(1)
 box.set_corner_radius_all(9)
 box.set_content_margin_all(12)
 return box

func make_tile(parent: Control, height: int = 74) -> Label:
 var label = make_label("", 16, INK, true)
 label.custom_minimum_size.y = height
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(label)
 return label

func show_tile(label: Label, value: String, tone: String = "idle"):
 label.text = value
 label.add_theme_stylebox_override("normal", tile_style(tone))
