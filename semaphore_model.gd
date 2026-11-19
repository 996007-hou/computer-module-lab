extends RefCounted

# Classroom signed semaphore with FIFO blocking and one initial permit.
var value := 1
var states := ["idle", "idle", "idle"]
var queue: Array[int] = []
var message := "初始 S = 1，临界资源空闲。选择进程后执行 P 操作。"

func p(pid: int) -> bool:
 if pid < 0 or pid >= states.size(): return false
 if states[pid] != "idle":
  message = "P%d 已在临界区、等待或已获唤醒，不能重复申请。" % (pid + 1)
  return false
 value -= 1
 if value < 0:
  states[pid] = "blocked"
  queue.append(pid)
  message = "P%d 执行 P：S 减为 %d，小于 0；进程进入阻塞队列。" % [pid + 1, value]
 else:
  states[pid] = "inside"
  message = "P%d 执行 P：S 减为 %d，获得许可并进入临界区。" % [pid + 1, value]
 return true

func v(pid: int) -> bool:
 if pid < 0 or pid >= states.size(): return false
 if states[pid] != "inside":
  message = "本互斥示例中，只有正在临界区的进程才能执行 V 并离开。"
  return false
 states[pid] = "idle"
 value += 1
 if value <= 0:
  var awakened = queue.pop_front()
  states[awakened] = "ready"
  message = "P%d 执行 V：S 增为 %d，唤醒队首 P%d；它已就绪，还需调度。" % [pid + 1, value, awakened + 1]
 else:
  message = "P%d 执行 V：S 增为 %d，临界资源重新空闲。" % [pid + 1, value]
 return true

func resume_process(pid: int) -> bool:
 if pid < 0 or pid >= states.size(): return false
 if states[pid] != "ready":
  message = "请选择已唤醒的进程；就绪后需要被调度才能继续。"
  return false
 states[pid] = "inside"
 message = "P%d 获得调度，P 操作返回并进入临界区；S 保持 %d。" % [pid + 1, value]
 return true
