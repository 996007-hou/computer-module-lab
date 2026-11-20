extends "res://chapter_lab.gd"

var capacity: SpinBox
var device_rate: SpinBox
var process_rate: SpinBox
var target_ticks: SpinBox
var whole_tick: Button
var half_tick: Button
var finish_run: Button
var progress: Label
var input_hint: Label
var device_tile: Label
var buffer_tile: Label
var program_tile: Label
var balance: Label
var compare_toggle: Button
var compare_panel: VBoxContainer
var compare_rate: SpinBox
var compare_labels: Array[Label] = []
var compare_bars: Array[Array] = []
var device_wait_tiles: Array[Label] = []
var program_wait_tiles: Array[Label] = []
var compare_feedback: Label
var phases: Array[Label] = []
var slots: Array[Label] = []
var history_rows: Array[Array] = []

var tick := 0
var generated := 0
var admitted := 0
var delivered := 0
var buffered: int:
 get: return admitted - delivered
var pending: int:
 get: return generated - admitted
var intake_complete := false
var history: Array[Dictionary] = []
var before_buffer := 0
var before_device := 0
var this_generated := 0
var this_admitted := 0
var this_read := 0
var read_limit := 0
var compare_admitted := 0
var compare_delivered := 0
var compare_read_limit := 0
var compare_this_read := 0

func _ready():
 build_intro("缓冲区满了，剩下的数据去哪了？", "时间步是演示中的一次完整操作。每步设备先尝试放入，程序再尝试取走。设备没传进去的数据留到下一步优先传输。")
 input_hint = make_label("", 14, MUTED, true)
 var inputs = add_row()
 capacity = add_number(inputs, "缓冲容量", 1, 12, 9)
 device_rate = add_number(inputs, "设备每步新产生", 0, 12, 6)
 process_rate = add_number(inputs, "A 组每步最多取", 0, 12, 3)
 make_button(inputs, "载入例子 9 / 6 / 3", load_example)
 add_child(input_hint)
 var actions = add_row()
 target_ticks = add_number(actions, "本轮步数", 1, 20, 4)
 whole_tick = make_button(actions, "推进一个时间步", advance)
 half_tick = make_button(actions, "只看设备放入", advance_half)
 finish_run = make_button(actions, "直接跑到结束", run_to_end)
 make_button(actions, "重置进度", reset)
 compare_toggle = Button.new()
 compare_toggle.text = "速度对比图"
 compare_toggle.toggle_mode = true
 compare_toggle.toggled.connect(toggle_comparison)
 actions.add_child(compare_toggle)
 progress = make_label("", 20, INK, true)
 add_child(progress)
 build_comparison()
 var stages = add_row()
 device_tile = make_tile(stages, 72)
 buffer_tile = make_tile(stages, 72)
 program_tile = make_tile(stages, 72)
 balance = make_label("", 17, INK, true)
 add_child(balance)

 var moments = add_row()
 for i in 3: phases.append(make_tile(moments, 76))
 var buffer_row = add_row()
 for i in 12: slots.append(make_tile(buffer_row, 52))
 add_feedback()

 add_child(make_label("最近四步的收支", 16))
 var table = GridContainer.new()
 table.columns = 5
 table.add_theme_constant_override("h_separation", 16)
 table.add_theme_constant_override("v_separation", 5)
 add_child(table)
 for column in ["步次", "实际放入", "实际取走", "步末缓冲中", "步末设备待传"]:
  table.add_child(table_cell(column))
 for row in 4:
  var cells: Array[Label] = []
  for column in 5:
   var cell = table_cell("")
   table.add_child(cell)
   cells.append(cell)
  history_rows.append(cells)
 capacity.value_changed.connect(func(_value): reset())
 target_ticks.value_changed.connect(func(_value): reset())
 for rate in [device_rate, process_rate, compare_rate]:
  rate.value_changed.connect(func(_value):
   show_input_hint()
   render_comparison()
  )
 reset()

