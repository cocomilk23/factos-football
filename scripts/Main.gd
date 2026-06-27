extends Node2D

const SCREEN_SIZE = Vector2(720.0, 1280.0)
const PLAYER_DRAW_CENTER = Vector2(250.0, 1080.0)
const LAUNCHER_DRAW_CENTER = Vector2(445.0, 1136.0)
const LAUNCHER_MOUTH = Vector2(445.0, 1082.0)
const STRIKE_CENTER = Vector2(356.0, 956.0)
const PERFECT_RADIUS = 32.0
const HIT_RADIUS = 104.0
const DANGER_Y = 1084.0
const ENEMY_SPAWN_Y = 250.0
const FEED_DURATION = 1.12
const MAX_CHARGE = 1.25
const MAX_LIVES = 3
const WAVE_COUNT = 15
const PLAYER_KICK_TIME = 0.52
const MAX_FOCUS = 100.0

var rng = RandomNumberGenerator.new()
var font: Font
var tex_field: Texture2D
var tex_launcher: Texture2D
var tex_ball: Texture2D
var tex_curve_ball: Texture2D
var tex_fire_ball: Texture2D
var tex_perfect_impact: Texture2D
var tex_heart: Texture2D
var tex_curve_icon: Texture2D
var tex_pierce_icon: Texture2D
var tex_slow_icon: Texture2D
var enemy_textures: Array = []
var character_defs: Array = []
var character_frames: Dictionary = {}

var game_mode = "select"
var selected_character = 0
var elapsed = 0.0
var score = 0
var lives = MAX_LIVES
var combo = 0
var combo_timer = 0.0
var perfect_streak = 0
var focus = 0.0
var game_over = false

var feed_timer = 0.0
var active_ball = {}
var shot_balls: Array = []
var enemies: Array = []
var particles: Array = []
var impact_fx: Array = []
var float_texts: Array = []
var skill_fx: Array = []

var spawn_timer = 0.0
var next_enemy_id = 1
var shake_time = 0.0
var shake_amount = 0.0

var is_charging = false
var charge = 0.0
var player_anim = 0.0
var kick_flash_timer = 0.0
var last_feedback = ""
var feedback_timer = 0.0


func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	load_assets()
	build_character_defs()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show_character_select()


func load_assets() -> void:
	tex_field = load("res://assets/img/stadium_field.png")
	tex_launcher = load("res://assets/img/launcher.png")
	tex_ball = load("res://assets/img/ball_projectile.png")
	tex_curve_ball = load("res://assets/img/curve_ball.png")
	tex_fire_ball = load("res://assets/img/fireball_projectile.png")
	tex_perfect_impact = load("res://assets/img/perfect_impact.png")
	tex_heart = load("res://assets/img/heart_icon.png")
	tex_curve_icon = load("res://assets/img/curve_icon.png")
	tex_pierce_icon = load("res://assets/img/pierce_icon.png")
	tex_slow_icon = load("res://assets/img/slow_icon.png")
	character_frames = {
		"messi": [
			load("res://assets/img/player_messi_frame_0.png"),
			load("res://assets/img/player_messi_frame_1.png"),
			load("res://assets/img/player_messi_frame_2.png"),
			load("res://assets/img/player_messi_frame_3.png")
		],
		"ronaldo": [
			load("res://assets/img/player_ronaldo_frame_0.png"),
			load("res://assets/img/player_ronaldo_frame_1.png"),
			load("res://assets/img/player_ronaldo_frame_2.png"),
			load("res://assets/img/player_ronaldo_frame_3.png")
		],
		"neymar": [
			load("res://assets/img/player_neymar_frame_0.png"),
			load("res://assets/img/player_neymar_frame_1.png"),
			load("res://assets/img/player_neymar_frame_2.png"),
			load("res://assets/img/player_neymar_frame_3.png")
		]
	}
	enemy_textures = [
		load("res://assets/img/enemy_0.png"),
		load("res://assets/img/enemy_1.png"),
		load("res://assets/img/enemy_2.png"),
		load("res://assets/img/enemy_3.png"),
		load("res://assets/img/enemy_4.png"),
		load("res://assets/img/enemy_5.png")
	]


func build_character_defs() -> void:
	character_defs = [
		{
			"id": "messi",
			"name": "MESSI",
			"role": "Left Foot",
			"skill": "Wowo Drop",
			"power": 0.92,
			"curve": 1.42,
			"timing": 1.18,
			"focus_gain": 1.08,
			"max_focus": 200.0,
			"damage": 1.0,
			"pierce_bonus": 0,
			"preferred_side": -1.0,
			"color": Color(0.42, 0.86, 1.0)
		},
		{
			"id": "ronaldo",
			"name": "RONALDO",
			"role": "Power Drive",
			"skill": "Triple Kick",
			"power": 1.22,
			"curve": 0.84,
			"timing": 0.96,
			"focus_gain": 0.86,
			"max_focus": 100.0,
			"damage": 1.35,
			"pierce_bonus": 1,
			"preferred_side": 1.0,
			"color": Color(1.0, 0.36, 0.28)
		},
		{
			"id": "neymar",
			"name": "NEYMAR",
			"role": "Trick Spin",
			"skill": "Rolling Neymar",
			"power": 1.0,
			"curve": 1.2,
			"timing": 1.05,
			"focus_gain": 1.42,
			"max_focus": 100.0,
			"damage": 1.0,
			"pierce_bonus": 0,
			"preferred_side": 0.0,
			"color": Color(1.0, 0.88, 0.18)
		}
	]

func show_character_select() -> void:
	game_mode = "select"
	game_over = false
	active_ball.clear()
	shot_balls.clear()
	enemies.clear()
	particles.clear()
	impact_fx.clear()
	float_texts.clear()
	skill_fx.clear()
	is_charging = false
	charge = 0.0
	queue_redraw()


func restart_game() -> void:
	game_mode = "play"
	elapsed = 0.0
	score = 0
	lives = MAX_LIVES
	combo = 0
	combo_timer = 0.0
	perfect_streak = 0
	focus = 0.0
	game_over = false
	feed_timer = 0.25
	spawn_timer = 1.2
	next_enemy_id = 1
	active_ball.clear()
	shot_balls.clear()
	enemies.clear()
	particles.clear()
	impact_fx.clear()
	float_texts.clear()
	skill_fx.clear()
	charge = 0.0
	is_charging = false
	player_anim = 0.0
	kick_flash_timer = 0.0
	last_feedback = "Time the feed ball"
	feedback_timer = 2.6
	shake_time = 0.0
	shake_amount = 0.0
	queue_redraw()


func selected_profile() -> Dictionary:
	if character_defs.is_empty():
		return {}
	return character_defs[selected_character]


