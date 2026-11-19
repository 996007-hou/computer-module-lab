extends VBoxContainer

signal back_requested
signal replacement_requested

const Paging = preload("res://paging_model.gd")
const SEGMENTS = [
 {"name":"代码", "base":1024, "length":600},
 {"name":"数据", "base":256, "length":384},
 {"name":"栈", "base":2048, "length":256}
]
const SEGMENT_PAGES = [[4, 5], [2, 1], [0]]
const PAGED_SEGMENT_LENGTHS = [1536, 2048, 768]

var mode: OptionButton
var segment: OptionButton
var address: LineEdit
var columns: HBoxContainer
var input_hint: Label
var intro: Label
var titles: Array[Label] = []
var cards: Array[Array] = []
var result: Label
var progress: Label
var previous: Button
var next: Button
var replacement: Button
var connections: Array[Line2D] = []
var logical_row := -1
var table_row := -1
var physical_row := -1
var step := 0

func _ready():
 add_theme_constant_override("separation", 12)
 var head = HBoxContainer.new()
 head.add_theme_constant_override("separation", 10)
 add_child(head)
 _button("← 主题", head, func(): back_requested.emit())
 var title = _label("地址转换图解", 20, "263342")
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 head.add_child(title)
 replacement = _button("页面置换 →", head, func(): replacement_requested.emit())

 intro = _label("", 15, "536575")
 add_child(intro)
 var inputs = HBoxContainer.new()
 inputs.add_theme_constant_override("separation", 9)
 add_child(inputs)
 mode = OptionButton.new()
 mode.add_item("分页 · 固定大小")
 mode.add_item("分段 · 按用途划分")
 mode.add_item("段页式 · 段内再分页")
 inputs.add_child(mode)
 segment = OptionButton.new()
 for i in SEGMENTS.size():
  segment.add_item("段 %d · %s" % [i, SEGMENTS[i].name])
 inputs.add_child(segment)
 input_hint = _label("", 14, "536575")
 input_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
 inputs.add_child(input_hint)
 address = LineEdit.new()
 address.custom_minimum_size.x = 95
 address.text = "1300"
 inputs.add_child(address)
 _button("恢复示例", inputs, _reset_example)

 columns = HBoxContainer.new()
 columns.add_theme_constant_override("separation", 12)
 add_child(columns)
 _add_column(columns)
 _add_connection_gap()
 _add_column(columns)
 _add_connection_gap()
 _add_column(columns)
 for i in 2:
  var line = Line2D.new()
  line.width = 2.0
  line.antialiased = true
  line.default_color = Color("357c6f")
  columns.add_child(line)
  connections.append(line)
 columns.resized.connect(_queue_connections)
 columns.sort_children.connect(_queue_connections)
 visibility_changed.connect(_queue_connections)

 var controls = HBoxContainer.new()
 controls.add_theme_constant_override("separation", 9)
 add_child(controls)
 previous = _button("← 上一步", controls, func(): _go_to(step - 1))
 next = _button("下一步 →", controls, func(): _go_to(step + 1))
 progress = _label("", 13, "536575")
 progress.autowrap_mode = TextServer.AUTOWRAP_OFF
 controls.add_child(progress)
 result = _label("", 16, "263342")
 add_child(result)
 add_child(_label("图中的块指内存页框。读写文件时的磁盘块属于外存，可在第 8、9 章对照学习。", 13, "536575"))

 mode.item_selected.connect(func(_index): _reset_example())
 segment.item_selected.connect(func(_index): _go_to(0))
 address.text_changed.connect(func(_value): _go_to(0))
 _render()

func open(can_replace: bool):
 replacement.visible = can_replace

static func translate_segment(index: int, offset_text: String) -> Dictionary:
 var selected: Dictionary = SEGMENTS[index]
 var normalized = offset_text.strip_edges()
 if not normalized.is_valid_int() or int(normalized) < 0 or int(normalized) >= selected.length:
  return {"ok":false, "error":"段 %d 的长度为 %d 字节，段内偏移应为 0～%d。地址越界时不会访问物理内存。" % [index, selected.length, selected.length - 1]}
 var offset = int(normalized)
 return {"ok":true, "offset":offset, "physical":selected.base + offset}

func _reset_example():
 segment.select(0)
 address.text = "120" if mode.selected == 1 else "1300"
 _go_to(0)

