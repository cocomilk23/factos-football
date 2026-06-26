extends Node2D

const SCREEN_SIZE = Vector2(1280.0, 720.0)
const PLAYER_POS = Vector2(640.0, 648.0)
const LAUNCHER_POS = Vector2(640.0, 592.0)
const STRIKE_CENTER = Vector2(640.0, 525.0)
const PERFECT_RADIUS = 34.0
const HIT_RADIUS = 106.0
const DANGER_Y = 578.0
const ENEMY_SPAWN_Y = 132.0
const FEED_DURATION = 1.18
const MAX_CHARGE = 1.25
const MAX_LIVES = 3
const WAVE_COUNT = 15

var rng = RandomNumberGenerator.new()
var font: Font
var tex_field: Texture2D
var tex_player: Texture2D
var tex_launcher: Texture2D
var tex_ball: Texture2D
var tex_curve: Texture2D
var tex_heart: Texture2D
var tex_electric: Texture2D
var tex_target: Texture2D
var tex_fireball: Texture2D
var enemy_textures: Array = []

var elapsed = 0.0
var score = 0
var lives = MAX_LIVES
var combo = 0
var combo_timer = 0.0
var game_over = false

var feed_timer = 0.0
var active_ball = {}
var shot_balls: Array = []
var enemies: Array = []
var particles: Array = []
var float_texts: Array = []

var spawn_timer = 0.0
var next_enemy_id = 1
var shake_time = 0.0
var shake_amount = 0.0

var is_charging = false
var charge = 0.0
var player_anim = 0.0
var last_feedback = ""
var feedback_timer = 0.0


func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	load_assets()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	restart_game()


func load_assets() -> void:
	tex_field = load("res://assets/img/stadium_field.png")
	tex_player = load("res://assets/img/player_volley.png")
	tex_launcher = load("res://assets/img/launcher.png")
	tex_ball = load("res://assets/img/ball_projectile.png")
	tex_curve = load("res://assets/img/curve_slash.png")
	tex_heart = load("res://assets/img/heart_icon.png")
	tex_electric = load("res://assets/img/electric_icon.png")
	tex_target = load("res://assets/img/target_icon.png")
	tex_fireball = load("res://assets/img/fireball_icon.png")
	enemy_textures = [
		load("res://assets/img/enemy_0.png"),
		load("res://assets/img/enemy_1.png"),
		load("res://assets/img/enemy_2.png"),
		load("res://assets/img/enemy_3.png")
	]


func restart_game() -> void:
	elapsed = 0.0
	score = 0
	lives = MAX_LIVES
	combo = 0
	combo_timer = 0.0
	game_over = false
	feed_timer = 0.35
	spawn_timer = 0.75
	next_enemy_id = 1
	active_ball.clear()
	shot_balls.clear()
	enemies.clear()
	particles.clear()
	float_texts.clear()
	charge = 0.0
	is_charging = false
	player_anim = 0.0
	last_feedback = "Time the feed ball"
	feedback_timer = 3.2
	shake_time = 0.0
	shake_amount = 0.0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()
		return

	if game_over:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			restart_game()
		return

	if event.is_action_pressed("shoot"):
		start_charge()
	elif event.is_action_released("shoot"):
		release_shot()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_charge()
		else:
			release_shot()


func start_charge() -> void:
	if is_charging:
		return
	is_charging = true
	charge = 0.0
	player_anim = 0.25


func release_shot() -> void:
	if not is_charging:
		return

	is_charging = false
	var released_charge = charge
	charge = 0.0

	if active_ball.is_empty():
		register_miss("No ball")
		return

	var quality = get_timing_quality(active_ball)
	if quality <= 0.05:
		var text = "Too Early"
		if float(active_ball.get("t", 0.0)) > 1.02:
			text = "Too Late"
		register_miss(text)
		active_ball.clear()
		feed_timer = 0.55
		return

	kick_active_ball(released_charge, quality)


