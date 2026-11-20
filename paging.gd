extends VBoxContainer
signal back_requested
const Playback = preload("res://playback.gd")
var player: Control
const Model = preload("res://paging_model.gd")
const Diagram = preload("res://paging_view.gd")
var program: LineEdit
var page_size: OptionButton
var frames: LineEdit
var mapping: LineEdit
var address: LineEdit
var diagram: Control
var explanation: Label
var detail: Label
var next_button: Button
var prev_button: Button
var info: Dictionary = {}
var step := 0
var font: Font
var restoring := false
var practice: CheckButton
var answer_row: HBoxContainer
var answer: LineEdit
var feedback: Label
var revealed := false
func _ready():
 add_theme_constant_override("separation", 8)
 var line = HBoxContainer.new()
 line.add_theme_constant_override("separation", 10)
 add_child(line)
 var back = Button.new()
 back.text = "← 主题"
 back.pressed.connect(func(): back_requested.emit())
 line.add_child(back)
 var title = _label("基本分页", 19, "263342")
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 line.add_child(title)
 line.add_child(_label("教材第 6 章 6.4 · 页表与地址转换", 13, "667788"))
 var terms = _label("页框是物理内存中与页等大的格子。页表记录每一页放在哪个页框。", 14, "536575")
 terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(terms)
 var parameters = HBoxContainer.new()
 parameters.add_theme_constant_override("separation", 8)
 add_child(parameters)
 parameters.add_child(_label("程序",14,"536575"))
 program = _field("10", 58)
 parameters.add_child(program)
 parameters.add_child(_label("KB",14,"536575"))
 parameters.add_child(_label("页大小",14,"536575"))
 page_size = OptionButton.new()
 for n in [1,2,4,8,16]: page_size.add_item(str(n) + " KB",n)
 page_size.select(1)
 parameters.add_child(page_size)
 parameters.add_child(_label("页框数",14,"536575"))
 frames = _field("8", 52)
 parameters.add_child(frames)
 parameters.add_child(_label("逻辑地址",14,"536575"))
 address = _field("4520", 84)
 parameters.add_child(address)
 parameters.add_child(_label("字节",14,"536575"))
 var mapping_line = HBoxContainer.new()
 mapping_line.add_theme_constant_override("separation", 8)
 add_child(mapping_line)
 mapping_line.add_child(_label("页表",14,"536575"))
 mapping = _field("2,3,6,5,7", 180)
 mapping_line.add_child(mapping)
 var hint = _label("按页号顺序填写页框号，如 2,3,6,5,7", 13,"667788")
 hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 mapping_line.add_child(hint)
 var reset = Button.new()
 reset.text = "教材页表示例"
 reset.pressed.connect(_reset_example)
 mapping_line.add_child(reset)
 var classroom = Button.new()
 classroom.text = "课堂 12 KB"
 classroom.tooltip_text = "按课堂参数设置：程序 12 KB、页大小 2 KB；页框映射为演示数据。"
 classroom.pressed.connect(_classroom_example)
 mapping_line.add_child(classroom)
 diagram = Control.new()
 diagram.set_script(Diagram)
 diagram.font = font
 diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 add_child(diagram)
 var controls = HBoxContainer.new()
 controls.add_theme_constant_override("separation", 8)
 add_child(controls)
 prev_button = Button.new()
 prev_button.text = "← 上一步"
 prev_button.pressed.connect(_previous)
 controls.add_child(prev_button)
 next_button = Button.new()
 next_button.text = "下一步 →"
 next_button.pressed.connect(_next)
 controls.add_child(next_button)
 player = HBoxContainer.new()
 player.set_script(Playback)
 controls.add_child(player)
 player.advance_requested.connect(_next)
 player.finish_requested.connect(_show_all)
 player.restart_requested.connect(_restart_steps)
 practice = CheckButton.new()
 practice.text = "自己算一算"
 practice.toggled.connect(_practice_changed)
 controls.add_child(practice)
 answer_row = HBoxContainer.new()
 answer_row.add_theme_constant_override("separation", 8)
 add_child(answer_row)
 answer_row.add_child(_label("物理地址", 14, "536575"))
 answer = _field("", 110)
 answer.placeholder_text = "字节"
 answer_row.add_child(answer)
 var check_answer = Button.new()
 check_answer.text = "检查答案"
 check_answer.pressed.connect(_check_answer)
 answer_row.add_child(check_answer)
 var reveal = Button.new()
 reveal.text = "查看答案"
 reveal.pressed.connect(_reveal_answer)
 answer_row.add_child(reveal)
 feedback = _label("", 13, "536575")
 answer_row.add_child(feedback)
 explanation = _label("",16,"263342")
 explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(explanation)
 detail = _label("",13,"667788")
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 add_child(detail)
 program.text_changed.connect(_changed)
 frames.text_changed.connect(_changed)
 mapping.text_changed.connect(_changed)
 address.text_changed.connect(_changed)
 page_size.item_selected.connect(func(_index): _changed(""))
 _changed("")
