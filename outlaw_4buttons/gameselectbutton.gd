extends Button





func _on_pressed_football():
    # 2D Game
    RenderingServer.set_default_clear_color(Color("#577a42")) # this works
    get_tree().change_scene_to_file("res://games/football/scenes/rotato.tscn")
    

    pass # Replace with function body.

func _on_pressed_volleyball():
    # 3D Game
    RenderingServer.set_default_clear_color(Color(0.863013, 0.819921, 0.762014, 1)) # this works
    get_tree().change_scene_to_file("res://games/volleyball/volleyball_two_sided.tscn")
    
    pass # Replace with function body.


func _on_pressed_fencing():
    # 3D Game
    RenderingServer.set_default_clear_color(Color(0,0,0, 1)) # this works
    get_tree().change_scene_to_file("res://games/fencing/game.tscn")
    
    pass # Replace with function body.
