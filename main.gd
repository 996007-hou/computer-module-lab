extends Control
const MemoryView = preload("res://memory_view.gd")
const ModuleCard = preload("res://module_card.gd")
const ModuleSlot = preload("res://module_slot.gd")
const PagingLab = preload("res://paging.gd")
const ScheduleLab = preload("res://schedule.gd")
const BankerLab = preload("res://banker.gd")
const ReplacementLab = preload("res://replacement.gd")
const ChapterIntro = preload("res://chapter_intro.gd")
const SemaphoreLab = preload("res://semaphore_lab.gd")
const AddressLab = preload("res://address_lab.gd")
var segments: Array = []
var steps: Array = []
var step_index := 0
var running := false
var counter := 1
var layout_input: LineEdit
var size_input: LineEdit
var mode: OptionButton
var unit_choice: OptionButton
var note: Label
var result: Label
var view: Control
var timer: Timer
var play_button: Button
var comparison: Label
var font: SystemFont
var preset: OptionButton
var knowledge: Label
var stats: Label
var segments_text: Label
var phase: Label
var module_state := {"program": false, "os": false, "memory": false, "process": false, "cpu": false, "resource": false, "storage": false}
var module_slots := {}
var module_buttons := {}
var module_flights: Array = []
var module_generation := 0
var module_hint: Label
var experiment: Control
var experiment_container: Control
var empty_hint: Control
var settings_panel: Control
var comparison_panel: Control
var home_screen: Control
var chapter_screen: Control
var chapter_intro: Control
var workspace_screen: Control
var library_scroll: ScrollContainer
var workspace_heading: HBoxContainer
var workspace_slots: HBoxContainer
var semaphore_presentation := false
var topic_panel: Control
var topic_open := false
var guide: Label
var paging_container: Control
var paging_lab: Control
var selected_topic := "allocation"
var schedule_container: Control
var schedule_lab: Control
var allocation_topic: Button
var paging_topic: Button
var schedule_topic: Button
var banker_topic: Button
var banker_container: Control
var banker_lab: Control
var replacement_topic: Button
var replacement_container: Control
var replacement_lab: Control
var semaphore_topic: Button
var semaphore_container: Control
var semaphore_lab: Control
var address_topic: Button
var address_container: ScrollContainer
var address_lab: Control
var windowed_mode := Window.MODE_WINDOWED

