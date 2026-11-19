# 个性化修改指南

这份指南给教师和协助改课件的 AI 使用。把**章号、要改的内容、希望看到的效果**发给 AI，再让它按下表读取对应的文件和函数。函数名可以在编辑器内直接搜索，代码移动后仍然能找到。

## 先选要改什么

- **改知识点或练习。** 第 1～3、8、9 章从 [chapter_material.gd](chapter_material.gd) 对应的 `CONTENT[章号]` 开始。讲解用 `context`，分步示意用 `steps`。练习用 `quiz`、`options`、`answer` 和 `why`，正确选项的下标从 `0` 开始。知识点缺少独立的 `steps` 或 `question` 时，默认内容来自 [chapter_intro.gd](chapter_intro.gd) 的 `LESSONS[章号]`。
- **改实验展示。** 从下表的「展示与默认值」开始。调整卡片、图表、配色、按钮提示或初始数据时，先读列出的界面函数。
- **改实验规则。** 从下表的「规则与验证」开始，并查看那一章的测试。涉及多个页面时，再读取共享界面或导航代码。

## 按章定位

| 章与实验 | 展示与默认值 | 规则与验证 |
| --- | --- | --- |
| 1 操作系统概述 · 文件读取 | [read_file_lab.gd](read_file_lab.gd) 的 `CACHE_PATH`、`DISK_PATH` 保存缓存和磁盘两套步骤。`CACHE_LINKS`、`DISK_LINKS` 与 `render()` 控制箭头、卡片和事件记录。 | 同文件的 `selected_path()`、`next_event()` 控制读取路径和事件推进。 |
| 2 进程、线程管理 · PCB 与换班 | [process_states_lab.gd](process_states_lab.gd) 的 `GUIDE` 改新手引导顺序和文案，`update_actions()` 改推荐按键，`render()` 改队列和 PCB 卡片。 | 同文件的 `dispatch()`、`expire_slice()`、`block_for_io()`、`finish_io()` 和 `execute_instruction()` 控制进程状态和执行进度。 |
| 3 进程同步与通信 · 水果盘、信号量 | 水果盘在 [fruit_sync_lab.gd](fruit_sync_lab.gd) 的 `GUIDE`、`update_guide()` 和 `render()`。独立 P/V 实验的按钮、课堂示范和画面在 [semaphore_lab.gd](semaphore_lab.gd) 的 `_ready()`、`_advance_demo()` 和 `_render()`。 | 水果盘的放取和等待状态在 `put_fruit()`、`take_fruit()`。P/V 规则在 [semaphore_model.gd](semaphore_model.gd) 的 `p()`、`v()`、`resume_process()`，用 [semaphore_test.gd](tests/semaphore_test.gd) 验证。 |
| 4 处理机调度 | [schedule.gd](schedule.gd) 的 `_ready()` 设置算法菜单和默认数据，`_render()` 显示候选进程与指标，时间轴在 [schedule_view.gd](schedule_view.gd)。 | [schedule_model.gd](schedule_model.gd) 的 `run()`、`_preemptive()`。对照 [schedule_test.gd](tests/schedule_test.gd) 的执行顺序、到达边界和时间片用例。 |
| 5 死锁 · 银行家算法 | [banker.gd](banker.gd) 的 `_ready()`、`_reset()` 管理界面和默认值，`_rebuild_matrix()` 改矩阵，`_render()` 改试分配和安全序列的显示。 | [banker_model.gd](banker_model.gd) 的 `evaluate()`。对照 [banker_test.gd](tests/banker_test.gd) 检查请求超限、资源不足和安全序列。 |
| 6 内存管理 · 动态分区、基本分页 | 分区预设在 [main.gd](main.gd) 的 `_on_preset()`，分区图在 [memory_view.gd](memory_view.gd) 的 `_draw()`。分页讲解和画面在 [paging.gd](paging.gd) 的 `_render()` 与 [paging_view.gd](paging_view.gd)。 | 分区查找、分配和紧凑在 `main.gd` 的 `_choose()`、`_allocate_now()`、`_compact()`，测试见 [smoke.gd](tests/smoke.gd)。分页的页号、偏移和物理地址在 [paging_model.gd](paging_model.gd) 的 `calculate()`，测试见 [paging_test.gd](tests/paging_test.gd)。 |
| 7 虚拟存储 · 页面置换、地址转换图解 | [replacement.gd](replacement.gd) 的 `_ready()` 改输入与默认值，`_render()`、`_render_snapshot()` 改缺页步骤和页框图。[address_lab.gd](address_lab.gd) 的 `_render_paging()`、`_render_segments()`、`_render_segment_pages()` 对应分页、分段、段页式图解。 | FIFO、LRU 在 [replacement_model.gd](replacement_model.gd) 的 `simulate()`，测试见 [replacement_test.gd](tests/replacement_test.gd)。改地址图解时，检查页内偏移是否保持、段内越界是否被拒绝。 |
| 8 I/O 设备管理 · 缓冲区 | [io_buffer_lab.gd](io_buffer_lab.gd) 的 `_ready()`、`load_example()` 管理输入和默认参数，`build_comparison()`、`render_comparison()` 管理 A/B 图，`render()`、`render_phases()` 管理单拍画面。 | 同文件的 `advance()`、`advance_half()`、`run_to_end()`、`receive_from_device()`、`available_transfer()` 和 `read_from_buffer()`。按下方索引选读。 |
| 9 文件系统 · 文件块与位图 | [file_blocks_lab.gd](file_blocks_lab.gd) 的 `load_example()` 改初始文件块，`render_tiles()` 改索引、磁盘块与位图的展示。 | 同文件的 `allocate()`、`delete_file()` 和 `owner_of()` 控制分配、回收和块归属。 |

