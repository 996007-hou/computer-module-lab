extends "res://chapter_lab.gd"

const BLOCK_COUNT = 12
const FILE_NAMES = ["A.txt", "B.txt"]
var indexes: Array[Array] = [[], []]
var file: OptionButton
var amount: SpinBox
var disk: Array[Label] = []
var records: Array[Label] = []
var bitmap: Label

func _ready():
 build_intro("文件占了磁盘上的哪些块？", "创建、扩展或删除文件。图中磁盘块会立即变化，文件索引会保留各块在文件里的顺序。")
 var controls = add_row()
 file = OptionButton.new()
 for value in FILE_NAMES: file.add_item(value)
 controls.add_child(file)
 file.item_selected.connect(func(_index): render_tiles())
 controls.add_child(make_label("块数", 14, MUTED))
 amount = SpinBox.new()
 amount.min_value = 1
 amount.max_value = BLOCK_COUNT
 amount.value = 2
 amount.custom_minimum_size.x = 74
 controls.add_child(amount)
 make_button(controls, "创建", create_file)
 make_button(controls, "扩展", extend_file)
 make_button(controls, "删除", delete_file)
 make_button(controls, "载入分散示例", load_example)
 make_button(controls, "清空磁盘", reset)
 add_child(make_label("磁盘块", 17))
 for row_index in 2:
  var row = add_row()
  for i in 6: disk.append(make_tile(row, 54))
 bitmap = make_label("", 15, MUTED)
 add_child(bitmap)
 add_child(make_label("文件索引表 · 按文件逻辑顺序", 17))
 var table = add_row()
 for i in FILE_NAMES.size(): records.append(make_tile(table, 64))
 add_feedback()
 load_example()

func load_example():
 indexes = [[1, 4, 8], [0, 3, 9]]
 file.select(0)
 amount.value = 2
 feedback.text = "A.txt 的三个数据块分散在磁盘上。试着扩展 A.txt，看看新增的块接在索引表的哪里。"
 render_tiles()

func reset():
 indexes = [[], []]
 feedback.text = "12 个块均可分配。选择文件名和块数后，可以创建文件。"
 render_tiles()

func create_file():
 var index = file.selected
 if not indexes[index].is_empty():
  feedback.text = "%s 已存在。可点击“扩展”为它增加数据块。" % FILE_NAMES[index]
  return
 allocate(index, "创建")

func extend_file():
 var index = file.selected
 if indexes[index].is_empty():
  feedback.text = "%s 尚未创建，请先点击“创建”。" % FILE_NAMES[index]
  return
 allocate(index, "扩展")

func allocate(index: int, action: String):
 var free: Array[int] = []
 for block in BLOCK_COUNT:
  if owner_of(block) == -1: free.append(block)
 var count = int(amount.value)
 if free.size() < count:
  feedback.text = "需要 %d 个空闲块，目前只有 %d 个。可减少块数或删除文件后再试。" % [count, free.size()]
  return
 for i in count: indexes[index].append(free[i])
 feedback.text = "%s %s，分配了 %d 块。新块追加到文件索引末尾。" % [action, FILE_NAMES[index], count]
 render_tiles()

func delete_file():
 var index = file.selected
 var count = indexes[index].size()
 if count == 0:
  feedback.text = "%s 尚未创建。" % FILE_NAMES[index]
  return
 indexes[index].clear()
 feedback.text = "删除 %s，释放 %d 个磁盘块。" % [FILE_NAMES[index], count]
 render_tiles()

func owner_of(block: int) -> int:
 for index in indexes.size():
  if block in indexes[index]: return index
 return -1

func render_tiles():
 var bits: Array[String] = []
 for block in disk.size():
  var owner = owner_of(block)
  var content = "空闲"
  var tone = "idle"
  if owner != -1:
   content = "%s · 逻辑块 %d" % [FILE_NAMES[owner], indexes[owner].find(block)]
   tone = "active" if owner == file.selected else "info"
  bits.append("0" if owner == -1 else "1")
  show_tile(disk[block], "块 %02d\n%s" % [block, content], tone)
 bitmap.text = "空闲位图（0 空闲 / 1 已用）    " + "  ".join(bits)
 for i in records.size():
  var locations: Array[String] = []
  for block in indexes[i]: locations.append(str(block))
  var content = "文件未创建" if locations.is_empty() else " → ".join(locations)
  show_tile(records[i], FILE_NAMES[i] + "\n" + content, "active" if i == file.selected else "idle")
