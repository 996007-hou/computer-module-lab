extends SceneTree
func _initialize():
 call_deferred("capture")
func capture():
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/home_view.png")
 app._show_chapters()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/chapters_view.png")
 app._begin_explore()
 app._add_example()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/topics_view.png")
 app._start_experiment()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/experiment_view.png")
 app._start_paging()
 app.paging_lab._next()
 app.paging_lab._next()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/paging_view.png")
 app.paging_lab._next()
 app.paging_lab.practice.button_pressed=true
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/paging_practice_view.png")
 app._clear_modules()
 app._add_module("process")
 app._add_module("os")
 app._add_module("cpu")
 app._start_schedule()
 app.schedule_lab.algorithms.select(1)
 app.schedule_lab._changed("")
 app.schedule_lab._next()
 app.schedule_lab._next()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/schedule_view.png")
 app._add_banker_example()
 app._start_banker()
 app.banker_lab._next()
 app.banker_lab._next()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 print("VIEWPORT ",root.size," APP ",app.size," OUTER ",app.workspace_screen.position," / ",app.workspace_screen.size," BANKER ",app.banker_container.size)
 root.get_texture().get_image().save_png("res://runtime/banker_view.png")
 app._add_virtual_example()
 app._start_replacement()
 for i in 5: app.replacement_lab._next()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/replacement_view.png")
 quit()
