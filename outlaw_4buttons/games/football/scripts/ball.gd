extends Node2D
class_name Ball

var radius: float = 10.0
var color: Color = Color.WHITE

var shape_entity: ShapeEntity

var velocity: Vector2 = Vector2.ZERO
var drag: float = 2
var friction: float = 10
var mass: float = 1.0
var is_fixed: bool
var is_frozen: bool

var bounce_count: int

var shake_on_hit: bool
var shake_vector: Vector2
var shake_tween: Tween
var shake_scale: float = 1

var trail: Line2D
var previous_position: Vector2
var trail_points: Array = []
var trail_timer: float = 0.0

var velocity_indicator: Node2D

var max_health: float
var current_health: float

func _ready() -> void:
	shape_entity = ShapeEntity.new()
	shape_entity.size = radius * 2
	shape_entity.color = color
	add_child(shape_entity)
	shape_entity.draw_entity()
	previous_position = position
	current_health = max_health

func process_ball(delta: float) -> void:
	# if trail:
	# 	var max_point_delta = radius
	# 	var delta_position = position - previous_position
	# 	var dist = delta_position.length()
	# 	if dist > max_point_delta:
	# 		var num_points = int(dist / max_point_delta)
	# 		for i in range(num_points):
	# 			var point = previous_position + (delta_position.normalized() * max_point_delta * (i + 1))
	# 			trail_points.append(point)
	# 		trail_timer = 0
	# 	else:
	# 		trail_timer += delta
	# 		if trail_timer > 0.01:
	# 			trail_points.append(position)
	# 			trail_timer = 0
	# 	while trail_points.size() > 20:
	# 		trail_points.remove_at(0)
	# 	if trail_points.size() > 0:
	# 		trail_points[trail_points.size() - 1] = position
	# 	trail.points = trail_points
	# previous_position = position

	if velocity_indicator:
		velocity_indicator.position = position + velocity * delta

	# shape_entity.position = shake_vector
	shape_entity.scale = Vector2(shake_scale, shake_scale)
	if shake_tween:
		shake_tween.custom_step(delta)
	
func add_trail_point() -> void:
	if trail:
		trail_points.append(position)
		while trail_points.size() > 20:
			trail_points.remove_at(0)
		trail.points = trail_points

func reset_trail() -> void:
	if trail:
		trail_points.clear()
		trail.points = trail_points

func on_ball_hit(other: Ball) -> void:
	if shake_on_hit:
		shake()

func damage_ball(damage_event: DamageEvent) -> void:
	# Apply damage to the ball
	current_health -= damage_event.base_damage
	shape_entity.set_mask_fill(current_health / max_health)
	if current_health <= 0:
		visible = false

func shake() -> void:
	shake_scale = 1
	shake_vector = Vector2.ZERO
	shake_tween = get_tree().create_tween()
	shake_tween.tween_property(self, "shake_scale", 0.8, 0.01).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(self, "shake_scale", 1.2, 0.075).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "shake_scale", 0.9, 0.1).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "shake_scale", 1.0, 0.15).set_ease(Tween.EASE_IN)
	shake_tween.pause()

func get_ball_state() -> BallState:
	var state = BallState.new()
	state.ball = self
	state.radius = radius
	state.drag = drag
	state.friction = friction
	state.position = position
	state.velocity = velocity
	state.mass = mass
	state.bounce_count = bounce_count
	return state

func copy_ball_state(ball_state: BallState) -> void:
	position = ball_state.position
	velocity = ball_state.velocity
	bounce_count = ball_state.bounce_count