func focus_capacity() -> float:
	return float(selected_profile().get("max_focus", MAX_FOCUS))


func selected_frames() -> Array:
	var profile = selected_profile()
	var id = str(profile.get("id", "messi"))
	return character_frames.get(id, [])


func _unhandled_input(event: InputEvent) -> void:
	if game_mode == "select":
		handle_select_input(event)
		return

	if event.is_action_pressed("restart"):
		if game_over:
			show_character_select()
		else:
			restart_game()
		return

	if game_over:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			show_character_select()
		return

	if event.is_action_pressed("skill"):
		activate_focus()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		activate_focus()
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


func handle_select_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		selected_character = (selected_character + 1) % character_defs.size()
		queue_redraw()
		return
	if event.is_action_pressed("shoot") or event.is_action_pressed("skill"):
		restart_game()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos = event.position
		for i in range(character_defs.size()):
			if select_card_rect(i).has_point(pos):
				selected_character = i
				queue_redraw()
				return
		if Rect2(Vector2(92.0, 1164.0), Vector2(536.0, 72.0)).has_point(pos):
			restart_game()


func activate_focus() -> void:
	if focus < MAX_FOCUS:
		return
	var profile = selected_profile()
	focus -= MAX_FOCUS
	var id = str(profile.get("id", "messi"))
	if id == "neymar":
		use_neymar_skill()
	elif id == "ronaldo":
		use_ronaldo_skill()
	else:
		use_messi_skill()
	focus = clamp(focus, 0.0, focus_capacity())
	set_feedback(str(profile.get("skill", "SKILL")) + "!", Color(0.35, 0.95, 1.0))
	spawn_burst(STRIKE_CENTER, Color(0.2, 0.95, 1.0), 28)
	shake(0.12, 4.0)


func use_neymar_skill() -> void:
	skill_fx.append({
		"type": "neymar_roll",
		"pos": Vector2(SCREEN_SIZE.x * 0.5, 1110.0),
		"ttl": 1.45,
		"age": 0.0,
		"hit_ids": []
	})


func use_ronaldo_skill() -> void:
	var centers = [Vector2(205.0, 515.0), Vector2(520.0, 650.0), Vector2(350.0, 805.0)]
	for i in range(centers.size()):
		skill_fx.append({
			"type": "ronaldo_kick",
			"pos": centers[i],
			"ttl": 1.05 + float(i) * 0.12,
			"age": -float(i) * 0.18,
			"radius": 148.0,
			"done": false
		})


func use_messi_skill() -> void:
	var target = get_global_mouse_position()
	target.x = clamp(target.x, 116.0, SCREEN_SIZE.x - 116.0)
	target.y = clamp(target.y, 320.0, 880.0)
	skill_fx.append({
		"type": "messi_wowo",
		"pos": target,
		"ttl": 1.12,
		"age": 0.0,
		"radius": 172.0,
		"done": false
	})


func start_charge() -> void:
	if is_charging:
		return
	is_charging = true
	charge = 0.0


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
		feed_timer = 0.5
		return

	kick_active_ball(released_charge, quality)


