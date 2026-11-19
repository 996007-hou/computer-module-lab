extends Control
signal back_requested
signal semaphore_requested
const MATERIAL = preload("res://chapter_material.gd")
const LABS = {
 1: preload("res://read_file_lab.gd"),
 2: preload("res://process_states_lab.gd"),
 3: preload("res://fruit_sync_lab.gd"),
 8: preload("res://io_buffer_lab.gd"),
 9: preload("res://file_blocks_lab.gd")
}

var chapter := 1
var step := 0
var heading: Label
var question: Label
var diagram: Label
var detail: Label
var counter: Label
var previous: Button
var next: Button
var topic_choice: OptionButton
var context_label: Label
var quiz_box: VBoxContainer
var quiz_question: Label
var quiz_feedback: Label
var quiz_buttons: Array[Button] = []
var flow: HBoxContainer
var topic_index := 0
var semaphore_button: Button
var lab_mode: Button
var theory_mode: Button
var theory: VBoxContainer
var theory_scroll: ScrollContainer
var lab_scroll: ScrollContainer
var active_lab: Control
var page_margin: MarginContainer
var page_column: VBoxContainer
var reading_room := 0.0

const LESSONS = {
 1: {"title":"操作系统概述", "question":"打开一个文件时，操作系统做了什么？", "steps":[
  ["用户 → 应用程序", "用户在应用程序里选择文件。应用程序提出读取请求。"],
  ["应用程序 → 操作系统", "应用程序通过操作系统提供的接口请求访问；操作系统检查请求并协调资源。"],
  ["操作系统 → 存储设备 → 应用程序", "操作系统通过设备驱动等机制读取数据，再把结果交给应用程序。"]]},
 2: {"title":"进程、线程管理", "question":"进程等待输入时，状态如何变化？", "steps":[
  ["就绪", "进程具备运行条件，正在等待处理机。"],
  ["就绪 → 运行", "调度程序选中进程，处理机开始执行它。"],
  ["运行 → 阻塞", "进程请求输入并等待结果，暂时无法继续运行。"],
  ["阻塞 → 就绪", "输入完成后，进程重新具备运行条件；它仍需等待调度。"]]},
 3: {"title":"进程同步与通信", "question":"两个进程如何互斥地使用共享资源？", "steps":[
  ["资源空闲 · P1 等待 · P2 等待", "两者都要进入临界区，互斥规则要求同一时刻最多一个进入。"],
  ["P1 进入临界区 · P2 等待", "假设 P1 先获得互斥锁；P2 不能同时进入。"],
  ["P1 离开并释放锁 · P2 等待", "P1 完成共享数据的操作，并释放锁。"],
  ["P2 进入临界区", "P2 获得锁后进入；完成后也要释放锁。互斥并不自动保证公平。"]]},
 8: {"title":"I/O 设备管理", "question":"缓冲区如何帮助程序读取设备数据？", "steps":[
  ["程序请求读取 → 操作系统", "程序发出读取请求；操作系统协调对应设备。"],
  ["设备 → 缓冲区", "设备把数据送入内存中的缓冲区，用于暂存数据。"],
  ["缓冲区 → 程序", "操作系统将数据交给程序；缓冲区可缓解设备与程序速度不一致。"]]},
 9: {"title":"文件系统", "question":"通过路径查找文件需要经过什么？", "steps":[
  ["/", "从根目录开始查找示例路径 /课程/笔记.txt。"],
  ["/ → 课程", "在根目录中查找名为“课程”的目录项，再进入该目录。"],
  ["/ → 课程 → 笔记.txt", "在课程目录中查找文件目录项，找到后再由文件系统处理访问请求。"]]}
}

