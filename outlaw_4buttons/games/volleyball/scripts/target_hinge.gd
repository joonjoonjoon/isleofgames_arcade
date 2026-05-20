class_name TargetHinge extends HingeJoint3D

@export var min_angle: float
@export var max_angle: float
@export var max_impulse: float = 1
@export var no_slack: bool
var max_hinge_vel: float = 30
var grab_spring: float = 20
var grab_damp: float = 0.5
var slack: float = 50

var neutral_direction: Vector3
var current_direction: Vector3
var axis: Vector3
var target_node: Node3D
var target_angle: float = 0
var angle_padding: float = 0.01
var current_angle: float
var velocity: float
var max_delta: float

const max_target_delta: float = PI / 2

func _ready() -> void:
    target_node = get_node(node_b)
    neutral_direction = target_node.global_basis.inverse() * global_basis.x
    axis = target_node.global_basis.inverse() * global_basis.z
    set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    if min_angle != max_angle:
        set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
        set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(min_angle))
        set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(max_angle))
    else:
        set_flag(HingeJoint3D.FLAG_USE_LIMIT, false)

func _physics_process(delta: float) -> void:
    current_direction = target_node.global_basis.inverse() * global_basis.x
    var new_angle: float = normalized_angle(neutral_direction.signed_angle_to(current_direction, axis))
    velocity = normalized_angle(new_angle - current_angle) / delta
    current_angle = new_angle
    var delta_angle: float = shortest_angle_distance(current_angle, target_angle)
    max_delta = max(max_delta, abs(delta_angle))
    var max_vel: float = min(abs(delta_angle / delta), max_hinge_vel)
    var spring_force: float = delta_angle * grab_spring - velocity * grab_damp
    var speed: float = sign(spring_force) * min(abs(spring_force), max_vel)
    # print("%.02f : %0.2f : %0.2f : %0.2f" % [delta_angle, current_angle, target_angle, spring_force])
    if abs(delta_angle) <= angle_padding:
        speed = 0
    set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, speed)
    set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, max_impulse)
    
    if not no_slack:
        var angle_to_current: float = shortest_angle_distance(target_angle, current_angle)
        var slack_delta: float = angle_to_current * delta * slack
        rotate_hinge(slack_delta)

func shortest_angle_distance(a: float, b: float) -> float:
    a = normalized_angle(a)
    b = normalized_angle(b)
    var delta_angle: float = b - a
    return normalized_angle(delta_angle)

func rotate_hinge(delta: float) -> void:
    target_angle = clamped_delta_angle(target_angle, delta, current_angle - max_target_delta, current_angle + max_target_delta)
    if min_angle != max_angle:
        target_angle = clamp(target_angle, deg_to_rad(min_angle), deg_to_rad(max_angle))

func set_target_angle(new_target_angle: float) -> void:
    rotate_hinge(new_target_angle - target_angle)

func set_target_angle_deg(new_target_angle: float) -> void:
    rotate_hinge(deg_to_rad(new_target_angle) - target_angle)

func clamped_delta_angle(angle: float, delta: float, min_clamp_angle: float, max_clamp_angle:float) -> float:
    angle = normalized_angle(angle)
    min_clamp_angle = normalized_angle(min_clamp_angle)
    max_clamp_angle = normalized_angle(max_clamp_angle)
    
    var new_angle: float = angle + delta
    new_angle = normalized_angle(new_angle)
    
    if min_clamp_angle > max_clamp_angle:
        if new_angle < min_clamp_angle and new_angle > min_clamp_angle:
            if delta < 0:
                new_angle = min_clamp_angle
            else:
                new_angle = max_clamp_angle
    else:
        if new_angle > max_clamp_angle or new_angle < min_clamp_angle:
            if delta < 0:
                new_angle = min_clamp_angle
            else:
                new_angle = max_clamp_angle
    
    return new_angle

func normalized_angle(angle: float) -> float:
    return wrapf(angle, -PI, PI)