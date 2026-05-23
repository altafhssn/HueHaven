extends Node

# Audio + haptics dispatcher — central hook point for sfx and device vibration.
# Sound files can be plugged in later by populating `streams`; the haptics
# table is consulted on every call() so phones buzz on key game events.

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

# Per-event haptic strength in milliseconds. 0 disables.
const HAPTICS: Dictionary = {
	"select":        15,
	"deselect":      0,
	"move":          12,
	"invalid":       45,    # noticeable thud on bad move
	"complete_tube": 25,
	"undo":          10,
	"win":           120,   # celebratory long buzz
	"stuck":         60,
	"bomb_tick":     0,
	"bomb_explode":  90,
	"magnet_pull":   30,
	"hourglass_use": 20,
}

var muted: bool = false
var haptics_enabled: bool = true

# event_name -> AudioStream. Auto-populated in _ready by scanning the sfx folder.
var streams: Dictionary = {}

const SFX_DIR := "res://assets/audio/sfx/"

func _ready() -> void:
	# Auto-load any file in the sfx folder whose name (without extension)
	# matches one of the registered EVENTS. Supports .wav and .ogg.
	for ev in EVENTS:
		for ext in [".ogg", ".wav"]:
			var path := SFX_DIR + ev + ext
			if ResourceLoader.exists(path):
				var stream := load(path)
				if stream is AudioStream:
					streams[ev] = stream
					break

func play(event: String) -> void:
	# Haptic pulse — fires regardless of mute (audio + vibration are separate concerns)
	if haptics_enabled:
		var dur: int = int(HAPTICS.get(event, 0))
		if dur > 0:
			Input.vibrate_handheld(dur)

	# Audio
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

func set_haptics_enabled(value: bool) -> void:
	haptics_enabled = value