func _ready():
 var margin = MarginContainer.new()
 page_margin = margin
 theme = Theme.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["margin_left", "margin_right"]: margin.add_theme_constant_override(side, 52)
 for side in ["margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 38)
 add_child(margin)
 var column = VBoxContainer.new()
 page_column = column
 column.add_theme_constant_override("separation", 20)
 margin.add_child(column)
 var top = HBoxContainer.new()
 column.add_child(top)
 heading = Label.new()
 heading.add_theme_font_size_override("font_size", 25)
 heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 top.add_child(heading)
 var back = Button.new()
 back.text = "← 返回章节"
 back.pressed.connect(func(): back_requested.emit())
 top.add_child(back)
 var modes = HBoxContainer.new()
 modes.add_theme_constant_override("separation", 10)
 column.add_child(modes)
 lab_mode = Button.new()
 lab_mode.text = "动手实验"
 lab_mode.toggle_mode = true
 lab_mode.pressed.connect(func(): _show_mode(true))
 modes.add_child(lab_mode)
 theory_mode = Button.new()
 theory_mode.text = "知识点与练习"
 theory_mode.toggle_mode = true
 theory_mode.pressed.connect(func(): _show_mode(false))
 modes.add_child(theory_mode)
 semaphore_button = Button.new()
 semaphore_button.text = "信号量 P / V 实验 →"
 semaphore_button.pressed.connect(func(): semaphore_requested.emit())
 modes.add_child(semaphore_button)
 lab_scroll = ScrollContainer.new()
 lab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 lab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(lab_scroll)
 theory_scroll = ScrollContainer.new()
 theory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 theory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(theory_scroll)
 theory = VBoxContainer.new()
 theory.add_theme_constant_override("separation", 16)
 theory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 theory.size_flags_vertical = Control.SIZE_EXPAND_FILL
 theory_scroll.add_child(theory)
 var caption = Label.new()
 caption.text = "选择知识点，查看分步演示并尝试练习"
 caption.add_theme_color_override("font_color", Color("667788"))
 theory.add_child(caption)
 var selector = HBoxContainer.new()
 selector.add_theme_constant_override("separation", 12)
 theory.add_child(selector)
 var selector_label = Label.new()
 selector_label.text = "知识点"
 selector.add_child(selector_label)
 topic_choice = OptionButton.new()
 topic_choice.custom_minimum_size.x = 310
 topic_choice.item_selected.connect(_select_topic)
 selector.add_child(topic_choice)
 question = Label.new()
 question.add_theme_font_size_override("font_size", 21)
 theory.add_child(question)
 context_label = Label.new()
 context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 context_label.add_theme_color_override("font_color", Color("536575"))
 theory.add_child(context_label)
 var panel = PanelContainer.new()
 var box = StyleBoxFlat.new()
 box.bg_color = Color("ffffff")
 box.border_color = Color("dce4ec")
 box.set_border_width_all(1)
 box.set_corner_radius_all(12)
 box.set_content_margin_all(24)
 panel.add_theme_stylebox_override("panel", box)
 panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 theory.add_child(panel)
 var content = VBoxContainer.new()
 content.alignment = BoxContainer.ALIGNMENT_CENTER
 content.add_theme_constant_override("separation", 16)
 panel.add_child(content)
 flow = HBoxContainer.new()
 flow.add_theme_constant_override("separation", 10)
 content.add_child(flow)
 diagram = Label.new()
 diagram.add_theme_font_size_override("font_size", 22)
 diagram.add_theme_color_override("font_color", Color("216e68"))
 diagram.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 diagram.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(diagram)
 detail = Label.new()
 detail.add_theme_font_size_override("font_size", 17)
 detail.add_theme_color_override("font_color", Color("536575"))
 detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(detail)
 var controls = HBoxContainer.new()
 controls.add_theme_constant_override("separation", 12)
 theory.add_child(controls)
 previous = Button.new()
 previous.text = "← 上一步"
 previous.pressed.connect(func(): step -= 1; _render())
 controls.add_child(previous)
 next = Button.new()
 next.text = "下一步 →"
 next.pressed.connect(func(): step += 1; _render())
 controls.add_child(next)
 counter = Label.new()
 counter.add_theme_color_override("font_color", Color("667788"))
 controls.add_child(counter)
 quiz_box = VBoxContainer.new()
 quiz_box.add_theme_constant_override("separation", 8)
 theory.add_child(quiz_box)
 quiz_question = Label.new()
 quiz_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 quiz_box.add_child(quiz_question)
 var answers = HBoxContainer.new()
 answers.add_theme_constant_override("separation", 8)
 quiz_box.add_child(answers)
 for i in 3:
  var answer = Button.new()
  answer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  answer.pressed.connect(_check_answer.bind(i))
  answers.add_child(answer)
  quiz_buttons.append(answer)
 quiz_feedback = Label.new()
 quiz_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 quiz_feedback.add_theme_color_override("font_color", Color("216e68"))
 quiz_box.add_child(quiz_feedback)
 _populate_topics()
 _render()
 _open_lab()
 resized.connect(_update_reading_layout)
 get_window().size_changed.connect(_update_reading_layout)
 _update_reading_layout()

func show_chapter(value: int):
 chapter = value
 step = 0
 topic_index = 0
 if is_node_ready():
  _populate_topics()
  _render()
  _open_lab()

func _open_lab():
 if is_instance_valid(active_lab):
  lab_scroll.remove_child(active_lab)
  active_lab.queue_free()
 active_lab = LABS[chapter].new()
 active_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 lab_scroll.add_child(active_lab)
 active_lab.update_reading_size(reading_room)
 lab_scroll.set_deferred("scroll_vertical", 0)
 _show_mode(true)

func _show_mode(interactive: bool):
 lab_scroll.visible = interactive
 theory.visible = not interactive
 theory_scroll.visible = not interactive
 lab_mode.set_pressed_no_signal(interactive)
 theory_mode.set_pressed_no_signal(not interactive)

func _update_reading_layout():
 var window_size = get_window().size
 reading_room = clampf(minf((window_size.x - 1200.0) / 500.0, (window_size.y - 720.0) / 160.0), 0.0, 1.0)
 var side_padding = maxi(44, roundi((size.x - 1620.0) / 2.0))
 for side in ["margin_left", "margin_right"]:
  page_margin.add_theme_constant_override(side, side_padding)
 for side in ["margin_top", "margin_bottom"]:
  page_margin.add_theme_constant_override(side, 30 + roundi(reading_room * 12))
 page_column.add_theme_constant_override("separation", 16 + roundi(reading_room * 8))
 theme.default_font_size = 16 + roundi(reading_room * 3)
 heading.add_theme_font_size_override("font_size", 25 + roundi(reading_room * 5))
 question.add_theme_font_size_override("font_size", 21 + roundi(reading_room * 4))
 diagram.add_theme_font_size_override("font_size", 22 + roundi(reading_room * 4))
 detail.add_theme_font_size_override("font_size", 17 + roundi(reading_room * 3))
 for panel in flow.get_children():
  panel.get_child(0).add_theme_font_size_override("font_size", 14 + roundi(reading_room * 2))
 if is_instance_valid(active_lab):
  active_lab.update_reading_size(reading_room)

func _populate_topics():
 topic_choice.clear()
 if MATERIAL.CONTENT.has(chapter):
  for topic in MATERIAL.CONTENT[chapter]: topic_choice.add_item(topic.name)
 else:
  topic_choice.add_item(LESSONS[chapter].title + "入门")
 topic_choice.select(topic_index)
 quiz_feedback.text = ""

func _select_topic(index: int):
 topic_index = index
 step = 0
 quiz_feedback.text = ""
 _render()

func _check_answer(index: int):
 var topic = MATERIAL.CONTENT[chapter][topic_index]
 quiz_feedback.text = ("回答正确。" if index == topic.answer else "再想一想。") + topic.why

func _render():
 var lesson = LESSONS[chapter]
 var topic: Dictionary = MATERIAL.CONTENT[chapter][topic_index] if MATERIAL.CONTENT.has(chapter) else {}
 var steps: Array = topic.get("steps", lesson.steps)
 step = clampi(step, 0, steps.size() - 1)
 for child in flow.get_children():
  flow.remove_child(child)
  child.queue_free()
 for i in steps.size():
  var node = PanelContainer.new()
  node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var style = StyleBoxFlat.new()
  style.bg_color = Color("e4f3f0") if i == step else Color("f3f5f8")
  style.border_color = Color("9bcfc3") if i == step else Color("e0e6ec")
  style.set_border_width_all(1)
  style.set_corner_radius_all(8)
  style.set_content_margin_all(12)
  node.add_theme_stylebox_override("panel", style)
  var stage = Label.new()
  stage.text = "%d  %s" % [i + 1, steps[i][0]]
  stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  stage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  stage.add_theme_font_size_override("font_size", 14 + roundi(reading_room * 2))
  stage.add_theme_color_override("font_color", Color("216e68") if i == step else Color("667788"))
  node.add_child(stage)
  flow.add_child(node)
 heading.text = "第 %d 章  %s" % [chapter, lesson.title]
 semaphore_button.visible = chapter == 3
 question.text = topic.get("question", lesson.question)
 context_label.text = topic.get("context", "通过下面的步骤观察这个例子。")
 diagram.text = steps[step][0]
 detail.text = steps[step][1]
 counter.text = "步骤 %d / %d" % [step + 1, steps.size()]
 previous.disabled = step == 0
 next.disabled = step == steps.size() - 1
 quiz_box.visible = not topic.is_empty()
 if not topic.is_empty():
  quiz_question.text = "小练习：" + topic.quiz
  for i in quiz_buttons.size(): quiz_buttons[i].text = topic.options[i]
