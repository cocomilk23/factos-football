extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.restart_game()

	scene.active_ball = {
		"t": 1.0,
		"side": 0.0,
		"pos": scene.STRIKE_CENTER,
		"spin": 0.0
	}
	var quality = scene.get_timing_quality(scene.active_ball)
	if quality < 0.99:
		printerr("ASSERT FAIL: perfect strike quality was ", quality)
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
		"hits": 0
	}
	scene.check_ball_enemy_hits(ball)

	if scene.score <= 0 or scene.enemies.size() != 0:
		printerr("ASSERT FAIL: hit did not score and clear enemy")
		quit(1)
		return

	print("ASSERT PASS: timing and hit scoring")
	quit(0)

