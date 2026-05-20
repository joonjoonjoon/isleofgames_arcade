class_name AudioManager_fencing extends Node

static var lunges: Array
static var last_grunt_id: int
static var player_pool: Array
static var current_player: int

func _ready() -> void:
    load_sounds("res://games/fencing/audio/lunge/", lunges)

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

static func play_lunge() -> void:
    last_grunt_id = play_sound_from_collection(lunges, last_grunt_id)

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
    lunges.clear()
    current_player = 0
