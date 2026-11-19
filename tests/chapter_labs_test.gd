extends SceneTree

var failures := 0

func _initialize():
 call_deferred("run_tests")

func run_tests():
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 var chapter = app.chapter_intro

 for number in [1, 2, 3, 8, 9]:
  app._open_chapter(number)
  check_control_colors(chapter.active_lab)
 check_control_colors(chapter)

 app._show_chapters()
 app._open_chapter(1)
 var read_lab = chapter.active_lab
 check(chapter.lab_scroll.visible and chapter.lab_mode.button_pressed, "chapter opens the experiment")
 for i in 4: read_lab.next_event()
 check(read_lab.cards[0].text.contains("A 就绪") and read_lab.cards[3].text.contains("报告完成"), "disk interrupt wakes the blocked process")
 chapter.theory_mode.pressed.emit()
 check(chapter.theory.visible and not chapter.lab_scroll.visible, "theory and exercises remain available")
 chapter.lab_mode.pressed.emit()
 check(chapter.active_lab == read_lab and read_lab.step == 3, "switching to theory keeps experimental state")
 read_lab.scenario.select(0)
 read_lab.scenario.item_selected.emit(0)
 read_lab.next_event()
 read_lab.next_event()
 check(read_lab.cards[3].text.contains("无需访问") and read_lab.links[1].text == "←", "cached data comes from memory")
 read_lab.next_event()
 check(read_lab.advance.disabled and read_lab.history.text.split("\n").size() == 3, "cache path is shorter and ends")

 app._open_chapter(2)
 var states = chapter.active_lab
 states.dispatch()
 states.execute_instruction()
 states.block_for_io()
 states.dispatch()
 states.finish_io()
 check(states.running == 1 and states.ready_queue == [0] and states.blocked_queue.is_empty(), "I/O completion readies P1 while P2 runs")
 states.expire_slice()
 states.dispatch()
 check(states.running == 0 and states.instructions[0] == 1 and states.feedback.text.contains("第 1 号"), "P1 resumes from saved instruction")
 states.reset()
 states.action_buttons[states.Action.DISPATCH].pressed.emit()
 states.action_buttons[states.Action.EXPIRE].pressed.emit()
 check(states.running == -1 and states.action_buttons[states.Action.DISPATCH].text == "调度 P2" and states.next_hint.text.contains("P2"), "free mode points to P2 after P1's time slice")
 states.guide_button.pressed.emit()
 for i in 3:
  states.action_buttons[states.GUIDE[i][0]].pressed.emit()
 check(states.guide_step == 3 and states.guide_text.text.contains("调度 P2"), "guide explains who is next after the time slice")
 states.action_buttons[states.Action.DISPATCH].pressed.emit()
 check(states.running == 1 and states.pcb_rows[1].text.contains("获得 CPU 1 次"), "guided P2 dispatch is visible before its first instruction")
 for i in range(4, states.GUIDE.size()):
  states.action_buttons[states.GUIDE[i][0]].pressed.emit()
 check(not states.is_guided() and states.running == 0 and states.ready_queue == [1] and states.dispatch_counts == [2, 1], "guide completes both CPU turns and restores free actions")

 app._open_chapter(3)
 var sync = chapter.active_lab
 sync.take_fruit(1)
 sync.put_fruit(0)
 sync.put_fruit(1)
 check(sync.plate == 0 and sync.waiting[1] and sync.producer_ticket == 1, "one-slot plate blocks a pending producer and the wrong consumer")
 sync.take_fruit(0)
 check(sync.producer_tile.text.contains("已唤醒"), "empty plate wakes the pending producer")
 sync.put_fruit(1)
 check(sync.consumer_cards[1].text.contains("已唤醒"), "putting an orange wakes only its consumer")
 sync.take_fruit(1)
 check(sync.plate == -1 and not sync.waiting[1], "matching consumer empties the plate")
 sync.reset()
 sync.action_buttons[sync.Action.PUT_APPLE].pressed.emit()
 check(sync.consumer_cards[0].text.contains("可取苹果"), "placing an apple makes its consumer eligible even without a wait request")
 sync.action_buttons[sync.Action.TAKE_APPLE].pressed.emit()
 check(sync.consumer_cards[0].text.contains("刚取到苹果") and sync.taken_counts == [1, 0], "successful take leaves its apple consumer highlighted")
 sync.guide_button.pressed.emit()
 for i in 2:
  sync.action_buttons[sync.GUIDE[i][0]].pressed.emit()
 check(sync.consumer_cards[0].text.contains("阻塞") and sync.consumer_cards[1].text.contains("可取橘子"), "orange cannot wake the apple consumer")
 for i in range(2, 4):
  sync.action_buttons[sync.GUIDE[i][0]].pressed.emit()
 check(sync.consumer_cards[0].text.contains("已唤醒"), "the guided apple activates its waiting consumer")
 sync.action_buttons[sync.Action.TAKE_APPLE].pressed.emit()
 check(not sync.is_guided() and sync.taken_counts == [1, 1] and sync.consumer_cards[0].text.contains("刚取到苹果"), "the guide ends with both consumers served")

 app._open_chapter(8)
 var io = chapter.active_lab
 io.load_example()
 for i in 3: io.advance()
 io.half_tick.pressed.emit()
 check(io.tick == 4 and io.intake_complete and io.buffered == 9 and io.pending == 6 and io.delivered == 9, "last tick shows all nine slots full before reading")
 check(io.phases[0].text.contains("可用 3 格") and io.slots[8].text.contains("刚放入") and not io.finish_run.disabled, "half-tick shows why only three fit and can still finish")
 io.finish_run.pressed.emit()
 check(io.generated == 24 and io.pending == 6 and io.buffered == 6 and io.delivered == 12 and io.history.size() == 4, "finishing the last half-tick conserves all twenty-four blocks")
 check(io.progress.text.contains("已结束") and io.whole_tick.disabled and io.half_tick.disabled and io.finish_run.disabled, "the observation stops and leaves the totals visible")
 io.advance()
 check(io.tick == 4 and io.generated == 24, "stepping past the end produces no new blocks")
 io.compare_toggle.button_pressed = true
 check(io.tick == 0 and io.compare_panel.visible, "opening the comparison starts both groups from zero")
 io.finish_run.pressed.emit()
 check(io.tick == 4 and io.buffered == 6 and io.delivered == 12 and io.compare_admitted == 24 and io.compare_delivered == 24, "both groups get the same input over the same number of ticks")
 check(io.device_wait_tiles[0].text.contains("设备等空位") and io.program_wait_tiles[1].text.contains("程序等数据") and io.program_wait_tiles[1].text.contains("只取到 6 块"), "comparison identifies which end is waiting and by how much")
 check(io.program_wait_tiles[0].text.contains("程序已取足") and io.device_wait_tiles[1].text.contains("设备未积压"), "the other endpoint is clearly marked as not waiting")
 io.target_ticks.value = 6
 check(io.tick == 0 and io.compare_delivered == 0 and io.progress.text.contains("还剩 6 拍"), "editing the target resets both groups and displays the new end")
 for i in 4: io.advance()
 io.device_rate.value = 0
 io.process_rate.value = 6
 io.run_to_end()
 check(io.generated == 24 and io.buffered == 0 and io.pending == 0 and io.delivered == 24, "the reader can drain waiting data over later ticks without new arrivals")
 io.capacity.value = 3
 check(io.tick == 0 and io.history.is_empty() and io.delivered == 0 and io.compare_delivered == 0, "changing capacity consistently resets the experiment")
 io.target_ticks.get_line_edit().text_changed.emit("999")
 check(io.input_hint.text.contains("1～20"), "oversized run duration gets a visible range hint")
 io.device_rate.value = 12
 check(io.input_hint.text.contains("只有 3 格"), "input above capacity explains why the device waits")

 app._open_chapter(9)
 var files = chapter.active_lab
 files.extend_file()
 check(files.indexes[0] == [1,4,8,2,5] and files.owner_of(5) == 0, "growth appends free blocks in logical order")
 files.amount.value = 12
 files.extend_file()
 check(files.indexes[0] == [1,4,8,2,5] and files.feedback.text.contains("只有 4 个"), "insufficient space leaves file untouched")
 files.delete_file()
 check(files.owner_of(1) == -1 and files.owner_of(0) == 1, "deleting A frees its blocks and preserves B")
 files.amount.value = 1
 files.create_file()
 check(files.indexes[0] == [1], "new file reuses the first released block")

 print("Chapter lab failures: ", failures)
 quit(1 if failures else 0)

func check(condition: bool, description: String):
 if not condition:
  failures += 1
  push_error("FAILED: " + description)

func check_control_colors(container: Node):
 for child in container.get_children(true):
  if child is Button:
   var states = {
    "font_color":"normal", "font_focus_color":"normal",
    "font_hover_color":"hover", "font_pressed_color":"pressed",
    "font_hover_pressed_color":"pressed", "font_disabled_color":"disabled"
   }
   for foreground in states:
    var background = child.get_theme_stylebox(states[foreground])
    check(contrast(child.get_theme_color(foreground), background.bg_color) >= 4.5, "%s %s contrast" % [child.text, foreground])
  elif child is LineEdit:
   var base = child.get_theme_stylebox("normal").bg_color
   for foreground in ["font_color", "font_placeholder_color"]:
    check(contrast(child.get_theme_color(foreground), base) >= 4.5, "input %s contrast" % foreground)
   check(contrast(child.get_theme_color("font_selected_color"), child.get_theme_color("selection_color")) >= 4.5, "input selection contrast")
  check_control_colors(child)

func contrast(foreground: Color, background: Color) -> float:
 var a = foreground.srgb_to_linear().get_luminance()
 var b = background.srgb_to_linear().get_luminance()
 return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)