func _ready():
 _fit_window_to_screen()
 font = SystemFont.new()
 font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei"])
 var theme = Theme.new()
 theme.default_font = font
 theme.default_font_size = 16
 theme.set_color("font_color", "Label", Color("263342"))
 theme.set_color("font_color", "Button", Color("263342"))
 theme.set_color("font_hover_color", "Button", Color("244c78"))
 theme.set_color("font_pressed_color", "Button", Color("244c78"))
 theme.set_color("font_focus_color", "Button", Color("244c78"))
 theme.set_color("font_hover_pressed_color", "Button", Color("244c78"))
 theme.set_color("font_disabled_color", "Button", Color("536575"))
 theme.set_color("font_color", "LineEdit", Color("263342"))
 theme.set_color("font_placeholder_color", "LineEdit", Color("536575"))
 theme.set_color("font_uneditable_color", "LineEdit", Color("536575"))
 theme.set_color("font_selected_color", "LineEdit", Color("263342"))
 theme.set_color("selection_color", "LineEdit", Color("cfe0f3"))
 theme.set_color("caret_color", "LineEdit", Color("263342"))
 theme.set_stylebox("normal", "Button", style("ffffff", "d8dee7", 8, 1, 12))
 theme.set_stylebox("hover", "Button", style("eef4fa", "9cb5cc", 8, 1, 12))
 theme.set_stylebox("pressed", "Button", style("e1ebf5", "9cb5cc", 8, 1, 12))
 theme.set_stylebox("focus", "Button", style("00000000", "477ba8", 8, 2, 12))
 theme.set_stylebox("disabled", "Button", style("f0f2f5", "e1e6eb", 8, 1, 12))
 theme.set_stylebox("normal", "LineEdit", style("ffffff", "d8dee7", 7, 1, 10))
 theme.set_stylebox("focus", "LineEdit", style("ffffff", "5989b0", 7, 2, 10))
 theme.set_stylebox("read_only", "LineEdit", style("f0f2f5", "d8dee7", 7, 1, 10))
 self.theme = theme
 var bg = ColorRect.new()
 bg.color = Color("f7f8fa")
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 home_screen = _build_home()
 add_child(home_screen)
 chapter_screen = _build_chapters()
 add_child(chapter_screen)
 chapter_intro = ChapterIntro.new()
 add_child(chapter_intro)
 chapter_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 chapter_intro.back_requested.connect(_show_chapters)
 chapter_intro.semaphore_requested.connect(_open_semaphore)
 chapter_intro.visible = false
 var outer = margin_box(30, 23)
 workspace_screen = outer
 outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(outer)
 var root = VBoxContainer.new()
 root.add_theme_constant_override("separation", 18)
 outer.add_child(root)
 var header = HBoxContainer.new()
 root.add_child(header)
 var header_left = VBoxContainer.new()
 header_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(header_left)
 header_left.add_child(label("计算机模块实验室", 25, "263342"))
 header_left.add_child(label("组合模块，理解它们如何协同工作", 14, "667788"))
 button("← 返回章节", header, _show_chapters)
 button("返回首页", header, _show_home)
 var reset_modules = button("清空组合", header, _clear_modules)
 reset_modules.tooltip_text = "移除所有模块，重新组合"
 var body = HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation", 24)
 root.add_child(body)
 library_scroll = ScrollContainer.new()
 library_scroll.custom_minimum_size.x = 230
 library_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 library_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 body.add_child(library_scroll)
 var library = VBoxContainer.new()
 library.custom_minimum_size.x = 210
 library.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 library.add_theme_constant_override("separation", 12)
 library_scroll.add_child(library)
 library.add_child(label("模块库", 19, "263342"))
 var intro = label("点击模块，加入右侧工作区", 13, "667788")
 intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 library.add_child(intro)
 for item in [["program", "程序", "提出内存申请"], ["os", "操作系统", "管理系统资源"], ["memory", "内存", "提供存储空间"], ["process", "进程", "等待资源与执行"], ["cpu", "CPU", "执行进程"], ["resource", "资源", "供进程申请"], ["storage", "外存", "存放未驻留页面"]]:
  var b = Button.new()
  b.set_script(ModuleCard)
  b.module_id = item[0]
  b.module_name = item[1]
  b.text = item[1] + "     ＋\n" + item[2]
  b.custom_minimum_size = Vector2(200, 58)
  b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  var id: String = item[0]
  b.pressed.connect(func(): _add_module(id))
  library.add_child(b)
  module_buttons[id] = b
 library.add_child(spacer(8))
 var quick = button("一键组合示例", library, _add_example)
 quick.tooltip_text = "添加程序、操作系统和内存三个模块"
 var quick_schedule = button("组合调度模块", library, _add_schedule_example)
 quick_schedule.tooltip_text = "添加进程、操作系统和 CPU 模块"
 var quick_banker = button("组合死锁模块", library, _add_banker_example)
 quick_banker.tooltip_text = "添加进程、操作系统和资源模块"
 var main = VBoxContainer.new()
 main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 main.add_theme_constant_override("separation", 12)
 body.add_child(main)
 var section = HBoxContainer.new()
 workspace_heading = section
 main.add_child(section)
 var heading = label("组合工作区", 19, "263342")
 heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 section.add_child(heading)
 module_hint = label("把三个模块放进工作区", 13, "667788")
 section.add_child(module_hint)
 var slots = HBoxContainer.new()
 workspace_slots = slots
 slots.add_theme_constant_override("separation", 12)
 main.add_child(slots)
 for item in [["program", "程序"], ["os", "操作系统"], ["memory", "内存"], ["process", "进程"], ["cpu", "CPU"], ["resource", "资源"], ["storage", "外存"]]:
  var slot = PanelContainer.new()
  slot.set_script(ModuleSlot)
  slots.add_child(slot)
  slot.setup(item[0], item[1])
  slot.module_added.connect(_add_module)
  slot.module_removed.connect(_remove_module)
  module_slots[item[0]] = slot
 empty_hint = panel("ffffff", "e0e5eb")
 empty_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
 main.add_child(empty_hint)
 var empty_box = VBoxContainer.new()
 empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
 empty_hint.add_child(empty_box)
 var empty_title = label("组合模块，开始探索", 22, "263342")
 empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 empty_box.add_child(empty_title)
 var empty_text = label("程序 + 操作系统 + 内存 → 内存管理\n进程 + 操作系统 + CPU → 处理机调度\n进程 + 操作系统 + 资源 → 信号量 / 银行家算法\n进程 + 操作系统 + 内存 + 外存 → 页面置换", 15, "667788")
 empty_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 empty_box.add_child(empty_text)
 topic_panel = panel("ffffff", "e0e5eb")
 topic_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 main.add_child(topic_panel)
 var topic_margin = margin_box(28, 24)
 topic_panel.add_child(topic_margin)
 var topic_box = VBoxContainer.new()
 topic_box.alignment = BoxContainer.ALIGNMENT_CENTER
 topic_box.add_theme_constant_override("separation", 14)
 topic_margin.add_child(topic_box)
 topic_box.add_child(label("组合完成 · 选择一个问题", 22, "263342"))
 var link_text = label("选择模块后，系统会显示可学习的问题。", 15, "536575")
 link_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 topic_box.add_child(link_text)
 topic_box.add_child(spacer(8))
 allocation_topic = button("内存分配   ·   第 6 章  →", topic_box, _start_experiment)
 allocation_topic.custom_minimum_size = Vector2(300, 48)
 allocation_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 paging_topic = button("基本分页   ·   第 6 章  →", topic_box, _start_paging)
 paging_topic.custom_minimum_size = Vector2(300, 48)
 paging_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 address_topic = button("地址转换图解 · 页、块、段  →", topic_box, _start_address_lab)
 address_topic.custom_minimum_size = Vector2(300, 48)
 address_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 schedule_topic = button("处理机调度   ·   第 4 章  →", topic_box, _start_schedule)
 schedule_topic.custom_minimum_size = Vector2(300, 48)
 schedule_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 banker_topic = button("银行家算法   ·   第 5 章  →", topic_box, _start_banker)
 banker_topic.custom_minimum_size = Vector2(300, 48)
 banker_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 semaphore_topic = button("信号量 P / V   ·   第 3 章  →", topic_box, _start_semaphore)
 semaphore_topic.custom_minimum_size = Vector2(300, 48)
 semaphore_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 replacement_topic = button("页面置换   ·   第 7 章  →", topic_box, _start_replacement)
 replacement_topic.custom_minimum_size = Vector2(300, 48)
 replacement_topic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 experiment_container = ScrollContainer.new()
 experiment_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 experiment_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 experiment_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(experiment_container)
 experiment = VBoxContainer.new()
 experiment.add_theme_constant_override("separation", 12)
 experiment.size_flags_vertical = Control.SIZE_EXPAND_FILL
 experiment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 experiment_container.add_child(experiment)
 var line = HBoxContainer.new()
 line.add_theme_constant_override("separation", 10)
 experiment.add_child(line)
 button("← 主题", line, _back_to_topics)
 line.add_child(label("内存分配", 19, "263342"))
 line.add_child(label("程序大小", 14, "536575"))
 size_input = LineEdit.new()
 size_input.text = "180"
 size_input.custom_minimum_size = Vector2(88, 38)
 line.add_child(size_input)
 unit_choice = OptionButton.new()
 unit_choice.add_item("MB")
 unit_choice.add_item("KB")
 unit_choice.tooltip_text = "切换单位会以新单位解释当前数值，不自动换算。"
 line.add_child(unit_choice)
 mode = OptionButton.new()
 mode.custom_minimum_size = Vector2(185, 38)
 for text in ["首次适应", "最佳适应", "最坏适应"]: mode.add_item(text)
 line.add_child(mode)
 var flexible = Control.new()
 flexible.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 line.add_child(flexible)
 button("参数 ▾", line, _toggle_settings)
 button("算法对比 ▾", line, _toggle_comparison)
 settings_panel = HBoxContainer.new()
 settings_panel.add_theme_constant_override("separation", 10)
 experiment.add_child(settings_panel)
 settings_panel.add_child(label("场景", 14, "536575"))
 preset = OptionButton.new()
 for text in ["算法选择对比", "外部碎片", "精确匹配", "回收与合并", "课堂：0.1 KB 碎片"]: preset.add_item(text)
 settings_panel.add_child(preset)
 settings_panel.add_child(label("分区（正数空闲 / 负数占用）", 14, "536575"))
 layout_input = LineEdit.new()
 layout_input.text = "100, -40, 500, -40, 200"
 layout_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 settings_panel.add_child(layout_input)
 button("紧凑", settings_panel, _compact)
 settings_panel.visible = false
 comparison_panel = VBoxContainer.new()
 experiment.add_child(comparison_panel)
 knowledge = label("", 14, "536575")
 comparison_panel.add_child(knowledge)
 comparison = label("", 14, "536575")
 comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 comparison_panel.add_child(comparison)
 stats = label("", 13, "667788")
 comparison_panel.add_child(stats)
 segments_text = label("", 12, "667788")
 segments_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 comparison_panel.add_child(segments_text)
 comparison_panel.visible = false
 guide = label("第 6 章 6.3.3  ·  选择算法后直接分配，或逐步查看查找过程。", 13, "667788")
 experiment.add_child(guide)
 var canvas = panel("f8fafc", "e0e5eb")
 canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 experiment.add_child(canvas)
 var canvas_margin = margin_box(18, 8)
 canvas.add_child(canvas_margin)
 view = Control.new()
 view.set_script(MemoryView)
 view.font = font
 view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 canvas_margin.add_child(view)
 view.released.connect(_release)
 var controls = HBoxContainer.new()
 controls.add_theme_constant_override("separation", 10)
 experiment.add_child(controls)
 var allocate = button("立即分配", controls, _allocate_now)
 allocate.tooltip_text = "按所选算法直接完成一次分配"
 play_button = button("▶ 自动演示", controls, _on_play)
 button("逐步：下一步", controls, _next_step)
 button("重置", controls, _reset)
 var explanation = VBoxContainer.new()
 explanation.add_theme_constant_override("separation", 3)
 experiment.add_child(explanation)
 phase = label("等待操作", 12, "216e68")
 explanation.add_child(phase)
 result = label("", 17, "263342")
 result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 explanation.add_child(result)
 note = label("", 14, "536575")
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 explanation.add_child(note)
 paging_container = ScrollContainer.new()
 paging_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 paging_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 paging_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(paging_container)
 paging_lab = VBoxContainer.new()
 paging_lab.set_script(PagingLab)
 paging_lab.font = font
 paging_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 paging_container.add_child(paging_lab)
 paging_lab.back_requested.connect(_back_to_topics)
 schedule_container = ScrollContainer.new()
 schedule_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 schedule_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 schedule_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(schedule_container)
 schedule_lab = VBoxContainer.new()
 schedule_lab.set_script(ScheduleLab)
 schedule_lab.font = font
 schedule_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 schedule_container.add_child(schedule_lab)
 schedule_lab.back_requested.connect(_back_to_topics)
 banker_container = ScrollContainer.new()
 banker_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 banker_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 banker_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(banker_container)
 banker_lab = VBoxContainer.new()
 banker_lab.set_script(BankerLab)
 banker_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 banker_container.add_child(banker_lab)
 banker_lab.back_requested.connect(_back_to_topics)
 semaphore_container = ScrollContainer.new()
 semaphore_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 semaphore_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 semaphore_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(semaphore_container)
 semaphore_lab = VBoxContainer.new()
 semaphore_lab.set_script(SemaphoreLab)
 semaphore_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 semaphore_container.add_child(semaphore_lab)
 semaphore_lab.back_requested.connect(_back_to_topics)
 semaphore_lab.presentation_requested.connect(_toggle_semaphore_presentation)
 replacement_container = ScrollContainer.new()
 replacement_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 replacement_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 replacement_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(replacement_container)
 replacement_lab = VBoxContainer.new()
 replacement_lab.set_script(ReplacementLab)
 replacement_lab.font = font
 replacement_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 replacement_container.add_child(replacement_lab)
 replacement_lab.back_requested.connect(_back_to_topics)
 replacement_lab.address_requested.connect(_start_address_lab)
 address_container = ScrollContainer.new()
 address_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
 address_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 address_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 main.add_child(address_container)
 address_lab = AddressLab.new()
 address_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 address_container.add_child(address_lab)
 address_lab.back_requested.connect(_back_to_topics)
 address_lab.replacement_requested.connect(_start_replacement)
 timer = Timer.new()
 timer.wait_time = 1.1
 timer.timeout.connect(_next_step)
 add_child(timer)
 layout_input.text_changed.connect(_on_layout_changed)
 size_input.text_changed.connect(_on_size_changed)
 mode.item_selected.connect(_on_mode_changed)
 preset.item_selected.connect(_on_preset)
 unit_choice.item_selected.connect(_on_unit_changed)
 _reset()
 _update_modules()
 workspace_screen.visible = false
 chapter_screen.visible = false
 home_screen.visible = true

