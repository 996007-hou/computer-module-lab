extends Control
signal released(index: int)
var segments: Array = []
var focus_index := -1
var candidate_index := -1
var font: Font
var unit := "MB"
var hitboxes: Array = []
var focus_intensity := 1.0
var focus_tween: Tween
func _ready():
 mouse_filter = Control.MOUSE_FILTER_STOP
 custom_minimum_size = Vector2(620, 250)
func highlight(index: int):
 focus_index = index
 if focus_tween: focus_tween.kill()
 focus_intensity = 0.25
 focus_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 focus_tween.tween_property(self, "focus_intensity", 1.0, 0.4)
func _process(_delta):
 if focus_tween and focus_tween.is_running(): queue_redraw()
func _draw():
 if font == null: return
 draw_string(font, Vector2(8, 26), "低地址  0", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("657586"))
 draw_string(font, Vector2(size.x - 78, 26), "高地址 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("657586"))
 hitboxes.clear()
 var total := 0.0
 for seg in segments: total += seg.size
 if total <= 0: return
 var usable := size.x - 16.0
 var x := 8.0
 var y := 48.0
 var height := 112.0
 for i in segments.size():
  var seg = segments[i]
  var width: float = usable * seg.size / total
  var rect = Rect2(x, y, width, height)
  hitboxes.append(rect)
  var c = Color("daf1eb") if seg.free else Color("dceafb")
  var edge = Color("75b7aa") if seg.free else Color("93b6da")
  if i == candidate_index:
   c = Color("c3e7ef")
   edge = Color("448ea1")
  if i == focus_index:
   c = c.lerp(Color("f1d89c"), focus_intensity)
   edge = Color("be8a2f")
  draw_rect(rect, c)
  draw_rect(rect, edge, false, 2.0)
  if width >= 62:
   var caption = "空闲" if seg.free else seg.name
   draw_string(font, Vector2(x + 9, y + 42), caption, HORIZONTAL_ALIGNMENT_LEFT, max(0, width - 14), 16, Color("263c4c"))
   draw_string(font, Vector2(x + 9, y + 70), _fmt(seg.size) + " " + unit, HORIZONTAL_ALIGNMENT_LEFT, max(0, width - 14), 14, Color("465c6b"))
   if i == candidate_index and width >= 90:
    draw_string(font, Vector2(x + 9, y + 94), "算法选中", HORIZONTAL_ALIGNMENT_LEFT, max(0, width - 14), 13, Color("276979"))
  x += width
 draw_rect(Rect2(8, 180, 9, 9), Color("55c8b4"))
 draw_string(font, Vector2(23, 190), "空闲分区", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("536575"))
 draw_rect(Rect2(130, 180, 9, 9), Color("7aa4df"))
 draw_string(font, Vector2(145, 190), "已分配", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("536575"))
 draw_rect(Rect2(235, 180, 9, 9), Color("448ea1"))
 draw_string(font, Vector2(250, 190), "算法选中", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("536575"))
 draw_rect(Rect2(350, 180, 9, 9), Color("be8a2f"))
 draw_string(font, Vector2(365, 190), "当前检查", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("536575"))
func index_at(pos: Vector2) -> int:
 for i in hitboxes.size():
  if hitboxes[i].has_point(pos): return i
 return -1
func _gui_input(event):
 if event is InputEventMouseMotion:
  var i = index_at(event.position)
  tooltip_text = "地址 %s–%s %s · %s · %s %s" % [_fmt(segments[i].start), _fmt(segments[i].start + segments[i].size), unit, "空闲" if segments[i].free else "已占用（点击回收）", _fmt(segments[i].size), unit] if i >= 0 else ""
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  var i = index_at(event.position)
  if i >= 0 and not segments[i].free: released.emit(i)

func _fmt(value: int) -> String:
 var magnitude = absi(value)
 var whole = floori(float(magnitude) / 10.0)
 var frac = magnitude % 10
 return ("-" if value < 0 else "") + str(whole) + ("." + str(frac) if frac else "")
