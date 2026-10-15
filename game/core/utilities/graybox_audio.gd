class_name GrayboxAudio
extends RefCounted
## Text-generated placeholder audio, no external asset or license dependency.
static func make_warning() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count: int = 2205
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	for i: int in range(count):
		var t: float = float(i) / 22050.0
		var envelope: float = minf(float(i) / 40.0, 1.0) * (1.0 - float(i) / float(count))
		bytes.encode_s16(i * 2, int(sin(TAU * 330.0 * t) * envelope * 16000))
	stream.data = bytes
	return stream
