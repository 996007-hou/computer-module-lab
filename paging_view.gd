extends Control
var info: Dictionary = {}
var step := 0
var font: Font
func _ready():
 custom_minimum_size = Vector2(700, 290)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func update_diagram(data: Dictionary, current_step: int):
 info = data
 step = current_step
 queue_redraw()
func _draw():
 if font == null or not info.get("ok", false): return
 var size_y = 27.0
 var top = 38.0
 var lx = 14.0
 var cx = size.x * 0.37
 var rx = size.x * 0.72
 draw_string(font, Vector2(lx, 20), "程序页面", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("536575"))
 draw_string(font, Vector2(cx, 20), "页表：页 → 页框", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("536575"))
 draw_string(font, Vector2(rx, 20), "物理内存页框", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("536575"))
 for n in info.page_count:
  var y = top + n * size_y
  var chosen = n == info.page and step >= 1
  var bg = Color("f7e5b5") if chosen else Color("e2f3ef")
  var border = Color("b98c35") if chosen else Color("9ccbbf")
  draw_rect(Rect2(lx,y,100,23),bg)
  draw_rect(Rect2(lx,y,100,23),border,false,1.0)
  draw_string(font, Vector2(lx+9,y+17), "页 %d" % n, HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("263b4a"))
  var table_bg = Color("f7e5b5") if chosen and step >= 2 else Color("edf3fa")
  draw_rect(Rect2(cx,y,142,23),table_bg)
  draw_rect(Rect2(cx,y,142,23),Color("bccddd"),false,1.0)
  draw_string(font, Vector2(cx+9,y+17), "%d        →        %d" % [n,info.mapping[n]], HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("263b4a"))
  if chosen and step >= 2:
   var target_y = top + info.frame * size_y + 11.5
   draw_line(Vector2(cx+146,y+11.5),Vector2(rx-6,target_y),Color("b98c35"),2.0,true)
 for frame in info.frame_count:
  var y = top + frame * size_y
  var selected = frame == info.frame and step >= 2
  var index = info.mapping.find(frame)
  var c = Color("f7e5b5") if selected else (Color("d9eafa") if index >= 0 else Color("f4f6f8"))
  draw_rect(Rect2(rx,y,145,23),c)
  draw_rect(Rect2(rx,y,145,23),Color("c49a49") if selected else Color("c5d2dc"),false,1.0)
  var text = "框 %d   %s" % [frame, ("页 %d" % index) if index >= 0 else "空闲"]
  draw_string(font, Vector2(rx+8,y+17),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("263b4a"))
