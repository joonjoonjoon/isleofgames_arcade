@tool
extends DrawShape
class_name Square

@export var origin: Vector2 = Vector2(0.5, 0.5)
@export var size: Vector2 = Vector2(10, 10)

func _draw() -> void:
    var origin_local: Vector2 = -size * origin
    if is_filled:
        var fill_width: float = size.x if outline_width == 0 else size.x - outline_width / 2
        var fill_height: float = size.y if outline_width == 0 else size.y - outline_width / 2
        var fill_origin: Vector2 = origin_local + Vector2(outline_width / 2, outline_width / 2)
        draw_rect(Rect2(fill_origin, Vector2(fill_width, fill_height)), fill_color, true, -1, true)
    if outline_width > 0:
        var outline_origin: Vector2 = origin_local + Vector2(outline_width / 2, outline_width / 2)
        draw_rect(Rect2(outline_origin, Vector2(size.x - outline_width, size.y - outline_width)), outline_color, false, outline_width, true)

func _process(delta: float) -> void:
    # Redraw if in editor
    if Engine.is_editor_hint():
        queue_redraw()
