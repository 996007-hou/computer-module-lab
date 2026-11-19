extends VBoxContainer
signal back_requested
const Playback = preload("res://playback.gd")
var player: Control
const Banker=preload("res://banker_model.gd")
var total: LineEdit
var max_field: LineEdit
var allocation: LineEdit
var request: LineEdit
var process_field: LineEdit
var edit_panel: Control
var table: GridContainer
var explanation: Label
var detail: Label
var available_label: Label
var previous: Button
var next: Button
var info: Dictionary = {}
var step:=0
var resetting:=false
var safety_only:=false
var mode_button: Button
var matrix_grid: GridContainer
var matrix_inputs: Array = []
var trace_label: Label
func _ready():
 add_theme_constant_override("separation",9)
 var head=HBoxContainer.new()
 head.add_theme_constant_override("separation",10)
 add_child(head)
 var back=Button.new()
 back.text="← 主题"
 back.pressed.connect(func(): back_requested.emit())
 head.add_child(back)
 var title=_label("银行家算法",19,"263342")
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 head.add_child(title)
 head.add_child(_label("教材第 5 章 5.5.2 · 课堂示例",13,"667788"))
 var introduction=_label("修改资源数据，检查当前状态，或模拟一次资源请求。",13,"667788")
 introduction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(introduction)
 var row=HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 add_child(row)
 row.add_child(_label("资源总量",14,"536575"))
 total=_field("10,5,7",110)
 row.add_child(total)
 row.add_child(_label("请求进程 P",14,"536575"))
 process_field=_field("1",45)
 row.add_child(process_field)
 row.add_child(_label("请求向量",14,"536575"))
 request=_field("1,0,2",100)
 row.add_child(request)
 var edit=Button.new()
 edit.text="编辑数据 ▾"
 edit.pressed.connect(func(): edit_panel.visible = not edit_panel.visible)
 row.add_child(edit)
 var reset=Button.new()
 reset.text="恢复课堂示例"
 reset.pressed.connect(_reset)
 row.add_child(reset)
 edit_panel=VBoxContainer.new()
 edit_panel.add_theme_constant_override("separation",5)
 add_child(edit_panel)
 var max_row=HBoxContainer.new()
 edit_panel.add_child(max_row)
 max_row.add_child(_label("最大需求 Max  ",13,"536575"))
 max_field=_field("7,5,3;3,2,2;9,0,2;2,2,2",390)
 max_row.add_child(max_field)
 var allocation_row=HBoxContainer.new()
 edit_panel.add_child(allocation_row)
 allocation_row.add_child(_label("已分配 Allocation  ",13,"536575"))
 allocation=_field("0,1,0;2,0,0;3,0,2;2,1,1",390)
 allocation_row.add_child(allocation)
 edit_panel.add_child(_label("每行是一个进程，行之间用分号；资源按相同顺序排列。",12,"667788"))
 edit_panel.visible=false
 var matrix_head=HBoxContainer.new()
 add_child(matrix_head)
 var matrix_title=_label("资源分配表 · 可直接修改数字",15,"263342")
 matrix_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 matrix_head.add_child(matrix_title)
 mode_button=Button.new()
 mode_button.text="只检查当前状态"
 mode_button.pressed.connect(_toggle_mode)
 matrix_head.add_child(mode_button)
 matrix_grid=GridContainer.new()
 matrix_grid.add_theme_constant_override("h_separation",6)
 matrix_grid.add_theme_constant_override("v_separation",5)
 add_child(matrix_grid)
 var dimensions=HBoxContainer.new()
 dimensions.add_theme_constant_override("separation",6)
 add_child(dimensions)
 for item in [["＋进程",_add_process],["－末进程",_remove_process],["＋资源",_add_resource],["－末资源",_remove_resource]]:
  var b=Button.new()
  b.text=item[0]
  b.pressed.connect(item[1])
  dimensions.add_child(b)
 add_child(_label("Max：最大需求    Allocation：已分配    Need = Max − Allocation（下方自动计算）",12,"667788"))
 available_label=_label("",14,"216e68")
 add_child(available_label)
 table=GridContainer.new()
 table.columns=5
 table.add_theme_constant_override("h_separation",24)
 table.add_theme_constant_override("v_separation",7)
 add_child(table)
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
 explanation=_label("",16,"263342")
 explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(explanation)
 detail=_label("",13,"667788")
 detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(detail)
 move_child(controls, available_label.get_index()+1)
 move_child(explanation, controls.get_index()+1)
 move_child(detail, explanation.get_index()+1)
 trace_label=_label("",13,"536575")
 trace_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(trace_label)
 for field in [total,max_field,allocation,request,process_field]: field.text_changed.connect(_changed)
 for field in [total,max_field,allocation]: field.focus_exited.connect(_rebuild_matrix)
 _rebuild_matrix()
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
func _vector(values: Array) -> String:
 var names: Array=[]
 for n in values: names.append(str(n))
 return "(" + ", ".join(names) + ")"
