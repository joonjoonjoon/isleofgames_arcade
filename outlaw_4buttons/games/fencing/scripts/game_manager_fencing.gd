extends Node3D

enum GameState {
    NONE,
    START_DELAY,
    FENCING,
    TIMESTOP,
    POINT
}
var current_state: GameState

var fencer_0: Fencer
var fencer_1: Fencer

var state_label: Label

var fencer_0_hit_buffer: bool
var fencer_0_hit_buffer_time: float
var fencer_1_hit_buffer: bool
var fencer_1_hit_buffer_time: float

var max_x: float = 5

var parry_flash: Node3D
var parry_flash_particles: GPUParticles3D
var bout_start_time: int

var middle_fill: CanvasItem
var right_fills: Array[CanvasItem]
var left_fills: Array[CanvasItem]
var score: int

func _ready() -> void:
    fencer_0 = $Fencer_0
    fencer_1 = $Fencer_1
    state_label = $UI/Label
    state_label.text = ""
    parry_flash = $ParryFlash
    # parry_flash.visible = false
    parry_flash_particles = $ParryFlash/GPUParticles3D
    middle_fill = $UI/ScorePanel/Middle/Fill
    right_fills.append($UI/ScorePanel/Right0/Fill)
    right_fills.append($UI/ScorePanel/Right1/Fill)
    right_fills.append($UI/ScorePanel/Right2/Fill)
    left_fills.append($UI/ScorePanel/Left0/Fill)
    left_fills.append($UI/ScorePanel/Left1/Fill)
    left_fills.append($UI/ScorePanel/Left2/Fill)
    update_score_fills()
    #Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    call_deferred("start_match")

var reset_timer: float
func _process(delta: float) -> void:
    if Input.is_action_just_pressed("reset"):
        get_tree().change_scene_to_file("res://gameselect.tscn")

    # if Input.is_key_pressed(KEY_R):
    #     reset_timer += delta
    #     if reset_timer >= 2:
    #         hard_reset()
    # else:
    #     reset_timer = 0

    if current_state == GameState.START_DELAY:
        start_process(delta)
        #if fencer_0.check_both_pressed():
            #fencer_0.is_ai_player = not fencer_0.is_ai_player
            #start_match()
        #if fencer_1.check_both_pressed():
            #fencer_1.is_ai_player = not fencer_1.is_ai_player
            #start_match()
    elif current_state == GameState.FENCING:
        if not state_label.text.is_empty() and Time.get_ticks_msec() - bout_start_time > 1000:
            state_label.text = ""
        resolve_collisions()
    if fencer_0.hand.global_position.x > fencer_1.hand.global_position.x:
        var overlap: float = fencer_0.hand.global_position.x - fencer_1.hand.global_position.x
        fencer_0.global_position.x -= overlap / 2
        fencer_1.global_position.x += overlap / 2
    if fencer_0.global_position.x < -max_x:
        fencer_0.global_position.x = -max_x
    if fencer_1.global_position.x > max_x:
        fencer_1.global_position.x = max_x

func resolve_collisions() -> void:
    var weapon_0: float = fencer_0.weapon_tip.global_position.x
    var weapon_1: float = fencer_1.weapon_tip.global_position.x
    var shoulder_0: float = fencer_0.shoulder.global_position.x
    var shoulder_1: float = fencer_1.shoulder.global_position.x
    var hit_buffer_time: int = 50
    if weapon_0 > weapon_1:
        if fencer_0.check_attack_state() and fencer_1.check_attack_state():
            clang()
            return
        elif fencer_0.check_attack_state() and fencer_1.check_parry_state():
            parry(1)
            return
        elif fencer_1.check_attack_state() and fencer_0.check_parry_state():
            parry(0)
            return
    if weapon_0 > shoulder_1:
        if not fencer_0_hit_buffer and fencer_0.check_attack_state() and not fencer_1.check_parry_state():
            fencer_0_hit_buffer = true
            fencer_0_hit_buffer_time = Time.get_ticks_msec()
    if fencer_0_hit_buffer:
        if Time.get_ticks_msec() - fencer_0_hit_buffer_time > hit_buffer_time:
            point(0)
            return
        elif fencer_1.check_attack_state():
            clang()
            return
        elif fencer_1.check_parry_state():
            parry(1)
            return
    if weapon_1 < shoulder_0:
        if not fencer_1_hit_buffer and fencer_1.check_attack_state() and not fencer_0.check_parry_state():
            fencer_1_hit_buffer = true
            fencer_1_hit_buffer_time = Time.get_ticks_msec()
    if fencer_1_hit_buffer:
        if Time.get_ticks_msec() - fencer_1_hit_buffer_time > hit_buffer_time:
            point(1)
            return
        elif fencer_0.check_attack_state():
            clang()
            return
        elif fencer_0.check_parry_state():
            parry(0)
            return

