class_name GameManager extends Node3D

enum GameState {SERVING, PLAYING, RESET}
var current_state: GameState

var ball: RigidBody3D

var guys: Array

var score_0: int
var score_1: int

var score_fill_0: float
var score_fill_1: float
var score_stake: float

var ball_spawn_left: Node3D
var ball_spawn_right: Node3D
var ball_spawn: Node3D

var score_bar_right: ScoreBar
var score_bar_left: ScoreBar

var victory_particles_0: GPUParticles3D
var victory_particles_1: GPUParticles3D

var put_ball_to_sleep: bool

var last_input_time: int

func _ready() -> void:
    #Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    ball = $Ball
    ball.body_entered.connect(_on_ball_body_entered)
    ball.sleeping = true
    guys.append($Guy1)
    guys.append($Guy2)
    ball_spawn_left = $BallSpawn_Left
    ball_spawn_right = $BallSpawn_Right
    current_state = GameState.SERVING
    score_bar_right = $SubUI/SubViewport/Control/ScoreBar_Right
    score_bar_left = $SubUI/SubViewport/Control/ScoreBar_Left
    victory_particles_0 = $Particles_0
    victory_particles_1 = $Particles_1
    reset_scores()
    ball_spawn = ball_spawn_left if randf() > 0.5 else ball_spawn_right
    ball.global_position = ball_spawn.global_position
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
    ball.sleeping = true
    call_deferred("_sleep_ball")
    last_input_time = Time.get_ticks_msec()

func _sleep_ball() -> void:
    ball.sleeping = true

var reset_key_pressed: bool
var reset_timer: float = 0.0 # Counter for delay
const RESET_DELAY: float = 2.0 # 5 second delay

func _process(delta: float) -> void:
    if current_state == GameState.SERVING and not ball.sleeping:
        current_state = GameState.PLAYING
        AudioManager.play_ball_body_sound()
        # score_stake = 1
        score_stake = 0.05
    if current_state == GameState.PLAYING:
        score_stake = lerpf(score_stake, 0.3, 1.0 - exp(-0.1 * delta))
        score_bar_left.set_target_stake_fill(score_stake)
        score_bar_right.set_target_stake_fill(score_stake)
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
    if Input.is_key_pressed(KEY_ESCAPE):
        get_tree().change_scene_to_file("res://gameselect.tscn")
    if (score_fill_0 > 0 or score_fill_1 > 0) and Time.get_ticks_msec() - last_input_time > 60000:
        hard_reset()

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

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        last_input_time = Time.get_ticks_msec()

func score(side: int) -> void:
    if current_state != GameState.PLAYING:
        return
    if side == 0:
        score_fill_0 += score_stake
        score_0 += 1
        ball_spawn = ball_spawn_right
        guys[1].set_active_head("loss")
    else:
        score_fill_1 += score_stake
        score_1 += 1
        ball_spawn = ball_spawn_left
        guys[0].set_active_head("loss")
    score_stake = 0
    Engine.time_scale = 0.05
    if score_fill_0 >= 1 or score_fill_1 >= 1:
        end_match()
    else:
        reset_point()

func reset_scores() -> void:
    score_fill_0 = 0
    score_fill_1 = 0
    score_bar_left.set_target_score_fill(0, true)
    score_bar_right.set_target_score_fill(0, true)
    score_bar_left.set_target_stake_fill(0, true)
    score_bar_right.set_target_stake_fill(0, true)
    score_stake = 0
    score_0 = 0
    score_1 = 0


func reset_point(instant: bool = false) -> void:
    current_state = GameState.RESET
    if not instant:
        await get_tree().create_timer(1.0, true, false, true).timeout
    Engine.time_scale = 0.2
    if not instant:
        await get_tree().create_timer(3.0, true, false, true).timeout
    score_bar_left.set_target_score_fill(score_fill_0)
    score_bar_right.set_target_score_fill(score_fill_1)
    score_bar_left.set_target_stake_fill(0)
    score_bar_right.set_target_stake_fill(0)
    guys[0].set_active_head("idle")
    guys[1].set_active_head("idle")
    current_state = GameState.SERVING
    ball.global_position = ball_spawn.global_position
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
    ball.sleeping = true
    call_deferred("_sleep_ball")
    Engine.time_scale = 1
    put_ball_to_sleep = true
    for guy in guys:
        guy.reset_guy()

func end_match() -> void:
    current_state = GameState.RESET
    if score_fill_0 >= 1:
        guys[0].set_active_head("win")
        guys[1].set_active_head("matchloss")
    else:
        guys[1].set_active_head("win")
        guys[0].set_active_head("matchloss")
    await get_tree().create_timer(1.0, true, false, true).timeout
    Engine.time_scale = 0.2
    score_bar_left.set_target_score_fill(score_fill_0)
    score_bar_right.set_target_score_fill(score_fill_1)
    score_bar_left.set_target_stake_fill(0)
    score_bar_right.set_target_stake_fill(0)
    await get_tree().create_timer(3.0, true, false, true).timeout
    Engine.time_scale = 1
    if score_fill_0 >= 1:
        victory_particles_0.emitting = true
    else:
        victory_particles_1.emitting = true
    await get_tree().create_timer(8.0, true, false, true).timeout
    hard_reset()

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
