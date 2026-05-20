class_name GameManager extends Node3D

enum GameState {PLAYING, RESET}
var current_state: GameState

var ball: RigidBody3D

var guys: Array

var score_0: int
var score_1: int

var ball_spawn_left: Node3D
var ball_spawn_right: Node3D
var ball_spawn: Node3D

# var score_label_0: Control
# var score_label_1: Control
# var win_label_0: Control
# var win_label_1: Control

var score_pips_left_on: Array
var score_pips_left_off: Array
var score_pips_right_on: Array
var score_pips_right_off: Array

var put_ball_to_sleep: bool

func _ready() -> void:
    ball = $Ball
    ball.body_entered.connect(_on_ball_body_entered)
    ball.sleeping = true
    guys.append($Guy1)
    guys.append($Guy2)
    # guys.append($Guy3)
    # guys.append($Guy4)
    ball_spawn_left = $BallSpawn_Left
    ball_spawn_right = $BallSpawn_Right
    current_state = GameState.PLAYING
    # score_label_0 = $UI/ScoreLabel_0
    # score_label_1 = $UI/ScoreLabel_1
    # score_label_0.visible = false
    # score_label_1.visible = false
    # win_label_0 = $UI/WinLabel_0
    # win_label_1 = $UI/WinLabel_1
    # win_label_0.visible = false
    # win_label_1.visible = false
    var score_pip_parent_left: Node3D = $ScorePips/Left
    for pip in score_pip_parent_left.get_children():
        score_pips_left_off.append(pip.get_child(0))
        score_pips_left_on.append(pip.get_child(1))
    var score_pip_parent_right: Node3D = $ScorePips/Right
    for pip in score_pip_parent_right.get_children():
        score_pips_right_off.append(pip.get_child(0))
        score_pips_right_on.append(pip.get_child(1))
    reset_scores()
    call_deferred("_sleep_ball")

func _sleep_ball() -> void:
    ball.sleeping = true

var audio_key_pressed: bool
var reset_key_pressed: bool
var reset_timer: float = 0.0 # Counter for delay
const RESET_DELAY: float = 2.0 # 5 second delay

func _process(delta: float) -> void:
    if Input.is_key_pressed(KEY_ESCAPE):
        print("ESCAPE PRESSED")
        get_tree().change_scene_to_file("res://gameselect.tscn")
    if Input.is_key_pressed(KEY_R):
        if not reset_key_pressed:
            reset_key_pressed = true
            reset_timer = 0.0 # Start counting
        else:
            reset_timer += delta # Increment timer
            if reset_timer >= RESET_DELAY:
                hard_reset()
                reset_key_pressed = false # Prevent repeated resets
    else:
        reset_key_pressed = false
        reset_timer = 0.0 # Reset counter if key released early

    if Input.is_key_pressed(KEY_T) and not audio_key_pressed:
        audio_key_pressed = true
        AudioManager.play_grunt()
    if not Input.is_key_pressed(KEY_T):
        audio_key_pressed = false

func _physics_process(delta: float) -> void:
    if put_ball_to_sleep:
        _sleep_ball()
        call_deferred("_sleep_ball")
        put_ball_to_sleep = false

func _on_ball_body_entered(body: Node) -> void:
    if body.name.begins_with("Ground"):
        if body.name.ends_with("Right"):
            score(0)
        else:
            score(1)

func score(side: int) -> void:
    if current_state != GameState.PLAYING:
        return
    if side == 0:
        score_0 += 1
        ball_spawn = ball_spawn_right
        # score_label_0.visible = true
        print("SCORE LEFT: %d" % score_0)
        for i in range(score_0):
            score_pips_left_off[i].visible = false
            score_pips_left_on[i].visible = true
    else:
        score_1 += 1
        ball_spawn = ball_spawn_left
        # score_label_1.visible = true
        print("SCORE RIGHT: %d" % score_1)
        for i in range(score_1):
            score_pips_right_off[i].visible = false
            score_pips_right_on[i].visible = true
    Engine.time_scale = 0
    if score_0 >= score_pips_left_on.size() or score_1 >= score_pips_right_on.size():
        end_match()
    else:
        reset_point()

func reset_scores() -> void:
    score_0 = 0
    score_1 = 0
    for pip in score_pips_left_on:
        pip.visible = false
    for pip in score_pips_left_off:
        pip.visible = true
    for pip in score_pips_right_on:
        pip.visible = false
    for pip in score_pips_right_off:
        pip.visible = true


func reset_point(instant: bool = false) -> void:
    current_state = GameState.RESET
    if not instant:
        await get_tree().create_timer(1.0, true, false, true).timeout
    Engine.time_scale = 0.2
    if not instant:
        await get_tree().create_timer(3.0, true, false, true).timeout
    current_state = GameState.PLAYING
    ball.global_position = ball_spawn.global_position
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
    ball.sleeping = true
    call_deferred("_sleep_ball")
    Engine.time_scale = 1
    put_ball_to_sleep = true
    # win_label_0.visible = false
    # win_label_1.visible = false
    # score_label_0.visible = false
    # score_label_1.visible = false
    for guy in guys:
        guy.reset_guy()

func end_match() -> void:
    current_state = GameState.RESET
    # score_label_0.visible = false
    # score_label_1.visible = false
    # if score_0 >= score_pips_left_on.size():
    #     win_label_0.visible = true
    # else:
    #     win_label_1.visible = true
    await get_tree().create_timer(1.0, true, false, true).timeout
    Engine.time_scale = 0.2
    await get_tree().create_timer(4.0, true, false, true).timeout
    reset_scores()
    reset_point()

var _cancel_reset := false

func hard_reset() -> void:
    # 1. Tell async code to stop
    _cancel_reset = true
    Engine.time_scale = 1

    # 2. Stop all active SceneTree timers
    for timer in get_tree().get_nodes_in_group("SceneTreeTimers"):
        if is_instance_valid(timer):
            timer.stop()

    # 3. Free nodes outside current scene (leftovers in root)
    for child in get_tree().root.get_children():
        if child != get_tree().current_scene:
            child.queue_free()

    # 4. Reload the main scene
    get_tree().reload_current_scene()

    # 5. Reset cancel flag for new scene
    _cancel_reset = false
