extends Node3D

@export var key_left: Key
@export var key_left_alt: Key
@export var key_right: Key
@export var key_right_alt: Key
@export var is_flipped: bool
var arm_right: TargetHinge
var arm_left: TargetHinge
var leg_right: TargetHinge
var leg_left: TargetHinge
var torso: RigidBody3D
var charge_left: float
var charge_right: float

var start_position: Vector3
var start_rotation: Vector3

var restart_time: int
var last_grunt_time: float

var head_idle: Node3D
var head_loss: Node3D
var head_win: Node3D
var head_matchloss: Node3D

func _ready() -> void:
    arm_right = $Torso/Arm_Right/TargetHinge
    arm_left = $Torso/Arm_Left/TargetHinge
    leg_right = $Torso/Leg_Right/TargetHinge
    leg_left = $Torso/Leg_Left/TargetHinge
    torso = $Torso
    head_idle = $Torso/Head/Heads/Head_Idle
    head_loss = $Torso/Head/Heads/Head_Loss
    head_win = $Torso/Head/Heads/Head_Win
    head_matchloss = $Torso/Head/Heads/Head_MatchLoss
    start_position = torso.position
    start_rotation = torso.rotation
    restart_time = Time.get_ticks_msec()

func _process(delta: float) -> void:
    var can_input: bool = Time.get_ticks_msec() - restart_time > 500
    var left_pressed: bool = can_input and (Input.is_key_label_pressed(key_left if not is_flipped else key_right) or Input.is_key_label_pressed(key_left_alt if not is_flipped else key_right_alt))
    var right_pressed: bool = can_input and (Input.is_key_label_pressed(key_right if not is_flipped else key_left) or Input.is_key_label_pressed(key_right_alt if not is_flipped else key_left_alt))

    var arm_target: float = 69
    var leg_target: float = 89
    var nudge: float = 30
    if left_pressed:
        if charge_left == 0:
            var direction: Vector3 = Vector3.LEFT if not is_flipped else Vector3.RIGHT
            torso.apply_central_impulse(direction * nudge)
            _grunt()
        charge_left += delta * 10
        charge_left = min(charge_left, 1)
        arm_left.set_target_angle_deg(arm_target + charge_left)
        leg_left.set_target_angle_deg(-(leg_target + charge_left))
    else:
        if charge_left > 0:
            _grunt()
        charge_left = 0
        arm_left.set_target_angle_deg(0)
        leg_left.set_target_angle_deg(0)
    if right_pressed:
        if charge_right == 0:
            var direction: Vector3 = Vector3.RIGHT if not is_flipped else Vector3.LEFT
            torso.apply_central_impulse(direction * nudge)
            _grunt()
        charge_right += delta * 10
        charge_right = min(charge_right, 1)
        arm_right.set_target_angle_deg(-(arm_target + charge_right))
        leg_right.set_target_angle_deg(leg_target + charge_right)
    else:
        if charge_right > 0:
            _grunt()
        charge_right = 0
        arm_right.set_target_angle_deg(0)
        leg_right.set_target_angle_deg(0)

func _grunt() -> void:
    if Time.get_ticks_msec() - last_grunt_time > 500:
        AudioManager.play_grunt()
        last_grunt_time = Time.get_ticks_msec()

func _physics_process(delta: float) -> void:
    var upright_force: float = 60
    var upright_offset: float = 0.5
    var top: Vector3 = torso.global_position + torso.global_basis.y * upright_offset
    var bottom: Vector3 = torso.global_position - torso.global_basis.y * upright_offset
    torso.apply_force(Vector3.UP * upright_force, top)
    torso.apply_force(Vector3.DOWN * upright_force, bottom)
    
func reset_guy() -> void:
    torso.position = start_position
    torso.rotation = start_rotation
    torso.linear_velocity = Vector3.ZERO
    torso.angular_velocity = Vector3.ZERO
    restart_time = Time.get_ticks_msec()

func set_active_head(head: String) -> void:
    head_idle.visible = head == "idle"
    head_loss.visible = head == "loss"
    head_win.visible = head == "win"
    head_matchloss.visible = head == "matchloss"
