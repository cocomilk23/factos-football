extends SceneTree

var scene: Node
var elapsed = 0.0


func _initialize() -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.selected_character = 0
	scene.restart_game()


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed >= 2.0:
		quit(0)
	return false