func _process(delta: float) -> void:
	if game_over:
		update_effects(delta)
		queue_redraw()
		return

	elapsed += delta
	if is_charging:
		charge = min(charge + delta, MAX_CHARGE)
	player_anim = max(player_anim - delta, 0.0)
	feedback_timer = max(feedback_timer - delta, 0.0)
	shake_time = max(shake_time - delta, 0.0)
	combo_timer = max(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo = 0

	update_feed(delta)
	update_enemies(delta)
	update_shot_balls(delta)
	update_effects(delta)
	queue_redraw()


func update_feed(delta: float) -> void:
	if active_ball.is_empty():
		feed_timer -= delta
		if feed_timer <= 0.0:
			spawn_feed_ball()
		return

	active_ball["t"] = float(active_ball["t"]) + delta / FEED_DURATION
	var t = float(active_ball["t"])
	var side = float(active_ball["side"])
	var end_pos = STRIKE_CENTER + Vector2(side * 24.0, 0.0)

	if t <= 1.0:
		var a = LAUNCHER_POS
		var b = LAUNCHER_POS + Vector2(side * 76.0, -156.0)
		var c = end_pos
		active_ball["pos"] = quadratic_bezier(a, b, c, t)
	else:
		var drift = t - 1.0
		active_ball["pos"] = end_pos + Vector2(side * 92.0, 158.0) * drift

	if t > 1.42:
		active_ball.clear()
		feed_timer = max(0.42, 1.08 - elapsed * 0.006 + rng.randf_range(-0.08, 0.12))
		set_feedback("Missed feed", Color(1.0, 0.72, 0.35))
		combo = 0


func spawn_feed_ball() -> void:
	var side_options = [-1.0, -0.55, 0.0, 0.55, 1.0]
	var side = side_options[rng.randi_range(0, side_options.size() - 1)]
	active_ball = {
		"t": 0.0,
		"side": side,
		"pos": LAUNCHER_POS,
		"spin": rng.randf_range(0.0, TAU)
	}


func kick_active_ball(released_charge: float, quality: float) -> void:
	var power = clamp(released_charge / MAX_CHARGE, 0.12, 1.0)
	var mouse = get_global_mouse_position()
	var aim_x = clamp((mouse.x - SCREEN_SIZE.x * 0.5) / (SCREEN_SIZE.x * 0.5), -1.0, 1.0)
	var direction = Vector2(aim_x * 0.78, -1.0).normalized()

	var timing_factor = lerp(0.74, 1.22, quality)
	var speed = lerp(410.0, 900.0, power) * timing_factor
	if quality < 0.45:
		direction = direction.rotated(rng.randf_range(-0.22, 0.22))
		speed *= 0.78

	var curve_peak = 1.0 - clamp(abs(power - 0.55) / 0.55, 0.0, 1.0) * 0.55
	var curve_accel = aim_x * lerp(180.0, 560.0, curve_peak) * lerp(0.72, 1.08, quality)
	var ball = {
		"pos": active_ball["pos"],
		"vel": direction * speed,
		"accel": Vector2(curve_accel, 0.0),
		"life": 3.6,
		"radius": 14.0,
		"trail": [active_ball["pos"]],
		"spin": float(active_ball.get("spin", 0.0)),
		"hits": 0
	}
	shot_balls.append(ball)

	if quality >= 0.82:
		set_feedback("Perfect Shot!", Color(0.35, 0.94, 1.0))
		spawn_burst(Vector2(active_ball["pos"]), Color(0.35, 0.94, 1.0), 14)
	elif quality >= 0.45:
		set_feedback("Good Volley", Color(0.78, 1.0, 0.45))
	else:
		set_feedback("Scrappy Hit", Color(1.0, 0.75, 0.35))

	active_ball.clear()
	feed_timer = max(0.34, 1.0 - elapsed * 0.006 + rng.randf_range(-0.1, 0.12))
	player_anim = 0.34


func register_miss(text: String) -> void:
	set_feedback(text, Color(1.0, 0.38, 0.32))
	combo = 0
	shake(0.08, 3.0)
	if not active_ball.is_empty():
		spawn_burst(Vector2(active_ball["pos"]), Color(1.0, 0.45, 0.28), 8)


func get_timing_quality(ball: Dictionary) -> float:
	var pos = Vector2(ball["pos"])
	var dist = pos.distance_to(STRIKE_CENTER)
	if dist > HIT_RADIUS:
		return 0.0
	if dist <= PERFECT_RADIUS:
		return 1.0
	var ratio = 1.0 - ((dist - PERFECT_RADIUS) / (HIT_RADIUS - PERFECT_RADIUS))
	return clamp(0.3 + ratio * 0.65, 0.0, 1.0)


func update_enemies(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var burst_count = 1
		if elapsed > 24.0 and rng.randf() < 0.28:
			burst_count = 2
		if elapsed > 50.0 and rng.randf() < 0.18:
			burst_count = 3
		for i in range(burst_count):
			spawn_enemy(i, burst_count)
		var interval = max(0.46, 1.42 - elapsed * 0.014)
		spawn_timer = interval + rng.randf_range(-0.16, 0.14)

	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		var pos = Vector2(enemy["pos"])
		var speed = float(enemy["speed"]) + elapsed * 0.58
		pos.y += speed * delta
		pos.x += sin(elapsed * 1.5 + float(enemy["phase"])) * 18.0 * delta
		enemy["pos"] = pos
		enemy["wobble"] = float(enemy["wobble"]) + delta
		enemies[i] = enemy

		if pos.y >= DANGER_Y:
			enemies.remove_at(i)
			lives -= 1
			combo = 0
			set_feedback("Defender broke through!", Color(1.0, 0.34, 0.25))
			spawn_burst(pos, Color(1.0, 0.32, 0.23), 18)
			shake(0.22, 9.0)
			if lives <= 0:
				game_over = true
				set_feedback("Game Over", Color(1.0, 0.28, 0.24))


func spawn_enemy(offset_index: int, burst_count: int) -> void:
	var base_x = rng.randf_range(96.0, SCREEN_SIZE.x - 96.0)
	if burst_count > 1:
		base_x += (float(offset_index) - (burst_count - 1.0) * 0.5) * 96.0
	var enemy = {
		"id": next_enemy_id,
		"pos": Vector2(clamp(base_x, 80.0, SCREEN_SIZE.x - 80.0), ENEMY_SPAWN_Y + offset_index * 34.0),
		"speed": rng.randf_range(48.0, 70.0) + min(elapsed * 0.65, 52.0),
		"radius": rng.randf_range(23.0, 29.0),
		"phase": rng.randf_range(0.0, TAU),
		"wobble": 0.0
	}
	enemies.append(enemy)
	next_enemy_id += 1


func update_shot_balls(delta: float) -> void:
	for i in range(shot_balls.size() - 1, -1, -1):
		var ball = shot_balls[i]
		var pos = Vector2(ball["pos"])
		var vel = Vector2(ball["vel"])
		var accel = Vector2(ball["accel"])
		vel += accel * delta
		pos += vel * delta
		vel *= pow(0.992, delta * 60.0)
		ball["pos"] = pos
		ball["vel"] = vel
		ball["spin"] = float(ball["spin"]) + vel.length() * delta * 0.045
		ball["life"] = float(ball["life"]) - delta

		var trail: Array = ball["trail"]
		trail.append(pos)
		while trail.size() > 26:
			trail.pop_front()
		ball["trail"] = trail

		check_ball_enemy_hits(ball)

		if float(ball["life"]) <= 0.0 or pos.y < -90.0 or pos.x < -170.0 or pos.x > SCREEN_SIZE.x + 170.0:
			shot_balls.remove_at(i)
		else:
			shot_balls[i] = ball


func check_ball_enemy_hits(ball: Dictionary) -> void:
	var pos = Vector2(ball["pos"])
	var radius = float(ball["radius"])
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		var enemy_pos = Vector2(enemy["pos"])
		if pos.distance_to(enemy_pos) <= radius + float(enemy["radius"]):
			enemies.remove_at(i)
			ball["hits"] = int(ball["hits"]) + 1
			ball["vel"] = Vector2(ball["vel"]) * 0.88
			ball["life"] = min(float(ball["life"]), 2.4)
			combo += 1
			combo_timer = 2.4
			var gained = 100 + max(combo - 1, 0) * 35
			score += gained
			float_texts.append({
				"pos": enemy_pos + Vector2(-28.0, -24.0),
				"text": "+" + str(gained),
				"ttl": 0.9,
				"color": Color(1.0, 0.92, 0.3)
			})
			spawn_burst(enemy_pos, Color(1.0, 0.86, 0.28), 18)
			shake(0.06, 3.8)
			if int(ball["hits"]) >= 3:
				ball["life"] = 0.0
			return


func update_effects(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
		p["vel"] = Vector2(p["vel"]) * pow(0.82, delta * 12.0)
		p["ttl"] = float(p["ttl"]) - delta
		if float(p["ttl"]) <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = p

	for i in range(float_texts.size() - 1, -1, -1):
		var t = float_texts[i]
		t["pos"] = Vector2(t["pos"]) + Vector2(0.0, -38.0) * delta
		t["ttl"] = float(t["ttl"]) - delta
		if float(t["ttl"]) <= 0.0:
			float_texts.remove_at(i)
		else:
			float_texts[i] = t


func spawn_burst(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(70.0, 230.0)
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"ttl": rng.randf_range(0.28, 0.62),
			"size": rng.randf_range(2.0, 5.0),
			"color": color
		})


func set_feedback(text: String, color: Color) -> void:
	last_feedback = text
	feedback_timer = 1.25
	float_texts.append({
		"pos": STRIKE_CENTER + Vector2(-80.0, -84.0),
		"text": text,
		"ttl": 0.9,
		"color": color
	})


func shake(duration: float, amount: float) -> void:
	shake_time = max(shake_time, duration)
	shake_amount = max(shake_amount, amount)


func quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab = a.lerp(b, t)
	var bc = b.lerp(c, t)
	return ab.lerp(bc, t)


func draw_tex_center(tex: Texture2D, center: Vector2, size: Vector2, color: Color = Color.WHITE) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(center - size * 0.5, size), false, color)


func draw_text_shadow(pos: Vector2, text: String, size: int, color: Color, shadow: Color = Color(0, 0, 0, 0.8)) -> void:
	draw_string(font, pos + Vector2(3.0, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, shadow)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func draw_panel(rect: Rect2, fill: Color = Color(0.0, 0.0, 0.0, 0.72), border: Color = Color(1.0, 1.0, 1.0, 0.18)) -> void:
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 3.0)


func draw_ellipse_shadow(center: Vector2, size: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(32):
		var a = float(i) / 32.0 * TAU
		points.append(center + Vector2(cos(a) * size.x * 0.5, sin(a) * size.y * 0.5))
	draw_colored_polygon(points, color)


func _draw() -> void:
	var offset = Vector2.ZERO
	if shake_time > 0.0:
		offset = Vector2(rng.randf_range(-shake_amount, shake_amount), rng.randf_range(-shake_amount, shake_amount))
	draw_set_transform(offset)
	draw_field()
	draw_strike_zone()
	draw_launcher()
	draw_player()
	draw_enemies()
	draw_balls()
	draw_effects_layer()
	draw_ui()
	draw_set_transform(Vector2.ZERO)


func draw_field() -> void:
	if tex_field != null:
		draw_texture_rect(tex_field, Rect2(Vector2.ZERO, SCREEN_SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.05, 0.38, 0.19))
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_SIZE.x, 96.0)), Color(0.0, 0.0, 0.0, 0.18), true)
	draw_rect(Rect2(Vector2(0.0, 575.0), Vector2(SCREEN_SIZE.x, 145.0)), Color(0.0, 0.0, 0.0, 0.08), true)
	for i in range(0, 28):
		var x = float(i) * 48.0
		draw_line(Vector2(x, DANGER_Y), Vector2(x + 24.0, DANGER_Y), Color(1.0, 0.22, 0.16, 0.55), 3.0)