func _fit_window_to_screen():
 if DisplayServer.get_name() == "headless": return
 var area = DisplayServer.screen_get_usable_rect()
 if area.size.x <= 0 or area.size.y <= 0: return
 var scale_factor = minf(1.0, minf(float(area.size.x)/1440.0, float(area.size.y)/900.0))
 if scale_factor < 1.0:
  var new_size = Vector2i(maxi(640, int(1440*scale_factor)), maxi(400, int(900*scale_factor)))
  DisplayServer.window_set_size(new_size)
  DisplayServer.window_set_position(area.position + (area.size-new_size)/2)

func _unhandled_key_input(event: InputEvent):
 if not event is InputEventKey or not event.pressed or event.echo: return
 var window = get_window()
 if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
  if event.keycode not in [KEY_F11, KEY_ESCAPE]: return
  window.mode = windowed_mode
 elif event.keycode == KEY_F11:
  windowed_mode = window.mode
  window.mode = Window.MODE_FULLSCREEN
 else:
  return
 get_viewport().set_input_as_handled()

func _build_home() -> Control:
 var outer = margin_box(52, 38)
 outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var root = VBoxContainer.new()
 root.add_theme_constant_override("separation", 14)
 outer.add_child(root)
 var top = HBoxContainer.new()
 root.add_child(top)
 var brand = label("计算机模块实验室", 20, "263342")
 brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 top.add_child(brand)
 top.add_child(label("操作系统  /  教学原型", 13, "667788"))
 root.add_child(spacer(28))
 var lead = HBoxContainer.new()
 lead.add_theme_constant_override("separation", 42)
 lead.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(lead)
 var left = VBoxContainer.new()
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 left.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.alignment = BoxContainer.ALIGNMENT_CENTER
 left.add_theme_constant_override("separation", 18)
 lead.add_child(left)
 left.add_child(label("把操作系统，\n变成看得见的实验。", 35, "263342"))
 var description = label("组合进程、CPU、内存和其他模块，\n一步步理解操作系统如何管理计算机。", 17, "536575")
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 left.add_child(description)
 left.add_child(spacer(6))
 var explore = button("开始组合模块   →", left, _begin_explore)
 explore.custom_minimum_size = Vector2(250, 58)
 explore.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 explore.add_theme_stylebox_override("normal", style("eaf1f8", "c5d5e4", 9, 1, 18))
 explore.add_theme_stylebox_override("hover", style("dbe9f6", "a8c1d8", 9, 1, 18))
 var chapters = button("按教材章节学习", left, _show_chapters)
 chapters.custom_minimum_size = Vector2(250, 45)
 chapters.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 left.add_child(label("选择模块，或者从右侧的问题直接开始", 13, "667788"))
 var right = panel("ffffff", "e0e5eb")
 right.custom_minimum_size = Vector2(470, 420)
 right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 lead.add_child(right)
 var rm = margin_box(30, 28)
 right.add_child(rm)
 var rv = VBoxContainer.new()
 rv.alignment = BoxContainer.ALIGNMENT_CENTER
 rv.add_theme_constant_override("separation", 16)
 rm.add_child(rv)
 rv.add_child(label("从一个问题开始", 21, "263342"))
 rv.add_child(label("选择感兴趣的主题，直接进入实验", 14, "667788"))
 for entry in [
  ["处理机调度   ·   谁先使用 CPU？  →", _home_schedule],
  ["死锁避免   ·   资源够不够分？  →", _home_banker],
  ["内存管理   ·   程序如何获得空间？  →", _start_from_home],
  ["页面置换   ·   内存满了怎么办？  →", _home_replacement]
 ]:
  var entry_button = button(entry[0], rv, entry[1])
  entry_button.custom_minimum_size.y = 52
 root.add_child(label("选择模块  →  选择问题  →  动手实验", 14, "667788"))
 return outer
