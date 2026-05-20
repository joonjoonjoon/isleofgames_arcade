extends Label

@export var ball_manager: BallManager

func _process(delta: float) -> void:
	text = str(ball_manager.step_count)
	
