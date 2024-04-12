extends Node

var BG : TextureRect
var ripple_time : float = 1.25
#var time_elapsed : float = 0.0
var max_inst : int = 8
var num_inst : int = 0

var mouse_pos;

var wave_position : PackedVector2Array
var wave_timer : Array
var time_elapsed : PackedFloat32Array = []

func _process(_delta: float) -> void:
	# First check if there are too many ripples
	# If there are too many delete the oldest one
	if num_inst > max_inst:
		decrease_num_inst()
		wave_timer[0].free()
		wave_timer.pop_front()
		time_elapsed.remove_at(0)
		time_elapsed.resize(num_inst)
		wave_position.remove_at(0)
		wave_position.resize(num_inst)
	# Then for each timer added from the ButtonProperties script
	# Update CPU data to send to the GPU
	for timer in wave_timer:
		check_timer(timer)
		set_pos(wave_position)
		# timers in the for loop will be freed from memory in check_timer
		# check if timer stil exists, if it does, update time_elapsed
		if timer != null:
			update_time_elapsed(timer, wave_timer.find(timer))

func set_pos(posArray : PackedVector2Array) -> void:
	if BG != null:
		# Send data to GPU
		print(posArray)
		BG.material.set("shader_parameter/hover", posArray)

func check_timer(timer : Timer) -> void:
	# If it's a fresh timer add its time to the GPU data array
	if timer.wait_time == timer.time_left:
		time_elapsed.append(timer.get_wait_time() - timer.get_time_left())
	# If the timer has run its time:
	# clean up arrays, free the timer from memory, reduce the count of ripples
	if timer.is_stopped():
		time_elapsed.remove_at(wave_timer.find(timer))
		wave_position.remove_at(wave_timer.find(timer))
		wave_timer.pop_at(wave_timer.find(timer))
		timer.free()
		decrease_num_inst()
		
func update_time_elapsed(timer : Timer, index : int) -> void:
	if BG != null:
		var time_left : float = timer.get_wait_time() - timer.get_time_left()
		# this matches the time_elapsed index with the correct timer index
		time_elapsed[index] = time_left
		# Send data to GPU
		BG.material.set("shader_parameter/time_since_hover", time_elapsed)
		
func inst_ripple(pos : Vector2) -> void:
	# Init timer OBJ
	var timer = Timer.new()
	timer.wait_time = ripple_time
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	# Tell the manager abt it and related data
	wave_timer.append(timer)
	wave_position.append(pos)
	increase_num_inst()
	
func inst_ripple_click(pos : Vector2) -> void:
	# Init timer OBJ
	var timer = Timer.new()
	timer.wait_time = ripple_time * 14.0
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	# Tell the manager abt it and related data
	wave_timer.append(timer)
	wave_position.append(pos)
	increase_num_inst()

func decrease_num_inst() -> void:
	num_inst -= 1
	BG.material.set("shader_parameter/num_inst", num_inst)
	
func increase_num_inst() -> void:
	num_inst += 1
	BG.material.set("shader_parameter/num_inst", num_inst)