func _build_chapters() -> Control:
 var outer = margin_box(52, 38)
 outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var root = VBoxContainer.new()
 root.add_theme_constant_override("separation", 18)
 outer.add_child(root)
 var head = HBoxContainer.new()
 root.add_child(head)
 var title = label("按教材章节学习", 25, "263342")
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 head.add_child(title)
 button("← 返回首页", head, _show_home)
 root.add_child(label("《实用操作系统教程》第 2 版  ·  选择章节进入学习", 14, "667788"))
 root.add_child(spacer(10))
 var grid = GridContainer.new()
 grid.columns = 3
 grid.add_theme_constant_override("h_separation", 16)
 grid.add_theme_constant_override("v_separation", 16)
 root.add_child(grid)
 var names = ["操作系统概述", "进程、线程管理", "进程同步与通信", "处理机调度", "死锁", "内存管理", "虚拟存储管理", "I/O 设备管理", "文件系统"]
 var summaries = ["文件读取 · 缓存与磁盘", "进程状态 · 队列与 PCB", "水果盘 · 信号量 P / V", "FCFS · SJF · HRRN · SRTF · RR", "银行家算法与安全序列", "动态分区 · 分页与分段", "地址转换图解 · 页面置换", "设备速率 · I/O 缓冲", "磁盘块 · 文件索引与位图"]
 for i in names.size():
  var chapter_button = Button.new()
  chapter_button.custom_minimum_size = Vector2(300, 130)
  chapter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  chapter_button.text = "第 %d 章   %s\n%s\n交互实验" % [i+1,names[i],summaries[i]]
  var chapter = i+1
  chapter_button.pressed.connect(func(): _open_chapter(chapter))
  grid.add_child(chapter_button)
 return outer
