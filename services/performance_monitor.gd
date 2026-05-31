extends Node
## PerformanceMonitor (autoload) — track FPS & frame time sejak Fase 1 (dok 08 Tahap 1).
## T1.14. Siap kirim ke analytics nanti (T3.4/T8.5).

var _fps_samples: Array[int] = []
var _frame_ms_samples: Array[float] = []
var _sample_interval := 300   # ~5 detik @60fps
var _enabled := true

var last_avg_fps: int = 0
var last_p95_frame_ms: float = 0.0
var device_model: String = ""


func _ready() -> void:
	device_model = OS.get_model_name()
	# Monitor butuh _process untuk sampling — TIDAK di-disable (beda dgn autoload lain).
	set_process(true)


func _process(delta: float) -> void:
	if not _enabled:
		return
	_fps_samples.append(int(Engine.get_frames_per_second()))
	_frame_ms_samples.append(delta * 1000.0)
	if _fps_samples.size() >= _sample_interval:
		_flush_sample()


func _flush_sample() -> void:
	last_avg_fps = _average_int(_fps_samples)
	last_p95_frame_ms = _percentile(_frame_ms_samples, 95)
	if last_avg_fps < 30:
		push_warning("PerformanceMonitor: FPS drop avg=%d p95_frame=%.1fms device=%s" % [
			last_avg_fps, last_p95_frame_ms, device_model
		])
	# TODO(T8.5): kirim ke Analytics: performance_drop {avg_fps, p95_frame_ms, device}
	_fps_samples.clear()
	_frame_ms_samples.clear()


func _average_int(arr: Array[int]) -> int:
	if arr.is_empty():
		return 0
	var sum := 0
	for v in arr:
		sum += v
	return sum / arr.size()


func _percentile(arr: Array[float], pct: int) -> float:
	if arr.is_empty():
		return 0.0
	var sorted := arr.duplicate()
	sorted.sort()
	var idx := int(ceil(pct / 100.0 * sorted.size())) - 1
	idx = clampi(idx, 0, sorted.size() - 1)
	return sorted[idx]
