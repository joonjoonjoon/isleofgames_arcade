extends Node3D

@export var key: Key
var arm_right: TargetHinge
var arm_left: TargetHinge
var leg_right: TargetHinge
var leg_left: TargetHinge
var torso: RigidBody3D
var charge: float
var bodies: Array

var start_position: Vector3
@export var is_flipped: bool
var freeze: bool

func _ready() -> void:
    arm_right = $Torso/Arm_Right/TargetHinge
    arm_left = $Torso/Arm_Left/TargetHinge
    leg_right = $Torso/Leg_Right/TargetHinge
    leg_left = $Torso/Leg_Left/TargetHinge
    torso = $Torso
    bodies.append($Torso/Arm_Left)
    bodies.append($Torso/Arm_Right)
    bodies.append($Torso/Leg_Left)
    bodies.append($Torso/Leg_Right)
    bodies.append($Torso/Torso/Head)
    start_position = torso.position

func _process(delta: float) -> void:
    if Input.is_key_label_pressed(key):
        charge += delta * 20
        charge = min(charge, 30)
        var arm_target: float = 39 + charge
        arm_right.set_target_angle_deg(-arm_target)
        arm_left.set_target_angle_deg(arm_target)
        var leg_target: float = 59 + charge
        leg_right.set_target_angle_deg(leg_target)
        leg_left.set_target_angle_deg(-leg_target)
    else:
        charge = 0
        arm_right.set_target_angle_deg(0)
        arm_left.set_target_angle_deg(0)
        leg_right.set_target_angle_deg(0)
        leg_left.set_target_angle_deg(0)

func _physics_process(delta: float) -> void:
    var upright_force: float = 30 + charge * 2
    var upright_offset: float = 0.25
    var top: Vector3 = torso.global_position + torso.global_basis.y * upright_offset
    var bottom: Vector3 = torso.global_position - torso.global_basis.y * upright_offset
    torso.apply_force(Vector3.UP * upright_force, top)
    torso.apply_force(Vector3.DOWN * upright_force, bottom)
    if freeze:
        call_deferred("_freeze_bodies")
        freeze = false

func _freeze_bodies() -> void:
    torso.linear_velocity = Vector3.ZERO
    torso.angular_velocity = Vector3.ZERO
    for body in bodies:
        body.linear_velocity = Vector3.ZERO
        body.angular_velocity = Vector3.ZERO

    
func reset_guy() -> void:
    torso.position = start_position
    torso.rotation = Vector3.ZERO if not is_flipped else Vector3(0, 0, PI)
    torso.linear_velocity = Vector3.ZERO
    torso.angular_velocity = Vector3.ZERO
    for body in bodies:
        body.linear_velocity = Vector3.ZERO
        body.angular_velocity = Vector3.ZERO
    freeze = true