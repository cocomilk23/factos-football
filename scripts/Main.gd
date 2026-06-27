extends Node2D

const SCREEN_SIZE = Vector2(720.0, 1280.0)
const PLAYER_DRAW_CENTER = Vector2(294.0, 1084.0)
const STRIKE_CENTER = Vector2(252.0, 1156.0)
const DANGER_Y = 1084.0
const ENEMY_SPAWN_Y = 250.0
const SHOT_REVEAL_Y = 1072.0
const SHOT_REVEAL_DISTANCE = 126.0
const MAX_CHARGE = 1.25
const MAX_GESTURE_TIME = 2.0
const MAX_LIVES = 3
const WAVE_COUNT = 15
const PLAYER_KICK_TIME = 0.52
const MAX_FOCUS = 100.0

var rng = RandomNumberGenerator.new()
var font: Font
var tex_field: Texture2D
var tex_ball: Texture2D
var tex_fire_ball: Texture2D
var tex_perfect_impact: Texture2D
var tex_heart: Texture2D
var tex_pierce_icon: Texture2D
var tex_slow_icon: Texture2D
var tex_wowo: Texture2D
var enemy_textures: Array = []
var character_defs: Array = []
var character_frames: Dictionary = {}
var neymar_roll_frames: Array = []
var ronaldo_sweep_frames: Array = []
var bgm_player: AudioStreamPlayer
var sfx_kick: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_skill_messi: AudioStreamPlayer
var sfx_skill_ronaldo: AudioStreamPlayer
var sfx_skill_neymar: AudioStreamPlayer
var sfx_game_over: AudioStreamPlayer
var audio_unlocked = false

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
var gesture_time = 0.0
var swipe_points: Array = []
var skill_dragging = false
var skill_drag_pos = Vector2.ZERO
var player_anim = 0.0
var kick_flash_timer = 0.0
var last_feedback = ""
var feedback_timer = 0.0
var skill_banner_text = ""
var skill_banner_timer = 0.0
var skill_banner_age = 0.0
var skill_banner_color = Color.WHITE


func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	load_assets()
	setup_audio()
	build_character_defs()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show_character_select()


func load_assets() -> void:
	tex_field = load("res://assets/img/stadium_field.png")
	tex_ball = load("res://assets/img/ball_projectile.png")
	tex_fire_ball = load("res://assets/img/fireball_projectile.png")
	tex_perfect_impact = load("res://assets/img/perfect_impact.png")
	tex_heart = load("res://assets/img/heart_icon.png")
	tex_pierce_icon = load("res://assets/img/pierce_icon.png")
	tex_slow_icon = load("res://assets/img/slow_icon.png")
	tex_wowo = load("res://assets/img/skill_wowo.png")
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
	neymar_roll_frames = [
		load("res://assets/img/skill_neymar_roll_0.png"),
		load("res://assets/img/skill_neymar_roll_1.png"),
		load("res://assets/img/skill_neymar_roll_2.png"),
		load("res://assets/img/skill_neymar_roll_3.png")
	]
	ronaldo_sweep_frames = [
		load("res://assets/img/skill_ronaldo_sweep_0.png"),
		load("res://assets/img/skill_ronaldo_sweep_1.png"),
		load("res://assets/img/skill_ronaldo_sweep_2.png"),
		load("res://assets/img/skill_ronaldo_sweep_3.png")
	]


func setup_audio() -> void:
	bgm_player = make_audio_player("res://assets/audio/bgm_loop.wav", -14.0)
	sfx_kick = make_audio_player("res://music/kick.wav", -4.0)
	sfx_hit = make_audio_player("res://assets/audio/hit.wav", -5.5)
	sfx_skill_messi = make_audio_player("res://music/messi_wowo.mp3", -2.5)
	sfx_skill_ronaldo = make_audio_player("res://music/ronaldo_siu.mp3", -2.5)
	sfx_skill_neymar = make_audio_player("res://music/neymar.mp3", -3.0)
	sfx_game_over = make_audio_player("res://assets/audio/game_over.wav", -5.0)


