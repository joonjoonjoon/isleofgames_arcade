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

var rotate_direction: int = 1
var shot_cooldown: float
func _process(delta: float) -> void:
    aim_fill.position.x = charge * -62
    if current_state == PlayerBallState.AIMING:
        aim_direction += delta * rotate_direction * 3
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
            shot_cooldown = 0.5
            rotate_direction *= -1
            var shoot_direction: Vector2 = Vector2.RIGHT.rotated(aim_direction)
            linear_velocity = shoot_direction * (550 + charge * 1200)
            #apply_impulse(shoot_direction * (550 + charge * 1200))
            charge = 0
            current_state = PlayerBallState.MOVING
            stop_timer = 0.1
    if current_state == PlayerBallState.MOVING:
        shot_cooldown -= delta
        if shot_cooldown <= 0:
            current_state = PlayerBallState.AIMING
            aimer.visible = true

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
            aim_direction += PI
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
