class_name AudioManager extends Node

static var grunts: Array
static var last_grunt_id: int
static var ball_sounds:  Array
static var last_ball_sound_id: int
static var ball_body_sounds:  Array
static var last_ball_body_sound_id: int
static var player_pool: Array
static var current_player: int

func _ready() -> void:
    load_sounds("res://games/volleyball/audio/grunts/", grunts)
    load_sounds("res://games/volleyball/audio/ballsounds/", ball_sounds)
    load_sounds("res://games/volleyball/audio/ballbodysounds/", ball_body_sounds)

    for i in range(5):
        var new_player = AudioStreamPlayer.new()
        player_pool.append(new_player)
        add_child(new_player)

func load_sounds(path: String, collection: Array) -> void:
    var dir: DirAccess = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name: String = dir.get_next()
        while file_name != "":
            var stream: AudioStream = load(path + file_name)
            if stream:
                collection.append(stream)
            file_name = dir.get_next()
        dir.list_dir_end()

static func play_grunt() -> void:
    last_grunt_id = play_sound_from_collection(grunts, last_grunt_id)

static func play_ball_sound() -> void:
    last_ball_sound_id = play_sound_from_collection(ball_sounds, last_ball_sound_id)

static func play_ball_body_sound() -> void:
    last_ball_body_sound_id = play_sound_from_collection(ball_body_sounds, last_ball_body_sound_id)

static func play_sound_from_collection(collection: Array, last_played: int) -> int:
    var sound_index: int = randi_range(0, collection.size() - 2)
    if sound_index >= last_played:
        sound_index += 1
    play_sound(collection[sound_index])
    return sound_index

static func play_sound(sound) -> void:
    var player = player_pool[current_player]
    player.stream = sound
    player.play()
    current_player = (current_player + 1) % player_pool.size()

func _exit_tree() -> void:
    player_pool.clear()
    grunts.clear()
    ball_sounds.clear()
    ball_body_sounds.clear()
    current_player = 0
