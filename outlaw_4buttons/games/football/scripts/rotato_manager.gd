extends Node2D

enum GameState { PRE_START, PLAYING, POST_GOAL }
var current_state: GameState

var goal_left: Area2D
var goal_right: Area2D
var ball: RigidBody2D
var left_team: Array[PlayerBall]
var right_team: Array[PlayerBall]
var all_players: Array[PlayerBall]
var left_score_text: Node
var right_score_text: Node
var state_text: Label

const MENU_RESET_HOLD_TIME: float = 3.0
const IDLE_TIMEOUT_MS: int = 60000
const WIN_SCORE: int = 3
const MENU_SCENE: String = "res://gameselect.tscn"

var menu_reset_timer: float = 0.0
var last_input_time: int = 0
var left_score: int = 0
var right_score: int = 0
var _returning_to_menu: bool = false

func _ready() -> void:
    goal_left = $Pitch/Goal_Left
    goal_right = $Pitch/Goal_Right
    goal_left.connect("body_entered", func(body: Node): _on_goal_entered(body, 0))
    goal_right.connect("body_entered", func(body: Node): _on_goal_entered(body, 1))
    ball = $Ball
    left_team.append($PlayerBall_0_0)
    left_team.append($PlayerBall_0_1)
    right_team.append($PlayerBall_1_0)
    right_team.append($PlayerBall_1_1)
    all_players.append(left_team[0])
    all_players.append(left_team[1])
    all_players.append(right_team[0])
    all_players.append(right_team[1])
    left_score_text = $Score_Label_Left
    right_score_text = $Score_Label_Right
    state_text = $StateLabel
    state_text.text = ""
    last_input_time = Time.get_ticks_msec()
    _start_play()

func _input(event: InputEvent) -> void:
    if event.is_pressed() and not event.is_echo():
        last_input_time = Time.get_ticks_msec()

func _process(delta: float) -> void:
    if Input.is_action_pressed("reset"):
        menu_reset_timer += delta
        if menu_reset_timer >= MENU_RESET_HOLD_TIME:
            _return_to_menu()
    else:
        menu_reset_timer = 0.0
    if Time.get_ticks_msec() - last_input_time > IDLE_TIMEOUT_MS:
        _return_to_menu()
    if Input.is_action_just_pressed("ui_accept"):
        _goal_scored(0)

func _start_play() -> void:
    state_text.text = ""
    for player in all_players:
        player.freeze_player()
    current_state = GameState.PRE_START
    ball.global_transform.origin = Vector2.ZERO
    var position_0: Vector2 = Vector2(-140, -50)
    var position_1: Vector2 = Vector2(-220, 50)
    left_team[0].global_transform.origin = position_0
    left_team[1].global_transform.origin = position_1
    position_0.x *= -1
    var other_y = position_0.y
    position_0.y = position_1.y
    position_1.x *= -1
    position_1.y = other_y
    right_team[0].global_transform.origin = position_0
    right_team[1].global_transform.origin = position_1

    var start_delay: float = 2
    for i in range(3):
        state_text.text = str(3 - i)
        await get_tree().create_timer(start_delay / 3).timeout
    state_text.text = "GO!!!"
    for player in all_players:
        player.freeze = false
        player.unfreeze_player()
    current_state = GameState.PLAYING
    await get_tree().create_timer(1).timeout
    state_text.text = ""

func _goal_scored(side: int) -> void:
    if current_state != GameState.PLAYING:
        return
    current_state = GameState.POST_GOAL
    for player in all_players:
        player.freeze_player()
    if side == 0:
        right_score += 1
        state_text.text = "RIGHT SCORES!!!"
    else:
        left_score += 1
        state_text.text = "LEFT SCORES!!!"
    await get_tree().create_timer(2).timeout
    if left_score >= WIN_SCORE or right_score >= WIN_SCORE:
        state_text.text = "LEFT WINS!!!" if left_score >= WIN_SCORE else "RIGHT WINS!!!"
        await get_tree().create_timer(3).timeout
        _return_to_menu()
    else:
        _start_play()

func _return_to_menu() -> void:
    if _returning_to_menu:
        return
    _returning_to_menu = true
    Engine.time_scale = 1.0
    RenderingServer.set_default_clear_color(Color("#fcba03"))
    get_tree().change_scene_to_file(MENU_SCENE)

func set_body_position(body: RigidBody2D, new_position: Vector2) -> void:
    body.global_position = new_position
    body.linear_velocity = Vector2.ZERO
    body.angular_velocity = 0

func _on_goal_entered(body: Node, side: int) -> void:
    if body.name == "Ball":
        _goal_scored(side)
