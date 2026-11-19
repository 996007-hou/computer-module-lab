extends PanelContainer
var amount := "180"
var unit := "MB"
func _get_drag_data(_position: Vector2):
 var preview = Label.new()
 preview.text = "程序  ·  " + amount + " " + unit
 set_drag_preview(preview)
 return {"kind":"program"}
