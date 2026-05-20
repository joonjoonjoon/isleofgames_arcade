class_name Fencer extends Node3D

@export var player_id: int

const wait_anim: String = "Armature|Waiting"
const idle_anim: String = "Armature|Idle"
const super_lunge_anim: String = "Armature|SuperLunge"
const prelunge_anim: String = "Armature|PreLunge"
const lunge_anim: String = "Armature|Lunge"
const lunge2_anim: String = "Armature|Lunge2"
const parry_anim: String = "Armature|Parry"
const parry2_anim: String = "Armature|Parry2"
const disarm_anim: String = "Armature|Disarm"
const feint_anim: String = "Armature|Feint"

enum State {
    WAITING,
    IDLE,
    LUNGE,
    SUPER_LUNGE,
    PARRY,
    BACKSTEP,
    FEINT,
    KNOCKED
}
var current_state: State
var state_timer: float
var buffered_action: State
var buffered_action_time: int
var is_attacking: bool
var is_parrying: bool

var anim_player: AnimationPlayer
var action_tween: Tween

var parry_action: String
var lunge_action: String

var weapon_tip: Node3D
var mid_weapon: Node3D
var shoulder: Node3D
var hand: Node3D
var parry_indicator: Node3D
var attack_indicator: Node3D
var start_position: float

var can_input: bool
var is_frozen: bool

var bot_label: Node3D

@export var is_ai_player: bool

func _ready() -> void:
    anim_player = $AnimationPlayer
    parry_action = "parry_" + str(player_id)
    lunge_action = "lunge_" + str(player_id)
    bot_label = $BotLabel
    weapon_tip = $Armature/Skeleton3D/WeaponTip/Offset
    mid_weapon = $Armature/Skeleton3D/MidWeapon/Offset
    shoulder = $Armature/Skeleton3D/Shoulder/Offset
    hand = $Armature/Skeleton3D/Hand/Offset
    parry_indicator = $Armature/Skeleton3D/ParryIndicator
    attack_indicator = $Armature/Skeleton3D/AttackIndicator
    parry_indicator.visible = false
    attack_indicator.visible = false
    start_position = global_position.x

func _process(delta: float) -> void:
    bot_label.visible = is_ai_player
    
    if is_frozen:
        return

    var buffer_time = 300
    var did_input: bool = false
    is_attacking = false
    is_parrying = false

    var wants_to_parry: bool = false
    var wants_to_lunge: bool = false
    if can_input:
        if is_ai_player:
            # Simple AI: randomly decide to parry or lunge every second
            if randi() % 100 < 10:
                if randi() % 2 == 0:
                    wants_to_parry = true
                else:
                    wants_to_lunge = true
            # wants_to_parry = false
            # wants_to_lunge = false
        else:
            wants_to_parry = Input.is_action_just_pressed(parry_action) or (buffered_action == State.PARRY and Time.get_ticks_msec() - buffered_action_time < buffer_time)
            wants_to_lunge = Input.is_action_just_pressed(lunge_action) or (buffered_action == State.LUNGE and Time.get_ticks_msec() - buffered_action_time < buffer_time)

    state_timer += delta
    if current_state == State.IDLE:
        if wants_to_parry:
            parry_start()
            did_input = true
        elif wants_to_lunge:
            lunge_start()
            did_input = true
    elif current_state == State.LUNGE:
        if state_timer < 0.2 and wants_to_parry:
            feint_start()
            did_input = true
        else:
            lunge_process(delta)
    elif current_state == State.SUPER_LUNGE:
        super_lunge_process(delta)
    elif current_state == State.FEINT:
        if wants_to_lunge:
            lunge_start()
        else:
            feint_process(delta)
    elif current_state == State.PARRY:
        if state_timer < 0.2 and wants_to_lunge:
            super_lunge_start()
            did_input = true
        elif wants_to_parry:
            backstep_start()
            did_input = true
        else:
            parry_process(delta)
    elif current_state == State.BACKSTEP:
        backstep_process(delta)
    elif current_state == State.KNOCKED:
        knock_process(delta)
    if did_input:
        buffered_action = State.IDLE
    else:
        if Input.is_action_just_pressed(parry_action):
            buffered_action = State.PARRY
            buffered_action_time = Time.get_ticks_msec()
        if Input.is_action_just_pressed(lunge_action):
            buffered_action = State.LUNGE
            buffered_action_time = Time.get_ticks_msec()
    parry_indicator.visible = is_parrying
    attack_indicator.visible = is_attacking

func wait_start() -> void:
    current_state = State.WAITING
    play_anim(wait_anim)

func idle_start() -> void:
    if (current_state == State.FEINT or current_state == State.LUNGE or current_state == State.KNOCKED) and Input.is_action_pressed(parry_action):
        buffered_action = State.PARRY
        buffered_action_time = Time.get_ticks_msec()
    current_state = State.IDLE
    play_anim(idle_anim)