func make_audio_player(path: String, volume: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = load_audio_stream(path)
	player.volume_db = volume
	add_child(player)
	return player


func load_audio_stream(path: String) -> AudioStream:
	var stream: AudioStream = null
	if path.get_extension().to_lower() == "wav":
		stream = AudioStreamWAV.load_from_file(path)
	elif path.get_extension().to_lower() == "mp3":
		stream = load(path)
		if stream == null:
			stream = AudioStreamMP3.load_from_file(path)
	else:
		stream = load(path)
	if stream == null and path.get_extension().to_lower() == "mp3":
		stream = AudioStreamMP3.load_from_file(path)
	if stream is AudioStreamWAV and path.find("bgm_loop") >= 0:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3 and path.find("bgm") >= 0:
		stream.loop = true
	return stream


func unlock_audio() -> void:
	if audio_unlocked:
		return
	audio_unlocked = true
	update_audio_state()


func update_audio_state() -> void:
	if bgm_player == null or bgm_player.stream == null or not audio_unlocked:
		return
	if not is_inside_tree() or not bgm_player.is_inside_tree():
		return
	if game_mode == "play" and not game_over:
		if not bgm_player.playing:
			bgm_player.play()
	elif bgm_player.playing:
		bgm_player.stop()


func play_sfx(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null or not audio_unlocked:
		return
	if not is_inside_tree() or not player.is_inside_tree():
		return
	player.stop()
	player.play()


func build_character_defs() -> void:
	character_defs = [
		{
			"id": "messi",
			"name": "MESSI",
			"skill_label": "WOWO DROP",
			"role": "Left Foot",
			"skill": "给你俩窝窝",
			"power": 0.92,
			"aim": 1.42,
			"timing": 1.18,
			"focus_gain": 1.15,
			"skill_cost": 120.0,
			"max_focus": 240.0,
			"damage": 1.0,
			"pierce_bonus": 0,
			"preferred_side": -1.0,
			"color": Color(0.42, 0.86, 1.0)
		},
		{
			"id": "ronaldo",
			"name": "RONALDO",
			"skill_label": "TRIPLE KICK",
			"role": "Power Drive",
			"skill": "罗三脚",
			"power": 1.22,
			"aim": 0.84,
			"timing": 0.96,
			"focus_gain": 0.95,
			"skill_cost": 155.0,
			"max_focus": 155.0,
			"damage": 1.35,
			"pierce_bonus": 1,
			"preferred_side": 1.0,
			"color": Color(1.0, 0.36, 0.28)
		},
		{
			"id": "neymar",
			"name": "NEYMAR",
			"skill_label": "NEYMAR ROLL",
			"role": "Trick Spin",
			"skill": "马尔翻滚",
			"power": 1.0,
			"aim": 1.2,
			"timing": 1.05,
			"focus_gain": 1.05,
			"skill_cost": 130.0,
			"max_focus": 130.0,
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
	gesture_time = 0.0
	swipe_points.clear()
	skill_dragging = false
	queue_redraw()


func restart_game() -> void:
	unlock_audio()
	game_mode = "play"
	elapsed = 0.0
	score = 0
	lives = MAX_LIVES
	combo = 0
	combo_timer = 0.0
	perfect_streak = 0
	focus = 0.0
	game_over = false
	feed_timer = 0.18
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
	gesture_time = 0.0
	swipe_points.clear()
	skill_dragging = false
	player_anim = 0.0
	kick_flash_timer = 0.0
	skill_banner_timer = 0.0
	skill_banner_age = 0.0
	last_feedback = "Time the feed ball"
	feedback_timer = 2.6
	shake_time = 0.0
	shake_amount = 0.0
	update_audio_state()
	queue_redraw()


func selected_profile() -> Dictionary:
	if character_defs.is_empty():
		return {}
	return character_defs[selected_character]


func focus_capacity() -> float:
	return float(selected_profile().get("max_focus", MAX_FOCUS))


func skill_cost() -> float:
	return float(selected_profile().get("skill_cost", MAX_FOCUS))


func selected_frames() -> Array:
	var profile = selected_profile()
	var id = str(profile.get("id", "messi"))
	return character_frames.get(id, [])


func skill_name(profile: Dictionary) -> String:
	return str(profile.get("skill_label", profile.get("skill", "SPECIAL")))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		unlock_audio()
	elif event is InputEventScreenTouch and event.pressed:
		unlock_audio()
	elif event is InputEventKey and event.pressed:
		unlock_audio()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		unlock_audio()
	elif event is InputEventScreenTouch and event.pressed:
		unlock_audio()
	elif event is InputEventKey and event.pressed:
		unlock_audio()

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
		activate_skill_at(get_global_mouse_position())
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		activate_skill_at(get_global_mouse_position())
		return

	if event.is_action_pressed("shoot"):
		start_charge(get_global_mouse_position())
	elif event.is_action_released("shoot"):
		release_shot(get_global_mouse_position())

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			handle_primary_press(event.position)
		else:
			handle_primary_release(event.position)
	elif event is InputEventMouseMotion:
		handle_primary_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			handle_primary_press(event.position)
		else:
			handle_primary_release(event.position)
	elif event is InputEventScreenDrag:
		handle_primary_drag(event.position)


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


func handle_primary_press(pos: Vector2) -> void:
	if focus >= skill_cost() and skill_panel_rect().has_point(pos):
		begin_skill_drag(pos)
		return
	start_charge(pos)


func handle_primary_drag(pos: Vector2) -> void:
	if skill_dragging:
		skill_drag_pos = clamp_skill_target(pos)
	elif is_charging:
		var added = add_swipe_point(pos)
		if added and is_invalid_gesture(swipe_points):
			trim_invalid_gesture_tail()
			release_shot(Vector2(swipe_points.back()) if not swipe_points.is_empty() else pos)


func handle_primary_release(pos: Vector2) -> void:
	if skill_dragging:
		finish_skill_drag(pos)
		return
	release_shot(pos)


func begin_skill_drag(pos: Vector2) -> void:
	skill_dragging = true
	skill_drag_pos = clamp_skill_target(pos)


func finish_skill_drag(pos: Vector2) -> void:
	skill_dragging = false
	activate_skill_at(pos)


func activate_focus() -> void:
	activate_skill_at(get_global_mouse_position())


func activate_skill_at(target: Vector2) -> void:
	var cost = skill_cost()
	if focus < cost:
		return
	var profile = selected_profile()
	focus -= cost
	var id = str(profile.get("id", "messi"))
	if id == "neymar":
		use_neymar_skill(target)
	elif id == "ronaldo":
		use_ronaldo_skill(target)
	else:
		use_messi_skill(target)
	focus = clamp(focus, 0.0, focus_capacity())
	var clean_skill_name = skill_name(profile)
	set_feedback(clean_skill_name + "!", Color(0.35, 0.95, 1.0))
	show_skill_banner(clean_skill_name, Color(profile.get("color", Color.WHITE)))
	spawn_burst(STRIKE_CENTER, Color(0.2, 0.95, 1.0), 28)
	if id == "neymar":
		play_sfx(sfx_skill_neymar)
	elif id == "ronaldo":
		play_sfx(sfx_skill_ronaldo)
	else:
		play_sfx(sfx_skill_messi)
	shake(0.12, 4.0)


func use_neymar_skill(target: Vector2) -> void:
	var lane_x = clamp(target.x, 190.0, SCREEN_SIZE.x - 190.0)
	skill_fx.append({
		"type": "neymar_roll",
		"pos": Vector2(lane_x, 1110.0),
		"ttl": 1.45,
		"age": 0.0,
		"hit_ids": []
	})


func use_ronaldo_skill(target: Vector2) -> void:
	var target_x = clamp(target.x, 130.0, SCREEN_SIZE.x - 130.0)
	var lane_targets = [
		Vector2(clamp(target_x - 135.0, 110.0, SCREEN_SIZE.x - 110.0), 540.0),
		Vector2(target_x, 685.0),
		Vector2(clamp(target_x + 135.0, 110.0, SCREEN_SIZE.x - 110.0), 830.0)
	]
	for i in range(lane_targets.size()):
		skill_fx.append({
			"type": "ronaldo_sweep",
			"start": Vector2(260.0, 990.0),
			"end": lane_targets[i],
			"pos": Vector2(260.0, 990.0),
			"ttl": 1.16 + float(i) * 0.12,
			"age": -float(i) * 0.18,
			"radius": 126.0,
			"frame": i + 1,
			"hit_ids": []
		})


func use_messi_skill(target: Vector2) -> void:
	target = clamp_skill_target(target)
	skill_fx.append({
		"type": "messi_wowo",
		"pos": target,
		"ttl": 1.12,
		"age": 0.0,
		"radius": 172.0,
		"done": false
	})


func start_charge(pos: Vector2) -> void:
	if is_charging:
		return
	is_charging = true
	charge = 0.0
	gesture_time = 0.0
	swipe_points.clear()
	add_swipe_point(pos)


func release_shot(pos: Vector2) -> void:
	if not is_charging:
		return
	add_swipe_point(pos)
	trim_invalid_gesture_tail()
	is_charging = false
	var released_charge = charge
	charge = 0.0
	gesture_time = 0.0

	if active_ball.is_empty():
		spawn_feed_ball()

	kick_active_ball(released_charge, 0.86)


func add_swipe_point(pos: Vector2) -> bool:
	var added = false
	if swipe_points.is_empty() or Vector2(swipe_points.back()).distance_to(pos) >= 4.0:
		swipe_points.append(pos)
		added = true
	while swipe_points.size() > 128:
		swipe_points.pop_front()
	return added


func trim_invalid_gesture_tail() -> void:
	while swipe_points.size() > 2 and is_invalid_gesture(swipe_points):
		swipe_points.pop_back()


func is_invalid_gesture(points: Array) -> bool:
	if points.size() < 5:
		return false

	var total_len = 0.0
	var displacement = Vector2(points.back()).distance_to(Vector2(points.front()))
	var previous_dir = Vector2.ZERO
	var x_sign = 0
	var x_flips = 0
	for i in range(1, points.size()):
		var segment = Vector2(points[i]) - Vector2(points[i - 1])
		var segment_len = segment.length()
		total_len += segment_len
		if segment_len < 7.0:
			continue
		var dir = segment / segment_len
		if previous_dir != Vector2.ZERO and total_len > 120.0:
			if previous_dir.dot(dir) < -0.35:
				return true
		previous_dir = dir

		if abs(segment.x) > 10.0:
			var current_sign = 1 if segment.x > 0.0 else -1
			if x_sign != 0 and current_sign != x_sign:
				x_flips += 1
			x_sign = current_sign

	if total_len > 180.0 and displacement < 76.0:
		return true
	if total_len > 220.0 and displacement > 1.0 and total_len / displacement > 2.25:
		return true
	if total_len > 180.0 and x_flips >= 3:
		return true

	if has_self_intersection(points):
		return true
	return false


func has_self_intersection(points: Array) -> bool:
	if points.size() < 6:
		return false
	var a = Vector2(points[points.size() - 2])
	var b = Vector2(points[points.size() - 1])
	for i in range(1, points.size() - 3):
		var c = Vector2(points[i - 1])
		var d = Vector2(points[i])
		if segments_intersect(a, b, c, d):
			return true
	return false


func segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var r = b - a
	var s = d - c
	var denom = r.cross(s)
	if abs(denom) < 0.001:
		return false
	var t = (c - a).cross(s) / denom
	var u = (c - a).cross(r) / denom
	return t > 0.05 and t < 0.95 and u > 0.05 and u < 0.95


func _process(delta: float) -> void:
	update_audio_state()
	if game_mode == "select":
		queue_redraw()
		return
	if game_over:
		update_effects(delta)
		queue_redraw()
		return

	elapsed += delta
	if is_charging:
		gesture_time += delta
		charge = min(charge + delta, MAX_CHARGE)
		if gesture_time >= MAX_GESTURE_TIME:
			var auto_pos = Vector2(swipe_points.back()) if not swipe_points.is_empty() else get_global_mouse_position()
			release_shot(auto_pos)
	player_anim = max(player_anim - delta, 0.0)
	kick_flash_timer = max(kick_flash_timer - delta, 0.0)
	feedback_timer = max(feedback_timer - delta, 0.0)
	if skill_banner_timer > 0.0:
		skill_banner_timer = max(skill_banner_timer - delta, 0.0)
		skill_banner_age += delta
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

	active_ball["spin"] = float(active_ball.get("spin", 0.0)) + delta * 10.0
	active_ball["pos"] = STRIKE_CENTER


func spawn_feed_ball() -> void:
	active_ball = {
		"t": 1.0,
		"side": 0.0,
		"pos": STRIKE_CENTER,
		"spin": rng.randf_range(0.0, TAU)
	}


func kick_active_ball(released_charge: float, quality: float) -> void:
	var profile = selected_profile()
	var power = clamp(released_charge / MAX_CHARGE, 0.18, 1.0)
	var path = build_swipe_path(power)
	var path_len = max(1.0, polyline_length(path))
	var direction = get_aim_direction()
	var speed = lerp(620.0, 1120.0, power) * float(profile.get("power", 1.0))

	var is_perfect = power >= 0.82 and swipe_points.size() >= 5
	var kind = "normal"
	if str(profile.get("id", "")) == "ronaldo" and power >= 0.86:
		kind = "fire"

	var damage = float(profile.get("damage", 1.0))
	if is_perfect:
		damage += 1.0

	var ball = {
		"pos": active_ball["pos"],
		"vel": direction * speed,
		"accel": Vector2.ZERO,
		"life": 4.8,
		"age": 0.0,
		"visible": false,
		"reveal_distance": SHOT_REVEAL_DISTANCE,
		"radius": 14.0 if is_perfect else 13.0,
		"trail": [],
		"spin": float(active_ball.get("spin", 0.0)),
		"path": path,
		"path_dist": 0.0,
		"path_len": path_len,
		"path_speed": speed,
		"hits": 0,
		"hit_ids": [],
		"power": power,
		"quality": quality,
		"damage": damage,
		"pierce_limit": 4 + int(profile.get("pierce_bonus", 0)) if is_perfect else 2 + int(profile.get("pierce_bonus", 0)),
		"kind": kind
	}
	shot_balls.append(ball)

	if is_perfect:
		perfect_streak += 1
		var focus_gain = (8.0 + perfect_streak * 1.2) * float(profile.get("focus_gain", 1.0))
		focus = min(focus_capacity(), focus + focus_gain)
		set_feedback("Power Shot x" + str(perfect_streak), Color(0.32, 0.95, 1.0))
		spawn_burst(Vector2(active_ball["pos"]), Color(0.35, 0.94, 1.0), 18)
		spawn_impact(Vector2(active_ball["pos"]), 78.0, Color(0.4, 0.95, 1.0))
	else:
		set_feedback("Straight Shot", Color(0.78, 1.0, 0.45))

	active_ball.clear()
	feed_timer = 0.12
	player_anim = PLAYER_KICK_TIME
	kick_flash_timer = 0.18
	play_sfx(sfx_kick)


func register_miss(text: String) -> void:
	set_feedback(text, Color(1.0, 0.38, 0.32))
	combo = 0
	perfect_streak = 0
	shake(0.08, 3.0)
	if not active_ball.is_empty():
		spawn_burst(Vector2(active_ball["pos"]), Color(1.0, 0.45, 0.28), 8)


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
				play_sfx(sfx_game_over)


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
		if ball.has("path"):
			var old_pos = pos
			var path_points: PackedVector2Array = ball["path"]
			var path_dist = float(ball.get("path_dist", 0.0)) + float(ball.get("path_speed", 860.0)) * delta
			pos = point_on_polyline(path_points, path_dist)
			vel = (pos - old_pos) / max(delta, 0.001)
			ball["path_dist"] = path_dist
		else:
			var accel = Vector2(ball["accel"])
			vel += accel * delta
			pos += vel * delta
			vel *= pow(0.991, delta * 60.0)
		ball["pos"] = pos
		ball["vel"] = vel
		ball["spin"] = float(ball["spin"]) + vel.length() * delta * 0.052
		ball["life"] = float(ball["life"]) - delta
		ball["age"] = float(ball.get("age", 0.0)) + delta
		if not bool(ball.get("visible", false)):
			var reveal_distance = float(ball.get("reveal_distance", SHOT_REVEAL_DISTANCE))
			if float(ball.get("path_dist", 0.0)) >= reveal_distance or pos.y <= SHOT_REVEAL_Y:
				ball["visible"] = true
				ball["trail"] = []

		if bool(ball.get("visible", false)):
			var trail: Array = ball["trail"]
			trail.append(pos)
			while trail.size() > 40:
				trail.pop_front()
			ball["trail"] = trail
			check_ball_enemy_hits(ball)

		var path_done = ball.has("path") and float(ball.get("path_dist", 0.0)) >= float(ball.get("path_len", 0.0))
		if path_done or float(ball["life"]) <= 0.0 or pos.y < 120.0 or pos.x < -180.0 or pos.x > SCREEN_SIZE.x + 180.0:
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
		var power = float(ball.get("power", 0.0))
		var quality = float(ball.get("quality", 0.5))
		if type == 2 and quality < 0.82:
			damage = max(1.0, damage - 0.5)
		if type == 4 and power >= 0.78:
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
	var power_bonus = 45 if float(ball.get("power", 0.0)) >= 0.82 else 0
	var perfect_bonus = 75 if float(ball.get("quality", 0.0)) >= 0.82 else 0
	var gained = int(enemy.get("score", 100)) + max(combo - 1, 0) * 40 + power_bonus + perfect_bonus
	score += gained
	focus = min(focus_capacity(), focus + (5.0 + combo * 0.55) * float(profile.get("focus_gain", 1.0)))
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
	play_sfx(sfx_hit)
	shake(0.06, 3.8)


func register_skill_kill(enemy: Dictionary, label: String) -> void:
	var enemy_pos = Vector2(enemy["pos"])
	var profile = selected_profile()
	combo += 1
	combo_timer = 2.6
	var gained = int(enemy.get("score", 100)) + max(combo - 1, 0) * 45 + 70
	score += gained
	focus = min(focus_capacity(), focus + (1.2 + combo * 0.12) * float(profile.get("focus_gain", 1.0)))
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
		elif type == "ronaldo_sweep":
			var age = float(fx.get("age", 0.0))
			if age >= 0.0:
				var start = Vector2(fx["start"])
				var end = Vector2(fx["end"])
				var p = clamp(age / 0.72, 0.0, 1.0)
				p = 1.0 - pow(1.0 - p, 2.0)
				var pos = start.lerp(end, p)
				fx["pos"] = pos
				var hit_ids: Array = fx.get("hit_ids", [])
				for e in range(enemies.size() - 1, -1, -1):
					var enemy = enemies[e]
					var enemy_id = int(enemy.get("id", -1))
					if hit_ids.has(enemy_id):
						continue
					if pos.distance_to(Vector2(enemy["pos"])) <= float(fx.get("radius", 126.0)) + float(enemy.get("radius", 24.0)):
						hit_ids.append(enemy_id)
						enemies.remove_at(e)
						register_skill_kill(enemy, "KICK")
				fx["hit_ids"] = hit_ids
				if age < delta:
					shake(0.1, 6.0)
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


func show_skill_banner(text: String, color: Color) -> void:
	skill_banner_text = text
	skill_banner_color = color
	skill_banner_timer = 1.15
	skill_banner_age = 0.0


func shake(duration: float, amount: float) -> void:
	shake_time = max(shake_time, duration)
	shake_amount = max(shake_amount, amount)


func get_aim_x() -> float:
	return clamp(get_aim_direction().x, -1.0, 1.0)


func get_aim_direction() -> Vector2:
	if swipe_points.size() >= 2:
		var end = Vector2(swipe_points.back())
		var delta = end - Vector2(swipe_points.front())
		for i in range(swipe_points.size() - 2, -1, -1):
			var candidate = end - Vector2(swipe_points[i])
			if candidate.length() >= 24.0:
				delta = candidate
				break
		if delta.length() >= 1.0:
			return clamp_forward_direction(delta)
	var delta = get_global_mouse_position() - STRIKE_CENTER
	return clamp_forward_direction(delta)


func clamp_forward_direction(delta: Vector2) -> Vector2:
	if delta.length() < 24.0:
		delta = Vector2(0.0, -1.0)
	if delta.y > -18.0:
		delta.y = -18.0
	return delta.normalized()


func build_swipe_path(power: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(STRIKE_CENTER)
	var dir = get_aim_direction()
	var end = STRIKE_CENTER + dir * (1180.0 + power * 620.0)
	for i in range(1, 57):
		var t = float(i) / 56.0
		points.append(STRIKE_CENTER.lerp(end, t))
	return points


func polyline_length(points: PackedVector2Array) -> float:
	var length = 0.0
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
	return length


func point_on_polyline(points: PackedVector2Array, distance: float) -> Vector2:
	if points.is_empty():
		return STRIKE_CENTER
	var remaining = distance
	for i in range(1, points.size()):
		var a = points[i - 1]
		var b = points[i]
		var segment = a.distance_to(b)
		if remaining <= segment:
			return a.lerp(b, remaining / max(segment, 0.001))
		remaining -= segment
	return points[points.size() - 1]


func clamp_skill_target(pos: Vector2) -> Vector2:
	return Vector2(clamp(pos.x, 116.0, SCREEN_SIZE.x - 116.0), clamp(pos.y, 300.0, 910.0))


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


func draw_text_center_shadow(y: float, text: String, size: int, color: Color, shadow: Color = Color(0, 0, 0, 0.82)) -> void:
	draw_string(font, Vector2(3.0, y + 4.0), text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_SIZE.x, size, shadow)
	draw_string(font, Vector2(0.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_SIZE.x, size, color)


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
	draw_aim_preview()
	draw_strike_zone()
	draw_enemies()
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


func draw_aim_preview() -> void:
	if not is_charging:
		return
	if is_charging and swipe_points.size() >= 2:
		var power = clamp(charge / MAX_CHARGE, 0.18, 1.0)
		var dir = get_aim_direction()
		var length = lerp(120.0, 260.0, power)
		var path = PackedVector2Array([
			STRIKE_CENTER,
			STRIKE_CENTER + dir * length
		])
		draw_polyline(path, Color(0.0, 0.0, 0.0, 0.18), 4.0, true)
		draw_polyline(path, Color(0.42, 0.95, 1.0, 0.58), 2.0, true)
		draw_circle(path[1], 4.0, Color(0.75, 1.0, 1.0, 0.7))
		return


func draw_strike_zone() -> void:
	var pulse = 1.0 + sin(elapsed * 8.0) * 0.04
	draw_ellipse_shadow(STRIKE_CENTER + Vector2(0.0, 18.0), Vector2(92.0 * pulse, 22.0 * pulse), Color(0.0, 0.0, 0.0, 0.24))
	draw_arc(STRIKE_CENTER, 42.0 * pulse, 0.0, TAU, 64, Color(0.25, 0.95, 1.0, 0.24), 2.5, true)


func draw_player() -> void:
	var frames = selected_frames()
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
	var shadow_center = PLAYER_DRAW_CENTER + Vector2(12.0, 104.0)
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
	if not active_ball.is_empty() and player_anim <= 0.0:
		draw_football_variant(Vector2(active_ball["pos"]), 13.0, float(active_ball.get("spin", 0.0)), "normal", Color.WHITE)
	for ball in shot_balls:
		if not bool(ball.get("visible", false)):
			continue
		var trail: Array = ball["trail"]
		var kind = str(ball.get("kind", "normal"))
		if trail.size() > 1:
			var points = PackedVector2Array()
			for p in trail:
				points.append(Vector2(p))
			var glow = Color(1.0, 0.88, 0.14, 0.58)
			if kind == "fire":
				glow = Color(1.0, 0.36, 0.08, 0.66)
			draw_polyline(points, Color(0, 0, 0, 0.18), 5.0, true)
			draw_polyline(points, glow, 2.8, true)
			draw_polyline(points, Color(1.0, 1.0, 0.76, 0.76), 0.9, true)
		draw_football_variant(Vector2(ball["pos"]), float(ball.get("radius", 13.0)), float(ball.get("spin", 0.0)), kind, Color.WHITE)


func draw_skill_effects() -> void:
	for fx in skill_fx:
		var type = str(fx.get("type", ""))
		var age = float(fx.get("age", 0.0))
		if type == "neymar_roll":
			var pos = Vector2(fx["pos"])
			draw_rect(Rect2(pos - Vector2(190.0, 38.0), Vector2(380.0, 76.0)), Color(0.12, 0.88, 1.0, 0.2), true)
			draw_polyline(PackedVector2Array([pos + Vector2(-180.0, 42.0), pos + Vector2(180.0, -42.0)]), Color(1.0, 0.96, 0.24, 0.7), 5.0, true)
			var frame = int(age * 12.0) % max(neymar_roll_frames.size(), 1)
			if frame < neymar_roll_frames.size():
				draw_tex_fit_center(neymar_roll_frames[frame], pos, Vector2(250.0, 150.0))
			draw_text_shadow(pos + Vector2(-72.0, -58.0), "ROLL", 22, Color(1.0, 0.95, 0.26))
		elif type == "ronaldo_sweep" and age >= 0.0:
			var pos = Vector2(fx["pos"])
			var radius = float(fx.get("radius", 140.0))
			draw_circle(pos, radius, Color(1.0, 0.24, 0.12, 0.1))
			draw_arc(pos, radius, -0.4, PI * 1.35, 48, Color(1.0, 0.72, 0.18, 0.58), 5.0, true)
			var frame = clamp(int(fx.get("frame", 1)), 0, ronaldo_sweep_frames.size() - 1)
			if frame >= 0 and frame < ronaldo_sweep_frames.size():
				draw_tex_fit_center(ronaldo_sweep_frames[frame], pos + Vector2(-28.0, -36.0), Vector2(270.0, 172.0))
		elif type == "messi_wowo":
			var pos = Vector2(fx["pos"])
			var fall = clamp(age / 0.44, 0.0, 1.0)
			var bun_pos = pos + Vector2(0.0, -260.0 * (1.0 - fall))
			var radius = float(fx.get("radius", 160.0))
			draw_circle(pos, radius, Color(0.3, 0.95, 1.0, 0.08))
			draw_arc(pos, radius, 0.0, TAU, 96, Color(0.52, 0.94, 1.0, 0.45), 5.0, true)
			draw_tex_fit_center(tex_wowo, bun_pos, Vector2(118.0 + 46.0 * fall, 118.0 + 46.0 * fall))

	draw_skill_drag_preview()


func draw_skill_drag_preview() -> void:
	if not skill_dragging:
		return
	var profile = selected_profile()
	var id = str(profile.get("id", "messi"))
	var pos = clamp_skill_target(skill_drag_pos)
	if id == "messi":
		draw_circle(pos, 172.0, Color(0.3, 0.95, 1.0, 0.1))
		draw_arc(pos, 172.0, 0.0, TAU, 96, Color(0.6, 0.96, 1.0, 0.46), 4.0, true)
		draw_tex_fit_center(tex_wowo, pos, Vector2(120.0, 120.0), Color(1.0, 1.0, 1.0, 0.62))
	elif id == "neymar":
		var rect = Rect2(Vector2(pos.x - 190.0, 250.0), Vector2(380.0, 860.0))
		draw_rect(rect, Color(0.1, 0.88, 1.0, 0.12), true)
		draw_rect(rect, Color(0.35, 0.95, 1.0, 0.5), false, 3.0)
		if not neymar_roll_frames.is_empty():
			draw_tex_fit_center(neymar_roll_frames[0], Vector2(pos.x, 1060.0), Vector2(250.0, 150.0), Color(1.0, 1.0, 1.0, 0.62))
	else:
		for i in range(3):
			var p = Vector2(clamp(pos.x + (float(i) - 1.0) * 135.0, 110.0, SCREEN_SIZE.x - 110.0), 540.0 + float(i) * 145.0)
			draw_circle(p, 126.0, Color(1.0, 0.26, 0.1, 0.12))
			draw_arc(p, 126.0, -0.4, PI * 1.35, 48, Color(1.0, 0.72, 0.18, 0.52), 4.0, true)
			var frame = min(i + 1, ronaldo_sweep_frames.size() - 1)
			if frame >= 0 and frame < ronaldo_sweep_frames.size():
				draw_tex_fit_center(ronaldo_sweep_frames[frame], p + Vector2(-22.0, -34.0), Vector2(240.0, 152.0), Color(1.0, 1.0, 1.0, 0.58))


func draw_football_variant(pos: Vector2, radius: float, spin: float, kind: String, tint: Color) -> void:
	var tex = tex_ball
	if kind == "fire" and tex_fire_ball != null:
		tex = tex_fire_ball
	if tex != null:
		draw_tex_center(tex, pos, Vector2(radius * 3.0, radius * 3.0), tint)
	else:
		draw_circle(pos, radius, tint)
		draw_circle(pos, radius, Color(0.04, 0.05, 0.06), false, 2.0)
	if kind == "fire":
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
	draw_text_shadow(Vector2(326.0, 1207.0), "AIM", 20, Color.WHITE)
	draw_meter(Rect2(Vector2(326.0, 1220.0), Vector2(200.0, 22.0)), abs(aim_x), Color(0.22, 0.9, 1.0, 0.95))
	draw_text_shadow(Vector2(536.0, 1242.0), "<" if aim_x < -0.08 else ">" if aim_x > 0.08 else "-", 24, Color(0.55, 0.96, 1.0))
	draw_skill_panel()

	if feedback_timer > 0.0:
		var fb_color = Color(1.0, 0.92, 0.12, min(feedback_timer, 1.0))
		draw_text_shadow(Vector2(380.0, 180.0), last_feedback, 24, fb_color)
	if game_over:
		draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.0, 0.0, 0.0, 0.64), true)
		draw_text_shadow(Vector2(188.0, 520.0), "GAME OVER", 48, Color(1.0, 0.28, 0.24))
		draw_text_shadow(Vector2(212.0, 590.0), "Final Score: " + str(score), 26, Color.WHITE)
		draw_text_shadow(Vector2(150.0, 650.0), "Tap to choose again", 26, Color(0.8, 0.94, 1.0))
	draw_skill_banner()


func draw_skill_banner() -> void:
	if skill_banner_timer <= 0.0:
		return
	var t = clamp(skill_banner_age / 1.15, 0.0, 1.0)
	var alpha = sin(t * PI)
	var c = skill_banner_color
	c.a = alpha
	var y = 420.0 - 28.0 * alpha
	draw_rect(Rect2(Vector2(0.0, y - 54.0), Vector2(SCREEN_SIZE.x, 104.0)), Color(0.0, 0.0, 0.0, 0.38 * alpha), true)
	draw_text_center_shadow(y + 18.0, skill_banner_text, 48, c, Color(0.0, 0.0, 0.0, 0.92 * alpha))
	draw_text_center_shadow(y + 55.0, "SPECIAL MOVE", 20, Color(1.0, 0.92, 0.25, 0.9 * alpha))


func draw_meter(rect: Rect2, value: float, color: Color) -> void:
	draw_rect(rect, Color(0.02, 0.03, 0.04, 0.9), true)
	draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), Vector2((rect.size.x - 8.0) * clamp(value, 0.0, 1.0), rect.size.y - 8.0)), color, true)
	draw_rect(rect, Color(1, 1, 1, 0.45), false, 3.0)


func power_color(power: float) -> Color:
	return Color(0.18 + power * 0.82, 0.92 - power * 0.28, 0.15, 0.95)


func draw_skill_panel() -> void:
	var capacity = focus_capacity()
	var cost = skill_cost()
	var ready = focus >= cost
	var rect = skill_panel_rect()
	draw_panel(rect, Color(0.02, 0.03, 0.05, 0.78), Color(0.3, 0.95, 1.0, 0.65) if ready else Color(1.0, 1.0, 1.0, 0.22))
	draw_tex_center(tex_slow_icon, rect.position + Vector2(26.0, 28.0), Vector2(38.0, 38.0), Color.WHITE if ready else Color(0.55, 0.55, 0.55, 0.65))
	var charge_count = max(1, int(round(capacity / cost)))
	for i in range(charge_count):
		var pip_w = 70.0 if charge_count == 1 else 32.0
		var pip_rect = Rect2(rect.position + Vector2(56.0 + float(i) * 40.0, 30.0), Vector2(pip_w, 12.0))
		var pip_value = clamp((focus - float(i) * cost) / cost, 0.0, 1.0)
		draw_meter(pip_rect, pip_value, Color(0.2, 0.9, 1.0, 0.95))
	draw_text_shadow(rect.position + Vector2(54.0, 24.0), "DRAG", 16, Color.WHITE if ready else Color(0.7, 0.7, 0.7))


func skill_panel_rect() -> Rect2:
	return Rect2(Vector2(552.0, 1192.0), Vector2(146.0, 56.0))


func select_card_rect(index: int) -> Rect2:
	return Rect2(Vector2(42.0, 210.0 + float(index) * 294.0), Vector2(636.0, 250.0))


func draw_character_select() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0, 0, 0, 0.42), true)
	draw_text_center_shadow(96.0, "SELECT STRIKER", 42, Color.WHITE)
	draw_text_center_shadow(146.0, "FACTOS FOOTBALL", 20, Color(0.84, 0.95, 1.0))
	for i in range(character_defs.size()):
		draw_character_card(i)
	draw_panel(Rect2(Vector2(92.0, 1164.0), Vector2(536.0, 72.0)), Color(0.02, 0.08, 0.12, 0.88), Color(0.4, 0.95, 1.0, 0.75))
	draw_text_center_shadow(1214.0, "START", 32, Color(1.0, 0.92, 0.22))


