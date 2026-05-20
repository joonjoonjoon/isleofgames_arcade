extends Node2D
class_name BallManager

@export var level_bounds: Vector2
@export var launch_origin: Vector2
@export var aimer: NodePath
@export var aimer_line_path: NodePath

var launch_force: float = 500

var camera: Camera2D
var aimer_node: Node2D
var aimer_line: Line2D

var cue_ball: Ball
var balls: Array

enum GameState { AIMING, IN_PLAY, RESET_DELAY }
var current_game_state: GameState = GameState.AIMING

var time_stop_timer: float
var reset_timer: float

var time_scale: float = 1.0
var step_time: float
var step_count: int
var is_paused: bool

var padding: float = 0.1

var debug_balls: Array = []

func _ready() -> void:
	camera = get_node("../Camera2D")
	aimer_node = get_node(aimer)
	aimer_line = get_node(aimer_line_path)
	new_cue_ball()
	
	for i in 4:
		new_ball()

func _input(event: InputEvent) -> void:
	if is_paused and Input.is_key_pressed(KEY_SPACE):
		is_paused = false

func _process(delta: float) -> void:
	if current_game_state == GameState.AIMING:
		aimer_node.visible = true
		aimer_line.visible = true
		var aim_direction: Vector2 = camera.get_global_mouse_position() - launch_origin
		var aim_angle: float = Vector2.UP.angle_to(aim_direction)
		aimer_node.rotation = aim_angle
		aimer_line.clear_points()
		var ball_state: BallState = cue_ball.get_ball_state()
		ball_state.velocity = aim_direction.normalized() * launch_force
		var loop_count: int = 0
		while ball_state.bounce_count < 6 and loop_count < 1000:
			ball_state = project_ball(ball_state, delta, delta)
			aimer_line.add_point(ball_state.position - aimer_line.global_position)
			loop_count += 1

		if Input.is_action_just_pressed("launch"):
			print("Launch")
			var force: Vector2 = aim_direction.normalized() * launch_force
			cue_ball.velocity = force
			current_game_state = GameState.IN_PLAY
	elif current_game_state == GameState.IN_PLAY:
		aimer_node.visible = false
		aimer_line.visible = false
		var any_balls_moving: bool = false
		for b in balls.size():
			var ball: Ball = balls[b]
			if ball.velocity.length() > 0.1:
				any_balls_moving = true
				break
		if not any_balls_moving:
			print("AIMING")
			current_game_state = GameState.RESET_DELAY
	elif current_game_state == GameState.RESET_DELAY:
		reset_timer += delta
		if reset_timer >= 1.0:
			print("RESET")
			current_game_state = GameState.AIMING
			reset_timer = 0.0
			cue_ball.bounce_count = 0 
			cue_ball.visible = true
			cue_ball.position = launch_origin
			cue_ball.velocity = Vector2.ZERO
			cue_ball.is_frozen = false
			cue_ball.reset_trail()

