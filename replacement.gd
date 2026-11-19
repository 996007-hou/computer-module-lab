extends VBoxContainer
signal back_requested
signal address_requested
const Playback = preload("res://playback.gd")
var player: Control
const Model=preload("res://replacement_model.gd")
const Grid=preload("res://replacement_view.gd")
var refs: LineEdit
var frames: LineEdit
var algorithms: OptionButton
var view: Control
var explanation: Label
var detail: Label
var summary: Label
var previous: Button
var next: Button
var data: Dictionary={}
var step:=0
var font: Font
var resetting:=false
var compare_toggle: CheckButton
var compare_label: Label
var access_caption: Label
var frame_cards: Array[Label] = []
func _ready():
 add_theme_constant_override("separation",10)
 var head=HBoxContainer.new()
 head.add_theme_constant_override("separation",10)
 add_child(head)
 var back=Button.new()
 back.text="← 主题"
 back.pressed.connect(func(): back_requested.emit())
 head.add_child(back)
 var title=_label("页面置换",19,"263342")
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 head.add_child(title)
 var address_button=Button.new()
 address_button.text="页、块、段图解 →"
 address_button.pressed.connect(func(): address_requested.emit())
 head.add_child(address_button)
 head.add_child(_label("教材第 7 章 7.3 · 请求分页",13,"667788"))
 var row=HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 add_child(row)
 row.add_child(_label("访问序列",14,"536575"))
 refs=_field("7,0,1,2,0,3,0,4,2,3,0,3,2",300)
 row.add_child(refs)
 row.add_child(_label("页框数",14,"536575"))
 frames=_field("3",54)
 row.add_child(frames)
 algorithms=OptionButton.new()
 algorithms.add_item("先进先出 FIFO")
 algorithms.add_item("最近最少使用 LRU")
 row.add_child(algorithms)
 var reset=Button.new()
 reset.text="恢复示例"
 reset.pressed.connect(_reset)
 row.add_child(reset)
 var belady=Button.new()
 belady.text="Belady 示例"
 belady.tooltip_text="FIFO 示例：尝试把页框数从 3 改为 4，比较缺页次数。"
 belady.pressed.connect(_belady)
 row.add_child(belady)
 access_caption=_label("",15,"263342")
 access_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(access_caption)
 var snapshot=HBoxContainer.new()
 snapshot.add_theme_constant_override("separation",8)
 add_child(snapshot)
 for i in 6:
  var frame_card=_label("",14,"263342")
  frame_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  frame_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  snapshot.add_child(frame_card)
  frame_cards.append(frame_card)
 add_child(_label("下图保留每次访问后的页框内容。“缺”表示缺页，“中”表示命中。",13,"667788"))
 view=Control.new()
 view.set_script(Grid)
 view.font=font
 view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_child(view)
 var controls=HBoxContainer.new()
 controls.add_theme_constant_override("separation",8)
 add_child(controls)
 previous=Button.new()
 previous.text="← 上一步"
 previous.pressed.connect(_previous)
 controls.add_child(previous)
 next=Button.new()
 next.text="下一步 →"
 next.pressed.connect(_next)
 controls.add_child(next)
 player = HBoxContainer.new()
 player.set_script(Playback)
 controls.add_child(player)
 player.advance_requested.connect(_next)
 player.finish_requested.connect(_show_all)
 player.restart_requested.connect(_restart_steps)
 compare_toggle=CheckButton.new()
 compare_toggle.text="对比完整结果"
 compare_toggle.toggled.connect(func(_pressed): _update_compare())
 controls.add_child(compare_toggle)
 explanation=_label("",16,"263342")
 explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(explanation)
 detail=_label("",13,"667788")
 detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(detail)
 summary=_label("",14,"216e68")
 add_child(summary)
 compare_label=_label("",13,"536575")
 compare_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(compare_label)
 refs.text_changed.connect(_changed)
 frames.text_changed.connect(_changed)
 algorithms.item_selected.connect(func(_index): _changed(""))
 _changed("")
func _label(text: String,size: int,color: String) -> Label:
 var l=Label.new()
 l.text=text
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color(color))
 return l
func _field(text: String,width: int) -> LineEdit:
 var f=LineEdit.new()
 f.text=text
 f.custom_minimum_size=Vector2(width,36)
 return f
func _changed(_text):
 if resetting: return
 player.stop()
 step=0
 data=Model.simulate(refs.text,frames.text,algorithms.selected)
 if data.ok: view.custom_minimum_size.y=83+data.frame_count*29
 _render()
 _update_compare()