func draw_character_card(index: int) -> void:
	var rect = select_card_rect(index)
	var profile = character_defs[index]
	var selected = index == selected_character
	var border = Color(profile.get("color", Color.WHITE), 0.8 if selected else 0.28)
	draw_panel(rect, Color(0.02, 0.04, 0.06, 0.82 if selected else 0.68), border)
	var id = str(profile.get("id", "messi"))
	var frames: Array = character_frames.get(id, [])
	if not frames.is_empty():
		draw_tex_fit_center(frames[2], rect.position + Vector2(128.0, 132.0), Vector2(200.0, 214.0))
	draw_text_shadow(rect.position + Vector2(250.0, 54.0), str(profile.get("name", "")), 32, Color.WHITE)
	draw_text_shadow(rect.position + Vector2(250.0, 91.0), str(profile.get("role", "")), 21, Color(profile.get("color", Color.WHITE)))
	draw_text_shadow(rect.position + Vector2(250.0, 130.0), "POWER  " + stat_bars(float(profile.get("power", 1.0)), 0.8, 1.3), 18, Color.WHITE)
	draw_text_shadow(rect.position + Vector2(250.0, 164.0), "AIM     " + stat_bars(float(profile.get("aim", 1.0)), 0.8, 1.45), 18, Color.WHITE)
	draw_text_shadow(rect.position + Vector2(250.0, 204.0), skill_name(profile), 22, Color(1.0, 0.92, 0.22))


func stat_bars(value: float, low: float, high: float) -> String:
	var count = int(round(clamp((value - low) / (high - low), 0.0, 1.0) * 5.0))
	var s = ""
	for i in range(5):
		s += "|" if i < count else "."
	return s