func _changed(_text):
 if resetting: return
 player.stop()
 step=0
 var request_text=request.text
 if safety_only:
  var zeroes: Array = []
  for i in total.text.replace("，",",").split(",").size(): zeroes.append("0")
  request_text=",".join(zeroes)
 info=Banker.evaluate(total.text,max_field.text,allocation.text,request_text,process_field.text)
 _render()
func _toggle_mode():
 safety_only=not safety_only
 mode_button.text="切换到申请资源" if safety_only else "只检查当前状态"
 request.editable=not safety_only
 process_field.editable=not safety_only
 _changed("")
func _set_dimensions(totals: Array, maxima: Array, allocated: Array, req: Array):
 var mx: Array=[]
 var al: Array=[]
 for row in maxima: mx.append(_csv(row))
 for row in allocated: al.append(_csv(row))
 resetting=true
 total.text=_csv(totals)
 max_field.text=";".join(mx)
 allocation.text=";".join(al)
 request.text=_csv(req)
 if int(process_field.text)>maxima.size(): process_field.text=str(maxima.size())
 resetting=false
 _rebuild_matrix()
 _changed("")
func _csv(values: Array) -> String:
 var parts: Array=[]
 for value in values: parts.append(str(value))
 return ",".join(parts)
func _dimension_data() -> Dictionary:
 var totals=Banker._vector(total.text)
 var maxima=Banker._matrix(max_field.text)
 var allocated=Banker._matrix(allocation.text)
 var req=Banker._vector(request.text)
 if totals.is_empty() or maxima.is_empty() or maxima.size()!=allocated.size() or req.size()!=totals.size():
  detail.text="请先填写完整的资源总量、矩阵和请求向量，再调整数量。"
  return {}
 for row in maxima+allocated:
  if row.size()!=totals.size():
   detail.text="请先让每行的资源数量与总量一致。"
   return {}
 return {"totals":totals,"maxima":maxima,"allocated":allocated,"request":req}
func _add_process():
 var d=_dimension_data()
 if d.is_empty(): return
 if d.maxima.size()>=6:
  detail.text="最多支持 6 个进程。"
  return
 var row: Array=[]
 for i in d.totals.size(): row.append(0)
 d.maxima.append(row.duplicate())
 d.allocated.append(row.duplicate())
 _set_dimensions(d.totals,d.maxima,d.allocated,d.request)
func _remove_process():
 var d=_dimension_data()
 if d.is_empty(): return
 if d.maxima.size()<=1:
  detail.text="至少保留 1 个进程。"
  return
 d.maxima.pop_back()
 d.allocated.pop_back()
 _set_dimensions(d.totals,d.maxima,d.allocated,d.request)
func _add_resource():
 var d=_dimension_data()
 if d.is_empty(): return
 if d.totals.size()>=4:
  detail.text="最多支持 4 类资源。"
  return
 d.totals.append(0)
 d.request.append(0)
 for row in d.maxima: row.append(0)
 for row in d.allocated: row.append(0)
 _set_dimensions(d.totals,d.maxima,d.allocated,d.request)
func _remove_resource():
 var d=_dimension_data()
 if d.is_empty(): return
 if d.totals.size()<=1:
  detail.text="至少保留 1 类资源。"
  return
 d.totals.pop_back()
 d.request.pop_back()
 for row in d.maxima: row.pop_back()
 for row in d.allocated: row.pop_back()
 _set_dimensions(d.totals,d.maxima,d.allocated,d.request)
func _rebuild_matrix():
 for child in matrix_grid.get_children():
  matrix_grid.remove_child(child)
  child.queue_free()
 matrix_inputs.clear()
 var max_rows=max_field.text.replace("；",";").split(";")
 var alloc_rows=allocation.text.replace("；",";").split(";")
 var resources=total.text.replace("，",",").split(",").size()
 if resources < 1 or resources > 4 or max_rows.size() != alloc_rows.size() or max_rows.size() > 6: return
 matrix_grid.columns=1+2*resources
 matrix_grid.add_child(_label("进程",13,"667788"))
 for group in ["Max", "已分配"]:
  for j in resources: matrix_grid.add_child(_label("%s %s" % [group, char(65+j)],13,"667788"))
 for i in max_rows.size():
  var max_values=max_rows[i].replace("，",",").split(",")
  var allocated=alloc_rows[i].replace("，",",").split(",")
  if max_values.size()!=resources or allocated.size()!=resources: return
  matrix_grid.add_child(_label("P%d" % (i+1),14,"263342"))
  var record: Array = []
  for values in [max_values,allocated]:
   var group_fields: Array = []
   for value in values:
    var cell=_field(value.strip_edges(),55)
    cell.text_changed.connect(_matrix_changed)
    matrix_grid.add_child(cell)
    group_fields.append(cell)
   record.append(group_fields)
  matrix_inputs.append(record)
func _matrix_changed(_text: String):
 var max_rows: Array = []
 var alloc_rows: Array = []
 for row in matrix_inputs:
  var groups: Array = []
  for fields in row:
   var values: Array = []
   for field in fields: values.append(field.text)
   groups.append(",".join(values))
  max_rows.append(groups[0])
  alloc_rows.append(groups[1])
 resetting=true
 max_field.text=";".join(max_rows)
 allocation.text=";".join(alloc_rows)
 resetting=false
 _changed("")