func _show_chapters():
 _cancel()
 home_screen.visible = false
 workspace_screen.visible = false
 chapter_screen.visible = true
 chapter_intro.visible = false
func _open_chapter(chapter: int):
 if chapter in [1,2,3,8,9]:
  chapter_screen.visible = false
  workspace_screen.visible = false
  home_screen.visible = false
  chapter_intro.show_chapter(chapter)
  chapter_intro.visible = true
 elif chapter == 4:
  _add_schedule_example()
  _begin_explore()
  _start_schedule()
 elif chapter == 5:
  _add_banker_example()
  _begin_explore()
  _start_banker()
 elif chapter == 6:
  _add_example()
  _begin_explore()
 elif chapter == 7:
  _add_virtual_example()
  _begin_explore()
  _start_replacement()

func _show_home():
 _cancel()
 home_screen.visible = true
 chapter_screen.visible = false
 chapter_intro.visible = false
 workspace_screen.visible = false
func _begin_explore():
 home_screen.visible = false
 chapter_screen.visible = false
 chapter_intro.visible = false
 workspace_screen.visible = true
 topic_open = false
 _update_modules()
func _start_from_home():
 _add_example()
 mode.select(0)
 preset.select(0)
 _on_preset(0)
 _begin_explore()
 _start_experiment()
func _home_schedule():
 _add_schedule_example()
 _begin_explore()
 _start_schedule()
func _home_banker():
 _add_banker_example()
 _begin_explore()
 _start_banker()
func _home_replacement():
 _add_virtual_example()
 _begin_explore()
 _start_replacement()
func _start_experiment():
 if not _has_modules(): return
 selected_topic = "allocation"
 topic_open = true
 _update_modules()
func _start_paging():
 if not _has_modules(): return
 selected_topic = "paging"
 topic_open = true
 _cancel()
 _update_modules()
func _start_address_lab():
 if not (_has_modules() or _has_replacement_modules()): return
 selected_topic = "address"
 topic_open = true
 _cancel()
 address_lab.open(_has_replacement_modules())
 _update_modules()
func _start_schedule():
 if not _has_scheduler_modules(): return
 selected_topic = "schedule"
 topic_open = true
 _cancel()
 _update_modules()
func _start_banker():
 if not _has_banker_modules(): return
 selected_topic = "banker"
 topic_open = true
 _cancel()
 _update_modules()
func _open_semaphore():
 _add_banker_example()
 _begin_explore()
 _start_semaphore()
func _start_semaphore():
 if not _has_banker_modules(): return
 selected_topic = "semaphore"
 topic_open = true
 _cancel()
 _update_modules()
func _toggle_semaphore_presentation():
 semaphore_presentation = not semaphore_presentation
 _update_workspace_focus()
func _update_workspace_focus():
 if not semaphore_container.visible:
  semaphore_presentation = false
 library_scroll.visible = not semaphore_presentation
 workspace_heading.visible = not semaphore_presentation
 workspace_slots.visible = not semaphore_presentation
 semaphore_lab.set_presentation(semaphore_presentation)
func _start_replacement():
 if not _has_replacement_modules(): return
 selected_topic = "replacement"
 topic_open = true
 _cancel()
 _update_modules()
func _back_to_topics():
 _cancel()
 _refresh()
 topic_open = false
 _update_modules()

func _add_module(id: String):
 if not module_state.has(id) or module_state[id]: return
 var source = module_buttons[id]
 var from_rect = source.get_global_rect()
 module_state[id] = true
 _update_modules()
 if workspace_screen.visible and source.is_inside_tree():
  _animate_after_layout(id, from_rect)

func _animate_after_layout(id: String, from_rect: Rect2):
 var generation = module_generation
 await get_tree().process_frame
 if not is_inside_tree() or not workspace_screen.visible or not module_state[id] or generation != module_generation: return
 _animate_module(id, from_rect, module_slots[id].get_global_rect())

func _animate_module(id: String, from_rect: Rect2, to_rect: Rect2):
 var flight = Label.new()
 flight.text = {"program":"程序", "os":"操作系统", "memory":"内存", "process":"进程", "cpu":"CPU", "resource":"资源", "storage":"外存"}[id]
 flight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 flight.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
 flight.add_theme_color_override("font_color", Color("216e68"))
 flight.add_theme_stylebox_override("normal", style("e4f3f0", "8bc8bc", 10, 1, 8))
 add_child(flight)
 module_flights.append(flight)
 flight.global_position = from_rect.position
 flight.size = from_rect.size
 var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
 tween.tween_property(flight, "global_position", to_rect.position, 0.38)
 tween.tween_property(flight, "size", to_rect.size, 0.38)
 tween.chain().tween_callback(_finish_module_flight.bind(weakref(flight)))
func _finish_module_flight(flight_ref: WeakRef):
 var flight = flight_ref.get_ref()
 if is_instance_valid(flight):
  module_flights.erase(flight)
  flight.queue_free()
func _cancel_module_flights():
 module_generation += 1
 for flight in module_flights:
  if is_instance_valid(flight): flight.queue_free()
 module_flights.clear()
func _remove_module(id: String):
 if not module_state.has(id): return
 module_state[id] = false
 topic_open = false
 _cancel()
 _refresh()
 _update_modules()
