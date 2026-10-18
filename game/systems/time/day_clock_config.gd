class_name DayClockConfig
extends Resource
## V0.1 day duration and checkpoint interval, independent of real-world time.
@export_range(1.0,3600.0) var day_seconds: float = 1800.0
@export_range(0.1,10.0) var save_interval: float = 0.5
@export_range(1.0,10.0) var announcement_seconds: float = 4.0
