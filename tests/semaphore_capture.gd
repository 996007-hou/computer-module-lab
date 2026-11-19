extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 for frame in 4: await process_frame
 app._open_semaphore()
 var lab = app.semaphore_lab
 lab._p()
 lab.selection.select(1)
 lab._p()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/semaphore_view.png")
 quit()
