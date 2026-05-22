extends Node

# Audio dispatcher — central hook point for sfx.
# Sound files can be plugged in later by populating `streams`; for now this just
# dispatches named events so the rest of the game can call out at every key moment.

const EVENTS = [
	"select",
	"deselect",
	"move",
	"invalid",
	"complete_tube",
	"undo",
	"win",
	"stuck",
	"bomb_tick",
	"bomb_explode",
	"magnet_pull",
	"hourglass_use",
]

var muted: bool = false

# Optional: name -> AudioStream. If set, will be played via a transient player.
var streams: Dictionary = {}

func play(event: String) -> void:
	if muted:
		return
	if not streams.has(event):
		return
	var stream: AudioStream = streams[event]
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func set_muted(value: bool) -> void:
	muted = value