func _process(delta: float) -> void:
	if game_mode == "select":
		queue_redraw()
		return
	if game_over:
		update_effects(delta)
		queue_redraw()
		return

	elapsed += delta
	if is_charging:
		charge = min(charge + delta, MAX_CHARGE)
	player_anim = max(player_anim - delta, 0.0)
	kick_flash_timer = max(kick_flash_timer - delta, 0.0)
	feedback_timer = max(feedback_timer - delta, 0.0)
	shake_time = max(shake_time - delta, 0.0)
	combo_timer = max(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo = 0

	update_feed(delta)
	update_enemies(delta)
	update_skill_fx(delta)
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
	active_ball["spin"] = float(active_ball.get("spin", 0.0)) + delta * 10.0
	var t = float(active_ball["t"])
	var side = float(active_ball["side"])
	var end_pos = STRIKE_CENTER + Vector2(side * 22.0, 0.0)

	if t <= 1.0:
		var a = LAUNCHER_MOUTH
		var b = LAUNCHER_MOUTH + Vector2(side * 68.0, -146.0)
		active_ball["pos"] = quadratic_bezier(a, b, end_pos, t)
	else:
		var drift = t - 1.0
		active_ball["pos"] = end_pos + Vector2(side * 70.0, 145.0) * drift

	if t > 1.42:
		active_ball.clear()
		feed_timer = max(0.4, 1.0 - elapsed * 0.004 + rng.randf_range(-0.08, 0.12))
		set_feedback("Missed feed", Color(1.0, 0.72, 0.35))
		combo = 0
		perfect_streak = 0


func spawn_feed_ball() -> void:
	var side_options = [-1.0, -0.62, -0.24, 0.0, 0.24, 0.62, 1.0]
	var side = side_options[rng.randi_range(0, side_options.size() - 1)]
	active_ball = {
		"t": 0.0,
		"side": side,
		"pos": LAUNCHER_MOUTH,
		"spin": rng.randf_range(0.0, TAU)
	}


func kick_active_ball(released_charge: float, quality: float) -> void:
	var profile = selected_profile()
	var power = clamp(released_charge / MAX_CHARGE, 0.12, 1.0)
	var aim_x = get_aim_x()
	var direction = get_aim_direction()
	var timing_factor = lerp(0.74, 1.25, quality)
	var speed = lerp(500.0, 1050.0, power) * timing_factor * float(profile.get("power", 1.0))
	if quality < 0.45:
		direction = direction.rotated(rng.randf_range(-0.22, 0.22))
		speed *= 0.78

	var curve_peak = 1.0 - clamp(abs(power - 0.58) / 0.58, 0.0, 1.0) * 0.5
	var curve_mult = float(profile.get("curve", 1.0))
	var preferred = float(profile.get("preferred_side", 0.0))
	if preferred != 0.0 and sign(aim_x) == sign(preferred):
		curve_mult *= 1.12
	var curve_accel = aim_x * lerp(520.0, 1500.0, curve_peak) * lerp(0.82, 1.22, quality) * curve_mult
	if abs(aim_x) < 0.08:
		curve_accel *= 0.25

	var is_perfect = quality >= 0.82
	var kind = "normal"
	if str(profile.get("id", "")) == "ronaldo" and power >= 0.86:
		kind = "fire"
	elif abs(aim_x) >= 0.28:
		kind = "curve"

	var damage = float(profile.get("damage", 1.0))
	if is_perfect:
		damage += 1.0

	var ball = {
		"pos": active_ball["pos"],
		"vel": direction * speed,
		"accel": Vector2(curve_accel, 0.0),
		"life": 4.8,
		"age": 0.0,
		"radius": 14.0 if is_perfect else 13.0,
		"trail": [active_ball["pos"]],
		"spin": float(active_ball.get("spin", 0.0)),
		"hits": 0,
		"hit_ids": [],
		"curve": aim_x,
		"power": power,
		"quality": quality,
		"damage": damage,
		"pierce_limit": 4 + int(profile.get("pierce_bonus", 0)) if is_perfect else 2 + int(profile.get("pierce_bonus", 0)),
		"kind": kind
	}
	shot_balls.append(ball)

	if is_perfect:
		perfect_streak += 1
		var focus_gain = (14.0 + perfect_streak * 3.0) * float(profile.get("focus_gain", 1.0))
		focus = min(focus_capacity(), focus + focus_gain)
		set_feedback("Perfect x" + str(perfect_streak), Color(0.32, 0.95, 1.0))
		spawn_burst(Vector2(active_ball["pos"]), Color(0.35, 0.94, 1.0), 18)
		spawn_impact(Vector2(active_ball["pos"]), 78.0, Color(0.4, 0.95, 1.0))
	elif quality >= 0.45:
		set_feedback("Good Volley", Color(0.78, 1.0, 0.45))
	else:
		perfect_streak = 0
		set_feedback("Scrappy Hit", Color(1.0, 0.75, 0.35))

	active_ball.clear()
	feed_timer = max(0.34, 0.96 - elapsed * 0.004 + rng.randf_range(-0.1, 0.12))
	player_anim = PLAYER_KICK_TIME
	kick_flash_timer = 0.18


func register_miss(text: String) -> void:
	set_feedback(text, Color(1.0, 0.38, 0.32))
	combo = 0
	perfect_streak = 0
	shake(0.08, 3.0)
	if not active_ball.is_empty():
		spawn_burst(Vector2(active_ball["pos"]), Color(1.0, 0.45, 0.28), 8)


func get_timing_quality(ball: Dictionary) -> float:
	var profile = selected_profile()
	var timing = float(profile.get("timing", 1.0))
	var perfect_radius = PERFECT_RADIUS * timing
	var hit_radius = HIT_RADIUS * timing
	var pos = Vector2(ball["pos"])
	var dist = pos.distance_to(STRIKE_CENTER)
	if dist > hit_radius:
		return 0.0
	if dist <= perfect_radius:
		return 1.0
	var ratio = 1.0 - ((dist - perfect_radius) / (hit_radius - perfect_radius))
	return clamp(0.3 + ratio * 0.65, 0.0, 1.0)


func update_enemies(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var burst_count = 1
		if elapsed > 42.0 and rng.randf() < 0.22:
			burst_count = 2
		if elapsed > 92.0 and rng.randf() < 0.15:
			burst_count = 3
		for i in range(burst_count):
			spawn_enemy(i, burst_count)
		var interval = max(0.58, 2.1 - elapsed * 0.01)
		spawn_timer = interval + rng.randf_range(-0.18, 0.16)

	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		var pos = Vector2(enemy["pos"])
		var speed = float(enemy["speed"]) + elapsed * 0.22
		pos.y += speed * delta
		var type = int(enemy.get("type", 0))
		var drift_scale = 12.0 + float(enemy.get("lane_drift", 0.0))
		if type == 1 or type == 5:
			drift_scale += 12.0
		pos.x += sin(elapsed * float(enemy.get("drift_rate", 1.5)) + float(enemy["phase"])) * drift_scale * delta
		pos.x = clamp(pos.x, 48.0, SCREEN_SIZE.x - 48.0)
		enemy["pos"] = pos
		enemy["wobble"] = float(enemy["wobble"]) + delta
		enemies[i] = enemy

		if pos.y >= DANGER_Y:
			enemies.remove_at(i)
			lives -= 1
			combo = 0
			perfect_streak = 0
			set_feedback("Defender broke through!", Color(1.0, 0.34, 0.25))
			spawn_burst(pos, Color(1.0, 0.32, 0.23), 20)
			shake(0.22, 9.0)
			if lives <= 0:
				game_over = true
				set_feedback("Game Over", Color(1.0, 0.28, 0.24))


func spawn_enemy(offset_index: int, burst_count: int) -> void:
	var type = choose_enemy_type()
	var profile = enemy_profile(type)
	var lane_count = 5
	var lane = rng.randi_range(0, lane_count - 1)
	var base_x = 88.0 + float(lane) * ((SCREEN_SIZE.x - 176.0) / float(lane_count - 1))
	if burst_count > 1:
		base_x += (float(offset_index) - (burst_count - 1.0) * 0.5) * 42.0
	var enemy = {
		"id": next_enemy_id,
		"type": type,
		"pos": Vector2(clamp(base_x, 58.0, SCREEN_SIZE.x - 58.0), ENEMY_SPAWN_Y + offset_index * 30.0),
		"speed": float(profile["speed"]) + min(elapsed * 0.22, 26.0),
		"radius": float(profile["radius"]),
		"hp": float(profile["hp"]),
		"max_hp": float(profile["hp"]),
		"score": int(profile["score"]),
		"phase": rng.randf_range(0.0, TAU),
		"wobble": 0.0,
		"lane_drift": float(profile["lane_drift"]),
		"drift_rate": rng.randf_range(1.0, 2.0)
	}
	enemies.append(enemy)
	next_enemy_id += 1


func choose_enemy_type() -> int:
	var roll = rng.randf()
	if elapsed > 18.0 and roll < 0.13:
		return 1
	if elapsed > 34.0 and roll < 0.26:
		return 2
	if elapsed > 58.0 and roll < 0.34:
		return 3
	if elapsed > 42.0 and roll < 0.46:
		return 4
	if elapsed > 20.0 and roll > 0.94:
		return 5
	return 0


func enemy_profile(type: int) -> Dictionary:
	match type:
		1:
			return {"hp": 1.0, "speed": 56.0, "radius": 19.0, "score": 130, "lane_drift": 14.0}
		2:
			return {"hp": 2.0, "speed": 34.0, "radius": 26.0, "score": 175, "lane_drift": 3.0}
		3:
			return {"hp": 3.0, "speed": 27.0, "radius": 29.0, "score": 250, "lane_drift": 2.0}
		4:
			return {"hp": 2.0, "speed": 38.0, "radius": 25.0, "score": 190, "lane_drift": 17.0}
		5:
			return {"hp": 1.0, "speed": 48.0, "radius": 23.0, "score": 330, "lane_drift": 26.0}
	return {"hp": 1.0, "speed": 36.0, "radius": 23.0, "score": 100, "lane_drift": 6.0}


func update_shot_balls(delta: float) -> void:
	for i in range(shot_balls.size() - 1, -1, -1):
		var ball = shot_balls[i]
		var pos = Vector2(ball["pos"])
		var vel = Vector2(ball["vel"])
		var accel = Vector2(ball["accel"])
		vel += accel * delta
		pos += vel * delta
		vel *= pow(0.991, delta * 60.0)
		ball["pos"] = pos
		ball["vel"] = vel
		ball["spin"] = float(ball["spin"]) + vel.length() * delta * 0.052
		ball["life"] = float(ball["life"]) - delta
		ball["age"] = float(ball.get("age", 0.0)) + delta

		var trail: Array = ball["trail"]
		trail.append(pos)
		while trail.size() > 48:
			trail.pop_front()
		ball["trail"] = trail

		check_ball_enemy_hits(ball)

		if float(ball["life"]) <= 0.0 or pos.y < 150.0 or pos.x < -160.0 or pos.x > SCREEN_SIZE.x + 160.0:
			shot_balls.remove_at(i)
		else:
			shot_balls[i] = ball


func check_ball_enemy_hits(ball: Dictionary) -> void:
	var pos = Vector2(ball["pos"])
	var radius = float(ball.get("radius", 14.0))
	var hit_ids: Array = ball.get("hit_ids", [])
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		var enemy_id = int(enemy.get("id", -1))
		if hit_ids.has(enemy_id):
			continue
		var enemy_pos = Vector2(enemy["pos"])
		if pos.distance_to(enemy_pos) > radius + float(enemy.get("radius", 24.0)):
			continue

		hit_ids.append(enemy_id)
		ball["hit_ids"] = hit_ids
		ball["hits"] = int(ball.get("hits", 0)) + 1
		ball["vel"] = Vector2(ball["vel"]) * 0.84
		ball["life"] = min(float(ball["life"]), 2.8)

		var damage = float(ball.get("damage", 1.0))
		var type = int(enemy.get("type", 0))
		var curve = abs(float(ball.get("curve", 0.0)))
		var quality = float(ball.get("quality", 0.5))
		if type == 2 and quality < 0.82:
			damage = max(1.0, damage - 0.5)
		if type == 4 and curve >= 0.44:
			damage += 1.0

		var hp = float(enemy.get("hp", 1.0)) - damage
		if hp <= 0.0:
			enemies.remove_at(i)
			register_enemy_kill(enemy, ball)
		else:
			enemy["hp"] = hp
			enemies[i] = enemy
			set_feedback("Armor cracked", Color(0.4, 0.95, 1.0))
			spawn_burst(enemy_pos, Color(0.25, 0.9, 1.0), 12)
			spawn_impact(enemy_pos, 54.0, Color(0.35, 0.88, 1.0))

		if int(ball["hits"]) >= int(ball.get("pierce_limit", 2)):
			ball["life"] = 0.0
		return


func register_enemy_kill(enemy: Dictionary, ball: Dictionary) -> void:
	var enemy_pos = Vector2(enemy["pos"])
	var profile = selected_profile()
	combo += 1
	combo_timer = 2.6
	var curve_bonus = 45 if abs(float(ball.get("curve", 0.0))) >= 0.44 else 0
	var perfect_bonus = 75 if float(ball.get("quality", 0.0)) >= 0.82 else 0
	var gained = int(enemy.get("score", 100)) + max(combo - 1, 0) * 40 + curve_bonus + perfect_bonus
	score += gained
	focus = min(focus_capacity(), focus + (7.0 + combo * 0.8) * float(profile.get("focus_gain", 1.0)))
	float_texts.append({
		"pos": enemy_pos + Vector2(-24.0, -28.0),
		"text": "+" + str(gained),
		"ttl": 0.92,
		"color": Color(1.0, 0.92, 0.3),
		"size": 22
	})
	if combo >= 3:
		float_texts.append({
			"pos": enemy_pos + Vector2(-28.0, -52.0),
			"text": "x" + str(combo),
			"ttl": 0.8,
			"color": Color(0.3, 0.92, 1.0),
			"size": 24
		})
	spawn_burst(enemy_pos, Color(1.0, 0.86, 0.28), 20)
	spawn_impact(enemy_pos, 62.0, Color(1.0, 0.84, 0.18))
	shake(0.06, 3.8)


func register_skill_kill(enemy: Dictionary, label: String) -> void:
	var enemy_pos = Vector2(enemy["pos"])
	var profile = selected_profile()
	combo += 1
	combo_timer = 2.6
	var gained = int(enemy.get("score", 100)) + max(combo - 1, 0) * 45 + 70
	score += gained
	focus = min(focus_capacity(), focus + (3.0 + combo * 0.35) * float(profile.get("focus_gain", 1.0)))
	float_texts.append({
		"pos": enemy_pos + Vector2(-34.0, -32.0),
		"text": label,
		"ttl": 0.72,
		"color": Color(1.0, 0.9, 0.28),
		"size": 20
	})
	spawn_burst(enemy_pos, Color(1.0, 0.74, 0.18), 18)
	spawn_impact(enemy_pos, 68.0, Color(1.0, 0.78, 0.18))


func update_skill_fx(delta: float) -> void:
	for i in range(skill_fx.size() - 1, -1, -1):
		var fx = skill_fx[i]
		var type = str(fx.get("type", ""))
		fx["age"] = float(fx.get("age", 0.0)) + delta
		fx["ttl"] = float(fx.get("ttl", 0.0)) - delta

		if type == "neymar_roll":
			var pos = Vector2(fx["pos"])
			pos.y -= 720.0 * delta
			fx["pos"] = pos
			var rect = Rect2(pos - Vector2(190.0, 48.0), Vector2(380.0, 96.0))
			var hit_ids: Array = fx.get("hit_ids", [])
			for e in range(enemies.size() - 1, -1, -1):
				var enemy = enemies[e]
				var enemy_id = int(enemy.get("id", -1))
				if hit_ids.has(enemy_id):
					continue
				if rect.has_point(Vector2(enemy["pos"])):
					hit_ids.append(enemy_id)
					enemies.remove_at(e)
					register_skill_kill(enemy, "ROLL")
			fx["hit_ids"] = hit_ids
		elif type == "ronaldo_kick":
			if float(fx.get("age", 0.0)) >= 0.0 and not bool(fx.get("done", false)):
				damage_enemies_in_circle(Vector2(fx["pos"]), float(fx.get("radius", 140.0)), "KICK")
				fx["done"] = true
				shake(0.12, 7.0)
		elif type == "messi_wowo":
			if float(fx.get("age", 0.0)) >= 0.44 and not bool(fx.get("done", false)):
				damage_enemies_in_circle(Vector2(fx["pos"]), float(fx.get("radius", 160.0)), "WOWO")
				fx["done"] = true
				shake(0.18, 9.0)

		if float(fx.get("ttl", 0.0)) <= 0.0:
			skill_fx.remove_at(i)
		else:
			skill_fx[i] = fx


func damage_enemies_in_circle(center: Vector2, radius: float, label: String) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if center.distance_to(Vector2(enemy["pos"])) <= radius + float(enemy.get("radius", 24.0)):
			enemies.remove_at(i)
			register_skill_kill(enemy, label)
	spawn_impact(center, radius * 1.95, Color(1.0, 0.86, 0.24))


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

	for i in range(impact_fx.size() - 1, -1, -1):
		var fx = impact_fx[i]
		fx["ttl"] = float(fx["ttl"]) - delta
		fx["age"] = float(fx.get("age", 0.0)) + delta
		if float(fx["ttl"]) <= 0.0:
			impact_fx.remove_at(i)
		else:
			impact_fx[i] = fx

	for i in range(float_texts.size() - 1, -1, -1):
		var t = float_texts[i]
		t["pos"] = Vector2(t["pos"]) + Vector2(0.0, -40.0) * delta
		t["ttl"] = float(t["ttl"]) - delta
		if float(t["ttl"]) <= 0.0:
			float_texts.remove_at(i)
		else:
			float_texts[i] = t


func spawn_burst(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(70.0, 250.0)
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"ttl": rng.randf_range(0.28, 0.68),
			"size": rng.randf_range(2.0, 5.4),
			"color": color
		})


func spawn_impact(pos: Vector2, size: float, color: Color) -> void:
	impact_fx.append({
		"pos": pos,
		"size": size,
		"ttl": 0.32,
		"age": 0.0,
		"color": color
	})


func set_feedback(text: String, color: Color) -> void:
	last_feedback = text
	feedback_timer = 1.25


func shake(duration: float, amount: float) -> void:
	shake_time = max(shake_time, duration)
	shake_amount = max(shake_amount, amount)


func get_aim_x() -> float:
	var mouse = get_global_mouse_position()
	return clamp((mouse.x - SCREEN_SIZE.x * 0.5) / (SCREEN_SIZE.x * 0.5), -1.0, 1.0)


func get_aim_direction() -> Vector2:
	var delta = get_global_mouse_position() - STRIKE_CENTER
	if delta.length() < 24.0:
		delta = Vector2(0.0, -1.0)
	if delta.y > -18.0:
		delta.y = -18.0
	return delta.normalized()


func quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab = a.lerp(b, t)
	var bc = b.lerp(c, t)
	return ab.lerp(bc, t)


func draw_tex_center(tex: Texture2D, center: Vector2, size: Vector2, color: Color = Color.WHITE) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(center - size * 0.5, size), false, color)