func _clear_modules():
 _cancel_module_flights()
 _cancel()
 for id in module_state: module_state[id] = false
 topic_open = false
 _refresh()
 _update_modules()
func _add_example():
 _cancel_module_flights()
 _cancel()
 for id in module_state: module_state[id] = false
 for id in ["program", "os", "memory"]: module_state[id] = true
 topic_open = false
 _update_modules()
func _add_schedule_example():
 _cancel_module_flights()
 _cancel()
 for id in module_state: module_state[id] = false
 for id in ["process", "os", "cpu"]: module_state[id] = true
 topic_open = false
 _update_modules()
func _add_banker_example():
 _cancel_module_flights()
 _cancel()
 for id in module_state: module_state[id] = false
 for id in ["process", "os", "resource"]: module_state[id] = true
 topic_open = false
 _update_modules()
func _add_virtual_example():
 _cancel_module_flights()
 _cancel()
 for id in module_state: module_state[id] = false
 for id in ["process", "os", "memory", "storage"]: module_state[id] = true
 topic_open = false
 _update_modules()
func _update_modules():
 var count = 0
 for id in module_state:
  if module_state[id]: count += 1
  module_slots[id].set_active(module_state[id])
  module_slots[id].visible = module_state[id]
  module_buttons[id].visible = not module_state[id]
  module_buttons[id].text = {"program": "程序", "os": "操作系统", "memory": "内存", "process": "进程", "cpu": "CPU", "resource": "资源", "storage": "外存"}[id] + ("     ✓\n已添加" if module_state[id] else "     ＋\n" + {"program": "提出内存申请", "os": "管理系统资源", "memory": "提供存储空间", "process": "等待资源与执行", "cpu": "执行进程", "resource": "供进程申请", "storage": "存放未驻留页面"}[id])
 var memory_ready = _has_modules()
 var scheduler_ready = _has_scheduler_modules()
 var banker_ready = _has_banker_modules()
 var replacement_ready = _has_replacement_modules()
 var address_ready = memory_ready or replacement_ready
 var ready = memory_ready or scheduler_ready or banker_ready or replacement_ready
 if topic_open and ((selected_topic in ["allocation", "paging"] and not memory_ready) or (selected_topic == "address" and not address_ready) or (selected_topic == "schedule" and not scheduler_ready) or (selected_topic in ["banker", "semaphore"] and not banker_ready) or (selected_topic == "replacement" and not replacement_ready)):
  topic_open = false
 module_hint.text = "已添加 %d 个模块" % count if not ready else "组合可用 · 选择学习主题"
 allocation_topic.visible = memory_ready
 paging_topic.visible = memory_ready
 address_topic.visible = address_ready
 schedule_topic.visible = scheduler_ready
 banker_topic.visible = banker_ready
 semaphore_topic.visible = banker_ready
 replacement_topic.visible = replacement_ready
 experiment.visible = memory_ready and topic_open and selected_topic == "allocation"
 experiment_container.visible = experiment.visible
 paging_container.visible = memory_ready and topic_open and selected_topic == "paging"
 schedule_container.visible = scheduler_ready and topic_open and selected_topic == "schedule"
 banker_container.visible = banker_ready and topic_open and selected_topic == "banker"
 semaphore_container.visible = banker_ready and topic_open and selected_topic == "semaphore"
 _update_workspace_focus()
 replacement_container.visible = replacement_ready and topic_open and selected_topic == "replacement"
 address_container.visible = address_ready and topic_open and selected_topic == "address"
 topic_panel.visible = ready and not topic_open
 empty_hint.visible = not ready
func _has_modules() -> bool:
 return module_state.program and module_state.os and module_state.memory
func _has_scheduler_modules() -> bool:
 return module_state.process and module_state.os and module_state.cpu
func _has_banker_modules() -> bool:
 return module_state.process and module_state.os and module_state.resource
func _has_replacement_modules() -> bool:
 return module_state.process and module_state.os and module_state.memory and module_state.storage
func _toggle_settings():
 settings_panel.visible = not settings_panel.visible
func _toggle_comparison():
 comparison_panel.visible = not comparison_panel.visible

func style(fill: String, border: String, radius: int, width: int, padding: int) -> StyleBoxFlat:
 var box = StyleBoxFlat.new()
 box.bg_color = Color(fill)
 box.border_color = Color(border)
 box.set_border_width_all(width)
 box.set_corner_radius_all(radius)
 box.content_margin_left = padding
 box.content_margin_right = padding
 box.content_margin_top = 7
 box.content_margin_bottom = 7
 return box
func panel(fill: String, border: String) -> PanelContainer:
 var p = PanelContainer.new()
 p.add_theme_stylebox_override("panel", style(fill, border, 12, 1, 0))
 return p
func margin_box(horizontal: int, vertical: int) -> MarginContainer:
 var m = MarginContainer.new()
 m.add_theme_constant_override("margin_left", horizontal)
 m.add_theme_constant_override("margin_right", horizontal)
 m.add_theme_constant_override("margin_top", vertical)
 m.add_theme_constant_override("margin_bottom", vertical)
 return m
func spacer(height: int) -> Control:
 var c = Control.new()
 c.custom_minimum_size.y = height
 return c
func label(text: String, size: int, color: String) -> Label:
 var l = Label.new()
 l.text = text
 l.add_theme_font_size_override("font_size", size)
 l.add_theme_color_override("font_color", Color(color))
 return l
func button(text: String, parent: Control, callback: Callable) -> Button:
 var b = Button.new()
 b.text = text
 b.custom_minimum_size.y = 38
 b.pressed.connect(callback)
 parent.add_child(b)
 return b