func build_comparison():
 compare_panel = VBoxContainer.new()
 compare_panel.add_theme_constant_override("separation", 8)
 add_child(compare_panel)
 var comparison_controls = add_row(compare_panel)
 compare_rate = add_number(comparison_controls, "B 组每步最多取", 0, 12, 8)
 compare_panel.add_child(make_label("两组容量和设备速度相同。橙色是设备待传的数据，蓝色在缓冲区，绿色已被程序取走。", 15, MUTED, true))
 var examples = add_row(compare_panel)
 for i in 2:
  var column = VBoxContainer.new()
  column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  column.add_theme_constant_override("separation", 7)
  examples.add_child(column)
  var tally = make_label("", 15, INK, true)
  column.add_child(tally)
  compare_labels.append(tally)
  var strip = HBoxContainer.new()
  strip.custom_minimum_size.y = 18
  strip.add_theme_constant_override("separation", 2)
  column.add_child(strip)
  var segments: Array[ColorRect] = []
  for color in ["e5b568", "91b4dc", "83bfb1"]:
   var segment = ColorRect.new()
   segment.color = Color(color)
   segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   strip.add_child(segment)
   segments.append(segment)
  compare_bars.append(segments)
  var device_wait = make_tile(column, 40)
  var program_wait = make_tile(column, 40)
  for status in [device_wait, program_wait]:
   status.add_theme_font_size_override("font_size", 20)
   label_sizes[status] = 20
  device_wait_tiles.append(device_wait)
  program_wait_tiles.append(program_wait)
 compare_feedback = make_label("", 16, GREEN, true)
 compare_panel.add_child(compare_feedback)
 compare_panel.hide()

func toggle_comparison(active: bool):
 compare_panel.visible = active
 if active:
  reset()
 show_input_hint()

func render_comparison():
 if not compare_panel.visible: return
 var primary = [pending, buffered, delivered]
 var alternative = [generated - compare_admitted, compare_admitted - compare_delivered, compare_delivered]
 var rates = [int(process_rate.value), int(compare_rate.value)]
 var read_limits = [read_limit, compare_read_limit]
 var read_counts = [this_read, compare_this_read]
 for group in 2:
  var counts: Array = primary if group == 0 else alternative
  var shown_rate: int = rates[group] if tick == 0 else read_limits[group]
  compare_labels[group].text = "%s 组 · %s最多取 %d 块\n待传 %d  |  缓冲中 %d  |  已读走 %d" % [
   "A" if group == 0 else "B", "每步" if tick == 0 else "本步", shown_rate, counts[0], counts[1], counts[2]
  ]
  for i in 3:
   var segment: ColorRect = compare_bars[group][i]
   segment.visible = counts[i] > 0
   if counts[i] > 0: segment.size_flags_stretch_ratio = float(counts[i])
  if tick == 0:
   show_tile(device_wait_tiles[group], "设备等待情况")
   show_tile(program_wait_tiles[group], "程序等待情况")
   continue
  var device_status = "设备未积压 · 待传已清空"
  var device_waits: bool = counts[0] > 0
  if device_waits: device_status = "设备等空位 · %d 块留在设备端" % counts[0]
  var program_status = "程序还没取数据"
  var shortage: int = 0
  if not intake_complete:
   shortage = read_limits[group] - read_counts[group]
   program_status = "程序已取足 · 本步取走 %d 块" % read_counts[group]
   if read_limits[group] == 0: program_status = "本步不读取（上限为 0）"
   if shortage > 0: program_status = "程序等数据 · 想取 %d 块，只取到 %d 块" % [read_limits[group], read_counts[group]]
  show_tile(device_wait_tiles[group], device_status, "waiting" if device_waits else "idle")
  show_tile(program_wait_tiles[group], program_status, "waiting" if shortage > 0 else "idle")
 if tick == 0:
  compare_feedback.text = "两组从空缓冲区开始。推进一个时间步，或直接跑到结束。"
 else:
  compare_feedback.text = "两组各产生 %d 块。A 组已读 %d 块，B 组已读 %d 块。" % [generated, delivered, compare_delivered]