func draw_tex_fit_center(tex: Texture2D, center: Vector2, max_size: Vector2, color: Color = Color.WHITE) -> void:
	if tex == null:
		return
	var raw = Vector2(float(tex.get_width()), float(tex.get_height()))
	if raw.x <= 0.0 or raw.y <= 0.0:
		return
	var scale = min(max_size.x / raw.x, max_size.y / raw.y)
	var size = raw * scale
	draw_texture_rect(tex, Rect2(center - size * 0.5, size), false, color)


func draw_text_shadow(pos: Vector2, text: String, size: int, color: Color, shadow: Color = Color(0, 0, 0, 0.82)) -> void:
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
	draw_field()
	if game_mode == "select":
		draw_character_select()
		return

	var offset = Vector2.ZERO
	if shake_time > 0.0:
		offset = Vector2(rng.randf_range(-shake_amount, shake_amount), rng.randf_range(-shake_amount, shake_amount))
	draw_set_transform(offset)
	draw_feed_path()
	draw_curve_preview()
	draw_strike_zone()
	draw_enemies()
	draw_launcher()
	draw_player()
	draw_balls()
	draw_skill_effects()
	draw_effects_layer()
	draw_set_transform(Vector2.ZERO)
	draw_ui()


func draw_field() -> void:
	if tex_field != null:
		draw_texture_rect(tex_field, Rect2(Vector2.ZERO, SCREEN_SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.05, 0.38, 0.19))
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_SIZE.x, 132.0)), Color(0.0, 0.0, 0.0, 0.16), true)
	draw_rect(Rect2(Vector2(0.0, 1092.0), Vector2(SCREEN_SIZE.x, 188.0)), Color(0.0, 0.0, 0.0, 0.08), true)
	for i in range(0, 18):
		var x = float(i) * 44.0
		draw_line(Vector2(x, DANGER_Y), Vector2(x + 22.0, DANGER_Y), Color(1.0, 0.22, 0.16, 0.58), 3.0)


