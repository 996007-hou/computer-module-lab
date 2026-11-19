extends SceneTree
func _initialize():
 call_deferred("capture")
func capture():
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 for frame in 4: await process_frame
 app._show_chapters()
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/chapters_light.png")
 app._open_chapter(3)
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://runtime/chapter_intro_light.png")
 quit()
