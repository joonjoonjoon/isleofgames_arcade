extends Node

const HOLD_TIME: float = 3.0
const MAX_SCALE: float = 1.35
const SHAKE_ROTATION: float = 0.12

@export var button_id: String
@export var game: Games
@export var button_visual: TextureRect

enum Games {
    FOOTBALL,
    VOLLEYBALL,
    FENCING
}

var hold_timer: float = 0.0
var _shake_time: float = 0.0

func _ready() -> void:
    _resolve_nodes()
    _reset_visual()

func _resolve_nodes() -> void:
    if button_visual:
        return
    var parent := get_parent()
    button_visual = parent.get_node_or_null("Button Image") as TextureRect
    if not button_visual:
        button_visual = parent.get_node_or_null("TextureRect3") as TextureRect

func _process(delta: float) -> void:
    if Input.is_action_pressed(button_id):
        hold_timer += delta
        _apply_hold_visual(clampf(hold_timer / HOLD_TIME, 0.0, 1.0), delta)
        if hold_timer >= HOLD_TIME:
            hold_timer = 0.0
            _reset_visual()
            _launch_game()
    else:
        if hold_timer > 0.0:
            _reset_visual()
        hold_timer = 0.0
        _shake_time = 0.0

func _apply_hold_visual(ratio: float, delta: float) -> void:
    if not button_visual:
        return
    if button_visual.size.x > 0.0:
        button_visual.pivot_offset = button_visual.size * 0.5
    var scale_factor := lerpf(1.0, MAX_SCALE, ratio)
    button_visual.scale = Vector2(scale_factor, scale_factor)
    _shake_time += delta * 28.0
    var shake := sin(_shake_time * 2.1) + cos(_shake_time * 3.7) * 0.6
    button_visual.rotation = shake * SHAKE_ROTATION * ratio

func _reset_visual() -> void:
    if not button_visual:
        return
    button_visual.scale = Vector2.ONE
    button_visual.rotation = 0.0

func _launch_game() -> void:
    match game:
        Games.FOOTBALL:
            _on_pressed_football()
        Games.VOLLEYBALL:
            _on_pressed_volleyball()
        Games.FENCING:
            _on_pressed_fencing()

func _on_pressed_football() -> void:
    RenderingServer.set_default_clear_color(Color("#577a42"))
    get_tree().change_scene_to_file("res://games/football/scenes/rotato.tscn")

func _on_pressed_volleyball() -> void:
    RenderingServer.set_default_clear_color(Color(0.863013, 0.819921, 0.762014, 1))
    get_tree().change_scene_to_file("res://games/volleyball/volleyball_two_sided.tscn")

func _on_pressed_fencing() -> void:
    RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))
    get_tree().change_scene_to_file("res://games/fencing/game.tscn")