func _label(text: String, size: int, color: String) -> Label:
 var l = Label.new()
 l.text = text
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color(color))
 return l
func _field(text: String, width: int) -> LineEdit:
 var field = LineEdit.new()
 field.text = text
 field.custom_minimum_size = Vector2(width,36)
 return field
func _changed(_text):
 if restoring: return
 player.stop()
 step = 0
 revealed = false
 answer.text = ""
 feedback.text = ""
 info = Model.calculate(program.text, str(page_size.get_selected_id()), frames.text, mapping.text, address.text)
 if info.ok: diagram.custom_minimum_size.y = maxf(290, 42 + info.frame_count * 27)
 _render()
func _render():
 player.set_state(info.ok, step, 3)
 diagram.update_diagram(info, step)
 answer_row.visible = info.ok and practice.button_pressed and step == 3
 prev_button.disabled = step <= 0 or not info.ok
 next_button.disabled = not info.ok or step >= 3
 if not info.ok:
  explanation.text = info.error
  explanation.add_theme_color_override("font_color", Color("a45225"))
  detail.text = "调整参数后，页面会自动更新。"
  return
 explanation.add_theme_color_override("font_color", Color("263342"))
 var size_b: int = info.page_size * 1024
 match step:
  0:
   explanation.text = "程序被分成 %d 页，每页 %d KB；页可以放进不相邻的页框。" % [info.page_count, info.page_size]
   detail.text = "页号从 0 开始。点击“下一步”转换地址；末页未使用 %d 字节（页内碎片）。" % info.internal_fragment
  1:
   explanation.text = "拆分地址：%d ÷ %d = 页号 %d，余数 %d。" % [info.address,size_b,info.page,info.offset]
   detail.text = "逻辑地址除以页大小，整数商是页号。余数是页内偏移，也就是从该页开头算起的位置。"
  2:
   explanation.text = "查询页表：页 %d 对应物理页框 %d。" % [info.page,info.frame]
   detail.text = "页表记录页号到页框号的映射；页内偏移保持不变。"
  3:
   if practice.button_pressed and not revealed:
    explanation.text = "试着算出物理地址，然后输入答案。"
    detail.text = "提示：页框号 × 页框大小（字节）+ 页内偏移。"
   else:
    explanation.text = "物理地址：%d × %d + %d = %d 字节。" % [info.frame,size_b,info.offset,info.physical]
    detail.text = "物理地址 = 页框号 × 页框大小 + 页内偏移。这个例子中的所有页均已装入内存。"
func _next():
 if info.ok and step < 3:
  step += 1
  _render()
func _show_all():
 step = 3
 _render()
func _restart_steps():
 step = 0
 _render()
func _previous():
 player.stop()
 if info.ok and step > 0:
  step -= 1
  _render()
func _practice_changed(_pressed: bool):
 player.stop()
 revealed = false
 feedback.text = ""
 _render()
func _check_answer():
 var text=answer.text.strip_edges()
 if not text.is_valid_int():
  feedback.text="请输入整数地址。"
 elif int(text)==info.physical:
  feedback.text="正确！"
  revealed=true
  _render()
 else:
  feedback.text="再检查页框号、单位和页内偏移。"
func _reveal_answer():
 revealed=true
 feedback.text="已显示答案。"
 _render()
func _reset_example():
 restoring = true
 program.text = "10"
 page_size.select(1)
 frames.text = "8"
 mapping.text = "2,3,6,5,7"
 address.text = "4520"
 restoring = false
 _changed("")
func _classroom_example():
 restoring = true
 program.text = "12"
 page_size.select(1)
 frames.text = "8"
 mapping.text = "2,0,4,1,7,5"
 address.text = "4520"
 restoring = false
 _changed("")
 detail.text = "课堂示例：12 KB ÷ 2 KB = 6 页；这里的页框位置为演示设定。"