func _render():
 player.set_state(info.ok and info.status in ["safe", "unsafe"], step, info.trace.size() + 2 if info.ok and info.status in ["safe", "unsafe"] else 0)
 for child in table.get_children():
  table.remove_child(child)
  child.queue_free()
 previous.disabled=step<=0 or not info.ok
 var can_trace=info.ok and info.status in ["safe","unsafe"]
 var last_step=info.trace.size()+2 if can_trace else 0
 next.disabled=not can_trace or step>=last_step
 if not info.ok:
  available_label.text=""
  explanation.text=info.error
  explanation.add_theme_color_override("font_color",Color("a45225"))
  detail.text="修改输入后自动重新计算。"
  trace_label.text=""
  return
 explanation.add_theme_color_override("font_color",Color("263342"))
 var assumed=can_trace and step>=1
 var records: Array=[]
 if assumed:
  for k in mini(maxi(step-1,0),info.trace.size()):
   var record=info.trace[k]
   records.append("P%d：%s + %s → %s" % [record.pid,_vector(record.before),_vector(record.released),_vector(record.after)])
 trace_label.text="检查记录（Work + 归还资源 → 新 Work）\n" + "\n".join(records) if not records.is_empty() else ""
 var work=info.available
 if assumed:
  work=info.initial_work
  if step>=2 and not info.trace.is_empty(): work=info.trace[mini(step-2,info.trace.size()-1)].after
 available_label.text=("模拟 Work = " if assumed else "当前可用 Available = ") + _vector(work) + "      Need = Max − Allocation"
 for text in ["进程","最大需求 Max","假设分配" if assumed and not safety_only else "已分配 Allocation","剩余需求 Need","Finish"]: table.add_child(_label(text,13,"667788"))
 for i in info.need.size():
  var max_values: Array=[]
  for j in info.total.size(): max_values.append(info.need[i][j]+info.allocation[i][j])
  var alloc_row=info.tentative_allocation[i] if assumed else info.allocation[i]
  var need_row=info.tentative_need[i] if assumed else info.need[i]
  var finished=false
  if assumed:
   for k in mini(maxi(step-1,0),info.trace.size()):
    if info.trace[k].pid == i+1: finished=true
  for text in ["P%d" % (i+1),_vector(max_values),_vector(alloc_row),_vector(need_row),"完成" if finished else "未完成"]: table.add_child(_label(text,14,"263342"))
 if not can_trace:
  explanation.text=info.message
  detail.text="原有资源分配没有改变。"
  return
 if step==0:
  explanation.text="检查当前资源分配状态是否存在安全序列。" if safety_only else "P%d 请求 %s；先检查请求是否超过剩余需求与可用资源。" % [info.pid+1,_vector(info.request)]
  detail.text="从当前 Available 开始，寻找能够依次完成的进程。" if safety_only else "两项检查都通过后，才能假设分配并进行安全性检查。"
 elif step==1:
  explanation.text=("安全检查开始，工作向量 Work = " if safety_only else "假设分配后，工作向量 Work = ") + _vector(info.initial_work) + "。"
  detail.text="这只是模拟，不改变原来的资源分配。"
 elif step < last_step:
  var record=info.trace[step-2]
  explanation.text="P%d 可完成：Need %s ≤ Work %s。" % [record.pid,_vector(record.need),_vector(record.before)]
  detail.text="它完成后归还 %s，Work 更新为 %s。" % [_vector(record.released),_vector(record.after)]
 else:
  if info.safe:
   var names: Array=[]
   for pid in info.sequence: names.append("P%d" % pid)
   explanation.text="找到安全序列：" + " → ".join(names) + "。"
   detail.text="当前状态安全；这里展示的是一个可行序列。" if safety_only else "因此本次请求可以被批准；这里展示的是一个可行序列。"
  else:
   explanation.text="无法让所有进程依次完成：当前状态不安全。" if safety_only else "无法让所有进程依次完成：假设分配后的状态不安全。"
   detail.text="不安全状态不等于系统此刻已经死锁。" if safety_only else "不批准此次请求；不安全状态不等于系统此刻已经死锁。"
func _next():
 if info.ok and info.status in ["safe","unsafe"] and step<info.trace.size()+2:
  step+=1
  _render()
func _show_all():
 step = info.trace.size() + 2 if info.ok and info.status in ["safe", "unsafe"] else 0
 _render()
func _restart_steps():
 step = 0
 _render()
func _previous():
 player.stop()
 if step>0:
  step-=1
  _render()
func _reset():
 resetting=true
 total.text="10,5,7"
 max_field.text="7,5,3;3,2,2;9,0,2;2,2,2"
 allocation.text="0,1,0;2,0,0;3,0,2;2,1,1"
 request.text="1,0,2"
 process_field.text="1"
 resetting=false
 _rebuild_matrix()
 _changed("")