func draw_strike_zone() -> void:
	var quality = 0.0
	if not active_ball.is_empty():
		quality = get_timing_quality(active_ball)
	var outer_color = Color(0.25, 0.85, 1.0, 0.34 if quality > 0.0 else 0.18)
	var perfect_color = Color(0.95, 1.0, 0.25, 0.42 if quality >= 0.82 else 0.2)
	draw_arc(STRIKE_CENTER, HIT_RADIUS, 0.0, TAU, 96, outer_color, 4.0, true)
	draw_arc(STRIKE_CENTER, PERFECT_RADIUS, 0.0, TAU, 64, perfect_color, 4.0, true)
	draw_line(STRIKE_CENTER + Vector2(-16.0, 0.0), STRIKE_CENTER + Vector2(16.0, 0.0), Color(1.0, 1.0, 1.0, 0.35), 2.0)
	draw_line(STRIKE_CENTER + Vector2(0.0, -16.0), STRIKE_CENTER + Vector2(0.0, 16.0), Color(1.0, 1.0, 1.0, 0.35), 2.0)


func draw_launcher() -> void:
	var center = Vector2(720.0, 634.0)
	draw_ellipse_shadow(center + Vector2(0.0, 62.0), Vector2(130.0, 28.0), Color(0, 0, 0, 0.35))
	if tex_launcher != null:
		draw_tex_center(tex_launcher, center, Vector2(160.0, 150.0))
	else:
		draw_rect(Rect2(center - Vector2(65.0, 40.0), Vector2(130.0, 80.0)), Color(0.15, 0.19, 0.24), true)
	draw_circle(center + Vector2(0.0, 18.0), 10.0 + sin(elapsed * 8.0) * 2.0, Color(1.0, 0.58, 0.08, 0.7))


