@tool
class_name ShapeEntity extends Node2D

enum ShapeType {
	CIRCLE,
	SQUARE
}
@export var shape_type: ShapeType = ShapeType.CIRCLE
@export var size: float = 10.0
@export var color: Color = Color.WHITE
@export var keep_rotation: bool
@export var show_fill_mask: bool

var radius: float:
	get:
		return size / 2.0
	set(value):
		size = value * 2.0

var shadow: Circle
var fill_bg: Circle
var fill_mask: Square
var fill_front: Circle
var parent: Node2D

@export_tool_button("Draw Entity") var redraw_entity_button = draw_entity

func _ready() -> void:
	parent = get_parent()

func _process(delta: float) -> void:
	if keep_rotation and parent:
		rotation = -parent.rotation

func draw_entity() -> void:
	if !shadow:
		shadow = $Shadow
		if !shadow:
			shadow = Circle.new()
			shadow.name = "Shadow"
			add_child(shadow)
			if Engine.is_editor_hint():
				shadow.owner = get_tree().edited_scene_root
	shadow.position = Vector2(0, size / 8)
	shadow.radius = size / 2
	shadow.fill_color = Color(0, 0, 0, 0.5) # Semi-transparent black
	shadow.outline_width = 0

	if !fill_bg:
		fill_bg = $FillBG
		if !fill_bg:
			fill_bg = Circle.new()
			fill_bg.name = "FillBG"
			add_child(fill_bg)
			if Engine.is_editor_hint():
				fill_bg.owner = get_tree().edited_scene_root
	fill_bg.radius = size / 2
	var bg_color: Color = color
	# bg_color.ok_hsl_l = bg_color.ok_hsl_l * 0.75
	fill_bg.fill_color = bg_color

	if show_fill_mask:
		if !fill_mask:
			fill_mask = $FillMask
			if !fill_mask:
				fill_mask = Square.new()
				fill_mask.name = "FillMask"
				fill_mask.origin = Vector2(0.5, 1)
				fill_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
				fill_mask.outline_width = 0
				fill_mask.fill_color = Color(1, 1, 1, 1)
				add_child(fill_mask)
				if Engine.is_editor_hint():
					fill_mask.owner = get_tree().edited_scene_root
		fill_mask.size = Vector2(size, size)
		fill_mask.position = Vector2(0, size / 2)

		if !fill_front:
			fill_front = $FillMask/FillFront
			if !fill_front:
				fill_front = Circle.new()
				fill_front.name = "FillFront"
				fill_mask.add_child(fill_front)
				if Engine.is_editor_hint():
					fill_front.owner = get_tree().edited_scene_root
		fill_front.position = Vector2(0, -size / 2)
		fill_front.radius = size / 2
		fill_front.fill_color = color

func set_mask_fill(amount: float) -> void:
	# Ensure amount is between 0 and 1
	amount = clamp(amount, 0, 1)
	fill_mask.size = Vector2(size, size * amount)
	fill_mask.queue_redraw()
	# fill_mask.position = Vector2(0, size / 2 * (1 - amount))
