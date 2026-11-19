extends RefCounted
# Basic paging: all pages must be resident; sizes are KiB, addresses are bytes.
static func calculate(program_text: String, page_text: String, frames_text: String, map_text: String, address_text: String) -> Dictionary:
 var fields = [program_text, page_text, frames_text, address_text]
 for text in fields:
  if not text.strip_edges().is_valid_int(): return {"ok": false, "error": "请在大小、页框数和地址中输入整数。"}
 var program = int(program_text)
 var page = int(page_text)
 var frames = int(frames_text)
 var address = int(address_text)
 if program < 1 or program > 64: return {"ok": false, "error": "程序大小需要在 1 到 64 KB 之间。"}
 if page not in [1, 2, 4, 8, 16]: return {"ok": false, "error": "页大小请选择 1、2、4、8 或 16 KB。"}
 if frames < 1 or frames > 32: return {"ok": false, "error": "物理页框数需要在 1 到 32 之间。"}
 var page_count = ceili(float(program) / page)
 if page_count > 8: return {"ok": false, "error": "程序需要 %d 页；演示最多支持 8 页，请调大页大小或减小程序。" % page_count}
 if page_count > frames: return {"ok": false, "error": "基本分页要求所有页面装入：%d 页需要至少 %d 个页框。" % [page_count, page_count]}
 if address < 0 or address >= program * 1024: return {"ok": false, "error": "逻辑地址超出程序范围，应为 0 到 %d 字节。" % (program * 1024 - 1)}
 var entries = map_text.replace("，", ",").split(",", true)
 if entries.size() != page_count: return {"ok": false, "error": "程序共 %d 页，页表需要填写 %d 个页框号。" % [page_count, page_count]}
 var mapping: Array = []
 for item in entries:
  var value = item.strip_edges()
  if not value.is_valid_int(): return {"ok": false, "error": "页表必须填写用逗号分隔的整数页框号。"}
  var frame = int(value)
  if frame < 0 or frame >= frames: return {"ok": false, "error": "页框号必须在 0 到 %d 之间。" % (frames - 1)}
  if mapping.has(frame): return {"ok": false, "error": "页框 %d 重复：此实验中不同页不能占用同一页框。" % frame}
  mapping.append(frame)
 var page_bytes = page * 1024
 var page_number = floori(float(address) / page_bytes)
 var offset = address % page_bytes
 var frame_number: int = mapping[page_number]
 return {"ok": true, "program":program, "page_size":page, "frame_count":frames, "page_count":page_count, "mapping":mapping, "address":address, "page":page_number, "offset":offset, "frame":frame_number, "physical":frame_number * page_bytes + offset, "internal_fragment":page_count * page_bytes - program * 1024}
