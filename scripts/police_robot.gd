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
var footstep_soundoff = false
var stride = 0

var walk_time = 0

func _ready():
	probe.reparent(get_node("/root"))
	probe.global_position = global_position + Vector3.UP*5
	animation_player.play("off",.1,1.0,false)
	light_control.play("off",.1)
	if !is_multiplayer_authority():
		return
	power_on_time = GameManager.rng.randi_range(0,60)
	
func _process(delta):
	animate()	

func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	if powered_on:
		if behavior.current_behavior == "wander":
			if watching != null:
				walk_time = 0
				watching = null
				footstep_soundoff = false
				$ShootTimer.stop()
			#if walk_time == 0:
			#	navigation_path(delta)
			walk_time+=delta
			navigation_path(delta)
			if walk_time<1:
				velocity = velocity.lerp(Vector3.ZERO,delta*15)
			elif walk_time>=1 and walk_time<2:
				if !footstep_soundoff:
					footstep_soundoff = true
					SoundManager.rpc("play_sound_3d","res://assets/sounds/sfx/police_mech_1/step.mp3", 10, 1, 0.1, 5, 120, global_position)
				look_at_target(delta)
				velocity = velocity.lerp(direction*SPEED*2,delta*7)
			elif walk_time>=2:
				walk_time = 0
				footstep_soundoff = false
				match stride:
					0:
						stride = 1
					1:
						stride = 0
			#print(velocity)
			probe.global_position = probe.global_position.lerp(global_position+Vector3.UP*10.85+global_basis.z*-4.04+global_basis.x*-3.633,delta)
			probe.global_rotation = global_rotation
		elif behavior.current_behavior == "watch" and watching != null:
			probe.global_position = probe.global_position.lerp(watching.global_position+Vector3.UP*10.85+watching.global_basis.z*3.633,delta)
			probe.look_at(watching.global_position)
			probe.look_at(probe.global_position+probe.global_basis.z*100)
			
			velocity = velocity.lerp(Vector3(0,velocity.y,0),delta*15)
			#print(velocity)
	elif GameManager.weather_manager.time_of_day>power_on_time:
		powered_on = true
		$Engine.volume_db = 10
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * 4
	else:
		velocity.y =0
		#apply_floor_snap()
	velocity_export = velocity
	#print(velocity)
	move_and_slide()

func animate():
	if is_on_floor() and powered_on:
		if velocity_export.length()>2:
			animation_player.speed_scale = velocity_export.length()/7
			if stride == 1 and animation_player.current_animation != "walk":
				animation_player.play("walk",.5,1.0,false)
				animation_player.seek(.8333)
			elif stride == 0 and animation_player.current_animation != "walk":
				animation_player.play("walk",.5,1.0,false)
		elif velocity_export.length()<=2:
			if behavior.current_behavior == "watch":
				animation_player.seek(0)
			animation_player.play("idle",1,1.0,false)
			animation_player.speed_scale = 1
	if powered_on and light_animation != "on":
		light_animation = "on"
		light_control.play(light_animation,.1)

func detect_player(body):
	if !is_multiplayer_authority():
		return
	if body is PlayerCharacter:
		target = body
		watching = target
		behavior.determine_behavior()
	else:
		target = null

func _on_shoot_timer_timeout():
	#$ShootTimer.start(0.5)
	GameManager.rpc("shoot","res://Assets/prefabs/laser.tscn",probe.global_position,probe.global_basis.z,probe.global_basis.x)


func _on_detector_2_body_entered(body):
	if powered_on:
		if watching == null:
			detect_player(body)
		elif body == watching:
			return
		else:
			target = null


func _on_detector_2_body_exited(body):
	if target == body:
		target = null