func table_cell(value: String) -> Label:
 var cell = make_label(value, 14, MUTED)
 cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return cell

func add_number(parent: Control, caption: String, low: int, high: int, initial: int) -> SpinBox:
 parent.add_child(make_label(caption, 15, MUTED))
 var input = SpinBox.new()
 input.min_value = low
 input.max_value = high
 input.value = initial
 input.custom_minimum_size.x = 76
 input.tooltip_text = "可填 %d～%d 的整数" % [low, high]
 parent.add_child(input)
 var entry = input.get_line_edit()
 entry.text_changed.connect(func(value):
  if value.is_empty() or (value.is_valid_int() and int(value) >= low and int(value) <= high):
   show_input_hint()
  else:
   input_hint.text = "「%s」请填 %d～%d 的整数。" % [caption, low, high]
 )
 entry.focus_exited.connect(show_input_hint)
 return input

func show_input_hint():
 var limit = int(capacity.value)
 var offered = int(device_rate.value)
 var reader_a = int(process_rate.value)
 var reader_b = int(compare_rate.value)
 if offered > limit:
  input_hint.text = "设备每步产生 %d 块，缓冲区只有 %d 格。即使起初全空，也有数据要等下一步。" % [offered, limit]
 elif reader_a > limit or (compare_toggle.button_pressed and reader_b > limit):
  input_hint.text = "有一组的读取上限超过缓冲容量。程序每步最多只能从缓冲区取出 %d 块。" % limit
 elif offered == 0:
  input_hint.text = "设备暂停产生新数据。接下来只会传送和读取已有的数据。"
 elif reader_a == 0 or (compare_toggle.button_pressed and reader_b == 0):
  input_hint.text = "每步读取设为 0 时，程序不会清空格子，缓冲区满后设备会开始排队。"
 elif target_ticks.value > 12:
  input_hint.text = "本轮有 %d 步。可直接跑到结束，表格保留最近 4 步。" % int(target_ticks.value)
 else:
  input_hint.text = "容量 1～12 格，速率 0～12 块/步，步数 1～20。改容量或步数会重新开始，改速率从下一步生效。"

func load_example():
 capacity.set_value_no_signal(9)
 device_rate.set_value_no_signal(6)
 process_rate.set_value_no_signal(3)
 compare_rate.set_value_no_signal(8)
 target_ticks.set_value_no_signal(4)
 reset()

func reset():
 tick = 0
 generated = 0
 admitted = 0
 delivered = 0
 compare_admitted = 0
 compare_delivered = 0
 intake_complete = false
 history.clear()
 show_input_hint()
 feedback.text = "先点「只看设备放入」，看第一批数据占了几个格子，再点「让程序取走」。"
 render()

func advance():
 if tick >= int(target_ticks.value) and not intake_complete: return
 if not intake_complete: receive_from_device()
 read_from_buffer()
 render()

func advance_half():
 if intake_complete:
  read_from_buffer()
 elif tick < int(target_ticks.value):
  receive_from_device()
 render()

func run_to_end():
 if intake_complete: read_from_buffer()
 while tick < int(target_ticks.value):
  receive_from_device()
  read_from_buffer()
 render()

func receive_from_device():
 tick += 1
 before_buffer = buffered
 before_device = pending
 this_generated = int(device_rate.value)
 read_limit = int(process_rate.value)
 compare_read_limit = int(compare_rate.value)
 this_read = 0
 compare_this_read = 0
 generated += this_generated
 this_admitted = available_transfer(admitted, delivered)
 admitted += this_admitted
 if compare_toggle.button_pressed:
  compare_admitted += available_transfer(compare_admitted, compare_delivered)
 intake_complete = true
 feedback.text = "设备端原有 %d 块待传，加上新产生的 %d 块，这一步放入 %d 块，设备端还剩 %d 块。" % [before_device, this_generated, this_admitted, pending]

