extends "res://chapter_lab.gd"

signal back_requested
signal presentation_requested

const Model = preload("res://semaphore_model.gd")
enum Action { REQUEST, ENTER, RELEASE }
const DEMO = [
 [0, Action.REQUEST, "P1 申请", "资源空闲，先让 P1 拿到唯一的许可。"],
 [1, Action.REQUEST, "P2 申请", "P1 正在使用资源。看看 P2 申请同一个资源会怎样。"],
 [0, Action.RELEASE, "P1 释放", "P1 离开后，许可交给队首的 P2。注意 P2 先变为就绪。"],
 [1, Action.ENTER, "调度 P2", "操作系统调度 P2。它已获得许可，可以进入临界区。"],
 [1, Action.RELEASE, "P2 释放", "P2 用完资源，释放许可，让它恢复空闲。"]
]

var model = Model.new()
var selection: OptionButton
var status: Label
var resource: Label
var process_labels: Array[Label] = []
var queue_label: Label
var result: Label
var history: Label
var events: Array[String] = []
var manual: HBoxContainer
var demo_actions: HBoxContainer
var demo_start: Button
var demo_next: Button
var demo_hint: Label
var details: VBoxContainer
var present_button: Button
var demo_step := -1
var action_controls: Array[Control] = []

func _ready():
 add_theme_constant_override("separation", 14)
 var head = add_row()
 make_button(head, "← 主题", func(): back_requested.emit())
 var heading = make_label("信号量 P / V · 临界区互斥", 26)
 heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 head.add_child(heading)
 present_button = make_button(head, "投屏大字", func(): presentation_requested.emit())
 add_child(make_label("把信号量想成发放许可的计数器。P 申请使用许可，V 归还许可并在有人排队时唤醒等待者。", 18, MUTED, true))

 var walkthrough = add_row()
 demo_start = make_button(walkthrough, "开始课堂示范", _toggle_demo)
 demo_hint = make_label("", 17, MUTED, true)
 demo_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 demo_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 walkthrough.add_child(demo_hint)
 demo_actions = add_row()
 demo_next = make_button(demo_actions, "", _advance_demo)
 var primary = demo_next.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
 primary.bg_color = Color("e4f3f0")
 primary.border_color = Color("8bc8bc")
 demo_next.add_theme_stylebox_override("normal", primary)

 manual = add_row()
 manual.add_child(make_label("选择进程", 17, MUTED))
 selection = OptionButton.new()
 for i in 3: selection.add_item("P%d" % (i + 1))
 manual.add_child(selection)
 action_controls.append(selection)
 action_controls.append(make_button(manual, "P · 申请许可", _p))
 action_controls.append(make_button(manual, "调度并进入", _resume))
 action_controls.append(make_button(manual, "V · 离开并释放", _v))
 action_controls.append(make_button(manual, "重置", _reset))
 for control in action_controls:
  control.custom_minimum_size.y = 42

 var overview = add_row()
 resource = make_tile(overview, 106)
 status = make_tile(overview, 106)
 queue_label = make_tile(overview, 106)
 _set_base_size(resource, 24)
 _set_base_size(status, 24)
 _set_base_size(queue_label, 23)
 var cards = add_row()
 for i in 3:
  var card = make_tile(cards, 80)
  _set_base_size(card, 20)
  process_labels.append(card)
 add_feedback()
 result = feedback
 _set_base_size(result, 20)

 var info_bar = add_row()
 make_button(info_bar, "P / V 规则与操作记录 ▾", func(): details.visible = not details.visible)
 details = VBoxContainer.new()
 details.add_theme_constant_override("separation", 8)
 add_child(details)
 details.add_child(make_label("P（申请）把 S 减 1。减完小于 0 时，进程进入阻塞队列。\nV（释放）把 S 加 1。加完不大于 0 时，唤醒队首进程。\nP 和 V 各自作为一个不可分割的操作执行。这里 S 为负数时，其绝对值就是阻塞队列里的人数。", 17, MUTED, true))
 history = make_label("", 16, MUTED, true)
 details.add_child(history)
 details.hide()
 _render()

