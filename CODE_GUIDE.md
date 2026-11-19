# 计算机模块实验室代码导览

项目用 Godot 和 GDScript 编写。`.gd` 文件里既有界面代码，也有实验逻辑。要改某一章，可以先判断改的是**教材文字、按钮操作，还是计算规则**。

## 章节从哪里打开

1. [project.godot](project.godot) 指定启动场景 [main.tscn](main.tscn)，场景挂载 [main.gd](main.gd)。
2. `main.gd` 的 `_build_chapters()` 创建章节入口，`_open_chapter()` 决定点击后打开哪个页面。第 1～3、8、9 章使用统一的章节页，第 4～7 章进入组合工作区。
3. [chapter_intro.gd](chapter_intro.gd) 的 `LABS` 把章节编号绑定到实验脚本，`_open_lab()` 创建实验，`_show_mode()` 切换「动手实验」和「知识点与练习」。`LESSONS` 保存章节标题与默认步骤。
4. [chapter_material.gd](chapter_material.gd) 的 `CONTENT` 按章号保存知识点、练习题和答案解析。`name` 是知识点名称，`context` 是讲解，`steps` 是分步示意，`options`、`answer` 和 `why` 分别是选项、正确选项的下标和解析。答案下标从 `0` 开始。没有单独填写 `steps` 时，章节页使用 `LESSONS` 中的默认步骤。

## 第 1～3 章具体改哪里

| 想改的内容 | 文件与定位 |
| --- | --- |
| 第 1 章的系统调用、中断和文件读取题目 | [chapter_material.gd](chapter_material.gd) 的 `CONTENT[1]`。章节默认的读文件示意在 [chapter_intro.gd](chapter_intro.gd) 的 `LESSONS[1]`。 |
| 第 1 章「一次文件读取」的实际演示 | [read_file_lab.gd](read_file_lab.gd)。`CACHE_PATH`、`DISK_PATH` 保存缓存命中和从磁盘读取的步骤，`CACHE_LINKS`、`DISK_LINKS` 保存各步的箭头。`next_event()` 推进一步，`render()` 更新卡片、连接和记录。 |
| 第 2 章的进程、线程、上下文切换与 PCB 题目 | [chapter_material.gd](chapter_material.gd) 的 `CONTENT[2]`。默认的状态变化示意在 [chapter_intro.gd](chapter_intro.gd) 的 `LESSONS[2]`。 |
| 第 2 章「P2 怎么进入 CPU」和新手引导 | [process_states_lab.gd](process_states_lab.gd)。`GUIDE` 保存换班步骤，`update_actions()` 控制按钮提示。`dispatch()` 把就绪队首送上 CPU，`expire_slice()` 把原进程放回队尾，`block_for_io()` 和 `finish_io()` 分别处理阻塞和回到就绪。当前指令位置和 PCB 卡片的显示在 `execute_instruction()` 和 `render()`。 |
| 第 3 章的临界区、竞争条件、生产者消费者与 P/V 题目 | [chapter_material.gd](chapter_material.gd) 的 `CONTENT[3]`。默认互斥示意在 [chapter_intro.gd](chapter_intro.gd) 的 `LESSONS[3]`。 |
| 第 3 章水果盘的放取、等待、唤醒和高亮 | [fruit_sync_lab.gd](fruit_sync_lab.gd)。`GUIDE` 保存引导顺序，`put_fruit()` 与 `take_fruit()` 更新盘子和等待状态，`render()` 刷新生产者和消费者卡片，`update_guide()` 决定下一步提示。 |
| 第 3 章独立的「信号量 P / V 实验」 | [main.gd](main.gd) 的 `_open_semaphore()` 打开工作区实验。[semaphore_lab.gd](semaphore_lab.gd) 处理按钮、演示顺序与状态显示，[semaphore_model.gd](semaphore_model.gd) 的 `p()`、`v()`、`resume_process()` 处理申请、释放、唤醒和恢复运行。 |

例如，要改「时间片到期后请调度 P2」的引导文字，在 `process_states_lab.gd` 搜索 `GUIDE`。要改时间片到期时进程去了哪个队列，则查看 `expire_slice()`。

## 其他章节的入口

| 章节 | 界面与实验逻辑 |
| --- | --- |
| 第 4 章 处理机调度 | [schedule.gd](schedule.gd) 显示候选进程、时间线和周转指标，[schedule_model.gd](schedule_model.gd) 的 `run()` 计算调度顺序。 |
| 第 5 章 银行家算法 | [banker.gd](banker.gd) 处理矩阵输入和分步演示，[banker_model.gd](banker_model.gd) 的 `evaluate()` 处理试分配、安全检查与安全序列。 |
| 第 6 章 内存管理 | [main.gd](main.gd) 的 `_choose()`、`_allocate_now()` 和 `_compact()` 处理动态分区，[memory_view.gd](memory_view.gd) 绘制分区。基本分页的界面和计算在 [paging.gd](paging.gd) 与 [paging_model.gd](paging_model.gd)。 |
| 第 7 章 虚拟存储 | [replacement.gd](replacement.gd) 显示命中、缺页和换出情况，[replacement_model.gd](replacement_model.gd) 的 `simulate()` 计算 FIFO 和 LRU。分页、分段、段页式的地址转换图解在 [address_lab.gd](address_lab.gd)，第 6、7 章都能进。 |
| 第 8 章 I/O 设备管理 | [io_buffer_lab.gd](io_buffer_lab.gd) 的 `receive_from_device()` 和 `read_from_buffer()` 处理一拍的两步，`render_comparison()` 更新速度对比图。 |
| 第 9 章 文件系统 | [file_blocks_lab.gd](file_blocks_lab.gd) 的 `allocate()`、`delete_file()` 和 `render_tiles()` 处理磁盘块分配、回收与位图显示。 |

第 1～3、8、9 章共用的实验卡片、按钮和字号适配在 [chapter_lab.gd](chapter_lab.gd)。首页布局在 [main.gd](main.gd) 的 `_build_home()`，全局颜色和按钮样式从 `_ready()` 查起。

## 修改后到哪里验证

- 第 1～3 章的读取流程、P1/P2 换班、消费者唤醒和新手引导，查 [tests/chapter_labs_test.gd](tests/chapter_labs_test.gd) 中对应的 `app._open_chapter(1)`、`app._open_chapter(2)` 和 `app._open_chapter(3)`。
- 独立的信号量实验查 [tests/semaphore_test.gd](tests/semaphore_test.gd)。其他调度、银行家算法、分页和置换的测试也在 [tests](tests) 目录。
- 按 [README](README.md) 准备 Godot 后，在 Windows 终端运行 [运行检查.bat](%E8%BF%90%E8%A1%8C%E6%A3%80%E6%9F%A5.bat) 执行整套回归检查。改界面或说明文字时，再打开对应章节查看实际显示。