func available_transfer(received_total: int, read_total: int) -> int:
 var waiting_blocks = generated - received_total
 var spare_slots = int(capacity.value) - (received_total - read_total)
 return mini(waiting_blocks, spare_slots)

func read_from_buffer():
 this_read = mini(read_limit, buffered)
 delivered += this_read
 if compare_toggle.button_pressed:
  compare_this_read = mini(compare_read_limit, compare_admitted - compare_delivered)
  compare_delivered += compare_this_read
 intake_complete = false
 history.append({"tick":tick, "admitted":this_admitted, "read":this_read, "buffered":buffered, "pending":pending})
 if history.size() > history_rows.size(): history.pop_front()
 feedback.text = "步初缓冲区有 %d 块 + 实际放入 %d 块 − 程序取走 %d 块 = 剩下 %d 块。" % [before_buffer, this_admitted, this_read, buffered]
 if pending > 0:
  feedback.text += " 还有 %d 块留在设备端。" % pending
 if this_read < read_limit: feedback.text += " 数据不足，程序这一步少读 %d 块。" % (read_limit - this_read)

func render():
 var limit = int(capacity.value)
 var target = int(target_ticks.value)
 var finished = tick >= target and not intake_complete
 half_tick.text = "让程序取走" if intake_complete else "只看设备放入"
 whole_tick.disabled = finished or intake_complete
 half_tick.disabled = finished
 finish_run.disabled = finished
 if finished:
  progress.text = "本轮已结束 · %d / %d 步。图中保留最后一步的数据，可以重置再试。" % [tick, target]
 elif intake_complete:
  progress.text = "第 %d / %d 步 · 设备已放入，等程序取走后才算完成这一步。" % [tick, target]
 else:
  progress.text = "已完成 %d / %d 步 · 还剩 %d 步" % [tick, target, target - tick]
 show_tile(device_tile, "设备端待传\n%d 块" % pending, "waiting" if pending > 0 else "idle")
 show_tile(buffer_tile, "缓冲区当前占用\n%d / %d 块" % [buffered, limit], "info")
 show_tile(program_tile, "程序累计读走\n%d 块" % delivered, "active" if delivered > 0 else "idle")
 balance.text = "累计产生 %d 块  =  设备待传 %d  +  缓冲中 %d  +  已读走 %d" % [generated, pending, buffered, delivered]
 render_phases(limit)
 for i in slots.size():
  slots[i].visible = i < limit
  if i >= buffered:
   show_tile(slots[i], "空")
  else:
   var block_id = delivered + i + 1
   var new_block = intake_complete and block_id > admitted - this_admitted
   show_tile(slots[i], "块 %d\n%s" % [block_id, "刚放入" if new_block else "缓冲中"], "info" if new_block else "active")
 for i in history_rows.size():
  var values: Array = []
  if i < history.size():
   var entry = history[i]
   values = [entry.tick, entry.admitted, entry.read, entry.buffered, entry.pending]
  for column in history_rows[i].size():
   var cell: Label = history_rows[i][column]
   cell.visible = not values.is_empty()
   if cell.visible: cell.text = ("第 %d 步" if column == 0 else "%d 块") % values[column]
 render_comparison()

func render_phases(limit: int):
 if tick == 0:
  show_tile(phases[0], "① 放入前\n空出 %d 格" % limit)
  show_tile(phases[1], "② 设备放入\n只放进有空位的格子")
  show_tile(phases[2], "③ 程序取走\n从队首开始取")
  return
 show_tile(phases[0], "第 %d 步 · 放入前\n已占 %d 格，可用 %d 格" % [tick, before_buffer, limit - before_buffer])
 show_tile(phases[1], "放入后\n%d / %d 块，放入 %d 块" % [before_buffer + this_admitted, limit, this_admitted], "info" if intake_complete else "idle")
 var read_text = "等待你点击「让程序取走」" if intake_complete else "%d / %d 块，取走 %d 块" % [buffered, limit, this_read]
 show_tile(phases[2], "取走后\n" + read_text, "idle" if intake_complete else "active")
