extends Control

signal exit_pressed

onready var console = get_node("Console")
var success_text = "The \"%s\" command has been used successfully."
var invalid_syntax_text = "Please use the correct syntax."
var not_recognised_command_text = "\'%s\' is not recognised as an internal or external command.  Please see the \'help\' command."
var not_recognised_variable_text = "\'%s\' is not recognised as an internal or external variable. Please see the \'variables\' command."
var command

func _on_Console_command_entered(command):
	$"Enter SFX".play()
	parse_command(command)

func parse_command(text):
	text = text.strip_edges(true, true)
	
	# Separate the command into words. E.g. "set player_max_speed 100" will return ["set", "player_max_speed", "100"].
	var separated_command = text.split(" ")
	
	# Lower case to ensure that even if the player adds an extra capital somewhere that it will still work fine.
	var command_str = separated_command[0].to_lower()
	command = global.command.get_command(command_str)
	# If the command doesn't exist.
	if not command:
		console.output_error(not_recognised_command_text % command_str)
		return
	
	if separated_command.size() < command.min_parameters:
		console.output_error(invalid_syntax_text)
		return
	
	# Different commands do different things.
	match command.aliases[0]:
		"set":
			var variable_str = separated_command[1].to_lower()
			var variable = global.gamevar.get_gamevar(variable_str)
			if not variable:
				console.output_error(not_recognised_variable_text % variable_str)
				return
			
			var new_value = separated_command[2].to_lower()
			variable.value = new_value
			
			console.output_text("[i]%s has been set to %s.[/i]" % [variable_str, new_value], false)
			
			if not variable.is_value_valid():
				console.output_text("The data type used is invalid.", false)
			# TODO - Could be cool to add some sort of in game effect (increased amount of visual artifacts?) if the player inputs the wrong value.
		"get":
			var variable_str = separated_command[1].to_lower()
			var variable = global.gamevar.get_gamevar(variable_str)
			if not variable:
				console.output_error(not_recognised_variable_text % variable_str)
				return
			
			console.output_text(variable.value, false)
		"exit":
			exit()
		"restart":
			exit()
			restart()
		"help":
			var output
			if separated_command.size() > 1:
				var cmd_str = separated_command[1].to_lower()
				var cmd = global.command.get_command(cmd_str)
				if not cmd:
					output = not_recognised_variable_text % cmd_str
				else:
					output = str("Syntax: ", cmd.syntax)
			else:
				output = "Commands:\n"
				for command in global.commands_list:
					output += str(command.aliases[0], " - ", command.description, "\n")
				output = output.trim_suffix("\n")
			
			console.output_text(output, false)
		"variables":
			var output = "Variables:\n"
			for variable in global.gamevars_list:
				if variable.writable:
					output += "%s : %s - %s\n" % [variable.aliases[0], variable.type, variable.description]
			
			output = output.trim_suffix("\n")
			console.output_text(output, false)
		"goto":
			var level_number = separated_command[1]
			if not level_number.is_valid_integer():
				console.output_error(invalid_syntax_text)
				return
			
			var num = int(level_number)
			if not num in [1, 2, 3, 4, 5, 6]:
				console.output_error("That level does not exist!")
				return
			global.go_to_level(num)

func exit():
	emit_signal("exit_pressed")

func _on_Exit_pressed():
	exit()

func restart():
	global.complete_restart()

func _on_Console_input_text_changed():
	var text = console.get_node("VBoxContainer/Input").text
	if text.length() > 0:
		var new_char = text[-1]
		if new_char == " ":
			$"Space Press SFX".play()
		else:
			[$"Key Press SFX", $"Key Press 2 SFX"][global.random_int(0, 2)].play()
	else:
		[$"Key Press SFX", $"Key Press 2 SFX"][global.random_int(0, 2)].play()
