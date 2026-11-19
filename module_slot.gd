extends PanelContainer
signal module_added(id: String)
signal module_removed(id: String)
var module_id := ""
var active := false
var title_label: Label
var subtitle_label: Label
var remove_button: Button
func setup(id: String, title: String):
 module_id = id
 custom_minimum_size = Vector2(140, 100)
 size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 mouse_filter = Control.MOUSE_FILTER_STOP
 var box = VBoxContainer.new()
 box.alignment = BoxContainer.ALIGNMENT_CENTER
 box.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(box)
 title_label = Label.new()
 title_label.text = title
 title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title_label.add_theme_font_size_override("font_size", 19)
 title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 box.add_child(title_label)
 subtitle_label = Label.new()
 subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 subtitle_label.add_theme_font_size_override("font_size", 13)
 subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 box.add_child(subtitle_label)
 remove_button = Button.new()
 remove_button.text = "移除"
 remove_button.pressed.connect(func(): module_removed.emit(module_id))
 box.add_child(remove_button)
 set_active(false)
func set_active(value: bool):
 active = value
 if not is_instance_valid(title_label): return
 subtitle_label.text = "已加入" if active else "等待加入"
 subtitle_label.add_theme_color_override("font_color", Color("216e68") if active else Color("788897"))
 remove_button.visible = active
 var box = StyleBoxFlat.new()
 box.bg_color = Color("e4f3f0") if active else Color("f9fafb")
 box.border_color = Color("8bc8bc") if active else Color("dbe2e9")
 box.set_border_width_all(1)
 box.set_corner_radius_all(10)
 box.content_margin_top = 12
 box.content_margin_bottom = 12
 add_theme_stylebox_override("panel", box)
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
 return data is Dictionary and data.get("kind") == "module" and data.get("id") == module_id
func _drop_data(_position: Vector2, _data: Variant):
 module_added.emit(module_id)
