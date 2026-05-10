extends Control

@export var template_id := "triangle":
	set(value):
		template_id = value
		queue_redraw()

@export var accent_color := Color(0.50, 0.78, 1.0, 1.0):
	set(value):
		accent_color = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _draw() -> void:
	var draw_rect := Rect2(Vector2.ZERO, size)
	if draw_rect.size.x <= 4.0 or draw_rect.size.y <= 4.0:
		return

	var center := draw_rect.get_center()
	var outer_radius := minf(draw_rect.size.x, draw_rect.size.y) * 0.34
	var inner_radius := outer_radius * 0.56
	var line_color := accent_color
	var glow_color := Color(accent_color.r, accent_color.g, accent_color.b, 0.18)
	var node_color := Color(0.94, 0.90, 0.76, 0.92)
	var background_line := Color(1.0, 1.0, 1.0, 0.05)

	draw_circle(center, outer_radius * 1.12, glow_color)
	draw_arc(center, outer_radius, 0.0, TAU, 64, line_color, 2.0, true)
	draw_arc(center, inner_radius, 0.0, TAU, 64, Color(line_color.r, line_color.g, line_color.b, 0.72), 1.5, true)

	var points := _build_template_points(center, outer_radius)
	for point in points:
		draw_circle(point, 3.4, node_color)
		draw_line(center, point, Color(line_color.r, line_color.g, line_color.b, 0.42), 1.2, true)

	if template_id != "line" and template_id != "fork":
		for index in range(points.size()):
			var next_index := (index + 1) % points.size()
			draw_line(points[index], points[next_index], line_color, 1.6, true)

	if template_id == "line":
		if points.size() >= 3:
			draw_line(points[0], points[1], line_color, 1.8, true)
			draw_line(points[1], points[2], line_color, 1.8, true)
	elif template_id == "ring" or template_id == "hexagon":
		draw_arc(center, outer_radius * 0.28, 0.0, TAU, 48, node_color, 1.6, true)
	elif template_id == "square":
		if points.size() >= 4:
			draw_line(points[0], points[2], background_line, 1.0, true)
			draw_line(points[1], points[3], background_line, 1.0, true)
	elif template_id == "star" or template_id == "wheel":
		for point in points:
			draw_line(center, point, Color(line_color.r, line_color.g, line_color.b, 0.62), 1.1, true)
	elif template_id == "fork":
		if points.size() >= 4:
			draw_line(points[0], points[1], line_color, 1.6, true)
			draw_line(points[0], points[2], line_color, 1.6, true)
			draw_line(points[0], points[3], line_color, 1.6, true)
	elif template_id == "triangle":
		draw_arc(center, outer_radius * 0.18, 0.0, TAU, 32, background_line, 1.0, true)
	else:
		draw_line(
			center + Vector2(-outer_radius * 0.75, 0),
			center + Vector2(outer_radius * 0.75, 0),
			background_line,
			1.0,
			true
		)

func _build_template_points(center: Vector2, radius: float) -> Array[Vector2]:
	match template_id:
		"line":
			return [
				center + Vector2(-radius, 0),
				center,
				center + Vector2(radius, 0),
			]
		"square":
			return [
				center + Vector2(-radius, -radius * 0.76),
				center + Vector2(radius, -radius * 0.76),
				center + Vector2(radius, radius * 0.76),
				center + Vector2(-radius, radius * 0.76),
			]
		"ring":
			var ring_points: Array[Vector2] = []
			for index in range(6):
				var angle := (TAU / 6.0) * index - PI * 0.5
				ring_points.append(center + Vector2(cos(angle), sin(angle)) * radius)
			return ring_points
		"hexagon":
			var hex_points: Array[Vector2] = []
			for index in range(6):
				var hex_angle := (TAU / 6.0) * index - PI * 0.5
				hex_points.append(center + Vector2(cos(hex_angle), sin(hex_angle)) * radius)
			return hex_points
		"star":
			return [
				center + Vector2(0, -radius),
				center + Vector2(radius, 0),
				center + Vector2(0, radius),
				center + Vector2(-radius, 0),
			]
		"fork":
			return [
				center + Vector2(0, -radius),
				center + Vector2(-radius * 0.86, radius * 0.56),
				center + Vector2(0, radius * 0.24),
				center + Vector2(radius * 0.86, radius * 0.56),
			]
		"wheel":
			var wheel_points: Array[Vector2] = []
			for wheel_index in range(6):
				var wheel_angle := (TAU / 6.0) * wheel_index - PI * 0.5
				wheel_points.append(center + Vector2(cos(wheel_angle), sin(wheel_angle)) * radius)
			return wheel_points
		_:
			return [
				center + Vector2(0, -radius),
				center + Vector2(radius * 0.92, radius * 0.68),
				center + Vector2(-radius * 0.92, radius * 0.68),
			]
