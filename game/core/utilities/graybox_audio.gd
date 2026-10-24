class_name GrayboxAudio
extends RefCounted
## Compatibility generator; formal playback lives in GameAudio.
static func make_warning() -> AudioStreamWAV:
	return PlaceholderTone.make(330.0)