func _go_to(index: int):
 step = clampi(index, 0, 2)
 _render()

func _render():
 var paged = mode.selected == 0
 segment.visible = not paged
 input_hint.text = "逻辑地址（字节）" if paged else "段内偏移（字节）"
 intro.text = [
  "程序按 1 KB 划成页，物理内存按同样大小划成块（页框）。页表告诉我们每页放在哪个块。",
  "程序按用途划成不同长度的段。段表给出每段的起始地址和长度，访问前先检查段内偏移。",
  "先用段号查段表，找到该段的页表，再把段内偏移拆成页号和页内偏移。图中每页与每块都是 1 KB。"
 ][mode.selected]
 titles[0].text = "程序的逻辑地址空间"
 titles[1].text = ["页表", "段表", "段表 → 对应段的页表"][mode.selected]
 titles[2].text = "物理内存"
 if paged:
  _render_paging()
 elif mode.selected == 1:
  _render_segments()
 else:
  _render_segment_pages()
 _queue_connections()

func _render_paging():
 var info = Paging.calculate("3", "1", "6", "4,1,5", address.text)
 var selected = info.get("page", -1)
 var frame = info.get("frame", -1)
 var mapping = [4, 1, 5]
 logical_row = selected
 table_row = selected
 physical_row = frame
 for i in 3:
  _card(0, i, "页 %d   ·   %d～%d" % [i, i * 1024, (i + 1) * 1024 - 1], i == selected)
  _card(1, i, "页 %d   →   页框 %d" % [i, mapping[i]], step >= 1 and i == selected)
 for i in 6:
  var page = mapping.find(i)
  var content = "空闲" if page == -1 else "页 %d" % page
  _card(2, i, "块 %d   ·   %s   ·   %d～%d" % [i, content, i * 1024, (i + 1) * 1024 - 1], step == 2 and i == frame)
 var steps: Array[String] = []
 if info.ok:
  steps = [
   "%d ÷ 1024 得到页号 %d，余数 %d 是页内偏移。" % [info.address, info.page, info.offset],
   "查页表：页 %d 放在块 %d，页内偏移 %d 保持不变。" % [info.page, info.frame, info.offset],
   "物理地址 = 块号 × 块大小 + 页内偏移 = %d × 1024 + %d = %d 字节。" % [info.frame, info.offset, info.physical]
  ]
 _show_result(info, steps)

func _render_segments():
 var selected = segment.selected
 var info = translate_segment(selected, address.text)
 var entry: Dictionary = SEGMENTS[selected]
 for i in SEGMENTS.size():
  var item: Dictionary = SEGMENTS[i]
  _card(0, i, "段 %d · %s   ·   %d 字节" % [i, item.name, item.length], i == selected)
  _card(1, i, "段 %d   ·   基址 %d   ·   段长 %d" % [i, item.base, item.length], i == selected and (step >= 1 or not info.ok))
 var order = [1, 0, 2]
 logical_row = selected if info.ok else -1
 table_row = logical_row
 physical_row = order.find(selected) if info.ok else -1
 for i in order.size():
  var index: int = order[i]
  var item: Dictionary = SEGMENTS[index]
  _card(2, i, "%d～%d   ·   %s段" % [item.base, item.base + item.length - 1, item.name], info.ok and step == 2 and index == selected)
 for i in range(3, 6): cards[2][i][0].hide()
 var steps: Array[String] = []
 if info.ok:
  steps = [
   "逻辑地址 =（段号 %d，段内偏移 %d）。" % [selected, info.offset],
   "查段表：基址 %d，段长 %d。偏移 %d 小于段长，可以访问。" % [entry.base, entry.length, info.offset],
   "物理地址 = 段基址 + 段内偏移 = %d + %d = %d 字节。" % [entry.base, info.offset, info.physical]
  ]
 _show_result(info, steps)

