extends RefCounted
# Single CPU, integer time units, zero context-switch overhead.
static func run(arrival_text: String, burst_text: String, algorithm: int, quantum: int = 2) -> Dictionary:
 var arrivals = arrival_text.replace("，", ",").split(",", true)
 var bursts = burst_text.replace("，", ",").split(",", true)
 if arrivals.size() < 1 or arrivals.size() > 6 or arrivals.size() != bursts.size():
  return {"ok":false,"error":"请输入 1–6 个进程，且到达时间与运行时间的数量必须一致。"}
 if algorithm < 0 or algorithm > 4: return {"ok":false,"error":"请选择支持的调度算法。"}
 if algorithm == 4 and (quantum < 1 or quantum > 100): return {"ok":false,"error":"时间片必须在 1–100 之间。"}
 var pending: Array = []
 for i in arrivals.size():
  var at = arrivals[i].strip_edges()
  var bt = bursts[i].strip_edges()
  if not at.is_valid_int() or not bt.is_valid_int(): return {"ok":false,"error":"到达时间和运行时间必须是整数。"}
  var a = int(at)
  var b = int(bt)
  if a < 0 or a > 100: return {"ok":false,"error":"到达时间需要在 0–100 之间。"}
  if b < 1 or b > 100: return {"ok":false,"error":"运行时间需要在 1–100 之间。"}
  pending.append({"id":"P%d" % (i+1),"order":i,"arrival":a,"burst":b})
 if algorithm >= 3: return _preemptive(pending, algorithm, quantum)
 var events: Array = []
 var results: Array = []
 var time := 0
 while not pending.is_empty():
  var ready: Array = []
  for p in pending:
   if p.arrival <= time: ready.append(p)
  if ready.is_empty():
   var next_arrival = pending[0].arrival
   for p in pending: next_arrival = mini(next_arrival,p.arrival)
   events.append({"kind":"idle","start":time,"end":next_arrival})
   time = next_arrival
   continue
  ready.sort_custom(func(a,b): return a.arrival < b.arrival if a.arrival != b.arrival else a.order < b.order)
  var choice = ready[0]
  if algorithm == 1:
   for p in ready:
    if p.burst < choice.burst: choice = p
  elif algorithm == 2:
   for p in ready:
    var pn: int = time - p.arrival + p.burst
    var cn: int = time - choice.arrival + choice.burst
    if pn * choice.burst > cn * p.burst: choice = p
  var start = time
  time += choice.burst
  var turn = time - choice.arrival
  var waiting = start - choice.arrival
  var detail = {"kind":"run","id":choice.id,"arrival":choice.arrival,"burst":choice.burst,"start":start,"end":time,"waiting":waiting,"turnaround":turn,"weighted":float(turn)/choice.burst,"ready":ready.duplicate(true),"ratio":float(waiting + choice.burst)/choice.burst,"finished":true,"remaining_after":0}
  events.append(detail)
  results.append(detail)
  pending.erase(choice)
 var total_turn := 0.0
 var total_weighted := 0.0
 for item in results:
  total_turn += item.turnaround
  total_weighted += item.weighted
 return {"ok":true,"events":events,"results":results,"average_turnaround":total_turn/results.size(),"average_weighted":total_weighted/results.size(),"algorithm":algorithm}

static func _preemptive(input: Array, algorithm: int, quantum: int) -> Dictionary:
 var pending: Array = input.duplicate(true)
 pending.sort_custom(func(a,b): return a.arrival < b.arrival if a.arrival != b.arrival else a.order < b.order)
 for p in pending: p["remaining"] = p.burst
 var ready: Array = []
 var events: Array = []
 var results: Array = []
 var time := 0
 var last_id := ""
 while not pending.is_empty() or not ready.is_empty():
  if ready.is_empty() and not pending.is_empty() and pending[0].arrival > time:
   events.append({"kind":"idle","start":time,"end":pending[0].arrival})
   time = pending[0].arrival
   last_id = ""
  var had_arrival := false
  while not pending.is_empty() and pending[0].arrival <= time:
   ready.append(pending.pop_front())
   had_arrival = true
  if ready.is_empty(): continue
  var choice = ready[0]
  if algorithm == 3:
   for p in ready:
    if p.remaining < choice.remaining:
     choice = p
    elif p.remaining == choice.remaining:
     if p.id == last_id or (choice.id != last_id and (p.arrival < choice.arrival or (p.arrival == choice.arrival and p.order < choice.order))): choice = p
  var snapshot: Array = ready.duplicate(true)
  ready.erase(choice)
  var duration: int = mini(quantum,choice.remaining) if algorithm == 4 else 1
  var start = time
  time += duration
  choice.remaining -= duration
  var finished: bool = choice.remaining == 0
  var turnaround: int = time - choice.arrival if finished else -1
  var event = {"kind":"run","id":choice.id,"arrival":choice.arrival,"burst":choice.burst,"start":start,"end":time,"waiting":start-choice.arrival-(choice.burst-choice.remaining-duration),"turnaround":turnaround,"weighted":float(turnaround)/choice.burst if finished else 0.0,"ready":snapshot,"ratio":0.0,"finished":finished,"remaining_after":choice.remaining}
  if algorithm == 3 and not had_arrival and not events.is_empty() and events.back().kind == "run" and events.back().id == choice.id and events.back().end == start:
   events.back().end = time
   events.back().finished = finished
   events.back().remaining_after = choice.remaining
   if finished:
    events.back().turnaround = turnaround
    events.back().weighted = float(turnaround)/choice.burst
  else:
   events.append(event)
  if finished:
   results.append({"id":choice.id,"arrival":choice.arrival,"burst":choice.burst,"end":time,"turnaround":turnaround,"weighted":float(turnaround)/choice.burst,"waiting":turnaround-choice.burst})
  else:
   # Round-robin admits arrivals at the slice boundary before requeueing.
   if algorithm == 4:
    while not pending.is_empty() and pending[0].arrival <= time: ready.append(pending.pop_front())
   ready.append(choice)
  last_id = choice.id
 var total_turn := 0.0
 var total_weighted := 0.0
 for result in results:
  total_turn += result.turnaround
  total_weighted += result.weighted
 return {"ok":true,"events":events,"results":results,"average_turnaround":total_turn/results.size(),"average_weighted":total_weighted/results.size(),"algorithm":algorithm}
