extends Control
var font: Font
var data: Dictionary={}
var shown:=0
func _ready():
 custom_minimum_size=Vector2(720,250)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func update_grid(value: Dictionary,count: int):
 data=value
 shown=count
 queue_redraw()
func _draw():
 if font==null or not data.get("ok",false): return
 var left=85.0
 var top=45.0
 var count=data.events.size()
 var width=minf(60.0,(size.x-left-10)/count)
 draw_string(font,Vector2(4,30),"访问页号",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("536575"))
 for frame in data.frame_count:
  draw_string(font,Vector2(4,top+frame*29+19),"页框 %d" % frame,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("536575"))
 for i in count:
  var x=left+i*width
  var seen=i<shown
  draw_string(font,Vector2(x+8,30),str(data.references[i]) if seen else "?",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("263b4a") if seen else Color("8897a3"))
  for frame in data.frame_count:
   var y=top+frame*29
   var value=data.events[i].frames[frame]
   var selected=seen and i==shown-1 and frame==data.events[i].frame
   var color=Color("f7e5b5") if selected else (Color("e2f3ef") if seen else Color("f4f6f8"))
   draw_rect(Rect2(x,y,width-3,26),color)
   draw_rect(Rect2(x,y,width-3,26),Color("c49a49") if selected else Color("c1d0d9"),false,1)
   if seen and value>=0: draw_string(font,Vector2(x+8,y+19),str(value),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("263b4a"))
  if seen:
   var outcome="缺" if data.events[i].fault else "中"
   draw_string(font,Vector2(x+8,top+data.frame_count*29+22),outcome,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a15d22") if data.events[i].fault else Color("267b69"))
