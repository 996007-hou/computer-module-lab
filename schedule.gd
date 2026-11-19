extends VBoxContainer
signal back_requested
const Playback = preload("res://playback.gd")
var player: Control
const Model = preload("res://schedule_model.gd")
const Timeline = preload("res://schedule_view.gd")
var arrivals: LineEdit
var bursts: LineEdit
var algorithms: OptionButton
var view: Control
var explanation: Label
var detail: Label
var metrics: Label
var previous: Button
var next: Button
var data: Dictionary = {}
var step := 0
var font: Font
var setting := false
var quantum: LineEdit
var quantum_label: Label
var scope_label: Label
var details_button: Button
var result_details: Label
var show_details := false
var candidates: Label
func _ready():
 add_theme_constant_override("separation",10)
 var head=HBoxContainer.new()
 head.add_theme_constant_override("separation",10)
 add_child(head)
 var back=Button.new()
 back.text="← 主题"
 back.pressed.connect(func(): back_requested.emit())
 head.add_child(back)
 var title=_label("处理机调度",19,"263342")
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 head.add_child(title)
 scope_label=_label("教材第 4 章 4.4 · 非抢占式",13,"667788")
 head.add_child(scope_label)
 var row=HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 add_child(row)
 row.add_child(_label("到达时间",14,"536575"))
 arrivals=_field("0,1,2,3,4",170)
 row.add_child(arrivals)
 row.add_child(_label("运行时间",14,"536575"))
 bursts=_field("3,6,1,4,2",170)
 row.add_child(bursts)
 algorithms=OptionButton.new()
 for text in ["先来先服务 FCFS","短作业优先 SJF","高响应比优先 HRRN","最短剩余时间 SRTF","时间片轮转 RR"]: algorithms.add_item(text)
 row.add_child(algorithms)
 quantum_label=_label("时间片",14,"536575")
 row.add_child(quantum_label)
 quantum=_field("2",42)
 row.add_child(quantum)
 var reset=Button.new()
 reset.text="课堂例题"
 reset.tooltip_text="参考课堂板书的五进程示例；均为非抢占式。"
 reset.pressed.connect(_reset)
 row.add_child(reset)
 add_child(_label("各项按 P1、P2……的顺序填写，以逗号分隔；同一时间单位。",13,"667788"))
 view=Control.new()
 view.set_script(Timeline)
 view.font=font
 view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_child(view)
 candidates=_label("",14,"415768")
 candidates.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(candidates)
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
 details_button=Button.new()
 details_button.text="查看各进程指标 ▾"
 details_button.pressed.connect(_toggle_details)
 controls.add_child(details_button)
 explanation=_label("",16,"263342")
 explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(explanation)
 detail=_label("",13,"667788")
 detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(detail)
 metrics=_label("",13,"667788")
 metrics.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(metrics)
 result_details=_label("",13,"536575")
 result_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(result_details)
 arrivals.text_changed.connect(_changed)
 bursts.text_changed.connect(_changed)
 quantum.text_changed.connect(_changed)
 algorithms.item_selected.connect(func(_index): _changed(""))
 _changed("")
func _label(text: String, size: int, color: String) -> Label:
 var l=Label.new()
 l.text=text
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color(color))
 return l
func _field(text: String, width: int) -> LineEdit:
 var f=LineEdit.new()
 f.text=text
 f.custom_minimum_size=Vector2(width,36)
 return f
func _changed(_text):
 if setting: return
 player.stop()
 step=0
 show_details=false
 details_button.text="查看各进程指标 ▾"
 quantum_label.visible=algorithms.selected == 4
 quantum.visible=algorithms.selected == 4
 scope_label.text="教材第 4 章 4.4 · " + ("抢占式" if algorithms.selected >= 3 else "非抢占式")
 var q= int(quantum.text) if quantum.text.strip_edges().is_valid_int() else 0
 data=Model.run(arrivals.text,bursts.text,algorithms.selected,q)
 _render()