func _physics_process(delta: float) -> void:
	if is_paused and Input.is_key_pressed(KEY_SPACE):
		is_paused = false
	if is_paused and Input.is_action_just_pressed("launch"):
		is_paused = false

	if !is_paused:
		# Delete debug balls
		for b in debug_balls.size():
			var ball: Circle = debug_balls[b]
			ball.queue_free()
		debug_balls.clear()
	
	if time_stop_timer > 0:
		time_stop_timer -= delta
		return

	if current_game_state == GameState.IN_PLAY and !is_paused:
		time_scale += delta * 0.5
		time_scale = clamp(time_scale, 1.0, 1.0)
	elif !is_paused:
		time_scale = 1
	var scaled_delta: float = delta * time_scale if !is_paused else 0.0
		
	if scaled_delta > 0 and (current_game_state == GameState.IN_PLAY or current_game_state == GameState.RESET_DELAY):
		if cue_ball.bounce_count >= 5:
			cue_ball.bounce_count = 0
			cue_ball.velocity = Vector2.ZERO
			cue_ball.is_frozen = true
			# cue_ball.visible = false

		var max_step_distance: float = 10
		step_time = scaled_delta

		for b in balls.size():
			var ball: Ball = balls[b]
			if !ball.visible or ball.is_frozen:
				continue
			if ball.visible and !ball.is_frozen and !ball.is_fixed:
				var step_distance: float = ball.velocity.length() * step_time
				if step_distance > max_step_distance:
					step_time = step_time * max_step_distance / step_distance

		step_count = int(ceil(scaled_delta / step_time))
		var elapsed_time: float = 0.0
		while elapsed_time < scaled_delta:
			elapsed_time += step_time
			for b in balls.size():
				var ball: Ball = balls[b]
				if !ball.visible or ball.is_frozen or ball.is_fixed or ball.velocity.length() <= 0:
					continue
				# Apply drag and friction
				ball.velocity -= ball.velocity * ball.drag * step_time
				var speed = ball.velocity.length()
				var friction_amount = min(speed, ball.friction * step_time)
				ball.velocity -= ball.velocity.normalized() * friction_amount
				# Move ball
				var ball_previous_velocity: Vector2 = ball.velocity
				var ball_delta_position: Vector2 = ball.velocity * step_time
				ball.position += ball_delta_position
				# Check level bounds
				var hit_wall: bool = false
				var out_position: Vector2 = Vector2.ZERO
				var wall_normal: Vector2 = Vector2.ZERO
				if (ball.position.x - ball.radius < -level_bounds.x):
					wall_normal = Vector2(1, 0)
					out_position = Vector2(-level_bounds.x + ball.radius + padding, ball.position.y)
					ball.velocity.x = abs(ball.velocity.x)
					hit_wall = true
				elif (ball.position.x + ball.radius > level_bounds.x):
					wall_normal = Vector2(-1, 0)
					out_position = Vector2(level_bounds.x - ball.radius - padding, ball.position.y)
					ball.velocity.x = -abs(ball.velocity.x)
					hit_wall = true
				if (ball.position.y - ball.radius < -level_bounds.y):
					wall_normal = Vector2(0, 1)
					out_position = Vector2(ball.position.x, -level_bounds.y + ball.radius + padding)
					ball.velocity.y = abs(ball.velocity.y)
					hit_wall = true
				elif (ball.position.y + ball.radius > level_bounds.y):
					wall_normal = Vector2(0, -1)
					out_position = Vector2(ball.position.x, level_bounds.y - ball.radius - padding)
					ball.velocity.y = -abs(ball.velocity.y)
					hit_wall = true
				if hit_wall:
					var velocity_normal: Vector2 = -ball_previous_velocity.normalized()
					var penetration: float = ball.position.distance_to(out_position)
					var wall_depenetration: Vector2 = velocity_normal * penetration / velocity_normal.dot(wall_normal)
					ball.position += wall_depenetration
					ball.add_trail_point()
					ball.bounce_count += 1
				# Check for collisions between balls
				var hit_any_balls: bool = true
				var loop_count: int = 0
				while hit_any_balls:
					loop_count += 1
					if loop_count > 10:
						print("Loop count exceeded")
						is_paused = true
						break
					hit_any_balls = false
					for o in balls.size():
						var other: Ball = balls[o]
						if !other.visible or other.is_frozen or other == ball:
							continue
						var delta_position = other.position - ball.position
						var dist = delta_position.length()
						var rad_sum = ball.radius + other.radius
						if (dist < rad_sum):
							var separation = rad_sum - dist
							if other.is_fixed:
								var projected_normal: Vector2 = delta_position.project(ball_previous_velocity)
								var point_a: Vector2 = ball.position + projected_normal
								var side_a: float = other.position.distance_to(point_a)
								side_a *= side_a
								var side_c: float = (rad_sum + padding) * (rad_sum + padding)
								var side_b: float = sqrt(side_c - side_a)
								var new_position = point_a - ball_previous_velocity.normalized() * side_b
								ball.position = new_position
								var normal = (other.position - ball.position).normalized()
								ball.velocity = ball_previous_velocity.bounce(-normal)
							else:
								var normal = delta_position.normalized()
								ball.position -= normal * separation / 2
								other.position += normal * separation / 2
								var tangent = Vector2(-normal.y, normal.x)
								var scalar_normal = normal.dot(ball.velocity)
								var scalar_normal_other = normal.dot(other.velocity)
								var scalar_tangent = tangent.dot(ball.velocity)
								var scalar_tangent_other = tangent.dot(other.velocity)
								var scalar_normal_after = (scalar_normal * (ball.mass - other.mass) + 2 * other.mass * scalar_normal_other) / (ball.mass + other.mass)
								var scalar_normal_after_other = (scalar_normal_other * (other.mass - ball.mass) + 2 * ball.mass * scalar_normal) / (ball.mass + other.mass)
								var new_vel = scalar_normal_after * normal + scalar_tangent * tangent
								var new_vel_other = scalar_normal_after_other * normal + scalar_tangent_other * tangent
								ball.velocity = new_vel
								other.velocity = new_vel_other
							ball.bounce_count += 1
							other.bounce_count += 1
							# _add_debug_ball(other.position, 5, Color.YELLOW)
							hit_any_balls = true
							# ball.add_trail_point()
							# other.add_trail_point()
							# var collision_delta_position: Vector2 = ball.position - pre_collision_position
							# var sub_step_time: float = collision_delta_position.length() / ball.velocity.length() * step_time
							# var remaining_step_time: float = step_time - sub_step_time
							# ball.position += ball.velocity * remaining_step_time

							if ball == cue_ball or other == cue_ball:
								# time_stop_timer = 0.2
								var non_cue_ball: Ball = ball if ball != cue_ball else other
								var damage_event: DamageEvent = DamageEvent.new()
								damage_event.base_damage = 1
								damage_event.source = cue_ball
								damage_event.target = non_cue_ball
								non_cue_ball.damage_ball(damage_event)
							ball.on_ball_hit(other)
							other.on_ball_hit(ball)
				# _add_debug_ball(ball.position, 5, Color.RED)
			
			cue_ball.add_trail_point()
		for b in balls.size():
			var ball: Ball = balls[b]
			if !ball.visible or ball.is_frozen:
				continue
			ball.process_ball(scaled_delta)
	# is_paused = true

