extends RefCounted
# Request paging: one process, equal-sized physical frames, no dirty-page cost.
static func simulate(reference_text: String, frame_text: String, algorithm: int) -> Dictionary:
 if not frame_text.strip_edges().is_valid_int(): return {"ok":false,"error":"页框数必须是整数。"}
 var capacity=int(frame_text)
 if capacity<1 or capacity>6: return {"ok":false,"error":"页框数需要在 1–6 之间。"}
 if algorithm not in [0,1]: return {"ok":false,"error":"请选择 FIFO 或 LRU。"}
 var parts=reference_text.replace("，",",").split(",",true)
 if parts.size()<1 or parts.size()>16: return {"ok":false,"error":"请输入 1–16 个页号，以逗号分隔。"}
 var refs: Array=[]
 for part in parts:
  var t=part.strip_edges()
  if not t.is_valid_int() or int(t)<0 or int(t)>99: return {"ok":false,"error":"页号应为 0–99 的整数。"}
  refs.append(int(t))
 var frames: Array=[]
 frames.resize(capacity)
 frames.fill(-1)
 var order: Array=[]
 var events: Array=[]
 var faults=0
 for page in refs:
  var order_before=order.duplicate()
  var index=frames.find(page)
  var fault=index<0
  var victim=-1
  if fault:
   faults+=1
   index=frames.find(-1)
   if index<0:
    victim=order.pop_front()
    index=frames.find(victim)
   frames[index]=page
   order.append(page)
  elif algorithm==1:
   order.erase(page)
   order.append(page)
  events.append({"page":page,"fault":fault,"victim":victim,"frame":index,"frames":frames.duplicate(),"faults":faults,"order_before":order_before,"order_after":order.duplicate()})
 return {"ok":true,"events":events,"references":refs,"frame_count":capacity,"faults":faults,"hits":refs.size()-faults,"algorithm":algorithm}
