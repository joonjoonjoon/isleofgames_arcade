class_name PlayerBall extends RigidBody2D

enum PlayerBallState {
    FROZEN,
    AIMING,
    CHARGING,
    MOVING
}
var current_state: PlayerBallState

@export var shoot_key: String
var aimer: Node2D
var aim_fill: Node2D
var charge: float
var speed: float
var stop_timer: float
var aim_direction: float

var do_teleport: bool
var teleport_position: Vector2

func _ready() -> void:
    aimer = $Aimer
    aim_fill = $Aimer/GrowArrow/Mask/Arrow
    aim_fill.position.x = 0
    aim_direction = rotation


func _process(delta: float) -> void:
    aim_fill.position.x = charge * -62
    if current_state == PlayerBallState.AIMING:
        aim_direction += delta * 4
        aim_direction = wrapf(aim_direction, -PI, PI)
        aimer.global_rotation = aim_direction
        if Input.is_action_pressed(shoot_key):
            current_state = PlayerBallState.CHARGING
    if current_state == PlayerBallState.CHARGING:
        aimer.global_rotation = aim_direction
        charge += delta
        charge = min(charge, 1)
        if not Input.is_action_pressed(shoot_key):
            aimer.visible = false
            var shoot_direction: Vector2 = Vector2.RIGHT.rotated(aim_direction)
            apply_impulse(shoot_direction * (250 + charge * 600))
            charge = 0
            current_state = PlayerBallState.MOVING
            stop_timer = 0.1

func _physics_process(delta: float) -> void:
    speed = linear_velocity.length()
    if speed > 0:
        var friction: float = min(speed, 500 * delta)
        linear_velocity -= linear_velocity.normalized() * friction
    if current_state == PlayerBallState.MOVING and speed < 10:
        stop_timer -= delta
        if stop_timer <= 0:
            linear_velocity = Vector2.ZERO
            angular_velocity = 0
            current_state = PlayerBallState.AIMING
            aimer.visible = true

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    if do_teleport:
        state.linear_velocity = Vector2.ZERO
        state.angular_velocity = 0
        state.transform.origin = teleport_position
        do_teleport = false

func teleport_to(position: Vector2) -> void:
    do_teleport = true
    teleport_position = position

func freeze_player() -> void:
    current_state = PlayerBallState.FROZEN
    aimer.visible = false

func unfreeze_player() -> void:
    current_state = PlayerBallState.AIMING
    aimer.visible = true