func draw_player() -> void:
	var charge_pose = clamp(charge / MAX_CHARGE, 0.0, 1.0) if is_charging else 0.0
	var kick_pose = player_anim / 0.34
	var center = Vector2(505.0, 582.0) + Vector2(-charge_pose * 7.0 + kick_pose * 12.0, -kick_pose * 8.0)
	draw_ellipse_shadow(center + Vector2(16.0, 130.0), Vector2(128.0, 28.0), Color(0, 0, 0, 0.34))
	if tex_player != null:
		draw_tex_center(tex_player, center, Vector2(210.0, 292.0))
	else:
		draw_circle(PLAYER_POS + Vector2(0.0, -116.0), 22.0, Color(0.95, 0.72, 0.48))


func draw_enemies() -> void:
	for enemy in enemies:
		var pos = Vector2(enemy["pos"])
		var r = float(enemy["radius"])
		var wobble = sin(float(enemy["wobble"]) * 7.0) * 3.0
		var tex = enemy_textures[int(enemy["id"]) % enemy_textures.size()] if enemy_textures.size() > 0 else null
		var visual_size = Vector2(r * 3.3, r * 3.55)
		draw_ellipse_shadow(pos + Vector2(0.0, r * 1.28), Vector2(r * 2.1, r * 0.44), Color(0, 0, 0, 0.25))
		if tex != null:
			draw_tex_center(tex, pos + Vector2(0.0, wobble), visual_size)
		else:
			draw_circle(pos + Vector2(0.0, wobble), r, Color(0.78, 0.18, 0.22))
		var bar_w = r * 2.2
		var bar_pos = pos + Vector2(-bar_w * 0.5, -r * 2.0 + wobble)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, 6.0)), Color(0.05, 0.05, 0.06, 0.9), true)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * 0.78, 6.0)), Color(1.0, 0.18, 0.15, 0.95), true)