func project_ball(ball_state: BallState, time_step: float, time_remaining: float) -> BallState:
	if time_remaining <= 0:
		return ball_state

	var ball_previous_velocity = ball_state.velocity
	ball_state.position += ball_state.velocity * time_step
	var hit_wall: bool = false
	var out_position: Vector2 = Vector2.ZERO
	var wall_normal: Vector2 = Vector2.ZERO
	if (ball_state.position.x - ball_state.radius < -level_bounds.x):
		wall_normal = Vector2(1, 0)
		out_position = Vector2(-level_bounds.x + ball_state.radius + padding, ball_state.position.y)
		ball_state.velocity.x = abs(ball_state.velocity.x)
		hit_wall = true
	elif (ball_state.position.x + ball_state.radius > level_bounds.x):
		wall_normal = Vector2(-1, 0)
		out_position = Vector2(level_bounds.x - ball_state.radius - padding, ball_state.position.y)
		ball_state.velocity.x = -abs(ball_state.velocity.x)
		hit_wall = true
	if (ball_state.position.y - ball_state.radius < -level_bounds.y):
		wall_normal = Vector2(0, 1)
		out_position = Vector2(ball_state.position.x, -level_bounds.y + ball_state.radius + padding)
		ball_state.velocity.y = abs(ball_state.velocity.y)
		hit_wall = true
	elif (ball_state.position.y + ball_state.radius > level_bounds.y):
		wall_normal = Vector2(0, -1)
		out_position = Vector2(ball_state.position.x, level_bounds.y - ball_state.radius - padding)
		ball_state.velocity.y = -abs(ball_state.velocity.y)
		hit_wall = true
	if hit_wall:
		var velocity_normal: Vector2 = -ball_state.velocity.normalized()
		var penetration: float = ball_state.position.distance_to(out_position)
		var wall_depenetration: Vector2 = velocity_normal * penetration / velocity_normal.dot(wall_normal)
		ball_state.position += wall_depenetration
		ball_state.bounce_count += 1
	var hit_any_balls: bool = false
	var loop_count: int = 0
	while not hit_any_balls:
		loop_count += 1
		if loop_count > 10:
			break
		hit_any_balls = false
		for o in balls.size():
			var other: Ball = balls[o]
			if !other.visible or other.is_frozen or other == ball_state.ball:
				continue
			var delta_position = other.position - ball_state.position
			var dist = delta_position.length()
			var rad_sum = ball_state.radius + other.radius
			if dist < rad_sum:
				var projected_normal: Vector2 = delta_position.project(ball_previous_velocity)
				var point_a: Vector2 = ball_state.position + projected_normal
				var side_a: float = other.position.distance_to(point_a)
				side_a *= side_a
				var side_c: float = (rad_sum + padding) * (rad_sum + padding)
				var side_b: float = sqrt(side_c - side_a)
				var new_position = point_a - ball_previous_velocity.normalized() * side_b
				var normal = (other.position - new_position).normalized()
				ball_state.position = new_position
				ball_state.velocity = ball_previous_velocity.bounce(-normal)
				ball_state.bounce_count += 1
				hit_any_balls = true
				
	time_remaining -= time_step
	return project_ball(ball_state, time_step, time_remaining)