func _on_preset(index: int):
 var layouts = ["100, -40, 500, -40, 200", "90, -40, 80, -40, 70", "80, -40, 180, -40, 300", "80, -40, 120, -40, 100", "-15,-9.9,0.1,-12,83"]
 var sizes = ["180", "200", "180", "150", "4"]
 unit_choice.select(1 if index == 4 else 0)
 layout_input.text = layouts[index]
 size_input.text = sizes[index]
 _reset()
 if index == 1: note.text = "试着分配 200 MB：空闲总量足够，但没有一块连续空间能容纳它。也可以尝试紧凑。"
 if index == 3: note.text = "点击两个空闲区之间的蓝色已占用区，观察相邻空闲区合并。"
 if index == 4: note.text = "课堂示例：用户区 120 KB 内留下 0.1 KB 碎片；系统区未绘制，地址从用户区起算。"
func _on_layout_changed(_text): _reset()
func _on_size_changed(_text):
 _cancel()
 _refresh()
func _on_mode_changed(_index):
 _cancel()
 _refresh()
func _on_unit_changed(_index):
 _cancel()
 _refresh()
 if segments.is_empty() or not _valid_amount(): return
 note.text = "单位已切换为 %s；输入的数字按新单位解释，不自动换算。" % _unit()
func _cancel():
 running = false
 if timer: timer.stop()
 if play_button: play_button.text = "▶ 自动演示"
 steps.clear()
 step_index = 0
 if view: view.focus_index = -1
 if view: view.queue_redraw()
func _parse_layout() -> bool:
 var parts = layout_input.text.replace("，", ",").split(",", true)
 if parts.size() == 0 or parts.size() > 12:
  note.text = "请输入 1 到 12 个分区，用英文逗号分隔。"
  return false
 var out: Array = []
 var start := 0
 for part in parts:
  var s = part.strip_edges()
  var n = _to_tenths(s, true)
  if n == 0 or n == -2147483648 or absi(n) > 100000:
   note.text = "分区必须是非零数值，最多一位小数，绝对值不超过 10000。"
   return false
  var length = abs(n)
  if out.size() > 0 and n > 0 and out.back().free:
   out.back().size += length
  else:
   out.append({"start":start, "size":length, "free":n > 0, "name":"占用"})
  start += length
 segments = out
 return true
func _to_tenths(raw: String, signed: bool = false) -> int:
 var value = raw.strip_edges()
 var negative = value.begins_with("-")
 if negative:
  if not signed: return -2147483648
  value = value.substr(1)
 var parts = value.split(".", true)
 if parts.size() > 2 or parts[0].is_empty() or not parts[0].is_valid_int() or parts[0].length() > 5: return -2147483648
 for ch in parts[0]:
  if ch < "0" or ch > "9": return -2147483648
 var frac := 0
 if parts.size() == 2:
  if parts[1].length() != 1 or not parts[1].is_valid_int(): return -2147483648
  frac = int(parts[1])
 var result = int(parts[0]) * 10 + frac
 return -result if negative else result
func _fmt(value: int) -> String:
 var magnitude = absi(value)
 var whole = floori(float(magnitude) / 10.0)
 var frac = magnitude % 10
 return ("-" if value < 0 else "") + str(whole) + ("." + str(frac) if frac else "")
func _unit() -> String:
 return unit_choice.get_item_text(unit_choice.selected)
func _valid_amount() -> bool:
 var amount = _to_tenths(size_input.text)
 if amount <= 0 or amount > 100000:
  note.text = "程序大小应大于 0 且不超过 10000，最多保留一位小数。"
  return false
 return true
func _reset():
 _cancel()
 counter = 1
 if not _parse_layout():
  segments = []
 _refresh()
func _refresh():
 view.segments = segments
 view.unit = _unit()
 view.candidate_index = -1
 view.queue_redraw()
 if segments.is_empty():
  stats.text = "等待有效的内存布局"
  segments_text.text = ""
  phase.text = "输入有误"
  result.text = "内存布局无效，请修改输入。"
  comparison.text = ""
  return
 if not _valid_amount():
  phase.text = "输入有误"
  result.text = "等待有效的程序大小。"
  comparison.text = ""
  return
 var descriptions = ["按地址从低到高查找，选择遇到的第一个足够大的空闲区。", "按空闲区大小从小到大查找，选择能够容纳程序的最小分区。", "优先选择最大的空闲区；若大小相同，选择低地址分区。"]
 knowledge.text = descriptions[mode.selected]
 phase.text = "等待操作"
 var total = 0
 var free_total = 0
 var max_free = 0
 var details: Array = []
 for seg in segments:
  total += seg.size
  if seg.free:
   free_total += seg.size
   max_free = maxi(max_free, seg.size)
  details.append(("空闲" if seg.free else seg.name) + " " + _fmt(seg.start) + "–" + _fmt(seg.start + seg.size) + "（" + _fmt(seg.size) + "）")
 stats.text = "总计 %s %s   ·   空闲 %s %s   ·   最大空闲 %s %s" % [_fmt(total), _unit(), _fmt(free_total), _unit(), _fmt(max_free), _unit()]
 segments_text.text = "分区明细： " + "   /   ".join(details) + "  " + _unit() + "（区间左闭右开）"
 note.text = "点击“立即分配”，或用自动演示 / 下一步查看查找过程。点击已占用区可回收。"
 var a = _to_tenths(size_input.text)
 var predicted = _choose(mode.selected, a)
 view.candidate_index = predicted
 view.queue_redraw()
 if predicted >= 0:
  result.text = "所选算法将选择地址 %s %s 的空闲区，大小 %s %s。" % [_fmt(segments[predicted].start), _unit(), _fmt(segments[predicted].size), _unit()]
 else:
  result.text = "当前没有足够大的连续空闲区，无法分配。"
 var labels: Array = []
 for i in 3:
  var idx = _choose(i, a)
  labels.append(["首次适应", "最佳适应", "最坏适应"][i] + "   →   " + (_fmt(segments[idx].start) + " " + _unit() if idx >= 0 else "无法分配"))
 comparison.text = "    ·    ".join(labels) + "  （分区起始地址）"
