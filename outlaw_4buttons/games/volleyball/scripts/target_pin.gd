extends PinJoint2D

@export var min_angle: float
@export var max_angle: float

var target_node: Node2D
var neutral_angle: Vector2

func _ready() -> void:
    angular_limit_enabled = min_angle != max_angle
    angular_limit_lower = min_angle
    angular_limit_upper = max_angle
    motor_enabled = true
    target_node = get_node(node_b)
    # neutral_angle = 