func draw_feed_path() -> void:
	var side = 0.0
	if not active_ball.is_empty():
		side = float(active_ball.get("side", 0.0))
	var end_pos = STRIKE_CENTER + Vector2(side * 22.0, 0.0)
	var points = PackedVector2Array()
	for i in range(20):
		var t = float(i) / 19.0
		points.append(quadratic_bezier(LAUNCHER_MOUTH, LAUNCHER_MOUTH + Vector2(side * 68.0, -146.0), end_pos, t))
	draw_polyline(points, Color(0.6, 0.95, 1.0, 0.22), 2.0, true)


func draw_curve_preview() -> void:
	if active_ball.is_empty() and not is_charging:
		return
	var aim_x = get_aim_x()
	var power = clamp(charge / MAX_CHARGE, 0.12, 1.0)
	var quality = 0.68
	if not active_ball.is_empty():
		quality = max(0.35, get_timing_quality(active_ball))
	var points = predict_curve_points(power, aim_x, quality)
	var arc_color = Color(0.24, 0.9, 1.0, 0.5)
	if abs(aim_x) >= 0.34:
		arc_color = Color(1.0, 0.82, 0.18, 0.58)
	draw_polyline(points, Color(0.0, 0.0, 0.0, 0.24), 12.0, true)
	draw_polyline(points, arc_color, 6.0, true)
	draw_polyline(points, Color(1.0, 1.0, 1.0, 0.82), 2.0, true)
	for i in range(3, points.size(), 8):
		draw_circle(points[i], 3.5, arc_color)


func predict_curve_points(power: float, aim_x: float, quality: float) -> PackedVector2Array:
	var profile = selected_profile()
	var points = PackedVector2Array()
	var direction = get_aim_direction()
	var speed = lerp(500.0, 1050.0, power) * lerp(0.8, 1.2, quality) * float(profile.get("power", 1.0))
	var curve_peak = 1.0 - clamp(abs(power - 0.58) / 0.58, 0.0, 1.0) * 0.5
	var accel = Vector2(aim_x * lerp(520.0, 1500.0, curve_peak) * lerp(0.82, 1.22, quality) * float(profile.get("curve", 1.0)), 0.0)
	var pos = STRIKE_CENTER
	var vel = direction * speed
	for i in range(46):
		points.append(pos)
		vel += accel * 0.033
		pos += vel * 0.033
		vel *= 0.991
	return points


