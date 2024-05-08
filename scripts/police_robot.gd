extends NPC

@export var powered_on: bool = false
@export var power_on_time: int
@export var light_control: AnimationPlayer
@export var light_animation: String
@export var probe: Node3D
@export var target: Node3D
@export var watching: Node3D
@export var behavior: Node
@export var detector: Node3D
@export var floor_ray_cast: RayCast3D
@export var nav_check_ray: RayCast3D
@export var head: BoneAttachment3D


func _ready():
	if !is_multiplayer_authority():
		return
	power_on_time = GameManager.rng.randi_range(0,60)

func _physics_process(delta):
	animate()
	if !is_multiplayer_authority():
		return
	if powered_on:
		if detector.is_colliding() and watching == null:
			detect_player(detector.get_collider(0))
		elif detector.is_colliding():
			target = null
		if behavior.current_behavior == "wander":
			navigation_path(delta)
			#print(velocity)
			watching = null
			probe.global_position = probe.global_position.lerp(global_position+Vector3.UP*10.85+global_basis.z*-4.04+global_basis.x*-3.633,delta)
			probe.global_rotation = global_rotation
			$ShootTimer.stop()
		elif behavior.current_behavior == "watch" and watching != null:
			probe.global_position = probe.global_position.lerp(watching.global_position+Vector3.UP*10.85+watching.global_basis.z*3.633,delta)
			probe.look_at(watching.global_position)
			probe.rotate(probe.basis.x,2*PI)
			velocity = velocity.lerp(Vector3(0,velocity.y,0),delta*15)
			#print(velocity)
	elif GameManager.weather_manager.time_of_day>power_on_time:
		powered_on = true

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * 4
	else:
		velocity.y =0
		#apply_floor_snap()
	velocity_export = velocity
	#print(velocity)
	move_and_slide()

func navigation_path(delta):
	var direction = Vector3()
	#print(nav.target_position)
	direction = nav.get_next_path_position() - global_position
	if nav.distance_to_target ( )<2:
		direction = Vector3.ZERO
	#direction.y = 0
	direction = direction.normalized()
	#print("currentPos:"+str(global_position))
	#print("nextPos:"+str(nav.get_next_path_position()))
	velocity = velocity.lerp(direction*SPEED*2,delta*15)
	var original_rotation = global_rotation
	var look_to = (global_position-direction.normalized()*100)
	look_to.y = global_position.y
	if (look_to - global_position).length() > 1:
		look_at(look_to)
	var target_rotation = global_rotation
	global_rotation = original_rotation
	global_rotation.y = lerp_angle(global_rotation.y,target_rotation.y,delta*1)
	global_rotation.x = lerp_angle(global_rotation.x,target_rotation.x,delta*1)
	global_rotation.z = lerp_angle(global_rotation.z,0,delta*14)

func animate():
	if !powered_on and current_animation != "off":
		current_animation = "off"
		light_animation = "off"
		animation_player.play(current_animation,.1,1.0,false)
		light_control.play(light_animation,.1)
		return
	elif is_on_floor() and powered_on:
		if velocity_export.length()>2 and current_animation != "walk":
			current_animation = "walk"
			animation_player.play(current_animation,.1,1.0,false)
			animation_player.speed_scale = velocity_export.length()/4
		elif velocity_export.length()<=2 and current_animation != "idle":
			current_animation = "idle"
			animation_player.play(current_animation,.1,1.0,false)
			animation_player.speed_scale = 1
	if powered_on and light_animation != "on":
		light_animation = "on"
		light_control.play(light_animation,.1)



func detect_player(body):
	if !is_multiplayer_authority():
		return
	if body is PlayerCharacter:
		if !powered_on:
			return
		target = body
		watching = target
		behavior.determine_behavior()
	else:
		target = null

func _on_shoot_timer_timeout():
	#$ShootTimer.start(0.5)
	GameManager.rpc("shoot","res://Assets/prefabs/laser.tscn",probe.global_position,probe.global_basis.z)
