extends "res://chapter_lab.gd"

const CACHE_PATH = [
 ["读取开始", "应用发起 read 请求，CPU 进入内核处理系统调用。", [0,1], ["发起 read", "进入内核", "等待查询", "空闲"]],
 ["缓存命中", "内核在内存页缓存里找到了数据，直接复制到应用的缓冲区。", [1,2], ["等待返回", "复制数据", "页缓存 → 用户缓冲区", "本次无需访问"]],
 ["应用继续运行", "read 返回后，应用继续处理读到的数据。", [0], ["收到文件数据", "返回用户态", "用户缓冲区已填充", "空闲"]]
]
const DISK_PATH = [
 CACHE_PATH[0],
 ["提交设备读取", "页缓存中没有目标数据。内核提交读取请求，让进程 A 进入阻塞。", [1,3], ["A 等待 I/O", "A 阻塞", "准备接收数据", "接到读取请求"]],
 ["设备和 CPU 并行工作", "设备将数据传入内存，这段时间可以让就绪的进程 B 使用 CPU。", [1,2,3], ["A 仍在等待", "B 正在运行", "接收数据", "读取并传输"]],
 ["I/O 完成中断", "设备通过中断通知 CPU 读取完成。内核唤醒进程 A，把它放回就绪队列。", [1,2,3], ["A 就绪，等待 CPU", "处理中断", "页缓存已填充", "报告完成"]],
 ["应用继续运行", "A 再次被调度后，内核完成本次 read，应用继续处理数据。", [0,1,2], ["收到文件数据", "A 恢复执行", "数据交给用户缓冲区", "空闲"]]
]
const MODULES = ["应用 / 进程 A", "操作系统 / CPU", "内存", "外存设备"]
const CACHE_LINKS = [["→", "", ""], ["", "←", ""], ["←", "←", ""]]
const DISK_LINKS = [["→", "", ""], ["", "", ""], ["", "", "←"], ["", "", ""], ["←", "←", ""]]

var scenario: OptionButton
var cards: Array[Label] = []
var links: Array[Label] = []
var history: Label
var advance: Button
var step := -1

func _ready():
 build_intro("一次文件读取", "操作系统会把部分文件数据暂存在内存中，这部分叫页缓存。切换缓存条件，观察读取是否需要访问外存设备。")
 var controls = add_row()
 scenario = OptionButton.new()
 scenario.add_item("数据已在页缓存")
 scenario.add_item("数据需要从磁盘读取")
 scenario.select(1)
 scenario.item_selected.connect(func(_index): reset())
 controls.add_child(scenario)
 advance = make_button(controls, "发起读取", next_event)
 make_button(controls, "重置", reset)
 var row = add_row()
 for i in MODULES.size():
  if i > 0:
   var link = make_label("", 22, GREEN)
   link.custom_minimum_size.x = 24
   link.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   row.add_child(link)
   links.append(link)
  cards.append(make_tile(row, 112))
 add_feedback()
 add_child(make_label("读取事件记录", 15, MUTED))
 history = make_label("", 15, INK, true)
 add_child(history)
 render()

func reset():
 step = -1
 render()

func next_event():
 var path = selected_path()
 if step >= path.size() - 1: return
 step += 1
 render()

func selected_path() -> Array:
 return CACHE_PATH if scenario.selected == 0 else DISK_PATH

func render():
 var path = selected_path()
 var current = path[step] if step >= 0 else []
 var transfers = CACHE_LINKS if scenario.selected == 0 else DISK_LINKS
 for i in links.size(): links[i].text = transfers[step][i] if step >= 0 else ""
 var start = ["A 正在运行", "CPU 正在执行 A", "待读取", "空闲"]
 for i in MODULES.size():
  var value: String = start[i] if current.is_empty() else current[3][i]
  var tone = "active" if not current.is_empty() and i in current[2] else "idle"
  if i == 0 and scenario.selected == 1 and step in [1, 2]: tone = "waiting"
  show_tile(cards[i], MODULES[i] + "\n" + value, tone)
 advance.text = "发起读取" if step < 0 else "推进下一事件"
 advance.disabled = step == path.size() - 1
 feedback.text = "选择缓存条件后，点击“发起读取”。" if current.is_empty() else current[1]
 var entries: Array[String] = []
 for i in step + 1: entries.append("%d   %s" % [i + 1, path[i][0]])
 history.text = "\n".join(entries) if not entries.is_empty() else "尚未发起请求"