func new_ball() -> void:
	# Create a new ball
	var ball = Ball.new()
	ball.mass = 10
	ball.is_fixed = true
	ball.radius = 15 if randf() < 0.8 else 20
	# ball.color = Color(randf(), randf(), randf()) # Random color
	ball.color = Color.from_string("#E03C32", Color.WHITE)
	ball.position = Vector2(randf_range(-level_bounds.x + ball.radius, level_bounds.x - ball.radius), randf_range(-level_bounds.y + ball.radius, launch_origin.y - ball.radius))
	ball.shake_on_hit = true
	ball.max_health = 5
	add_child(ball)
	balls.append(ball)

func _add_debug_ball(position: Vector2, radius: float, color: Color) -> void:
	# Create a new debug ball
	var ball: Circle = Circle.new()
	ball.radius = radius
	ball.outline_width = 0
	ball.fill_color = color
	ball.position = position
	add_child(ball)
	debug_balls.append(ball)

func new_cue_ball() -> void:
	# Create a new cue ball
	cue_ball = Ball.new()
	cue_ball.drag = 0
	cue_ball.friction = 0
	cue_ball.radius = 10
	cue_ball.color = Color(1, 1, 1) # White color
	cue_ball.position = launch_origin
	add_child(cue_ball)
	balls.append(cue_ball)

	cue_ball.trail = Line2D.new()
	cue_ball.trail.joint_mode = Line2D.LINE_JOINT_ROUND
	cue_ball.trail.gradient = Gradient.new()
	cue_ball.trail.gradient.set_color(0, Color(1, 1, 1, 0))
	cue_ball.trail.gradient.set_color(1, Color(1, 1, 1, 1))
	add_child(cue_ball.trail)
	move_child(cue_ball.trail, 0)
	cue_ball.trail.width = 18

	# var velocity_indicator: Circle = Circle.new()
	# cue_ball.velocity_indicator = velocity_indicator
	# velocity_indicator.radius = 5
	# velocity_indicator.fill_color = Color(0, 1, 0)
	# velocity_indicator.position = cue_ball.position
	# add_child(velocity_indicator)
