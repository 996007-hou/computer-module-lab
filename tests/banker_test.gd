extends SceneTree
const Banker = preload("res://banker_model.gd")
var failures := 0
func _initialize(): call_deferred("run_tests")
func run_tests():
 var total="10,5,7"
 var mx="7,5,3;3,2,2;9,0,2;2,2,2"
 var alloc="0,1,0;2,0,0;3,0,2;2,1,1"
 var safe=Banker.evaluate(total,mx,alloc,"1,0,2","1")
 check(safe.ok and safe.status=="safe", "classroom request safe")
 check(safe.available==[3,3,4] and safe.need[0]==[7,4,3], "classroom available and need")
 check(safe.initial_work==[2,3,2] and safe.sequence==[2,4,1,3], "classroom safe sequence")
 check(safe.trace[0].before==[2,3,2] and safe.trace[0].after==[4,3,2], "release updates work")
 check(safe.allocation[0]==[0,1,0] and safe.available==[3,3,4], "hypothetical allocation preserves original")
 var exceed=Banker.evaluate(total,mx,alloc,"8,0,0","1")
 check(exceed.ok and exceed.status=="exceeds_need", "excess need rejected")
 var wait=Banker.evaluate(total,mx,alloc,"4,0,0","1")
 check(wait.ok and wait.status=="wait", "insufficient available")
 var unsafe=Banker.evaluate("4","4;4","1;1","1","1")
 check(unsafe.ok and unsafe.status=="unsafe", "unsafe tentative allocation rejected")
 check(not Banker.evaluate("3","1;2","2;1","0","1").ok, "allocation exceeds max rejected")
 check(not Banker.evaluate("3","3;3","2;2","0","1").ok, "allocation exceeds total rejected")
 check(not Banker.evaluate("3,2","3,2;3,2","1;1,0","0,0","1").ok, "matrix dimensions rejected")
 var app=load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 app._begin_explore()
 app._add_banker_example()
 check(app._has_banker_modules() and app.banker_topic.visible and app.topic_panel.visible, "banker module combination")
 app._start_banker()
 check(app.banker_container.visible and not app.schedule_container.visible, "open banker experiment")
 var lab=app.banker_lab
 check(lab.info.ok and lab.info.status=="safe" and lab.step==0, "classroom example ready")
 lab.matrix_inputs[0][0][0].text="8"
 lab._matrix_changed("8")
 check(lab.info.ok and lab.info.need[0][0]==8, "matrix cells update need")
 lab._reset()
 lab._toggle_mode()
 check(lab.safety_only and lab.info.initial_work==lab.info.available, "safety check uses current state without request")
 lab._show_all()
 check(lab.explanation.text.contains("安全序列") and lab.detail.text.contains("当前状态"), "safety-only conclusion")
 lab._toggle_mode()
 check(not lab.safety_only and lab.info.initial_work==[2,3,2], "request mode preserves request")
 lab._add_process()
 check(lab.info.ok and lab.info.need.size()==5 and lab.matrix_inputs.size()==5, "add process")
 lab._remove_process()
 lab._add_resource()
 check(lab.info.ok and lab.info.total.size()==4 and lab.matrix_inputs[0][0].size()==4, "add resource")
 lab._remove_resource()
 check(lab.info.ok and lab.info.total.size()==3 and lab.info.need.size()==4, "remove added dimensions")
 lab._reset()
 lab._next()
 check(lab.available_label.text.contains("(2, 3, 2)") and lab.table.get_child(7).text=="(1, 1, 2)", "tentative work and allocation shown")
 lab._next()
 check(lab.available_label.text.contains("(4, 3, 2)") and lab.table.get_child(14).text=="完成", "finish state and returned resources shown")
 for i in lab.info.trace.size(): lab._next()
 check(lab.explanation.text.contains("P2 → P4 → P1 → P3"), "classroom safe sequence walkthrough")
 lab.request.text="8,0,0"
 lab._changed("")
 check(lab.info.status=="exceeds_need" and lab.next.disabled, "reject request beyond need")
 app._remove_module("resource")
 check(not app.banker_container.visible and app.empty_hint.visible, "remove required resource module")
 print("Banker failures: ", failures)
 quit(1 if failures else 0)
func check(condition: bool, name: String):
 if not condition:
  push_error("FAILED: " + name)
  failures += 1
