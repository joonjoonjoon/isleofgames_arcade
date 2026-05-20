extends RigidBody3D

@export var trail_material: BaseMaterial3D
@export var ball_color: Color
@export var bg_color: Color
var hit_splash = preload("res://games/volleyball/subscenes/hit_splash.tscn")
var last_collision_position: Vector3
var last_hit_splash: Node
var trail: Array
var previous_position: Vector3
var trail_positions: Array[Vector3]
var trail_timer: float
var cum_delta: float

func _ready() -> void:
    connect("body_entered", _on_body_entered)
    call_deferred("make_trail")
    previous_position = global_position

func make_trail() -> void:
    var trail_scale: float = scale.x
    var trail_count: float = 18
    ball_color = ball_color.lerp(bg_color, 0.2)
    for i in range(trail_count):
        var new_ball = $MeshInstance3D.duplicate()
        print("NEW BALL "+new_ball.name)
        get_tree().root.add_child(new_ball)
        new_ball.global_position = global_position
        trail_scale *= 0.9
        new_ball.scale = Vector3.ONE * trail_scale
        var new_material: BaseMaterial3D = trail_material.duplicate()
        new_material.albedo_color = ball_color.lerp(bg_color, i / trail_count)
        new_ball.material_override = new_material
        trail.append(new_ball)
        trail_positions.append(global_position)
        

func _process(delta: float) -> void:
    cum_delta += (global_position - previous_position).length()
    previous_position = global_position
    trail_timer -= delta
    var trail_distance: float = 0.05
    if trail.size() > 0 and (cum_delta > trail_distance or trail_timer <= 0):
        for i in range(trail_positions.size() - 1, 0, -1):
            trail_positions[i] = trail_positions[i - 1]
        trail_positions[0] = global_position + Vector3.FORWARD * 2
        cum_delta = 0
        trail_timer = 0.07
    var next_position: Vector3 = global_position + Vector3.FORWARD * 2
    for i in range(trail.size()):
        trail[i].global_position = trail_positions[i].lerp(next_position, cum_delta / trail_distance)
        next_position = trail_positions[i]
    # var follow_position: Vector3 = global_position
    # for ball in trail:
    #     var trail_distance: float = 0.2 * ball.scale.x
    #     var to_next: Vector3 = follow_position - ball.global_position
    #     var distance: float = to_next.length()
    #     if distance > trail_distance:
    #         var move: Vector3 = to_next.normalized() * (distance - trail_distance)
    #         ball.global_position += move
    #     else:
    #         ball.global_position = ball.global_position.move_toward(follow_position, 2 * delta)
    #     follow_position = ball.global_position

func _physics_process(delta: float) -> void:
    var speed: float = linear_velocity.length()
    var max_speed: float = 6
    if speed > max_speed:
        linear_velocity = linear_velocity.normalized() * max_speed

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if state.get_contact_count() > 0:
        last_collision_position = state.get_contact_local_position(0)

func _on_body_entered(body: Node) -> void:
    var parent: Node
    var x_scale: float = 1.0
    if body is RigidBody3D:
        AudioManager.play_ball_body_sound()
        parent = body
        if body.name == "Torso":
            x_scale = body.get_parent().scale.x
        elif body.get_parent().name == "Torso":
            x_scale = body.get_parent().get_parent().scale.x
        print("XSCALE "+str(x_scale))
    else:
        AudioManager.play_ball_sound()
        parent = get_tree().root
    var new_splash = hit_splash.instantiate()
    parent.add_child(new_splash)
    new_splash.global_position = last_collision_position
    var delta_position: Vector3 = global_position - last_collision_position
    delta_position.z = 0
    var angle: float = Vector3.UP.signed_angle_to(delta_position.normalized(), -Vector3.FORWARD)
    if x_scale < 0:
        # angle += PI
        new_splash.scale.z = -1
    # print("ANGLE "+str(roundi(rad_to_deg(angle))))
    new_splash.global_rotation = Vector3(0, 0, angle)
    get_tree().create_timer(1.0).timeout.connect(func(): if new_splash: new_splash.queue_free())
    var scale_tween: Tween = get_tree().create_tween()
    scale_tween.tween_property(new_splash, "scale", Vector3(), 0.25).set_delay(0.75)
    if last_hit_splash:
        last_hit_splash.queue_free()
    last_hit_splash = new_splash
