extends RefCounted
# Banker's algorithm: evaluate a request on a temporary snapshot.
static func evaluate(total_text: String, max_text: String, alloc_text: String, request_text: String, process_text: String) -> Dictionary:
 var total = _vector(total_text)
 var max_rows = _matrix(max_text)
 var alloc_rows = _matrix(alloc_text)
 var request = _vector(request_text)
 if total.is_empty() or total.size() > 4: return _error("资源总量需要 1–4 个非负整数，以逗号分隔。")
 if max_rows.is_empty() or max_rows.size() > 6 or max_rows.size() != alloc_rows.size(): return _error("最大需求与已分配矩阵需要 1–6 行，且行数一致；各行用分号隔开。")
 if request.size() != total.size(): return _error("请求向量的资源种类数量必须与总量一致。")
 if not process_text.strip_edges().is_valid_int(): return _error("请求进程编号应为整数，例如 1。")
 var pid = int(process_text)-1
 if pid < 0 or pid >= max_rows.size(): return _error("请求进程编号需要在 1–%d 之间。" % max_rows.size())
 var available: Array = total.duplicate()
 var needs: Array = []
 for i in max_rows.size():
  if max_rows[i].size() != total.size() or alloc_rows[i].size() != total.size(): return _error("矩阵每行的资源种类数量必须与总量一致。")
  var row: Array = []
  for j in total.size():
   if alloc_rows[i][j] > max_rows[i][j]: return _error("P%d 的已分配量不能超过最大需求。" % (i+1))
   if max_rows[i][j] > total[j]: return _error("P%d 的最大需求不能超过对应资源总量。" % (i+1))
   available[j] -= alloc_rows[i][j]
   row.append(max_rows[i][j]-alloc_rows[i][j])
  needs.append(row)
 for value in available:
  if value < 0: return _error("已分配资源总和不能超过资源总量。")
 var base = {"ok":true,"pid":pid,"available":available.duplicate(),"need":needs.duplicate(true),"request":request.duplicate(),"allocation":alloc_rows.duplicate(true),"total":total.duplicate()}
 for j in total.size():
  if request[j] > needs[pid][j]:
   base.merge({"status":"exceeds_need","message":"请求超过该进程剩余需求，不能受理。"})
   return base
 for j in total.size():
  if request[j] > available[j]:
   base.merge({"status":"wait","message":"当前可用资源不足，进程需要等待。"})
   return base
 var work: Array = available.duplicate()
 var tentative_alloc: Array = alloc_rows.duplicate(true)
 var tentative_need: Array = needs.duplicate(true)
 for j in total.size():
  work[j] -= request[j]
  tentative_alloc[pid][j] += request[j]
  tentative_need[pid][j] -= request[j]
 var initial_work=work.duplicate()
 var finished: Array = []
 finished.resize(max_rows.size())
 finished.fill(false)
 var sequence: Array = []
 var trace: Array = []
 while sequence.size() < max_rows.size():
  var chosen := -1
  for i in max_rows.size():
   if finished[i]: continue
   var fits := true
   for j in total.size():
    if tentative_need[i][j] > work[j]: fits = false
   if fits:
    chosen=i
    break
  if chosen < 0: break
  var before=work.duplicate()
  for j in total.size(): work[j] += tentative_alloc[chosen][j]
  finished[chosen]=true
  sequence.append(chosen+1)
  trace.append({"pid":chosen+1,"before":before,"need":tentative_need[chosen].duplicate(),"released":tentative_alloc[chosen].duplicate(),"after":work.duplicate()})
 var safe=sequence.size() == max_rows.size()
 base.merge({"status":"safe" if safe else "unsafe","safe":safe,"initial_work":initial_work,"trace":trace,"sequence":sequence,"tentative_need":tentative_need,"tentative_allocation":tentative_alloc,"message":"存在安全序列，可以批准请求。" if safe else "找不到完整的安全序列，不批准此次请求。"})
 return base
static func _error(message: String) -> Dictionary:
 return {"ok":false,"error":message}
static func _vector(text: String) -> Array:
 var parts=text.replace("，",",").split(",",true)
 var out: Array = []
 for raw in parts:
  var item=raw.strip_edges()
  if not item.is_valid_int(): return []
  var n=int(item)
  if n < 0 or n > 100: return []
  out.append(n)
 return out
static func _matrix(text: String) -> Array:
 var out: Array = []
 for row in text.replace("；",";").split(";",true):
  var vec=_vector(row)
  if vec.is_empty(): return []
  out.append(vec)
 return out