func clang() -> void:
    current_state = GameState.TIMESTOP
    fencer_0.is_frozen = true
    fencer_1.is_frozen = true
    fencer_0_hit_buffer = false
    fencer_1_hit_buffer = false
    var overlap: float = fencer_0.mid_weapon.global_position.x - fencer_1.mid_weapon.global_position.x
    overlap = max(overlap, 0)
    print("overlap "+str(overlap))
    var middle: float = (fencer_0.global_position.x + fencer_1.global_position.x) / 2
    if overlap > 0:
        fencer_0.global_position.x -= overlap / 2
        fencer_1.global_position.x += overlap / 2
    await get_tree().create_timer(0.1).timeout
    parry_flash.global_position = fencer_0.mid_weapon.global_position
    parry_flash_particles.emitting = true
    fencer_0.global_position += fencer_0.global_basis.z * 0.5
    fencer_1.global_position += fencer_1.global_basis.z * 0.5
    fencer_0.knock_start(0.2)
    fencer_1.knock_start(0.2)
    fencer_0.is_frozen = false
    fencer_1.is_frozen = false
    current_state = GameState.FENCING
    fencer_0._process(0)
    fencer_1._process(0)

func parry(side: int) -> void:
    var attacker: Fencer = fencer_1 if side == 0 else fencer_0
    var parryer: Fencer = fencer_0 if side == 0 else fencer_1
    fencer_0_hit_buffer = false
    fencer_1_hit_buffer = false
    fencer_0.is_frozen = true
    fencer_1.is_frozen = true
    current_state = GameState.TIMESTOP
    var middle: float = (parryer.hand.global_position.x + parryer.weapon_tip.global_position.x) / 2
    # parry_flash.visible = true
    parry_flash.global_position = parryer.mid_weapon.global_position
    parry_flash_particles.emitting = true
    await get_tree().create_timer(0.2).timeout
    # parry_flash.visible = false
    attacker.global_position = parryer.global_position + parryer.global_basis.z * 3
    fencer_0.is_frozen = false
    fencer_1.is_frozen = false
    current_state = GameState.FENCING
    attacker.knock_start()
    parryer.parry_recover()
    fencer_0._process(0)
    fencer_1._process(0)

func point(side: int) -> void:
    current_state = GameState.TIMESTOP
    state_label.text = "POINT À " + ("GAUCHE" if side == 0 else "DROITE")
    fencer_0.is_frozen = true
    fencer_1.is_frozen = true
    var scorer: Fencer = fencer_0 if side == 0 else fencer_1
    var scoree: Fencer = fencer_1 if side == 0 else fencer_0
    var overlap: float = scorer.weapon_tip.global_position.x - scoree.shoulder.global_position.x
    # scoree.global_position.x += overlap
    # await get_tree().create_timer(1, true, false, true).timeout
    score += 1 if side == 1 else -1
    update_score_fills()
    await get_tree().create_timer(1.5, true, false, true).timeout
    if score >= 3 or score <= -3:
        state_label.text = "VICTOIRE À " + ("GAUCHE" if side == 0 else "DROITE")
        fencer_0.anim_player.play("Armature|Salute2")
        fencer_1.anim_player.play("Armature|Salute2")
        await get_tree().create_timer(2.5, true, false, true).timeout
        score = 0
        update_score_fills()
        fencer_0.anim_player.play("Armature|Waiting")
        fencer_1.anim_player.play("Armature|Waiting")
    state_label.text = ""
    start_match()

var countdown_timer: float
func start_match() -> void:
    current_state = GameState.START_DELAY
    fencer_0.reset_fencer()
    fencer_0.can_input = false
    fencer_0.wait_start()
    fencer_1.reset_fencer()
    fencer_1.can_input = false
    fencer_1.wait_start()
    state_label.text = ""
    fencer_0_hit_buffer = false
    fencer_1_hit_buffer = false
    countdown_timer = 0

func start_process(delta: float) -> void:
    countdown_timer += delta
    if countdown_timer >= 1 and countdown_timer < 2:
        state_label.text = "PRÊT"
        fencer_0.anim_player.play("Armature|Salute1")
        fencer_1.anim_player.play("Armature|Salute1")
    elif countdown_timer >= 2:
        fencer_0.idle_start()
        fencer_1.idle_start()
        state_label.text = "ALLEZ"
        fencer_0.can_input = true
        fencer_1.can_input = true
        current_state = GameState.FENCING
        bout_start_time = Time.get_ticks_msec()

func update_score_fills() -> void:
    middle_fill.visible = score == 0
    for i in range(right_fills.size()):
        right_fills[i].visible = i < score
    for i in range(left_fills.size()):
        left_fills[i].visible = i < -score

func hard_reset() -> void:
    Engine.time_scale = 1
    get_tree().reload_current_scene()
