extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
 DisplayServer.window_set_size(Vector2i(1200,720))
 var app=load("res://main.tscn").instantiate()
 root.add_child(app)
 app._start_from_home()
 app._toggle_settings()
 app._toggle_comparison()
 for frame in 8: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/small_memory.png")
 app._add_banker_example()
 app._start_banker()
 app.banker_lab.edit_panel.visible=true
 for frame in 8: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/small_banker.png")
 print("Small viewport ",root.size," canvas ",app.size)
 quit()
