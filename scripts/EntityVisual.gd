extends Node2D

# -1 = Hidden, 0 = Peeking, 1 = Enraged (Bounce Back), 2 = Purged, 3 = Calm (Secret Ending)
var state: int = -1
var blink_timer: float = 0.0

func _process(delta: float) -> void:
	blink_timer += delta
	queue_redraw()

func _draw() -> void:
	if state == -1 or state == 2:
		return
		
	var center: Vector2 = get_viewport_rect().size / 2.0
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	if state == 0:
		var pulse: float = 0.18 + sin(blink_timer * 2.0) * 0.05
		draw_circle(center + Vector2(0, -60), 115.0, Color(0.08, 0.08, 0.12, pulse))
		_draw_tracking_eye(center + Vector2(-38, -70), 14.0, mouse_pos, Color(0.75, 0.75, 0.85, 0.6), Color.BLACK)
		_draw_tracking_eye(center + Vector2(38, -70), 14.0, mouse_pos, Color(0.75, 0.75, 0.85, 0.6), Color.BLACK)
		
	elif state == 1:
		var shake := Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		var head_pos: Vector2 = center + Vector2(0, -30) + shake
		
		draw_circle(head_pos, 200.0, Color(0.02, 0.0, 0.0, 0.88))
		for i in range(12):
			var line_y: float = head_pos.y + randf_range(-190.0, 190.0)
			var line_w: float = randf_range(80.0, 320.0)
			draw_line(
				Vector2(head_pos.x - line_w, line_y),
				Vector2(head_pos.x + line_w, line_y),
				Color(1.0, 0.1, 0.1, 0.35),
				randf_range(1.0, 4.0)
			)
		
		_draw_tracking_eye(head_pos + Vector2(-75, -55), 34.0, mouse_pos, Color(1.0, 0.9, 0.9), Color(0.9, 0.0, 0.0))
		_draw_tracking_eye(head_pos + Vector2(75, -55), 34.0, mouse_pos, Color(1.0, 0.9, 0.9), Color(0.9, 0.0, 0.0))
		
		var mouth_points := PackedVector2Array()
		for j in range(11):
			var mx: float = head_pos.x - 100.0 + (j * 20.0)
			var my: float = head_pos.y + 70.0 + (18.0 if j % 2 == 0 else -18.0) + randf_range(-6.0, 6.0)
			mouth_points.append(Vector2(mx, my))
		draw_polyline(mouth_points, Color(1.0, 0.15, 0.15, 0.9), 4.0)
		
	elif state == 3:
		# Secret Ending: Wajah bayangan tenang tanpa glitch
		var head_pos: Vector2 = center + Vector2(0, -60)
		draw_circle(head_pos, 130.0, Color(0.1, 0.14, 0.2, 0.45))
		_draw_tracking_eye(head_pos + Vector2(-42, -15), 18.0, mouse_pos, Color(0.85, 0.95, 1.0, 0.85), Color(0.2, 0.5, 0.8))
		_draw_tracking_eye(head_pos + Vector2(42, -15), 18.0, mouse_pos, Color(0.85, 0.95, 1.0, 0.85), Color(0.2, 0.5, 0.8))

func _draw_tracking_eye(eye_pos: Vector2, radius: float, target: Vector2, sclera_col: Color, pupil_col: Color) -> void:
	draw_circle(eye_pos, radius, sclera_col)
	var dir: Vector2 = (target - eye_pos).normalized()
	var dist: float = min((target - eye_pos).length() * 0.05, radius * 0.55)
	draw_circle(eye_pos + dir * dist, radius * 0.42, pupil_col)
