extends Node3D

@export var target: Node3D

func _process(delta: float) -> void:
    global_position = target.global_position - Vector3.FORWARD
    global_basis = target.global_basis