extends SceneTree
const Scheduler=preload("res://schedule_model.gd")
const Banker=preload("res://banker_model.gd")
const Paging=preload("res://paging_model.gd")
const Replacement=preload("res://replacement_model.gd")
var failures:=0
func _initialize(): call_deferred("run_tests")
func run_tests():
 seed(8023)
 for sample in 200:
  var count=randi_range(1,6)
  var arrivals: Array=[]
  var bursts: Array=[]
  var as_text: Array=[]
  var bs_text: Array=[]
  for i in count:
   arrivals.append(randi_range(0,10))
   bursts.append(randi_range(1,10))
   as_text.append(str(arrivals[i]))
   bs_text.append(str(bursts[i]))
  for alg in 5:
   var run=Scheduler.run(",".join(as_text),",".join(bs_text),alg,randi_range(1,4))
   if not run.ok:
    fail("generated valid schedule rejected")
    continue
   var remaining=bursts.duplicate()
   var completed=[]
   completed.resize(count)
   completed.fill(-1)
   var cursor=0
   for event in run.events:
    if event.start != cursor or event.end <= event.start: fail("timeline gap or invalid interval")
    if event.kind == "idle":
     for i in count:
      if arrivals[i] <= event.start and remaining[i] > 0: fail("CPU idle with runnable process")
    else:
     var id=int(event.id.trim_prefix("P"))-1
     if id < 0 or id >= count:
      fail("invalid process id")
      continue
     if arrivals[id] > event.start: fail("process ran before arrival")
     for tick in range(event.start,event.end):
      if alg==3:
       for j in count:
        if arrivals[j] <= tick and remaining[j] > 0 and remaining[j] < remaining[id]: fail("SRTF did not choose shortest remaining")
      remaining[id]-=1
      if remaining[id] < 0: fail("process executed too long")
      if remaining[id]==0: completed[id]=tick+1
    cursor=event.end
   for i in count:
    if remaining[i] != 0 or completed[i] < 0: fail("process unfinished")
   var avg:=0.0
   var avgw:=0.0
   for i in count:
    var turn=completed[i]-arrivals[i]
    avg+=turn
    avgw+=float(turn)/bursts[i]
   if not is_equal_approx(avg/count,run.average_turnaround) or not is_equal_approx(avgw/count,run.average_weighted): fail("summary mismatch")
 for sample in 200:
  var page=[1,2,4,8,16][randi_range(0,4)]
  var count=randi_range(1,8)
  var program=randi_range(maxi(1,(count-1)*page+1),mini(64,count*page)) if (count-1)*page+1 <= 64 else 1
  count=ceili(float(program)/page)
  var frames=maxi(count,randi_range(1,12))
  var pool: Array=[]
  for x in frames: pool.append(x)
  pool.shuffle()
  var map: Array=[]
  var map_text: Array=[]
  for x in count:
   map.append(pool[x])
   map_text.append(str(pool[x]))
  var address=randi_range(0,program*1024-1)
  var outcome=Paging.calculate(str(program),str(page),str(frames),",".join(map_text),str(address))
  if not outcome.ok or outcome.physical != map[address/(page*1024)]*(page*1024)+address%(page*1024): fail("paging translation mismatch")
 for sample in 200:
  var totals=[randi_range(2,7),randi_range(2,7)]
  var remain=totals.duplicate()
  var allocations: Array=[]
  var maximum: Array=[]
  for i in 3:
   var a=[randi_range(0,remain[0]),randi_range(0,remain[1])]
   remain[0]-=a[0]
   remain[1]-=a[1]
   allocations.append(a)
   maximum.append([randi_range(a[0],totals[0]),randi_range(a[1],totals[1])])
  var pid=randi_range(0,2)
  var req=[randi_range(0,mini(remain[0],maximum[pid][0]-allocations[pid][0])),randi_range(0,mini(remain[1],maximum[pid][1]-allocations[pid][1]))]
  var max_strings: Array=[]
  var alloc_strings: Array=[]
  for i in 3:
   max_strings.append("%d,%d" % maximum[i])
   alloc_strings.append("%d,%d" % allocations[i])
  var result=Banker.evaluate("%d,%d" % totals,";".join(max_strings),";".join(alloc_strings),"%d,%d" % req,str(pid+1))
  var trial=allocations.duplicate(true)
  trial[pid][0]+=req[0]
  trial[pid][1]+=req[1]
  var work=[remain[0]-req[0],remain[1]-req[1]]
  var expected=can_finish(maximum,trial,work,[false,false,false])
  if not result.ok or result.safe != expected: fail("banker safety mismatch")
 for sample in 200:
  var capacity=randi_range(1,6)
  var values: Array=[]
  var texts: Array=[]
  for i in 12:
   var value=randi_range(0,7)
   values.append(value)
   texts.append(str(value))
  for alg in 2:
   var actual=Replacement.simulate(",".join(texts),str(capacity),alg)
   var resident: Array=[]
   var entered: Dictionary={}
   var used: Dictionary={}
   for i in values.size():
    var value=values[i]
    var victim=-1
    var missed=not resident.has(value)
    if missed:
     if resident.size()==capacity:
      victim=resident[0]
      for p in resident:
       if (entered[p] if alg==0 else used[p]) < (entered[victim] if alg==0 else used[victim]): victim=p
      resident.erase(victim)
     resident.append(value)
     entered[value]=i
    used[value]=i
    if actual.events[i].fault != missed or actual.events[i].victim != victim: fail("page replacement mismatch")
 var app=load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 for sample in 200:
  app.segments=[]
  var start=0
  for i in randi_range(1,8):
   var length=randi_range(1,100)
   app.segments.append({"start":start,"size":length,"free":bool(randi()%2),"name":""})
   start+=length
  var requested=randi_range(1,100)
  for alg in 3:
   var chosen=app._choose(alg,requested)
   var candidates: Array=[]
   for i in app.segments.size():
    if app.segments[i].free and app.segments[i].size>=requested: candidates.append(i)
   if candidates.is_empty():
    if chosen != -1: fail("allocation selected with no candidate")
    continue
   if not candidates.has(chosen):
    fail("allocation selected invalid candidate")
    continue
   for i in candidates:
    if alg==0 and i<chosen: fail("first fit skipped earlier candidate")
    if alg==1 and app.segments[i].size<app.segments[chosen].size: fail("best fit skipped smaller candidate")
    if alg==2 and app.segments[i].size>app.segments[chosen].size: fail("worst fit skipped larger candidate")
    if alg>0 and app.segments[i].size==app.segments[chosen].size and i<chosen: fail("allocation tie order")
 print("Invariant failures: ",failures)
 quit(1 if failures else 0)
func can_finish(maximum: Array, allocation: Array, work: Array, done: Array) -> bool:
 if done.all(func(v): return v): return true
 for i in done.size():
  if done[i]: continue
  if maximum[i][0]-allocation[i][0] <= work[0] and maximum[i][1]-allocation[i][1] <= work[1]:
   var new_work=[work[0]+allocation[i][0],work[1]+allocation[i][1]]
   var next=done.duplicate()
   next[i]=true
   if can_finish(maximum,allocation,new_work,next): return true
 return false
func fail(message: String):
 if failures < 10: push_error(message)
 failures+=1
