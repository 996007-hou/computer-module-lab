extends "res://chapter_lab.gd"

enum Action { PUT_APPLE, PUT_ORANGE, TAKE_APPLE, TAKE_ORANGE }

const FRUITS = ["苹果", "橘子"]
const GUIDE = [
 [Action.TAKE_APPLE, "先点「取苹果」。盘子为空，苹果消费者会进入等待。"],
 [Action.PUT_ORANGE, "点「放橘子」。橘子可以被取走，苹果消费者仍等待苹果。"],
 [Action.TAKE_ORANGE, "点「取橘子」。只有橘子消费者能取，盘子因此空出来。"],
 [Action.PUT_APPLE, "点「放苹果」。等苹果的消费者会亮起来，显示「已唤醒 · 可取」。"],
 [Action.TAKE_APPLE, "点「取苹果」。苹果消费者完成取用，盘子空出一个位置。"]
]
var plate := -1
var waiting: Array[bool] = [false, false]
var producer_ticket := -1
var last_taken := -1
var taken_counts: Array[int] = [0, 0]
var consumer_cards: Array[Label] = []
var plate_tile: Label
var plate_picture: Control
var producer_tile: Label
var permits: Label
var guide_button: Button
var guide_text: Label
var action_buttons: Array[Button] = []
var recommended_style: StyleBoxFlat
var guide_step := -1

func _ready():
 build_intro("水果盘怎么协调三个进程？", "生产者往单格盘里放水果。苹果消费者只取苹果，橘子消费者只取橘子。")
 var onboarding = add_row()
 guide_button = make_button(onboarding, "开始新手引导", toggle_guide)
 guide_text = make_label("", 15, MUTED, true)
 guide_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 guide_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 onboarding.add_child(guide_text)
 var controls = add_row()
 var titles = ["放苹果", "放橘子", "取苹果", "取橘子"]
 for action in titles.size():
  action_buttons.append(make_button(controls, titles[action], perform_action.bind(action)))
 recommended_style = action_buttons[Action.PUT_APPLE].get_theme_stylebox("normal").duplicate()
 recommended_style.bg_color = Color("dfeeea")
 recommended_style.border_color = Color("6ba69b")
 make_button(controls, "重置", reset)
 var row = add_row()
 producer_tile = make_tile(row, 126)
 var plate_panel = PanelContainer.new()
 plate_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 plate_panel.add_theme_stylebox_override("panel", tile_style("info"))
 row.add_child(plate_panel)
 var plate_contents = VBoxContainer.new()
 plate_contents.alignment = BoxContainer.ALIGNMENT_CENTER
 plate_panel.add_child(plate_contents)
 plate_picture = Control.new()
 plate_picture.custom_minimum_size.y = 56
 plate_picture.draw.connect(draw_plate)
 plate_picture.resized.connect(plate_picture.queue_redraw)
 plate_contents.add_child(plate_picture)
 plate_tile = make_label("", 16)
 plate_tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 plate_contents.add_child(plate_tile)
 for i in FRUITS.size(): consumer_cards.append(make_tile(row, 126))
 permits = make_label("", 16, INK)
 add_child(permits)
 add_feedback()
 add_child(make_label("同步控制谁要等谁。放水果的人等空位，两位消费者分别等自己的水果。点击一次放或取，表示持有互斥锁完成一次访问。", 15, MUTED, true))
 reset()

func reset():
 if guide_step >= 0: guide_step = 0
 plate = -1
 waiting = [false, false]
 producer_ticket = -1
 last_taken = -1
 taken_counts = [0, 0]
 render("盘子目前是空的。先点「取苹果」，看看苹果消费者为什么要等。")

func is_guided() -> bool:
 return guide_step >= 0 and guide_step < GUIDE.size()

func toggle_guide():
 if is_guided():
  guide_step = -1
  update_guide()
 else:
  guide_step = 0
  reset()

func perform_action(action: int):
 if action_buttons[action].disabled: return
 if is_guided(): guide_step += 1
 if action == Action.PUT_APPLE or action == Action.PUT_ORANGE:
  put_fruit(action - Action.PUT_APPLE)
 else:
  take_fruit(action - Action.TAKE_APPLE)

func put_fruit(fruit: int):
 last_taken = -1
 if producer_ticket != -1 and producer_ticket != fruit:
  render("生产者还有一个放%s的请求，请继续该请求。" % FRUITS[producer_ticket])
  return
 if plate != -1:
  producer_ticket = fruit
  render("盘子里已有%s。放%s的进程等待空位。" % [FRUITS[plate], FRUITS[fruit]])
  return
 plate = fruit
 producer_ticket = -1
 var suffix = "被唤醒，可以继续取。" if waiting[fruit] else "现在可以取用。"
 render("盘子放入了%s。%s消费者%s" % [FRUITS[fruit], FRUITS[fruit], suffix])