func draw_balls() -> void:
	if not active_ball.is_empty():
		draw_football(Vector2(active_ball["pos"]), 14.0, float(active_ball.get("spin", 0.0)), Color(1.0, 1.0, 1.0))

	for ball in shot_balls:
		var trail: Array = ball["trail"]
		if trail.size() > 1:
			var points = PackedVector2Array()
			for p in trail:
				points.append(Vector2(p))
			draw_polyline(points, Color(1.0, 0.92, 0.2, 0.6), 9.0, true)
			draw_polyline(points, Color(1.0, 1.0, 0.75, 0.9), 3.0, true)
		draw_football(Vector2(ball["pos"]), float(ball["radius"]), float(ball["spin"]), Color(1.0, 1.0, 1.0))


func draw_football(pos: Vector2, radius: float, spin: float, tint: Color) -> void:
	if tex_ball != null:
		draw_tex_center(tex_ball, pos, Vector2(radius * 2.65, radius * 2.65), tint)
	else:
		draw_circle(pos, radius, tint)
		draw_circle(pos, radius, Color(0.04, 0.05, 0.06), false, 2.0)
		for i in range(5):
			var a = spin + float(i) * TAU / 5.0
			var p = pos + Vector2(cos(a), sin(a)) * radius * 0.45
			draw_circle(p, radius * 0.18, Color(0.04, 0.05, 0.06))
		draw_arc(pos, radius * 0.68, spin, spin + PI, 20, Color(0.04, 0.05, 0.06, 0.75), 2.0, true)