func _render():
 player.set_state(data.ok, step, data.get("events", []).size())
 view.update_timeline(data,step)
 previous.disabled = step <= 0 or not data.ok
 next.disabled = not data.ok or step >= data.get("events",[]).size()
 details_button.visible=data.ok and step == data.get("events",[]).size() and step > 0
 result_details.visible=details_button.visible and show_details
 if not data.ok:
  explanation.text=data.error
  explanation.add_theme_color_override("font_color",Color("a45225"))
  detail.text="修改输入后会重新计算。"
  metrics.text=""
  candidates.text=""
  return
 explanation.add_theme_color_override("font_color",Color("263342"))
 if step == 0:
  explanation.text="选择算法后，点击下一步查看 CPU 如何挑选进程。"
  detail.text="抢占式：执行中的进程可能让出 CPU。" if algorithms.selected >= 3 else "非抢占式：进程一旦开始运行，便执行到完成。"
  metrics.text=""
  candidates.text="逐步演示时，这里会列出就绪进程和算法比较的数据。"
  return
 var event=data.events[step-1]
 if event.kind=="idle":
  candidates.text="就绪队列为空。"
  explanation.text="%d–%d：没有进程到达，CPU 空闲。" % [event.start,event.end]
  detail.text="时间推进到下一个进程到达。"
 else:
  var names: Array=[]
  var candidate_details: Array=[]
  for p in event.ready: names.append(p.id)
  for p in event.ready:
   var measurement = ""
   match algorithms.selected:
    0: measurement = "到达 %d" % p.arrival
    1: measurement = "运行 %d" % p.burst
    2: measurement = "响应比 %.2f" % (float(event.start - p.arrival + p.burst) / p.burst)
    3: measurement = "剩余 %d" % p.remaining
    4: measurement = "队列第 %d 位" % (event.ready.find(p) + 1)
   candidate_details.append(("▶ " if p.id==event.id else "") + p.id + "（" + measurement + "）")
  candidates.text="本次候选：" + "    ".join(candidate_details)
  explanation.text="时刻 %d：从 %s 中选择 %s，运行至 %d。" % [event.start,"、".join(names),event.id,event.end]
  var why=["按到达时间先后选择。","从就绪进程中选择运行时间最短者。","选择响应比最高者；响应比 =（等待 + 运行）÷ 运行。","优先运行剩余时间最短者；剩余时间相同则继续当前进程。","每次最多运行一个时间片；时间片结束后进程回到队尾。"][algorithms.selected]
  if algorithms.selected == 2: why += "  本次响应比 %.2f。" % event.ratio
  if event.finished:
   detail.text=why + "  已完成，周转时间 = %d - %d = %d。" % [event.end,event.arrival,event.turnaround]
  else:
   detail.text=why + "  尚需运行 %d。" % event.remaining_after
 if step==data.events.size():
  metrics.text="平均周转时间 %.2f  ·  平均带权周转时间 %.2f" % [data.average_turnaround,data.average_weighted]
  var rows: Array=[]
  var sorted=data.results.duplicate()
  sorted.sort_custom(func(a,b): return int(a.id.trim_prefix("P")) < int(b.id.trim_prefix("P")))
  for item in sorted:
   rows.append("%s   完成 %d   周转 %d   带权 %.2f" % [item.id,item.end,item.turnaround,item.weighted])
  result_details.text="\n".join(rows)
 else: metrics.text=""
func _toggle_details():
 show_details=not show_details
 details_button.text="收起各进程指标 ▴" if show_details else "查看各进程指标 ▾"
 _render()
func _next():
 if data.ok and step < data.events.size():
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
 if data.ok and step > 0:
  step-=1
  _render()
func _reset():
 setting=true
 arrivals.text="0,1,2,3,4"
 bursts.text="3,6,1,4,2"
 setting=false
 _changed("")
