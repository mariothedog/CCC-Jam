extends CanvasLayer

func _ready():
	$"Hacking GUI".visible = false

func _input(_event):
	if Input.is_action_just_pressed("open_console"):
		toggle_console()

func toggle_console():
	$"Hacking GUI".visible = not $"Hacking GUI".visible
	var tree = get_tree()
	tree.paused = not tree.paused
	
	if tree.paused:
		$"Open SFX".play()