func take_fruit(fruit: int):
 last_taken = -1
 if plate != fruit:
  waiting[fruit] = true
  render("盘中没有%s。该消费者等待，盘子的内容保持不变。" % FRUITS[fruit])
  return
 plate = -1
 waiting[fruit] = false
 last_taken = fruit
 taken_counts[fruit] += 1
 var suffix = "等待空位的生产者被唤醒，可以继续放%s。" % FRUITS[producer_ticket] if producer_ticket != -1 else "盘子现在有一个空位。"
 render("%s消费者取走了%s。%s" % [FRUITS[fruit], FRUITS[fruit], suffix])

func render(message: String):
 var producer_status = "可选择水果"
 var producer_tone = "idle"
 if producer_ticket != -1:
  producer_status = "已唤醒 · 可放%s" % FRUITS[producer_ticket] if plate == -1 else "等待空位 · %s" % FRUITS[producer_ticket]
  producer_tone = "active" if plate == -1 else "waiting"
 show_tile(producer_tile, "生产者\n" + producer_status, producer_tone)
 plate_tile.text = "共享盘子 · " + ("空位" if plate == -1 else FRUITS[plate])
 plate_picture.queue_redraw()
 for i in consumer_cards.size():
  var status = "未提交取用请求"
  var tone = "idle"
  if plate == i:
   status = "已唤醒 · 可取" if waiting[i] else "可取%s" % FRUITS[i]
   tone = "active"
  elif last_taken == i:
   status = "刚取到%s" % FRUITS[i]
   tone = "active"
  elif waiting[i]:
   status = "阻塞 · 等待%s" % FRUITS[i]
   tone = "waiting"
  show_tile(consumer_cards[i], "%s消费者\n%s\n已取 %d 次" % [FRUITS[i], status, taken_counts[i]], tone)
 permits.text = "盘中状态    空位 %d    苹果 %d    橘子 %d" % [int(plate == -1), int(plate == 0), int(plate == 1)]
 feedback.text = message
 update_guide()

func update_guide():
 var recommended = -1
 if is_guided():
  recommended = GUIDE[guide_step][0]
  guide_button.text = "退出引导"
  guide_text.text = "第 %d / %d 步  %s" % [guide_step + 1, GUIDE.size(), GUIDE[guide_step][1]]
 else:
  guide_button.text = "重演新手引导" if guide_step == GUIDE.size() else "开始新手引导"
  guide_text.text = "引导完成。两位消费者都取到了各自的水果，可以继续自由操作。" if guide_step == GUIDE.size() else "从空盘开始，观察苹果消费者如何等待、被唤醒，再取走苹果。"
  if plate != -1:
   recommended = Action.TAKE_APPLE + plate
  elif producer_ticket != -1:
   recommended = Action.PUT_APPLE + producer_ticket
  elif waiting[0] or waiting[1]:
   recommended = Action.PUT_APPLE if waiting[0] else Action.PUT_ORANGE
 for action in action_buttons.size():
  var button = action_buttons[action]
  button.disabled = is_guided() and action != recommended
  if action == recommended:
   button.add_theme_stylebox_override("normal", recommended_style)
  else:
   button.remove_theme_stylebox_override("normal")

func draw_plate():
 var center = Vector2(plate_picture.size.x / 2.0, 45)
 plate_picture.draw_set_transform(center, 0, Vector2(1.0, 0.25))
 plate_picture.draw_circle(Vector2.ZERO, 42, Color("b9cce1"), true, -1.0, true)
 plate_picture.draw_circle(Vector2(0, -4), 37, Color("ffffff"), true, -1.0, true)
 plate_picture.draw_set_transform(Vector2.ZERO)
 if plate == -1: return
 var fruit_center = center + Vector2(0, -18)
 if plate == 0:
  plate_picture.draw_circle(fruit_center + Vector2(-6, 0), 13, Color("b7424d"), true, -1.0, true)
  plate_picture.draw_circle(fruit_center + Vector2(6, 0), 13, Color("b7424d"), true, -1.0, true)
  plate_picture.draw_line(fruit_center + Vector2(0, -9), fruit_center + Vector2(1, -22), Color("73442f"), 2.5, true)
 else:
  plate_picture.draw_circle(fruit_center, 17, Color("dd7824"), true, -1.0, true)
 plate_picture.draw_line(fruit_center + Vector2(0, -16), fruit_center + Vector2(8, -21), Color("417555"), 4, true)
