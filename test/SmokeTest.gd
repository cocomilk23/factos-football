extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.load_assets()
	scene.setup_audio()
	scene.build_character_defs()
	scene.restart_game()

	if scene.bgm_player.stream == null or scene.sfx_kick.stream == null or scene.sfx_skill_messi.stream == null or scene.sfx_skill_ronaldo.stream == null or scene.sfx_skill_neymar.stream == null:
		printerr("ASSERT FAIL: audio streams did not load")
		quit(1)
		return

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
	for i in range(1, path.size()):
		if path[i].y > path[i - 1].y + 0.01:
			printerr("ASSERT FAIL: swipe path moved backward at point ", i)
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
		"curve": 0.0,
		"pierce_limit": 2
	}
	scene.check_ball_enemy_hits(ball)

	if scene.score <= 0 or scene.enemies.size() != 0:
		printerr("ASSERT FAIL: hit did not score and clear enemy")
		quit(1)
		return

	print("ASSERT PASS: audio, 180-degree swipe path, and hit scoring")
	quit(0)

