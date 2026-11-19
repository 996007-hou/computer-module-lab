extends SceneTree
var failures := 0
const Paging = preload("res://paging_model.gd")
func _initialize(): call_deferred("run_tests")
func run_tests():
 var a = Paging.calculate("10","2","8","2,3,6,5,7","4520")
 check(a.ok and a.page == 2 and a.offset == 424 and a.frame == 6 and a.physical == 12712, "example translation")
 check(a.page_count == 5 and a.internal_fragment == 0, "page count and exact fragmentation")
 var b = Paging.calculate("9","2","8","2,3,6,5,7","9215")
 check(b.ok and b.page == 4 and b.offset == 1023 and b.physical == 15359 and b.internal_fragment == 1024, "last byte with internal fragmentation")
 check(not Paging.calculate("9","2","8","2,3,6,5,7","9216").ok, "address at end is out of range")
 check(not Paging.calculate("10","2","8","2,3,6,5,5","1").ok, "duplicate frame rejected")
 check(not Paging.calculate("10","2","8","2,3,6,5,8","1").ok, "frame beyond limit rejected")
 check(not Paging.calculate("10","2","8","2,3,6,5","1").ok, "missing frame rejected")
 check(not Paging.calculate("10","2","4","0,1,2,3,0","1").ok, "insufficient frames rejected")
 check(not Paging.calculate("10","3","8","0,1,2,3","1").ok, "unsupported page size rejected")
 var large=Paging.calculate("12","2","22","2,3,6,10,21,0","8200")
 check(large.ok and large.page==4 and large.frame==21 and large.physical==43016, "classroom-sized frame numbers")
 check(not Paging.calculate("12","2","33","2,3,6,10,21,0","8200").ok, "frame limit")
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 app._add_example()
 app._begin_explore()
 app._start_paging()
 check(app.paging_container.visible and not app.experiment.visible, "paging topic opens")
 var lab = app.paging_lab
 check(lab.info.ok and lab.step == 0, "paging example is ready")
 lab._next()
 lab._next()
 lab._next()
 check(lab.step == 3 and lab.info.physical == 12712 and lab.next_button.disabled, "three-step walkthrough")
 lab.practice.button_pressed=true
 check(lab.answer_row.visible and not lab.explanation.text.contains("12712"), "practice hides answer")
 lab.answer.text="12711"
 lab._check_answer()
 check(not lab.revealed and lab.feedback.text.contains("再检查"), "practice gives helpful feedback")
 lab.answer.text="12712"
 lab._check_answer()
 check(lab.revealed and lab.feedback.text.contains("正确"), "practice accepts correct answer")
 lab.practice.button_pressed=false
 lab._previous()
 check(lab.step == 2, "previous step")
 lab.mapping.text = "2,3,6,5,5"
 lab._changed("")
 check(not lab.info.ok and lab.next_button.disabled, "invalid edit stops walkthrough")
 lab._reset_example()
 check(lab.info.ok and lab.step == 0, "restore preset")
 lab._classroom_example()
 check(lab.info.ok and lab.info.page_count == 6 and lab.info.page_size == 2, "classroom example has six pages")
 lab.frames.text="22"
 lab.mapping.text="2,3,6,10,21,0"
 lab._changed("")
 check(lab.info.ok and lab.diagram.custom_minimum_size.y>=636, "larger classroom frame numbers remain scrollable")
 app._back_to_topics()
 check(app.topic_panel.visible and not app.paging_container.visible, "return to topic selection")
 app._start_experiment()
 check(app.experiment.visible and not app.paging_container.visible, "existing experiment remains accessible")
 app._start_paging()
 app._remove_module("memory")
 check(not app.paging_container.visible and app.empty_hint.visible, "removing required module closes paging")
 print("Paging failures: ", failures)
 quit(1 if failures else 0)
func check(condition: bool, name: String):
 if not condition:
  push_error("FAILED: " + name)
  failures += 1
