class_name PlaceholderTone
extends RefCounted
static func make(frequency: float = 440.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count: int = 2205
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i: int in range(count):
		var envelope: float = minf(float(i) / 40.0, 1.0) * (1.0 - float(i) / count)
		bytes.encode_s16(i * 2, int(sin(TAU * frequency * i / stream.mix_rate) * envelope * 16000))
	stream.data = bytes
	return stream
