extends "res://chapter_lab.gd"

enum Action { DISPATCH, EXECUTE, EXPIRE, BLOCK, FINISH_IO }

const GUIDE = [
 [Action.DISPATCH, "先调度队首的 P1，观察它从就绪队列移到 CPU。"],
 [Action.EXECUTE, "让 P1 执行一条指令，观察下一条指令的编号从 0 变成 1。"],
 [Action.EXPIRE, "让 P1 的时间片到期。它会回到就绪队尾，P2 排到第一位。"],
 [Action.DISPATCH, "现在 CPU 空闲，P2 在队首。点击「调度 P2」，让它进入 CPU。"],
 [Action.EXECUTE, "P2 已获得 CPU。让它执行一条指令，观察执行位置发生变化。"],
 [Action.BLOCK, "让 P2 发起 I/O。它会去阻塞队列，CPU 空出来。"],
 [Action.DISPATCH, "再次调度 P1。它会从第 1 号指令继续。"],
 [Action.FINISH_IO, "报告 P2 的 I/O 完成。观察 P2 回到就绪队列，此时 P1 仍在 CPU 上。"]
]

var ready_queue: Array[int] = []
var blocked_queue: Array[int] = []
var running := -1
var instructions: Array[int] = []
var dispatch_counts: Array[int] = []
var lane_tokens: Array[Array] = []
var lane_placeholders: Array[Label] = []
var pcb_rows: Array[Label] = []
var action_buttons: Array[Button] = []
var action_handlers: Array[Callable] = []
var guide_button: Button
var guide_text: Label
var next_hint: Label
var recommended_style: StyleBoxFlat
var guide_step := -1

func _ready():
 build_intro("谁在运行，谁在等待？", "时间片是一轮调度允许进程连续占用 CPU 的最长时间。让它到期，观察原进程如何让出 CPU。")
 var onboarding = add_row()
 guide_button = make_button(onboarding, "开始新手引导", toggle_guide)
 guide_text = make_label("", 15, MUTED, true)
 guide_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 guide_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 onboarding.add_child(guide_text)
 var actions = add_row()
 action_handlers = [dispatch, execute_instruction, expire_slice, block_for_io, finish_io]
 var titles = ["调度队首", "执行一条指令", "时间片到期", "发起 I/O", "报告 I/O 完成"]
 for action in titles.size():
  action_buttons.append(make_button(actions, titles[action], perform_action.bind(action)))
 recommended_style = action_buttons[Action.DISPATCH].get_theme_stylebox("normal").duplicate()
 recommended_style.bg_color = Color("dfeeea")
 recommended_style.border_color = Color("6ba69b")
 next_hint = make_label("", 15, GREEN, true)
 add_child(next_hint)
 make_button(actions, "重置", reset)
 var lanes = add_row()
 add_lane(lanes, "就绪队列", "info")
 add_lane(lanes, "CPU · 运行位", "active")
 add_lane(lanes, "阻塞队列", "waiting")
 add_feedback()
 add_child(make_label("进程控制块（PCB）", 17))
 add_child(make_label("PCB 记录进程状态和恢复执行所需的信息。程序计数器记录下一条指令的位置，实验用从 0 开始的指令编号表示。", 14, MUTED, true))
 var pcbs = add_row()
 for i in 2: pcb_rows.append(make_tile(pcbs, 86))
 reset()

func reset():
 if guide_step >= 0: guide_step = 0
 ready_queue = [0, 1]
 blocked_queue = []
 running = -1
 instructions = [0, 0]
 dispatch_counts = [0, 0]
 render("两个进程都已就绪。CPU 等待调度。")

func toggle_guide():
 if is_guided():
  guide_step = -1
  update_actions()
 else:
  guide_step = 0
  reset()

func is_guided() -> bool:
 return guide_step >= 0 and guide_step < GUIDE.size()

func perform_action(action: int):
 if action_buttons[action].disabled: return
 if is_guided(): guide_step += 1
 action_handlers[action].call()

func dispatch():
 if running != -1:
  render("CPU 正在运行 %s。等它让出 CPU 后再调度。" % process_name(running))
 elif ready_queue.is_empty():
  render("就绪队列为空。可以报告一个 I/O 完成事件来唤醒进程。")
 else:
  running = ready_queue.pop_front()
  dispatch_counts[running] += 1
  render("%s 获得 CPU，从第 %d 号指令继续。" % [process_name(running), instructions[running]])

func execute_instruction():
 if running == -1:
  render("CPU 当前空闲，先调度一个进程。")
  return
 instructions[running] += 1
 render("%s 执行一条指令，下一条指令编号变为 %d。" % [process_name(running), instructions[running]])