func draw_effects_layer() -> void:
	for p in particles:
		var c = Color(p["color"])
		c.a = clamp(float(p["ttl"]) * 2.2, 0.0, 1.0)
		draw_circle(Vector2(p["pos"]), float(p["size"]), c)

	for t in float_texts:
		var c = Color(t["color"])
		c.a = clamp(float(t["ttl"]) * 1.5, 0.0, 1.0)
		draw_string(font, Vector2(t["pos"]), str(t["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, c)


func draw_ui() -> void:
	draw_panel(Rect2(Vector2(18.0, 16.0), Vector2(230.0, 90.0)), Color(0, 0, 0, 0.74))
	draw_text_shadow(Vector2(34.0, 42.0), "SCORE", 22, Color.WHITE)
	draw_text_shadow(Vector2(34.0, 92.0), str(score), 46, Color(1.0, 0.88, 0.1))

	var wave = min(WAVE_COUNT, max(1, int(elapsed / 22.0) + 1))
	var wave_progress = clamp(float(wave) / float(WAVE_COUNT), 0.0, 1.0)
	draw_panel(Rect2(Vector2(494.0, 18.0), Vector2(292.0, 40.0)), Color(0, 0, 0, 0.72))
	draw_text_shadow(Vector2(572.0, 48.0), "WAVE " + str(wave) + " / " + str(WAVE_COUNT), 22, Color.WHITE)
	var wave_bar = Rect2(Vector2(470.0, 72.0), Vector2(340.0, 20.0))
	draw_rect(wave_bar, Color(0.03, 0.04, 0.05, 0.9), true)
	draw_rect(Rect2(wave_bar.position, Vector2(wave_bar.size.x * wave_progress, wave_bar.size.y)), Color(0.05, 0.86, 0.22, 0.95), true)
	draw_rect(wave_bar, Color(1, 1, 1, 0.35), false, 2.0)
	draw_football(wave_bar.position + Vector2(wave_bar.size.x * wave_progress, 10.0), 15.0, elapsed * 4.0, Color.WHITE)

	draw_panel(Rect2(Vector2(1030.0, 16.0), Vector2(224.0, 86.0)), Color(0, 0, 0, 0.74))
	draw_text_shadow(Vector2(1050.0, 42.0), "LIVES", 22, Color.WHITE)
	for i in range(MAX_LIVES):
		var c = Color.WHITE if i < lives else Color(0.18, 0.18, 0.18, 0.55)
		draw_tex_center(tex_heart, Vector2(1072.0 + i * 58.0, 75.0), Vector2(46.0, 46.0), c)

	var power = clamp(charge / MAX_CHARGE, 0.0, 1.0)
	draw_text_shadow(Vector2(28.0, 663.0), "POWER", 28, Color.WHITE)
	var p_rect = Rect2(Vector2(30.0, 675.0), Vector2(295.0, 24.0))
	draw_rect(p_rect, Color(0.02, 0.03, 0.04, 0.9), true)
	draw_rect(Rect2(p_rect.position + Vector2(4.0, 4.0), Vector2((p_rect.size.x - 8.0) * power, p_rect.size.y - 8.0)), Color(0.15 + power * 0.85, 0.9 - power * 0.25, 0.15, 0.95), true)
	draw_rect(p_rect, Color(1, 1, 1, 0.45), false, 3.0)
	draw_panel(Rect2(Vector2(342.0, 662.0), Vector2(44.0, 44.0)), Color(0.08, 0.08, 0.09, 0.9))
	draw_text_shadow(Vector2(357.0, 694.0), "E", 25, Color.WHITE)

	draw_panel(Rect2(Vector2(1010.0, 648.0), Vector2(70.0, 62.0)), Color(0.02, 0.03, 0.05, 0.72))
	draw_panel(Rect2(Vector2(1092.0, 648.0), Vector2(70.0, 62.0)), Color(0.02, 0.03, 0.05, 0.72))
	draw_panel(Rect2(Vector2(1174.0, 648.0), Vector2(70.0, 62.0)), Color(0.02, 0.03, 0.05, 0.72))
	draw_tex_center(tex_electric, Vector2(1045.0, 679.0), Vector2(52.0, 52.0))
	draw_tex_center(tex_target, Vector2(1127.0, 679.0), Vector2(52.0, 52.0))
	draw_tex_center(tex_fireball, Vector2(1209.0, 679.0), Vector2(52.0, 52.0))

	var mouse = get_global_mouse_position()
	var aim_x = clamp((mouse.x - SCREEN_SIZE.x * 0.5) / (SCREEN_SIZE.x * 0.5), -1.0, 1.0)
	var aim_end = STRIKE_CENTER + Vector2(aim_x * 260.0, -235.0)
	draw_line(STRIKE_CENTER, aim_end, Color(0.7, 0.95, 1.0, 0.32), 3.0)
	draw_circle(aim_end, 7.0, Color(0.7, 0.95, 1.0, 0.72))

	if feedback_timer > 0.0:
		var fb_color = Color(1.0, 0.9, 0.1, min(feedback_timer, 1.0))
		draw_text_shadow(Vector2(932.0, 180.0), last_feedback, 30, fb_color)

	if game_over:
		draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.0, 0.0, 0.0, 0.62), true)
		draw_string(font, Vector2(500.0, 310.0), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color(1.0, 0.28, 0.24))
		draw_string(font, Vector2(495.0, 365.0), "Final Score: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		draw_string(font, Vector2(420.0, 418.0), "Press R or click to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.8, 0.94, 1.0))

