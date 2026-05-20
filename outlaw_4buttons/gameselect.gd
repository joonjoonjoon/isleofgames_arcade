extends Control

func _ready():
    RenderingServer.set_default_clear_color(Color("#fcba03")) # this works
    Engine.time_scale = 1
    # reset timescale
