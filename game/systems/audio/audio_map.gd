class_name AudioEventMap
extends Resource
## Null clips are intentional slots; only listed temporary events get a placeholder.
@export var clips: Dictionary = {}
@export var placeholders: PackedStringArray = []
## Resource-level pitch, also configurable for formal clips.
@export var pitches: Dictionary = {}
@export var environments: Dictionary = {"Region_HD": null, "Region_TY": null, "Region_NSZC": null}
@export var music: Dictionary = {"exploration": null, "combat": null, "large_battle": null, "story": null}
@export_range(0.01, 5.0) var fade_seconds: float = 0.35