func draw_strike_zone() -> void:
	var profile = selected_profile()
	var timing = float(profile.get("timing", 1.0))
	var quality = 0.0
	if not active_ball.is_empty():
		quality = get_timing_quality(active_ball)
	var pulse = 1.0 + sin(elapsed * 8.0) * 0.04
	var outer_color = Color(0.22, 0.95, 1.0, 0.35 if quality > 0.0 else 0.18)
	var perfect_color = Color(1.0, 0.95, 0.22, 0.46 if quality >= 0.82 else 0.22)
	draw_arc(STRIKE_CENTER, HIT_RADIUS * timing * pulse, 0.0, TAU, 96, outer_color, 4.0, true)
	draw_arc(STRIKE_CENTER, PERFECT_RADIUS * timing * pulse, 0.0, TAU, 64, perfect_color, 5.0, true)
	draw_line(STRIKE_CENTER + Vector2(-16.0, 0.0), STRIKE_CENTER + Vector2(16.0, 0.0), Color(1.0, 1.0, 1.0, 0.38), 2.0)
	draw_line(STRIKE_CENTER + Vector2(0.0, -16.0), STRIKE_CENTER + Vector2(0.0, 16.0), Color(1.0, 1.0, 1.0, 0.38), 2.0)


func draw_launcher() -> void:
	var center = LAUNCHER_DRAW_CENTER
	draw_ellipse_shadow(center + Vector2(0.0, 45.0), Vector2(122.0, 24.0), Color(0, 0, 0, 0.36))
	draw_tex_fit_center(tex_launcher, center, Vector2(142.0, 118.0))
	draw_circle(center + Vector2(0.0, 10.0), 8.0 + sin(elapsed * 9.0) * 2.0, Color(0.28, 0.95, 1.0, 0.68))


func draw_player() -> void:
	var frames = selected_frames()
	var profile_id = str(selected_profile().get("id", "messi"))
	var frame = 0
	if player_anim > 0.0:
		var progress = 1.0 - player_anim / PLAYER_KICK_TIME
		if progress < 0.22:
			frame = 1
		elif progress < 0.58:
			frame = 2
		else:
			frame = 3
	elif is_charging:
		frame = 1
	var offsets = [Vector2(-12.0, 4.0), Vector2(0.0, 0.0), Vector2(18.0, -2.0), Vector2(15.0, 2.0)]
	var center = PLAYER_DRAW_CENTER + offsets[frame]
	var max_size = Vector2(188.0, 238.0)
	if frame == 2:
		max_size = Vector2(236.0, 246.0)
	if profile_id == "messi":
		if frame == 1:
			center += Vector2(82.0, 0.0)
		elif frame == 2:
			center += Vector2(194.0, 0.0)
		elif frame == 3:
			center += Vector2(150.0, 0.0)
	var shadow_center = PLAYER_DRAW_CENTER + Vector2(12.0, 104.0)
	if profile_id == "messi" and frame > 0:
		shadow_center = center + Vector2(0.0, 104.0)
	draw_ellipse_shadow(shadow_center, Vector2(102.0, 22.0), Color(0, 0, 0, 0.35))
	if kick_flash_timer > 0.0:
		draw_circle(STRIKE_CENTER + Vector2(4.0, 12.0), 40.0 * kick_flash_timer / 0.18, Color(1.0, 0.92, 0.25, kick_flash_timer * 2.5))
	if frame < frames.size():
		draw_tex_fit_center(frames[frame], center, max_size)


func draw_enemies() -> void:
	for enemy in enemies:
		var pos = Vector2(enemy["pos"])
		var r = float(enemy.get("radius", 23.0))
		var type = int(enemy.get("type", 0))
		var wobble = sin(float(enemy["wobble"]) * 7.0) * 2.5
		var tex = enemy_textures[type] if type >= 0 and type < enemy_textures.size() else null
		var depth = clamp((pos.y - ENEMY_SPAWN_Y) / (DANGER_Y - ENEMY_SPAWN_Y), 0.0, 1.0)
		var depth_scale = lerp(0.78, 1.16, depth)
		var visual_size = Vector2(r * 3.05, r * 3.26) * depth_scale
		if type == 3:
			visual_size *= 1.12
		if type == 5:
			draw_circle(pos + Vector2(0.0, wobble), r * 1.65 * depth_scale, Color(1.0, 0.88, 0.12, 0.18))
		var dust_alpha = 0.18 + depth * 0.12
		draw_rect(Rect2(pos + Vector2(-r * 0.9, r * 1.15), Vector2(r * 0.55, 3.0)), Color(0.38, 0.3, 0.14, dust_alpha), true)
		draw_rect(Rect2(pos + Vector2(r * 0.28, r * 1.08), Vector2(r * 0.46, 3.0)), Color(0.38, 0.3, 0.14, dust_alpha * 0.8), true)
		draw_ellipse_shadow(pos + Vector2(0.0, r * 1.18), Vector2(r * 2.0 * depth_scale, r * 0.42 * depth_scale), Color(0, 0, 0, 0.28))
		draw_tex_fit_center(tex, pos + Vector2(0.0, wobble), visual_size)
		var hp = float(enemy.get("hp", 1.0))
		var max_hp = max(1.0, float(enemy.get("max_hp", 1.0)))
		var bar_w = r * 2.15
		var bar_pos = pos + Vector2(-bar_w * 0.5, -r * 1.82 + wobble)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, 5.0)), Color(0.04, 0.05, 0.06, 0.92), true)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * clamp(hp / max_hp, 0.0, 1.0), 5.0)), enemy_bar_color(type), true)


func enemy_bar_color(type: int) -> Color:
	match type:
		1:
			return Color(0.3, 1.0, 0.45, 0.95)
		2:
			return Color(0.2, 0.88, 1.0, 0.95)
		3:
			return Color(1.0, 0.22, 0.16, 0.95)
		4:
			return Color(0.72, 0.34, 1.0, 0.95)
		5:
			return Color(1.0, 0.88, 0.1, 0.95)
	return Color(1.0, 0.36, 0.22, 0.95)


func draw_balls() -> void:
	if not active_ball.is_empty():
		draw_football_variant(Vector2(active_ball["pos"]), 13.0, float(active_ball.get("spin", 0.0)), "normal", Color.WHITE)
	for ball in shot_balls:
		var trail: Array = ball["trail"]
		var kind = str(ball.get("kind", "normal"))
		if trail.size() > 1:
			var points = PackedVector2Array()
			for p in trail:
				points.append(Vector2(p))
			var glow = Color(1.0, 0.88, 0.14, 0.58)
			if kind == "curve":
				glow = Color(0.16, 0.9, 1.0, 0.62)
			elif kind == "fire":
				glow = Color(1.0, 0.36, 0.08, 0.66)
			draw_polyline(points, Color(0, 0, 0, 0.24), 13.0, true)
			draw_polyline(points, glow, 8.0, true)
			draw_polyline(points, Color(1.0, 1.0, 0.76, 0.95), 2.0, true)
		draw_football_variant(Vector2(ball["pos"]), float(ball.get("radius", 13.0)), float(ball.get("spin", 0.0)), kind, Color.WHITE)


