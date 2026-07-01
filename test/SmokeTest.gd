extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.load_menu_assets()
	scene.setup_menu_audio()
	scene.build_character_defs()
	if scene.match_assets_loaded:
		printerr("ASSERT FAIL: match assets loaded before gameplay")
		quit(1)
		return
	if scene.menu_bgm_player.stream == null or scene.sfx_button.stream == null:
		printerr("ASSERT FAIL: menu audio streams did not load")
		quit(1)
		return
	scene.restart_game()

	if scene.menu_bgm_player.stream == null or scene.bgm_player.stream == null or scene.sfx_button.stream == null or scene.sfx_kick.stream == null or scene.sfx_skill_messi.stream == null or scene.sfx_skill_ronaldo.stream == null or scene.sfx_skill_neymar.stream == null:
		printerr("ASSERT FAIL: audio streams did not load")
		quit(1)
		return
	if scene.menu_bgm_player.stream is AudioStreamMP3 and not scene.menu_bgm_player.stream.loop:
		printerr("ASSERT FAIL: menu music did not enable looping")
		quit(1)
		return
	if scene.bgm_player.stream is AudioStreamMP3 and not scene.bgm_player.stream.loop:
		printerr("ASSERT FAIL: gameplay music did not enable looping")
		quit(1)
		return
	if scene.sfx_kick.volume_db < 1.5:
		printerr("ASSERT FAIL: kick sound was not boosted enough")
		quit(1)
		return
	scene.set_bgm_volume(0.35)
	if abs(scene.bgm_volume - 0.35) > 0.001 or scene.bgm_player.volume_db >= scene.GAME_BGM_BASE_DB:
		printerr("ASSERT FAIL: BGM volume did not apply")
		quit(1)
		return
	scene.set_bgm_volume(0.72)
	scene.open_settings_menu()
	if not scene.settings_open:
		printerr("ASSERT FAIL: settings menu did not open")
		quit(1)
		return
	var paused_elapsed = scene.elapsed
	scene._process(1.0)
	if abs(scene.elapsed - paused_elapsed) > 0.001:
		printerr("ASSERT FAIL: settings menu did not pause gameplay")
		quit(1)
		return
	scene.handle_settings_press(scene.settings_continue_rect().get_center())
	if scene.settings_open:
		printerr("ASSERT FAIL: settings menu did not close")
		quit(1)
		return
	var settings_touch = InputEventScreenTouch.new()
	settings_touch.pressed = true
	settings_touch.position = scene.settings_button_touch_rect().get_center()
	if not scene.handle_settings_shortcut(settings_touch) or not scene.settings_open:
		printerr("ASSERT FAIL: settings button touch did not open menu")
		quit(1)
		return
	scene.handle_settings_press(scene.settings_continue_rect().get_center())
	var viewport_corner_touch = InputEventScreenTouch.new()
	viewport_corner_touch.pressed = true
	viewport_corner_touch.position = Vector2(920.0, 420.0)
	if not scene.is_settings_button_press(viewport_corner_touch):
		printerr("ASSERT FAIL: viewport-scaled corner touch did not hit settings")
		quit(1)
		return
	if scene.shot_stock != scene.MAX_SHOT_STOCK or scene.active_ball.is_empty():
		printerr("ASSERT FAIL: shot stock did not initialize")
		quit(1)
		return
	if scene.difficulty_defs.size() != 3 or scene.level_duration() > 100.0:
		printerr("ASSERT FAIL: difficulty setup did not initialize to rookie pacing")
		quit(1)
		return
	if scene.input_lock_timer <= 0.0:
		printerr("ASSERT FAIL: restart did not lock starter input")
		quit(1)
		return
	scene.input_lock_timer = 0.0

	scene.swipe_points = [
		scene.STRIKE_CENTER,
		scene.STRIKE_CENTER + Vector2(36.0, -260.0),
		scene.STRIKE_CENTER + Vector2(120.0, -520.0),
	]
	var path = scene.build_swipe_path(0.74)
	if path.size() < 20 or path[0] != scene.STRIKE_CENTER:
		printerr("ASSERT FAIL: swipe path did not build correctly")
		quit(1)
		return
	var path_dir = (path[path.size() - 1] - path[0]).normalized()
	var first_dir = (path[1] - path[0]).normalized()
	if path_dir.distance_to(first_dir) > 0.01:
		printerr("ASSERT FAIL: swipe path was not a straight shot")
		quit(1)
		return
	if path[path.size() - 1].distance_to(path[0]) < 1400.0:
		printerr("ASSERT FAIL: short swipe did not continue into a full shot")
		quit(1)
		return

	scene.swipe_points = [
		scene.STRIKE_CENTER,
		scene.STRIKE_CENTER + Vector2(340.0, -12.0),
	]
	var right_path = scene.build_swipe_path(0.62)
	if right_path[right_path.size() - 1].x <= scene.STRIKE_CENTER.x + 220.0:
		printerr("ASSERT FAIL: flat right shot did not preserve 180-degree range")
		quit(1)
		return

	scene.swipe_points = [
		scene.STRIKE_CENTER,
		scene.STRIKE_CENTER + Vector2(-340.0, -12.0),
	]
	var left_path = scene.build_swipe_path(0.62)
	if left_path[left_path.size() - 1].x >= scene.STRIKE_CENTER.x - 220.0:
		printerr("ASSERT FAIL: flat left shot did not preserve 180-degree range")
		quit(1)
		return

	var messy_points = [
		scene.STRIKE_CENTER,
		scene.STRIKE_CENTER + Vector2(120.0, -60.0),
		scene.STRIKE_CENTER + Vector2(0.0, -120.0),
		scene.STRIKE_CENTER + Vector2(120.0, -180.0),
		scene.STRIKE_CENTER + Vector2(-80.0, -110.0),
		scene.STRIKE_CENTER + Vector2(60.0, -40.0),
	]
	if not scene.is_invalid_gesture(messy_points):
		printerr("ASSERT FAIL: messy gesture was not rejected")
		quit(1)
		return

	scene.shot_balls.clear()
	scene.active_ball = {
		"t": 1.0,
		"side": 0.0,
		"pos": scene.STRIKE_CENTER,
		"spin": 0.0
	}
	scene.start_charge(scene.STRIKE_CENTER)
	scene.add_swipe_point(scene.STRIKE_CENTER + Vector2(0.0, -190.0))
	scene.gesture_time = scene.MAX_GESTURE_TIME - 0.01
	scene._process(0.02)
	if scene.is_charging or scene.shot_balls.is_empty():
		printerr("ASSERT FAIL: gesture timeout did not auto shoot")
		quit(1)
		return
	if scene.shot_stock != scene.MAX_SHOT_STOCK - 1:
		printerr("ASSERT FAIL: shot did not consume a stocked ball")
		quit(1)
		return
	scene.shot_balls.clear()

	scene.shot_stock = 0
	scene.active_ball.clear()
	scene.start_charge(scene.STRIKE_CENTER + Vector2(0.0, -180.0))
	if scene.is_charging:
		printerr("ASSERT FAIL: charging started with no stocked balls")
		quit(1)
		return
	scene.player_anim = 0.0
	scene.shot_recharge_timer = 0.01
	scene._process(0.02)
	if scene.shot_stock != 1 or scene.active_ball.is_empty():
		printerr("ASSERT FAIL: shot stock did not recharge")
		quit(1)
		return

	scene.start_charge(scene.STRIKE_CENTER + Vector2(0.0, -180.0))
	var old_target = scene.aim_target_direction
	scene.add_swipe_point(scene.STRIKE_CENTER + Vector2(64.0, -180.0))
	if old_target.distance_to(scene.aim_target_direction) < 0.02:
		printerr("ASSERT FAIL: small aim adjustment did not update target direction")
		quit(1)
		return
	scene.is_charging = false
	scene.charge = 0.0
	scene.swipe_points.clear()

	scene.shot_balls.clear()
	scene.active_ball = {
		"t": 1.0,
		"side": 0.0,
		"pos": scene.STRIKE_CENTER,
		"spin": 0.0
	}
	scene.shot_stock = scene.MAX_SHOT_STOCK
	scene.scatter_timer = scene.POWERUP_DURATION
	scene.kick_active_ball(scene.MAX_CHARGE, 0.86, Vector2(0.0, -1.0))
	if scene.shot_balls.size() != 3:
		printerr("ASSERT FAIL: scatter powerup did not fire three balls")
		quit(1)
		return
	scene.shot_balls.clear()
	scene.scatter_timer = 0.0

	scene.active_ball = {
		"t": 1.0,
		"side": 0.0,
		"pos": scene.STRIKE_CENTER,
		"spin": 0.0
	}
	scene.shot_stock = scene.MAX_SHOT_STOCK
	scene.big_ball_timer = scene.POWERUP_DURATION
	scene.kick_active_ball(scene.MAX_CHARGE, 0.86, Vector2(0.0, -1.0))
	if scene.shot_balls.is_empty() or float(scene.shot_balls[0].get("radius", 0.0)) < 20.0:
		printerr("ASSERT FAIL: big ball powerup did not enlarge shot")
		quit(1)
		return
	scene.shot_balls.clear()
	scene.big_ball_timer = 0.0

	scene.shot_stock = 0
	scene.no_cd_timer = scene.POWERUP_DURATION
	scene.active_ball.clear()
	scene.start_charge(scene.STRIKE_CENTER + Vector2(0.0, -180.0))
	scene.release_shot(scene.STRIKE_CENTER + Vector2(0.0, -260.0))
	if scene.shot_balls.is_empty() or scene.shot_stock != 0:
		printerr("ASSERT FAIL: no-cd powerup did not allow free shot")
		quit(1)
		return
	scene.shot_balls.clear()
	scene.no_cd_timer = 0.0

	scene.powerups.clear()
	scene.activate_powerup("scatter", scene.STRIKE_CENTER + Vector2(0.0, -260.0))
	if scene.scatter_timer <= 0.0:
		printerr("ASSERT FAIL: powerup activation did not start timer")
		quit(1)
		return
	scene.scatter_timer = 0.0

	scene.enemies.append({
		"id": 1,
		"pos": scene.STRIKE_CENTER + Vector2(0.0, -140.0),
		"speed": 0.0,
		"radius": 32.0,
		"phase": 0.0,
		"wobble": 0.0
	})
	var ball = {
		"pos": scene.STRIKE_CENTER + Vector2(0.0, -140.0),
		"vel": Vector2.ZERO,
		"accel": Vector2.ZERO,
		"life": 1.0,
		"radius": 14.0,
		"trail": [],
		"spin": 0.0,
		"hits": 0,
		"hit_ids": [],
		"damage": 1.0,
		"quality": 0.9,
		"pierce_limit": 2
	}
	scene.check_ball_enemy_hits(ball)

	if scene.score <= 0 or scene.enemies.size() != 0:
		printerr("ASSERT FAIL: hit did not score and clear enemy")
		quit(1)
		return

	print("ASSERT PASS: audio, straight shot, aim smoothing, shot stock, powerups, difficulty, timeout, and hit scoring")
	quit(0)

