extends Label

func _process(delta: float) -> void:
	var fps: int = Engine.get_frames_per_second()
	text = str(fps)
	# if fps < 30:
	# 	self.add_color_override("font_color", Color(1, 0, 0))
	# elif fps < 60:
	# 	self.add_color_override("font_color", Color(1, 1, 0))
	# else:
	# 	self.add_color_override("font_color", Color(0, 1, 0))