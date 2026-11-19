extends HBoxContainer
signal advance_requested
signal finish_requested
signal restart_requested
var play_button: Button
var finish_button: Button
var restart_button: Button
var status: Label
var timer: Timer
var valid := false
var current := 0
var total := 0
func _ready():
 add_theme_constant_override("separation", 8)
 play_button = Button.new()
 play_button.text = "▶ 自动演示"
 play_button.pressed.connect(_toggle)
 add_child(play_button)
 finish_button = Button.new()
 finish_button.text = "直接看结果"
 finish_button.pressed.connect(_finish)
 add_child(finish_button)
 restart_button = Button.new()
 restart_button.text = "重新开始"
 restart_button.pressed.connect(_restart)
 add_child(restart_button)
 status = Label.new()
 status.add_theme_font_size_override("font_size", 13)
 status.add_theme_color_override("font_color", Color("667788"))
 add_child(status)
 timer = Timer.new()
 timer.wait_time = 1.2
 timer.timeout.connect(_tick)
 add_child(timer)
 visibility_changed.connect(_visibility_changed)
 _update_buttons()
func set_state(is_valid: bool, current_step: int, total_steps: int):
 valid = is_valid
 current = current_step
 total = total_steps
 if not valid or current >= total: stop()
 _update_buttons()
func _update_buttons():
 if not is_instance_valid(play_button): return
 play_button.disabled = not valid or total <= 0
 finish_button.disabled = not valid or total <= 0 or current >= total
 restart_button.disabled = not valid or current <= 0
 status.text = "步骤 %d / %d" % [current, total] if valid and total > 0 else ""
func _toggle():
 if not valid or total <= 0: return
 if not timer.is_stopped():
  stop()
  return
 if current >= total: restart_requested.emit()
 if not valid or current >= total: return
 play_button.text = "Ⅱ 暂停"
 timer.start()
 _tick()
func _tick():
 if not valid or current >= total:
  stop()
  return
 advance_requested.emit()
 if not valid or current >= total: stop()
func _finish():
 stop()
 if valid and current < total: finish_requested.emit()
func _restart():
 stop()
 if valid and current > 0: restart_requested.emit()
func stop():
 if is_instance_valid(timer): timer.stop()
 if is_instance_valid(play_button): play_button.text = "▶ 自动演示"
func _visibility_changed():
 if not is_visible_in_tree(): stop()