func _choose(algorithm: int, amount: int) -> int:
 var best := -1
 for i in segments.size():
  var s = segments[i]
  if not s.free or s.size < amount: continue
  if best < 0: best = i
  elif algorithm == 1 and s.size < segments[best].size: best = i
  elif algorithm == 2 and s.size > segments[best].size: best = i
  if algorithm == 0: break
 return best
func _allocate_now():
 if not _has_modules() or not _valid_amount() or segments.is_empty(): return
 _cancel()
 _prepare()
 var remaining_steps = steps.size() + 1
 if steps.is_empty(): return
 for i in remaining_steps:
  _next_step()

func _failure():
 var total := 0
 for s in segments:
  if s.free: total += s.size
 phase.text = "分配失败"
 note.text = "分配失败：没有足够大的连续空闲区。" + ("虽然空闲总量有 %s %s，但空间分散，这是外部碎片。" % [_fmt(total), _unit()] if total >= _to_tenths(size_input.text) else "空闲总量为 %s %s，也不足以容纳程序。" % [_fmt(total), _unit()])
 result.text = "未分配：现有分区保持不变。"
func _prepare():
 if not _valid_amount() or segments.is_empty(): return
 var target = _choose(mode.selected, _to_tenths(size_input.text))
 if target < 0:
  _failure()
  return
 var indices: Array = []
 for i in segments.size():
  if segments[i].free: indices.append(i)
 if mode.selected == 1: indices.sort_custom(func(a, b): return segments[a].size < segments[b].size if segments[a].size != segments[b].size else segments[a].start < segments[b].start)
 if mode.selected == 2: indices.sort_custom(func(a, b): return segments[a].size > segments[b].size if segments[a].size != segments[b].size else segments[a].start < segments[b].start)
 for i in indices:
  steps.append(i)
  if i == target: break
 step_index = 0
func _next_step():
 if not _has_modules(): return
 if steps.is_empty():
  _prepare()
  if steps.is_empty():
   _cancel()
   return
 if step_index < steps.size():
  var i = steps[step_index]
  view.highlight(i)
  var s = segments[i]
  var fits = s.size >= _to_tenths(size_input.text)
  note.text = "地址 %s %s：空闲 %s %s，%s所需 %s %s。" % [_fmt(s.start), _unit(), _fmt(s.size), _unit(), "可以容纳" if fits else "小于", _fmt(_to_tenths(size_input.text)), _unit()]
  note.text += " 按当前算法的查找顺序，这就是要选择的分区。" if fits else " 继续检查下一个空闲区。"
  phase.text = "检查分区"
  result.text = "第 %d / %d 步：检查空闲分区。" % [step_index + 1, steps.size()]
  step_index += 1
  view.queue_redraw()
 else:
  var i = steps.back()
  var s = segments[i]
  var amount = _to_tenths(size_input.text)
  var remainder = s.size - amount
  segments[i] = {"start":s.start,"size":amount,"free":false,"name":"程序" + str(counter)}
  counter += 1
  if remainder > 0: segments.insert(i + 1, {"start":s.start + amount,"size":remainder,"free":true,"name":""})
  _cancel()
  _refresh()
  view.candidate_index = -1
  view.queue_redraw()
  phase.text = "分配完成"
  note.text = "分配完成。点击程序区块可回收；相邻的空闲区会自动合并。"
  result.text = "已分配 %s %s，起始地址 %s %s，剩余 %s %s。" % [_fmt(amount), _unit(), _fmt(s.start), _unit(), _fmt(remainder), _unit()]
func _on_play():
 if not _has_modules(): return
 if running:
  running = false
  timer.stop()
  play_button.text = "▶ 继续演示"
 else:
  running = true
  play_button.text = "Ⅱ 暂停"
  _next_step()
  if running: timer.start()
func _release(index: int):
 if not _has_modules(): return
 _cancel()
 var s = segments[index]
 segments[index].free = true
 segments[index].name = ""
 if index > 0 and segments[index - 1].free:
  segments[index - 1].size += segments[index].size
  segments.remove_at(index)
  index -= 1
 if index + 1 < segments.size() and segments[index + 1].free:
  segments[index].size += segments[index + 1].size
  segments.remove_at(index + 1)
 _refresh()
 phase.text = "回收完成"
 note.text = "已回收起始地址 %s %s 的分区，并合并相邻空闲区。" % [_fmt(s.start), _unit()]
 result.text = "回收完成；可继续拖入程序。"

func _compact():
 if not _has_modules() or segments.is_empty(): return
 _cancel()
 var occupied: Array = []
 var free_total := 0
 var next_start := 0
 for segment in segments:
  if segment.free:
   free_total += segment.size
  else:
   var moved = segment.duplicate()
   moved.start = next_start
   next_start += moved.size
   occupied.append(moved)
 if free_total > 0:
  occupied.append({"start":next_start, "size":free_total, "free":true, "name":""})
 segments = occupied
 _refresh()
 phase.text = "紧凑完成"
 result.text = "已将已分配区移向低地址，空闲空间合并为 %s %s。" % [_fmt(free_total), _unit()]
 note.text = "紧凑通过移动已分配区消除外部碎片；实际系统需要地址重定位，移动也会带来开销。"
