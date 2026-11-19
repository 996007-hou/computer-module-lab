extends Button
var module_id := ""
var module_name := ""
func _get_drag_data(_position: Vector2):
 var preview = Label.new()
 preview.text = "  " + module_name + "  "
 preview.add_theme_font_size_override("font_size", 18)
 set_drag_preview(preview)
 return {"kind": "module", "id": module_id}