func expire_slice():
 if running == -1:
  render("当前没有运行中的进程。")
  return
 var pid = running
 ready_queue.append(pid)
 running = -1
 render("%s 时间片用完，执行现场保存在 PCB 中，进程进入就绪队尾。" % process_name(pid))

func block_for_io():
 if running == -1:
  render("先调度一个进程，再让它发起需要等待的 I/O。")
  return
 var pid = running
 blocked_queue.append(pid)
 running = -1
 render("%s 等待 I/O，进入阻塞队列。CPU 可以调度就绪队列中的其他进程。" % process_name(pid))

func finish_io():
 if blocked_queue.is_empty():
  render("当前没有等待 I/O 的进程。")
  return
 var pid: int = blocked_queue.pop_front()
 ready_queue.append(pid)
 render("%s 的 I/O 完成，进入就绪队尾。它还需要被调度。" % process_name(pid))

func render(message: String):
 show_lane(0, ready_queue)
 show_lane(1, [] if running == -1 else [running])
 show_lane(2, blocked_queue)
 feedback.text = message
 for pid in pcb_rows.size():
  var state = "运行" if pid == running else ("阻塞" if pid in blocked_queue else "就绪")
  var location = "CPU 上的下一条指令" if pid == running else "PCB 保存的下一条指令"
  show_tile(pcb_rows[pid], "%s  ·  %s  ·  获得 CPU %d 次\n%s %d" % [process_name(pid), state, dispatch_counts[pid], location, instructions[pid]])
 update_actions()

func update_actions():
 var can_dispatch = running == -1 and not ready_queue.is_empty()
 var has_running = running != -1
 var enabled = [can_dispatch, has_running, has_running, has_running, not blocked_queue.is_empty()]
 var dispatch_button = action_buttons[Action.DISPATCH]
 dispatch_button.text = "调度 %s" % process_name(ready_queue[0]) if can_dispatch else "调度队首"

 var recommended = -1
 if is_guided():
  recommended = GUIDE[guide_step][0]
  guide_button.text = "退出引导"
  guide_text.text = "第 %d / %d 步  %s" % [guide_step + 1, GUIDE.size(), GUIDE[guide_step][1]]
  next_hint.hide()
 else:
  guide_button.text = "重演新手引导" if guide_step == GUIDE.size() else "开始新手引导"
  guide_text.text = "引导完成。P1 和 P2 都运行过，你可以继续自由操作。" if guide_step == GUIDE.size() else "从头演示一次 P1 和 P2 换班，跟着高亮按钮操作。"
  next_hint.show()
  if can_dispatch:
   recommended = Action.DISPATCH
   next_hint.text = "CPU 空闲，%s 在就绪队首。下一步：点击「%s」。" % [process_name(ready_queue[0]), dispatch_button.text]
  elif has_running:
   next_hint.text = "%s 正在运行。可以执行指令、让它的时间片到期，或让它等待 I/O。" % process_name(running)
  else:
   recommended = Action.FINISH_IO
   next_hint.text = "CPU 空闲且就绪队列为空。报告 I/O 完成，让一个进程重新就绪。"

 for action in action_buttons.size():
  var button = action_buttons[action]
  button.disabled = not enabled[action] or (is_guided() and action != recommended)
  if action == recommended:
   button.add_theme_stylebox_override("normal", recommended_style)
  else:
   button.remove_theme_stylebox_override("normal")

func process_name(pid: int) -> String:
 return "P%d" % (pid + 1)

func add_lane(row: HBoxContainer, title: String, tone: String):
 var panel = PanelContainer.new()
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_theme_stylebox_override("panel", tile_style(tone))
 row.add_child(panel)
 var lane = VBoxContainer.new()
 lane.add_theme_constant_override("separation", 8)
 panel.add_child(lane)
 lane.add_child(make_label(title, 16))
 var tokens = add_row(lane)
 var empty = make_label("空", 15, MUTED)
 empty.custom_minimum_size.y = 42
 empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 tokens.add_child(empty)
 lane_placeholders.append(empty)
 var labels: Array[Label] = []
 for i in 2:
  var token = make_tile(tokens, 42)
  token.size_flags_horizontal = Control.SIZE_FILL
  token.custom_minimum_size.x = 64
  labels.append(token)
 lane_tokens.append(labels)

func show_lane(index: int, queue: Array):
 lane_placeholders[index].visible = queue.is_empty()
 for i in lane_tokens[index].size():
  var token: Label = lane_tokens[index][i]
  token.visible = i < queue.size()
  if token.visible:
   show_tile(token, process_name(queue[i]))
