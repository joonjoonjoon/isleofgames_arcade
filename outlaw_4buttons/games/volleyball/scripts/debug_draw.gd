extends Node2D
class_name DebugDraw

static var lines := []
const MAX_LINES := 20

static func print(text: String) -> void:
	# Add to the lines to be drawn
	if lines.size() >= MAX_LINES:
		lines.pop_front()
	lines.append(text)

func _process(_delta):
	# Clear all lines each frame unless repopulated
	queue_redraw()

func _draw():
	var y := 20
	for line in lines:
		draw_string(ThemeDB.fallback_font, Vector2(10, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.hex(0xd63d31ff))
		y += 20
	lines.clear()
	# update()

# Use a built-in font if none assigned
# func get_font(prop_name: String) -> Font:
# 	var default_font := ThemeDB.fallback_font
# 	return get_theme_default_font() if default_font == null else default_font

# func _ready():
# 	set_process(true)
# 	set_notify_transform(true)
# 	set_notify_draw(true)