func _render_segment_pages():
 var selected = segment.selected
 var length: int = PAGED_SEGMENT_LENGTHS[selected]
 var input = address.text.strip_edges()
 var offset = int(input)
 var valid = input.is_valid_int() and offset >= 0 and offset < length
 var page = floori(float(offset) / 1024) if valid else -1
 var inner_offset = offset % 1024
 logical_row = selected if valid else -1
 table_row = page
 physical_row = SEGMENT_PAGES[selected][page] if valid else -1
 for i in SEGMENTS.size():
  _card(0, i, "段 %d · %s   ·   %d 字节" % [i, SEGMENTS[i].name, PAGED_SEGMENT_LENGTHS[i]], i == selected)
 for i in 3:
  if i < SEGMENT_PAGES[selected].size():
   _card(1, i, "段 %d 的页 %d   →   页框 %d" % [selected, i, SEGMENT_PAGES[selected][i]], step >= 1 and i == page)
  else:
   cards[1][i][0].hide()
 var occupants = ["空闲", "空闲", "空闲", "空闲", "空闲", "空闲"]
 for i in SEGMENT_PAGES.size():
  for j in SEGMENT_PAGES[i].size():
   occupants[SEGMENT_PAGES[i][j]] = "段 %d · 页 %d" % [i, j]
 for i in occupants.size():
  _card(2, i, "块 %d   ·   %s" % [i, occupants[i]], step == 2 and i == physical_row)
 if not valid:
  _show_result({"ok":false, "error":"段 %d 的长度为 %d 字节，段内偏移应为 0～%d。" % [selected, length, length - 1]}, [])
  return
 var steps: Array[String] = [
  "查段表找到段 %d 的页表。段内偏移 %d 小于段长 %d，拆成页号 %d 和页内偏移 %d。" % [selected, offset, length, page, inner_offset],
  "查段 %d 的页表：页 %d 对应物理块 %d。" % [selected, page, physical_row],
  "物理地址 = %d × 1024 + %d = %d 字节。" % [physical_row, inner_offset, physical_row * 1024 + inner_offset]
 ]
 _show_result({"ok":true}, steps)

func _show_result(info: Dictionary, steps: Array[String]):
 previous.disabled = not info.ok or step == 0
 next.disabled = not info.ok or step == 2
 progress.text = ["① 读逻辑地址", "② 查表", "③ 得到物理地址"][step] if info.ok else "检查输入"
 result.text = steps[step] if info.ok else info.error
 result.add_theme_color_override("font_color", Color("263342" if info.ok else "a45225"))

func _add_column(parent: HBoxContainer):
 var column = VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation", 6)
 parent.add_child(column)
 var title = _label("", 15, "536575")
 column.add_child(title)
 titles.append(title)
 var items: Array = []
 for i in (6 if titles.size() == 3 else 3):
  var panel = PanelContainer.new()
  column.add_child(panel)
  var label = _label("", 14, "263342")
  panel.add_child(label)
  items.append([panel, label])
 cards.append(items)

func _card(column: int, row: int, text: String, active: bool):
 var item: Array = cards[column][row]
 var box = StyleBoxFlat.new()
 box.bg_color = Color("e4f3f0" if active else "ffffff")
 box.border_color = Color("82b9ac" if active else "dce4ec")
 box.set_border_width_all(1)
 box.set_corner_radius_all(8)
 box.set_content_margin_all(8)
 item[0].add_theme_stylebox_override("panel", box)
 item[1].text = text
 item[0].show()

func _add_connection_gap():
 var space = Control.new()
 space.custom_minimum_size.x = 28
 columns.add_child(space)

func _queue_connections():
 _update_connections.call_deferred()

func _update_connections():
 for connection in connections: connection.clear_points()
 if not is_visible_in_tree() or logical_row < 0 or step == 0: return
 _connect_cards(connections[0], cards[0][logical_row][0], cards[1][table_row][0])
 if step == 2:
  _connect_cards(connections[1], cards[1][table_row][0], cards[2][physical_row][0])

func _connect_cards(line: Line2D, source: Control, target: Control):
 var start = source.global_position - columns.global_position + Vector2(source.size.x, source.size.y / 2)
 var end = target.global_position - columns.global_position + Vector2(0, target.size.y / 2)
 var midpoint = (start.x + end.x) / 2
 line.points = PackedVector2Array([
  start, Vector2(midpoint, start.y), Vector2(midpoint, end.y), end,
  end + Vector2(-6, -4), end, end + Vector2(-6, 4)
 ])

func _label(text: String, size: int, color: String) -> Label:
 var label = Label.new()
 label.text = text
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", size)
 label.add_theme_color_override("font_color", Color(color))
 return label

func _button(text: String, parent: Control, action: Callable) -> Button:
 var button = Button.new()
 button.text = text
 button.pressed.connect(action)
 parent.add_child(button)
 return button
