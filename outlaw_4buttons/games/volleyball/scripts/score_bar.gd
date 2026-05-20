class_name ScoreBar extends Control

var current_score_fill: float
var target_score_fill: float
var current_stake_fill: float
var target_stake_fill: float

var score_fill_control: Control
var stake_fill_control: Control

var min_val: float = 0.0125
var max_val: float = 0.972

func _ready() -> void:
    score_fill_control = $ScoreFill/ScoreFill
    stake_fill_control = $ScoreFill/StakeFill

func _process(delta: float) -> void:
    # set_target_stake_fill(1)
    current_score_fill = lerpf(current_score_fill, target_score_fill, delta * 1.5)
    current_score_fill = move_toward(current_score_fill, target_score_fill, delta * 0.1)
    current_stake_fill = lerpf(current_stake_fill, target_stake_fill, delta * 1.5)
    current_stake_fill = move_toward(current_stake_fill, target_stake_fill, delta * 0.1)

    var score_fill: float = _smooth_val(current_score_fill)
    score_fill = remap(score_fill, 0, 1, min_val, max_val) if score_fill < 1 else 1
    var stake_fill: float = _smooth_val(current_score_fill + current_stake_fill)
    stake_fill = remap(stake_fill, 0, 1, min_val, max_val) if stake_fill < 1 else 1
    score_fill_control.scale.y = score_fill
    stake_fill_control.scale.y = stake_fill

func _smooth_val(value: float) -> float:
    # return sin((value * PI) / 2)
    var knee: float = 0.75
    var knee_value: float = 0.9
    if value < knee:
        return lerpf(0, knee_value, value / knee)
    return lerpf(knee_value, 1, (value - knee) / (1 - knee))

func set_target_score_fill(new_target: float, instant: bool = false) -> void:
    target_score_fill = new_target
    if instant:
        current_score_fill = target_score_fill

func set_target_stake_fill(new_target: float, instant: bool = false) -> void:
    target_stake_fill = new_target
    if instant:
        current_stake_fill = target_stake_fill