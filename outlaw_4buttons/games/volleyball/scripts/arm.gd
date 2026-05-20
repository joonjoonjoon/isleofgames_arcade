class_name Arm extends Node3D

@export var hinge_0: TargetHinge
@export var hinge_1: TargetHinge

func _process(delta: float) -> void:
    var speed: float = 16
    if Input.is_key_pressed(KEY_D):
        hinge_0.rotate_hinge(-delta * speed)
        hinge_1.rotate_hinge(-delta * speed)
    if Input.is_key_pressed(KEY_A):
        hinge_0.rotate_hinge(delta * speed)
        hinge_1.rotate_hinge(delta * speed)