func _set_base_size(label: Label, font_size: int):
 label_sizes[label] = font_size
 label.add_theme_font_size_override("font_size", font_size)

func set_presentation(active: bool):
 present_button.text = "退出投屏大字" if active else "投屏大字"
 update_reading_size(1.0 if active else 0.0)
 for label in [resource, status, queue_label]:
  label.custom_minimum_size.y = 124 if active else 106
  if active: label.add_theme_font_size_override("font_size", 34)
 for label in process_labels:
  label.custom_minimum_size.y = 96 if active else 80
  if active: label.add_theme_font_size_override("font_size", 27)
 if active:
  result.add_theme_font_size_override("font_size", 27)
  demo_hint.add_theme_font_size_override("font_size", 23)
 for control in action_controls + [demo_start, demo_next]:
  control.add_theme_font_size_override("font_size", 21 if active else 17)

func _p():
 model.p(selection.selected)
 _record()

func _v():
 model.v(selection.selected)
 _record()

func _resume():
 model.resume_process(selection.selected)
 _record()

func _reset():
 demo_step = -1
 _reset_model()

func _reset_model():
 model = Model.new()
 events.clear()
 selection.select(0)
 _render()

func _in_demo() -> bool:
 return demo_step >= 0 and demo_step < DEMO.size()

func _toggle_demo():
 if _in_demo():
  demo_step = -1
  _render()
 else:
  demo_step = 0
  _reset_model()

func _advance_demo():
 if not _in_demo(): return
 var current: Array = DEMO[demo_step]
 demo_step += 1
 selection.select(current[0])
 match current[1]:
  Action.REQUEST: _p()
  Action.ENTER: _resume()
  Action.RELEASE: _v()

func _record():
 events.append(model.message)
 if events.size() > 5: events.pop_front()
 _render()

func _render():
 var occupant: int = model.states.find("inside")
 var ready: int = model.states.find("ready")
 if occupant >= 0:
  show_tile(resource, "共享资源\nP%d 正在使用" % (occupant + 1), "active")
 elif ready >= 0:
  show_tile(resource, "共享资源\n许可已交给 P%d" % (ready + 1), "info")
 else:
  show_tile(resource, "共享资源\n空闲", "idle")
 var meaning = "还有 1 个许可" if model.value > 0 else "没有空闲许可"
 if model.value < 0: meaning = "%d 个进程正在等待" % -model.value
 show_tile(status, "信号量 S = %d\n%s" % [model.value, meaning], "info")
 var state_names = {"idle":"未申请", "inside":"正在使用资源", "blocked":"等待许可", "ready":"已唤醒 · 等待调度"}
 var tones = {"idle":"idle", "inside":"active", "blocked":"waiting", "ready":"info"}
 for i in model.states.size():
  var state = model.states[i]
  show_tile(process_labels[i], "P%d\n%s" % [i + 1, state_names[state]], tones[state])
 var waiting: Array[String] = []
 for pid in model.queue: waiting.append("P%d" % (pid + 1))
 var queue_text = "无等待进程" if waiting.is_empty() else "队首  " + " → ".join(waiting)
 show_tile(queue_label, "阻塞队列\n" + queue_text, "idle" if waiting.is_empty() else "waiting")
 result.text = model.message
 history.text = "最近操作\n" + "\n".join(events) if not events.is_empty() else ""
 manual.visible = not _in_demo()
 demo_actions.visible = _in_demo()
 if _in_demo():
  demo_start.text = "退出示范"
  demo_next.text = DEMO[demo_step][2]
  demo_hint.text = "第 %d / %d 步  %s" % [demo_step + 1, DEMO.size(), DEMO[demo_step][3]]
 elif demo_step == DEMO.size():
  demo_start.text = "重演课堂示范"
  demo_hint.text = "示范完成。P1 和 P2 轮流使用了同一个资源。你可以自由选择进程继续操作。"
 else:
  demo_start.text = "开始课堂示范"
  if ready >= 0:
   demo_hint.text = "P%d 已拿到许可。选择 P%d，再点「调度并进入」。" % [ready + 1, ready + 1]
  else:
   demo_hint.text = "从空闲状态开始，演示 P1 和 P2 怎样轮流使用同一个资源。"