func draw_skill_effects() -> void:
	for fx in skill_fx:
		var type = str(fx.get("type", ""))
		var age = float(fx.get("age", 0.0))
		if type == "neymar_roll":
			var pos = Vector2(fx["pos"])
			draw_rect(Rect2(pos - Vector2(190.0, 38.0), Vector2(380.0, 76.0)), Color(0.12, 0.88, 1.0, 0.2), true)
			draw_polyline(PackedVector2Array([pos + Vector2(-180.0, 44.0), pos + Vector2(180.0, -44.0)]), Color(1.0, 0.96, 0.24, 0.88), 8.0, true)
			var frames: Array = character_frames.get("neymar", [])
			if frames.size() > 2:
				draw_tex_fit_center(frames[2], pos, Vector2(210.0, 132.0))
			draw_text_shadow(pos + Vector2(-72.0, -58.0), "ROLL", 22, Color(1.0, 0.95, 0.26))
		elif type == "ronaldo_kick" and age >= 0.0:
			var pos = Vector2(fx["pos"])
			var pulse = clamp(age / 0.55, 0.0, 1.0)
			var radius = float(fx.get("radius", 140.0))
			draw_circle(pos, radius * pulse, Color(1.0, 0.34, 0.18, 0.16))
			draw_arc(pos, radius * pulse, -0.2, TAU - 0.2, 72, Color(1.0, 0.72, 0.18, 0.75), 7.0, true)
			var frames: Array = character_frames.get("ronaldo", [])
			if frames.size() > 2:
				draw_tex_fit_center(frames[2], pos + Vector2(-22.0, -70.0), Vector2(190.0, 190.0))
		elif type == "messi_wowo":
			var pos = Vector2(fx["pos"])
			var fall = clamp(age / 0.44, 0.0, 1.0)
			var bun_pos = pos + Vector2(0.0, -260.0 * (1.0 - fall))
			var radius = float(fx.get("radius", 160.0))
			draw_circle(pos, radius, Color(0.3, 0.95, 1.0, 0.08))
			draw_arc(pos, radius, 0.0, TAU, 96, Color(0.52, 0.94, 1.0, 0.45), 5.0, true)
			draw_circle(bun_pos, 38.0 + 18.0 * fall, Color(0.92, 0.7, 0.34, 0.95))
			draw_circle(bun_pos + Vector2(-13.0, -8.0), 8.0, Color(1.0, 0.86, 0.48, 0.95))
			var frames: Array = character_frames.get("messi", [])
			if frames.size() > 0:
				draw_tex_fit_center(frames[0], Vector2(84.0, 1010.0), Vector2(118.0, 142.0))


func draw_football_variant(pos: Vector2, radius: float, spin: float, kind: String, tint: Color) -> void:
	var tex = tex_ball
	if kind == "curve" and tex_curve_ball != null:
		tex = tex_curve_ball
	elif kind == "fire" and tex_fire_ball != null:
		tex = tex_fire_ball
	if tex != null:
		draw_tex_center(tex, pos, Vector2(radius * 3.0, radius * 3.0), tint)
	else:
		draw_circle(pos, radius, tint)
		draw_circle(pos, radius, Color(0.04, 0.05, 0.06), false, 2.0)
	if kind == "curve":
		draw_arc(pos, radius * 1.8, spin, spin + PI * 1.35, 28, Color(0.26, 0.95, 1.0, 0.72), 3.0, true)
	elif kind == "fire":
		draw_arc(pos, radius * 1.8, spin, spin + PI * 1.4, 28, Color(1.0, 0.7, 0.1, 0.72), 4.0, true)


func draw_effects_layer() -> void:
	for fx in impact_fx:
		var c = Color(fx["color"])
		var alpha = clamp(float(fx["ttl"]) / 0.32, 0.0, 1.0)
		c.a = alpha * 0.75
		var size = float(fx["size"]) * (1.0 + float(fx.get("age", 0.0)) * 1.5)
		draw_tex_center(tex_perfect_impact, Vector2(fx["pos"]), Vector2(size, size), c)
	for p in particles:
		var c = Color(p["color"])
		c.a = clamp(float(p["ttl"]) * 2.2, 0.0, 1.0)
		draw_circle(Vector2(p["pos"]), float(p["size"]), c)
	for t in float_texts:
		var c = Color(t["color"])
		c.a = clamp(float(t["ttl"]) * 1.5, 0.0, 1.0)
		draw_text_shadow(Vector2(t["pos"]), str(t["text"]), int(t.get("size", 24)), c)


