extends SceneTree
const Replace=preload("res://replacement_model.gd")
var failures:=0
func _initialize(): call_deferred("run_tests")
func run_tests():
 var refs="7,0,1,2,0,3,0,4,2,3,0,3,2"
 var fifo=Replace.simulate(refs,"3",0)
 var lru=Replace.simulate(refs,"3",1)
 check(fifo.ok and fifo.faults==10 and fifo.hits==3,"FIFO known sequence")
 check(lru.ok and lru.faults==9 and lru.hits==4,"LRU known sequence")
 var sequence=Replace.simulate("1,2,1,3","2",1)
 check(sequence.events[3].victim==2 and sequence.events[3].frames==[1,3],"LRU updates use on hit")
 check(sequence.events[2].order_before==[1,2] and sequence.events[2].order_after==[2,1],"LRU access order is visible")
 var f=Replace.simulate("1,2,1,3","2",0)
 check(f.events[3].victim==1 and f.events[3].frames==[3,2],"FIFO does not update on hit")
 check(f.events[2].order_after==[1,2],"FIFO entry order is stable on hit")
 var belady="1,2,3,4,1,2,5,1,2,3,4,5"
 check(Replace.simulate(belady,"3",0).faults==9 and Replace.simulate(belady,"4",0).faults==10,"FIFO Belady example")
 check(not Replace.simulate("1,2","0",0).ok,"invalid frame count")
 check(not Replace.simulate("1,,2","2",0).ok,"invalid page list")
 var app=load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 app._show_chapters()
 app._open_chapter(7)
 check(app._has_replacement_modules() and app.replacement_container.visible,"chapter seven opens replacement")
 var lab=app.replacement_lab
 check(lab.data.ok and lab.step==0,"example ready")
 lab.address_requested.emit()
 check(app.address_container.visible and app.address_lab.replacement.visible,"chapter seven links to address diagram")
 var diagram=app.address_lab
 diagram._go_to(2)
 check(diagram.result.text.contains("1300 字节") and diagram.logical_row==1 and diagram.physical_row==1,"default paging lookup")
 diagram.address.text="20"
 diagram._go_to(2)
 check(diagram.result.text.contains("4116 字节") and diagram.physical_row==4,"nonconsecutive physical mapping")
 diagram.mode.select(1)
 diagram._reset_example()
 diagram._go_to(2)
 check(diagram.result.text.contains("1144 字节") and diagram.physical_row==1,"segment base plus offset")
 diagram.address.text="600"
 diagram.address.text_changed.emit("600")
 check(diagram.next.disabled and diagram.result.text.contains("0～599") and diagram.physical_row==-1,"segment end is out of bounds")
 diagram.mode.select(2)
 diagram._reset_example()
 diagram._go_to(2)
 check(diagram.result.text.contains("5396 字节") and diagram.table_row==1 and diagram.physical_row==5,"segmented paging uses the selected segment's page table")
 diagram.segment.select(2)
 diagram.segment.item_selected.emit(2)
 check(diagram.next.disabled and diagram.result.text.contains("0～767"),"segmented paging rejects padding past the segment")
 diagram.replacement_requested.emit()
 check(app.replacement_container.visible,"address diagram returns to replacement")
 lab.compare_toggle.button_pressed=true
 check(lab.compare_label.visible and lab.compare_label.text.contains("FIFO 缺页 10 次") and lab.compare_label.text.contains("LRU 缺页 9 次"),"compare replacement algorithms")
 for i in lab.data.events.size(): lab._next()
 check(lab.step==13 and lab.summary.text.contains("缺页 10 次"),"complete FIFO walkthrough")
 lab._restart_steps()
 for i in 4: lab._next()
 check(lab.access_caption.text.contains("从外存调入") and lab.frame_cards[0].text.contains("页 7 换成页 2"),"snapshot shows eviction in the updated frame")
 lab.algorithms.select(1)
 lab._changed("")
 check(lab.data.faults==9 and lab.step==0,"LRU recalculates")
 lab._belady()
 check(lab.algorithms.selected==0 and lab.data.faults==9,"load Belady example")
 app._remove_module("storage")
 check(not app.replacement_container.visible,"removing storage closes replacement")
 print("Replacement failures: ",failures)
 quit(1 if failures else 0)
func check(condition: bool, message: String):
 if not condition:
  push_error("FAILED: "+message)
  failures+=1
