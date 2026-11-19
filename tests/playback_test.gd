extends SceneTree
var failures := 0
func _initialize(): call_deferred("run_tests")
func run_tests():
 var app=load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 app._start_from_home()
 app._start_paging()
 var paging=app.paging_lab
 paging.player._toggle()
 check(paging.step==1 and not paging.player.timer.is_stopped(),"paging starts and advances")
 paging._previous()
 check(paging.step==0 and paging.player.timer.is_stopped(),"previous pauses playback")
 paging.practice.button_pressed=true
 paging.player._finish()
 check(paging.step==3 and not paging.revealed and not paging.explanation.text.contains(str(paging.info.physical)),"direct result respects practice")
 paging.player._restart()
 check(paging.step==0,"restart returns to first step")
 paging.player._toggle()
 app._back_to_topics()
 await process_frame
 check(paging.player.timer.is_stopped(),"leaving paging stops timer")
 app._add_schedule_example()
 app._start_schedule()
 var scheduler=app.schedule_lab
 scheduler.player._finish()
 check(scheduler.step==scheduler.data.events.size() and scheduler.metrics.text.contains("平均周转时间"),"schedule direct result")
 scheduler.player._toggle()
 check(scheduler.step==1 and not scheduler.player.timer.is_stopped(),"play from end restarts")
 scheduler.arrivals.text="-1"
 scheduler._changed("")
 check(scheduler.player.timer.is_stopped() and scheduler.player.play_button.disabled,"invalid edit stops playback")
 app._add_banker_example()
 app._start_banker()
 var banker=app.banker_lab
 banker.player._finish()
 check(banker.step==banker.info.trace.size()+2 and banker.info.safe,"banker direct result")
 banker.player._restart()
 banker.player._toggle()
 app._show_home()
 await process_frame
 check(banker.player.timer.is_stopped(),"home stops banker playback")
 app._add_virtual_example()
 app._begin_explore()
 app._start_replacement()
 var replacement=app.replacement_lab
 replacement.player._finish()
 check(replacement.step==replacement.data.events.size() and replacement.summary.text.contains("缺页 10 次"),"replacement direct result")
 replacement.player._restart()
 replacement.player._toggle()
 app._remove_module("storage")
 await process_frame
 check(replacement.player.timer.is_stopped(),"removing module stops playback")
 print("Playback failures: ",failures)
 quit(1 if failures else 0)
func check(condition: bool, message: String):
 if not condition:
  push_error("FAILED: "+message)
  failures+=1