func draw_ui() -> void:
	var profile = selected_profile()
	draw_panel(Rect2(Vector2(16.0, 18.0), Vector2(166.0, 80.0)), Color(0, 0, 0, 0.72), Color(0.3, 0.95, 1.0, 0.25))
	draw_text_shadow(Vector2(28.0, 42.0), "SCORE", 18, Color.WHITE)
	draw_text_shadow(Vector2(28.0, 88.0), str(score), 38, Color(1.0, 0.88, 0.1))
	draw_panel(Rect2(Vector2(200.0, 18.0), Vector2(220.0, 80.0)), Color(0, 0, 0, 0.72), Color(profile.get("color", Color.WHITE), 0.55))
	draw_text_shadow(Vector2(218.0, 43.0), str(profile.get("name", "PLAYER")), 19, Color.WHITE)
	draw_text_shadow(Vector2(218.0, 78.0), str(profile.get("role", "")), 18, Color(profile.get("color", Color.WHITE)))

	draw_panel(Rect2(Vector2(438.0, 18.0), Vector2(266.0, 80.0)), Color(0, 0, 0, 0.72), Color(0.3, 0.95, 1.0, 0.25))
	draw_text_shadow(Vector2(452.0, 43.0), "LIVES", 18, Color.WHITE)
	for i in range(MAX_LIVES):
		var c = Color.WHITE if i < lives else Color(0.18, 0.18, 0.18, 0.55)
		draw_tex_center(tex_heart, Vector2(530.0 + i * 50.0, 65.0), Vector2(40.0, 40.0), c)

	var wave = min(WAVE_COUNT, max(1, int(elapsed / 24.0) + 1))
	var wave_progress = clamp(float(wave) / float(WAVE_COUNT), 0.0, 1.0)
	var wave_bar = Rect2(Vector2(110.0, 116.0), Vector2(500.0, 16.0))
	draw_rect(wave_bar, Color(0.03, 0.04, 0.05, 0.92), true)
	draw_rect(Rect2(wave_bar.position, Vector2(wave_bar.size.x * wave_progress, wave_bar.size.y)), Color(0.08, 0.88, 0.42, 0.95), true)
	draw_rect(wave_bar, Color(1, 1, 1, 0.35), false, 2.0)
	draw_text_shadow(Vector2(302.0, 112.0), "WAVE " + str(wave) + "/" + str(WAVE_COUNT), 16, Color.WHITE)

	var power = clamp(charge / MAX_CHARGE, 0.0, 1.0)
	draw_text_shadow(Vector2(22.0, 1207.0), "POWER", 20, Color.WHITE)
	draw_meter(Rect2(Vector2(22.0, 1220.0), Vector2(276.0, 22.0)), power, power_color(power))
	var aim_x = get_aim_x()
	draw_text_shadow(Vector2(326.0, 1207.0), "CURVE", 20, Color.WHITE)
	draw_meter(Rect2(Vector2(326.0, 1220.0), Vector2(200.0, 22.0)), abs(aim_x), Color(0.22, 0.9, 1.0, 0.95))
	draw_text_shadow(Vector2(536.0, 1242.0), "<" if aim_x < -0.08 else ">" if aim_x > 0.08 else "-", 24, Color(0.55, 0.96, 1.0))
	draw_skill_panel()

	var aim_end = predict_curve_points(max(0.2, power), aim_x, 0.72)[14]
	draw_circle(aim_end, 5.0, Color(0.7, 0.95, 1.0, 0.5))
	if feedback_timer > 0.0:
		var fb_color = Color(1.0, 0.92, 0.12, min(feedback_timer, 1.0))
		draw_text_shadow(Vector2(380.0, 180.0), last_feedback, 24, fb_color)
	if game_over:
		draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.0, 0.0, 0.0, 0.64), true)
		draw_text_shadow(Vector2(188.0, 520.0), "GAME OVER", 48, Color(1.0, 0.28, 0.24))
		draw_text_shadow(Vector2(212.0, 590.0), "Final Score: " + str(score), 26, Color.WHITE)
		draw_text_shadow(Vector2(150.0, 650.0), "Tap to choose again", 26, Color(0.8, 0.94, 1.0))


func draw_meter(rect: Rect2, value: float, color: Color) -> void:
	draw_rect(rect, Color(0.02, 0.03, 0.04, 0.9), true)
	draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), Vector2((rect.size.x - 8.0) * clamp(value, 0.0, 1.0), rect.size.y - 8.0)), color, true)
	draw_rect(rect, Color(1, 1, 1, 0.45), false, 3.0)


func power_color(power: float) -> Color:
	return Color(0.18 + power * 0.82, 0.92 - power * 0.28, 0.15, 0.95)


func draw_skill_panel() -> void:
	var capacity = focus_capacity()
	var focus_ratio = clamp(focus / capacity, 0.0, 1.0)
	var ready = focus >= MAX_FOCUS
	var rect = Rect2(Vector2(552.0, 1192.0), Vector2(146.0, 56.0))
	draw_panel(rect, Color(0.02, 0.03, 0.05, 0.78), Color(0.3, 0.95, 1.0, 0.65) if ready else Color(1.0, 1.0, 1.0, 0.22))
	draw_tex_center(tex_slow_icon, rect.position + Vector2(26.0, 28.0), Vector2(38.0, 38.0), Color.WHITE if ready else Color(0.55, 0.55, 0.55, 0.65))
	var charge_count = int(round(capacity / MAX_FOCUS))
	for i in range(charge_count):
		var pip_rect = Rect2(rect.position + Vector2(56.0 + float(i) * 40.0, 30.0), Vector2(32.0, 12.0))
		var pip_value = clamp((focus - float(i) * MAX_FOCUS) / MAX_FOCUS, 0.0, 1.0)
		draw_meter(pip_rect, pip_value, Color(0.2, 0.9, 1.0, 0.95))
	draw_text_shadow(rect.position + Vector2(54.0, 24.0), "E", 18, Color.WHITE if ready else Color(0.7, 0.7, 0.7))


func select_card_rect(index: int) -> Rect2:
	return Rect2(Vector2(42.0, 210.0 + float(index) * 294.0), Vector2(636.0, 250.0))


func draw_character_select() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0, 0, 0, 0.42), true)
	draw_text_shadow(Vector2(108.0, 96.0), "CHOOSE STRIKER", 42, Color.WHITE)
	draw_text_shadow(Vector2(142.0, 146.0), "Mobile portrait squad", 22, Color(0.84, 0.95, 1.0))
	for i in range(character_defs.size()):
		draw_character_card(i)
	draw_panel(Rect2(Vector2(92.0, 1164.0), Vector2(536.0, 72.0)), Color(0.02, 0.08, 0.12, 0.88), Color(0.4, 0.95, 1.0, 0.75))
	draw_text_shadow(Vector2(272.0, 1214.0), "START", 32, Color(1.0, 0.92, 0.22))


func draw_character_card(index: int) -> void:
	var rect = select_card_rect(index)
	var profile = character_defs[index]
	var selected = index == selected_character
	var border = Color(profile.get("color", Color.WHITE), 0.8 if selected else 0.28)
	draw_panel(rect, Color(0.02, 0.04, 0.06, 0.82 if selected else 0.68), border)
	var id = str(profile.get("id", "messi"))
	var frames: Array = character_frames.get(id, [])
	if not frames.is_empty():
		draw_tex_fit_center(frames[2], rect.position + Vector2(118.0, 130.0), Vector2(190.0, 210.0))
	draw_text_shadow(rect.position + Vector2(230.0, 56.0), str(profile.get("name", "")), 32, Color.WHITE)
	draw_text_shadow(rect.position + Vector2(230.0, 92.0), str(profile.get("role", "")), 22, Color(profile.get("color", Color.WHITE)))
	draw_text_shadow(rect.position + Vector2(230.0, 132.0), "Power " + stat_bars(float(profile.get("power", 1.0)), 0.8, 1.3), 18, Color.WHITE)
	draw_text_shadow(rect.position + Vector2(230.0, 166.0), "Curve " + stat_bars(float(profile.get("curve", 1.0)), 0.8, 1.45), 18, Color.WHITE)
	draw_text_shadow(rect.position + Vector2(230.0, 200.0), "Skill " + str(profile.get("skill", "")), 18, Color(1.0, 0.92, 0.22))


func stat_bars(value: float, low: float, high: float) -> String:
	var count = int(round(clamp((value - low) / (high - low), 0.0, 1.0) * 5.0))
	var s = ""
	for i in range(5):
		s += "|" if i < count else "."
	return s

