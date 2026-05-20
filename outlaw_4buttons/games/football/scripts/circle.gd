@tool
extends DrawShape
class_name Circle

@export var radius: float = 10

func _draw() -> void:
	if is_filled:
		var fill_radius: float = radius if outline_width == 0 else radius - outline_width / 4
		draw_circle(Vector2.ZERO, fill_radius, fill_color, true, -1, true)
	if outline_width > 0:
		draw_circle(Vector2.ZERO, radius - outline_width / 2, outline_color, false, outline_width, true)

func _process(delta: float) -> void:
	# Redraw if in editor
	if Engine.is_editor_hint():
		queue_redraw()