func lunge_start() -> void:
    AudioManager_fencing.play_lunge()
    current_state = State.LUNGE
    state_timer = 0
    play_anim(prelunge_anim)

var pre_lunge_time: float = 0.15
var lunge_time: float = 0.4
func lunge_process(delta: float) -> void:
    if state_timer >= pre_lunge_time and state_timer < lunge_time:
        is_attacking = true
        play_anim(lunge_anim)
    if state_timer < lunge_time:
        var lunge_distance: float = 0.5
        global_position += global_basis.z * smoothed_value(lunge_time, state_timer, lunge_distance, delta)
    if state_timer >= lunge_time and state_timer - delta < lunge_time:
        play_anim(lunge2_anim)
    if state_timer >= lunge_time + 0.2:
        global_position += global_basis.z * 0.5
        idle_start()

func super_lunge_start() -> void:
    current_state = State.SUPER_LUNGE
    state_timer = 0
    play_anim(prelunge_anim)

var pre_lunge_time_super: float = 0.25
var lunge_time_super: float = 0.5
func super_lunge_process(delta: float) -> void:
    if state_timer >= pre_lunge_time_super and state_timer < lunge_time_super:
        is_attacking = true
        play_anim(super_lunge_anim)
    if state_timer < lunge_time_super:
        var lunge_distance = 2.5
        global_position += global_basis.z * smoothed_value(lunge_time_super, state_timer, lunge_distance, delta)
    if state_timer >= lunge_time_super:
        play_anim(lunge2_anim)
    if state_timer >= lunge_time + 0.4:
        global_position += global_basis.z * 0.5
        idle_start()

func feint_start() -> void:
    current_state = State.FEINT
    state_timer = 0
    play_anim(prelunge_anim)
    is_attacking = false

func feint_process(delta: float) -> void:
    var feint_time = 0.2
    if state_timer < feint_time:
        global_position += global_basis.z * smoothed_value(feint_time, state_timer, 0.25, delta)
    if state_timer >= feint_time:
        play_anim(feint_anim)
    if state_timer >= feint_time + 0.1:
        idle_start()

func parry_start() -> void:
    current_state = State.PARRY
    state_timer = 0
    play_anim(parry_anim)
    is_parrying = true

var parry_time: float = 0.3
func parry_process(delta: float) -> void:
    # if state_timer < 0.1:
    #     global_position -= global_basis.z * smoothed_value(0.1, state_timer, 0.5, delta)
    if state_timer < parry_time:
        is_parrying = true
    if state_timer >= parry_time and state_timer < delta - parry_time:
        play_anim(parry2_anim)
    if state_timer >= parry_time + 0.2:
        idle_start()

func parry_recover() -> void:
    idle_start()
    # current_state = State.PARRY
    # state_timer = parry_time

func backstep_start() -> void:
    state_timer = 0
    current_state = State.BACKSTEP
    play_anim(parry2_anim)

func backstep_process(delta: float) -> void:
    global_position -= global_basis.z * smoothed_value(0.1, state_timer, 1.5, delta)
    if state_timer >= 0.1:
        idle_start()

var knock_time: float
func knock_start(time: float = 0.4) -> void:
    current_state = State.KNOCKED
    knock_time = time
    state_timer = 0
    play_anim(disarm_anim)

func knock_process(delta: float) -> void:
    global_position -= global_basis.z * smoothed_value(knock_time, state_timer, 0.1, delta)
    if state_timer > knock_time:
        idle_start()

func play_anim(anim: String) -> void:
    anim_player.play(anim)
    anim_player.advance(0)

func smoothed_value(total_time: float, current_time: float, value_range: float, delta_time: float) -> float:
    if total_time <= 0:
        return value_range
    var t1: float = clamp(current_time / total_time, 0, 1)
    var t2: float = clamp((current_time + delta_time) / total_time, 0, 1)
    var ease_1: float = 1.0 - pow(1.0 - t1, 2)
    var ease_2: float = 1.0 - pow(1.0 - t2, 2)
    var progress_delta: float = ease_2 - ease_1
    return progress_delta * value_range

func reset_fencer() -> void:
    global_position.x = start_position
    is_frozen = false
    idle_start()

func check_attack_state() -> bool:
    return is_attacking and (current_state == State.LUNGE or current_state == State.SUPER_LUNGE)

func check_parry_state() -> bool:
    return is_parrying and current_state == State.PARRY

func check_both_pressed() -> bool:
    return (Input.is_action_pressed(parry_action) and Input.is_action_pressed(lunge_action)) or \
        (Input.is_action_pressed(parry_action) and Input.is_action_pressed(lunge_action))
