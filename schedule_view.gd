extends Control
var font: Font
var data: Dictionary = {}
var shown := 0
func _ready():
 custom_minimum_size = Vector2(720, 145)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func update_timeline(value: Dictionary, count: int):
 data = value
 shown = count
 queue_redraw()
func _draw():
 if font == null or not data.get("ok",false): return
 var events: Array = data.events
 if events.is_empty(): return
 var end: float = events.back().end
 if end <= 0: return
 var left = 12.0
 var width = size.x - 30.0
 draw_string(font,Vector2(left,24),"CPU 时间线（从左到右）",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("536575"))
 draw_line(Vector2(left,94),Vector2(left+width,94),Color("a8b7c4"),1)
 for i in events.size():
  var event = events[i]
  var x = left + width * event.start / end
  var w = width * (event.end - event.start) / end
  var c = Color("f1f4f7")
  if i < shown: c = Color("d9e1e8") if event.kind == "idle" else Color("d6eee8")
  if i == shown - 1: c = Color("f6e2ac")
  draw_rect(Rect2(x,46,w,45),c)
  draw_rect(Rect2(x,46,w,45),Color("b6c8d4"),false,1)
  if w > 34:
   var name = "空闲" if event.kind == "idle" else event.id
   draw_string(font,Vector2(x+5,74),name,HORIZONTAL_ALIGNMENT_LEFT,w-7,14,Color("263b4a"))
  if w > 38 or i == 0: draw_string(font,Vector2(x,115),str(event.start),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("536575"))
 draw_string(font,Vector2(left+width-15,115),str(events.back().end),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("536575"))