func _update_compare():
 if not is_instance_valid(compare_label): return
 compare_label.visible=compare_toggle.button_pressed and data.ok
 if not compare_label.visible: return
 var fifo=Model.simulate(refs.text,frames.text,0)
 var lru=Model.simulate(refs.text,frames.text,1)
 compare_label.text="同一访问序列的完整结果：FIFO 缺页 %d 次  ·  LRU 缺页 %d 次。" % [fifo.faults,lru.faults]
func _render():
 player.set_state(data.ok, step, data.get("events", []).size())
 view.update_grid(data,step)
 previous.disabled=step<=0 or not data.ok
 next.disabled=not data.ok or step>=data.get("events",[]).size()
 _render_snapshot()
 if not data.ok:
  explanation.text=data.error
  explanation.add_theme_color_override("font_color",Color("a45225"))
  detail.text="修改输入后自动重新计算。"
  summary.text=""
  return
 explanation.add_theme_color_override("font_color",Color("263342"))
 if step==0:
  explanation.text="页框为空；点击下一步，观察每次访问是否缺页。"
  detail.text="FIFO 按进入内存的先后置换；LRU 置换最久未使用的页面。"
  summary.text=""
  return
 var e=data.events[step-1]
 if not e.fault:
  explanation.text="访问页 %d：命中，页框 %d 已有该页。" % [e.page,e.frame]
 elif e.victim<0:
  explanation.text="访问页 %d：缺页，将其放入空闲页框 %d。" % [e.page,e.frame]
 else:
  explanation.text="访问页 %d：缺页，换出页 %d，放入页框 %d。" % [e.page,e.victim,e.frame]
 var order_values: Array=[]
 for page in e.order_after: order_values.append(str(page))
 var order_text=" → ".join(order_values)
 if e.victim >= 0:
  detail.text=("FIFO 换出最早进入内存的页 %d。" if algorithms.selected==0 else "LRU 换出最久未被访问的页 %d。") % e.victim
 elif e.fault:
  detail.text="还有空闲页框，不需要换出其他页面。"
 else:
  detail.text="命中不会改变 FIFO 的进入顺序。" if algorithms.selected==0 else "命中后，将该页记为最近使用。"
 detail.text += "  当前顺序（%s）：%s。" % ["最早进入 → 最晚进入" if algorithms.selected==0 else "最久未用 → 最近使用",order_text]
 summary.text="已访问 %d 次  ·  缺页 %d 次  ·  命中 %d 次" % [step,e.faults,step-e.faults]
 if step==data.events.size(): summary.text += "  ·  缺页率 %.1f%%" % (100.0*data.faults/step)

func _render_snapshot():
 for card in frame_cards: card.hide()
 if not data.ok:
  access_caption.text=""
  return
 var event: Dictionary = data.events[step-1] if step > 0 else {}
 if event.is_empty():
  access_caption.text="CPU 接下来访问虚拟页 %d，物理内存的页框目前为空。" % data.references[0]
 elif event.fault:
  access_caption.text="访问虚拟页 %d → 缺页 → 从外存调入物理块 %d（页框 %d）" % [event.page,event.frame,event.frame]
 else:
  access_caption.text="访问虚拟页 %d → 命中 → 直接读取物理块 %d（页框 %d）" % [event.page,event.frame,event.frame]
 for i in data.frame_count:
  var card = frame_cards[i]
  var page: int = event.frames[i] if step > 0 else -1
  var active: bool = step > 0 and i == event.frame
  var content = "空闲" if page < 0 else "页 %d" % page
  if active and event.victim >= 0: content = "页 %d 换成页 %d" % [event.victim,page]
  card.text = "页框 %d\n%s" % [i,content]
  var box = StyleBoxFlat.new()
  box.bg_color = Color("f7e5b5" if active and event.fault else "e4f3f0" if active else "ffffff")
  box.border_color = Color("dce4ec")
  box.set_border_width_all(1)
  box.set_corner_radius_all(8)
  box.set_content_margin_all(8)
  card.add_theme_stylebox_override("normal",box)
  card.show()
func _next():
 if data.ok and step<data.events.size():
  step+=1
  _render()
func _show_all():
 step = data.get("events", []).size()
 _render()
func _restart_steps():
 step = 0
 _render()
func _previous():
 player.stop()
 if data.ok and step>0:
  step-=1
  _render()
func _reset():
 resetting=true
 refs.text="7,0,1,2,0,3,0,4,2,3,0,3,2"
 frames.text="3"
 resetting=false
 _changed("")
func _belady():
 resetting=true
 refs.text="1,2,3,4,1,2,5,1,2,3,4,5"
 frames.text="3"
 algorithms.select(0)
 resetting=false
 _changed("")
 explanation.text="Belady 示例：先观察 3 个页框，再改为 4 个页框比较 FIFO 缺页次数。"
 detail.text="提示：页框更多时，FIFO 的缺页次数并不一定更少。"