第 1～3、8、9 章可在 [chapter_labs_test.gd](tests/chapter_labs_test.gd) 搜索 `app._open_chapter(章号)`，只看对应章的断言。按 [README](README.md) 配好 Godot 后，可以运行 [运行检查.bat](%E8%BF%90%E8%A1%8C%E6%A3%80%E6%9F%A5.bat)。

## 第 8 章修改位置

| 修改项 | AI 首先读取 [io_buffer_lab.gd](io_buffer_lab.gd) 的哪些位置 |
| --- | --- |
| A/B 对比图布局、图例、等待提示 | `build_comparison()` 的 `examples` 容器负责组别布局，`render_comparison()` 负责数据和等待提示。 |
| 容量、速率和拍数的默认值 | `_ready()` 设置容量、设备产生速率、A 组读取速率和拍数，`build_comparison()` 设置 B 组读取速率，`load_example()` 恢复预设。改预设时检查对应按钮文字和测试期望值。 |
| 按拍显示的收支表 | `_ready()` 里的「最近四拍的收支」创建表格，`render()` 填充表格。`read_from_buffer()` 写入 `history`。 |
| 单拍执行的顺序 | `advance()`、`advance_half()`、`run_to_end()` 决定如何推进，`receive_from_device()` 与 `read_from_buffer()` 执行两个阶段，`render_phases()` 显示阶段状态。调整顺序时同步检查三个推进入口、拍末记录、讲解和测试。 |

定位不够时，先在对应文件搜索界面上看到的标题或按钮文字，再顺着该函数查看直接调用的代码。

## 涉及共享界面时再查

- 全局颜色、按钮样式和首页布局在 [main.gd](main.gd) 的 `_ready()`、`_build_home()`。章节选择由 `_build_chapters()`、`_open_chapter()` 管理。
- 第 1～3、8、9 章共用 [chapter_intro.gd](chapter_intro.gd) 的 `LABS`、`_open_lab()`、`_show_mode()` 实现实验入口和讲解切换。公用的卡片、按钮和字号适配在 [chapter_lab.gd](chapter_lab.gd)。
