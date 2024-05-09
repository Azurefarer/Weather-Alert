class_name PlayerCharacter extends CharacterBody3D

const MOVE_SPEED = 10
const MAX_SPEED = 200
const FALL_SPEED = 200
const TURN_SPEED = 1
const DRAG = 10
@export var jump_index = 1
@export var gliding: bool
@export var velocity_export: Vector3
var run_force : float = 7000.0 # In newtons
var walk_force : float = 3500.0 # In newtons
var player_move_force : float
var mouse_delta: Vector2
var move_direction = Vector3.ZERO
var flattening = false
var begun_falling = 0.0
@export var camera: Camera3D
@export var camera_track: RayCast3D
@export var camera_track2: RayCast3D
@export var stats: Node
var can_snap = false
var jumping = false
var flight_angle: float
var flight_speed: float
var landing = false
var holding_item : Item = null
var interacting = null
@export var land_power = 0
@export var rotate_check_ray: RayCast3D
@export var ceil_check_ray: RayCast3D
@export var floor_check_ray: RayCast3D
@export var snap_check_ray: RayCast3D
var tilt = -.6
var obstruction_zoom: float
var targeted_item: Node3D
@export var left_hand_ik: SkeletonIK3D
@export var right_hand_ik: SkeletonIK3D
@export var left_hand_ik_active_target: Node3D
@export var right_hand_ik_active_target: Node3D
@export var fire_extinguisher_ik_pos_left: Node3D
@export var fire_extinguisher_ik_pos_right: Node3D
@export var umbrella_hang_ik_pos_left: Node3D
@export var umbrella_hang_ik_pos_right: Node3D
@export var umbrella_ik_pos_left: Node3D
@export var umbrella_ik_pos_right: Node3D
@export var glider_ik_pos_left: Node3D
@export var glider_ik_pos_right: Node3D
@export var left_hand_physics_bone: PhysicalBone3D
@export var right_hand_physics_bone: PhysicalBone3D
@export var root_physics_bone: PhysicalBone3D
@export var right_hand_bone_attach: BoneAttachment3D
var dive_bomb_momentum:= 0.0

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	if !is_multiplayer_authority():
		camera.current = false
		return
	camera.current = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_multiplayer_authority():
		return
	GameManager.player = self
	while GameManager.ship == null:
		await get_tree().physics_frame
	#if GameManager.game_mode == "game":
		#GameManager.ship.get_node("Scalar/Players").global_position
		#GameManager.level.add_child(preload("res://Assets/Scenes/World.tscn").instantiate())
		# NOTE: maybe makes desync between world weather systems
	print("authority: "+str(get_multiplayer_authority())+"|system: "+str(multiplayer.get_unique_id()))
	camera.reparent(get_node("/root"))
	$Camera3Dtrack.reparent(get_node("/root"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_track.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)*1.2
	camera_track.global_position.y = 4+ global_position.y-tilt*5
	camera.global_position = lerp(camera.global_position,camera_track.global_position,1)
	GameManager.main.clear_black()
	#while GameManager.stage == null:
	#	global_position = Vector3(280,115,-153)
	#	await get_tree().physics_frame

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print (global_position)
	pass

func toggle_held_item(holding : Item):
	if holding.holder_id != -1:
		return
	if holding == holding_item:
		return
	drop_item()
	if targeted_item == null:
		targeted_item = holding
	holding.rpc("update_holder_id",name.to_int())
	match holding.name_:
		"":
			left_hand_ik.stop()
			right_hand_ik.stop()
			return
		"Umbrella":
			left_hand_ik_active_target.transform = umbrella_hang_ik_pos_left.transform
			left_hand_ik.start()
			right_hand_ik_active_target.transform = umbrella_hang_ik_pos_right.transform
			right_hand_ik.start()
		"FireExtinguisher":
			left_hand_ik_active_target.transform = fire_extinguisher_ik_pos_left.transform
			left_hand_ik.start()
			right_hand_ik_active_target.transform = fire_extinguisher_ik_pos_right.transform
			right_hand_ik.start()
		"Glider":
			left_hand_ik_active_target.transform = glider_ik_pos_left.transform
			left_hand_ik.start()
			right_hand_ik_active_target.transform = glider_ik_pos_right.transform
			right_hand_ik.start()
	holding.global_position = right_hand_ik_active_target.global_position-$RootScene.basis.x*.25
	#holding_item.reparent(right_hand_ik_active_target)
	holding.global_rotation = $RootScene.global_rotation

func drop_item():
	if holding_item == null:
		return
	targeted_item = holding_item
	holding_item.rpc("update_holder_id",-1)
	holding_item = null

func _physics_process(delta):
	animate(delta)
	if !is_multiplayer_authority():
		return
	landing = is_on_floor()
	if Input.is_action_just_pressed("tab"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	check_run()
	gravity(delta)
	if player_focus() and fully_actionable():
		move_inputs(delta)
		check_jump()
	velocity.x = lerpf(velocity.x,0.0,clamp(delta*DRAG,0,1))
	velocity.z = lerpf(velocity.z,0.0,clamp(delta*DRAG,0,1))
	velocity.y = lerpf(velocity.y,0.0,clamp(delta*DRAG/7,0,1))
	move_and_slide()
	velocity_export = velocity
	if snap_check_ray.is_colliding() and can_snap:
		apply_floor_snap()

	camera.fov = clamp(camera.fov,10,70)

	# Merge into other identical check Maybe
	if fully_actionable() and player_focus():
		tilt -= mouse_delta.y * TURN_SPEED * delta
		if is_on_floor():
			tilt = clamp(tilt,-2.1,.5)
		else:
			tilt = clamp(tilt,-2.1,2.1)
	#print(tilt)

	camera_track.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)
	camera_track.global_position.y = 4+ global_position.y-tilt*10
	camera_track.look_at(self.global_position)
	#camera_track.get_node("SpringArm").spring_length = (camera_track.global_position-global_position).length()*.9
	#var targetPos = global_position+(camera_track.get_node("SpringArm").get_node("target").global_position-global_position)*1
	if camera_track.is_colliding():
		obstruction_zoom+=delta/4
		camera.global_position = lerp(camera.global_position,global_position+(camera_track.get_node("SpringArm").get_node("target").global_position-camera.global_position)*(.95+obstruction_zoom),delta*7)
	elif camera_track2.is_colliding():
		obstruction_zoom-=delta/4
		camera.global_position.x = lerp(camera.global_position.x,camera_track.global_position.x,delta*4)
		camera.global_position.z = lerp(camera.global_position.z,camera_track.global_position.z,delta*4)
		camera.global_position.y = lerp(camera.global_position.y,camera_track2.get_collision_point().y+camera_track2.global_basis.y.y*3,delta*2)
		if tilt <0:
			camera.global_position.y = lerp(camera.global_position.y,camera_track.global_position.y,delta*2)

	else:
		obstruction_zoom-=delta/4
		camera.global_position = lerp(camera.global_position,camera_track.global_position,delta*7)
	obstruction_zoom = clamp(obstruction_zoom,0,1)
	camera.look_at(self.global_position+Vector3.UP*1.2)
	#camera.rotation.x = camera_track.rotation.x
	if is_on_floor() and !landing:
		land()
	if Input.is_action_just_pressed("pickup"):
		if targeted_item !=null:
			if targeted_item is Item:
				toggle_held_item(targeted_item)
	if Input.is_action_just_pressed("interact"):
		if targeted_item !=null:
			if targeted_item is Interactable:
				targeted_item.use(self)
	if Input.is_action_just_pressed("drop"):
		drop_item()
		left_hand_ik.stop()
		right_hand_ik.stop()

	mouse_delta = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		mouse_delta.x = event.relative.x
		mouse_delta.y = event.relative.y

func is_gliding():
	gliding = false
	if holding_item != null:
			if holding_item.name_=="Glider" and !is_on_floor() and begun_falling > .15:
				gliding = true
				return true

func check_run():
	if Input.is_action_pressed("run"):
		player_move_force = run_force
	else:
		player_move_force = walk_force

func check_jump():
	if Input.is_action_pressed("jump") and !jumping:
		if !is_on_floor():
			return
		match jump_index:
			1:
				jump_index = 2 # left and right knee jump stuff
			2:
				jump_index = 1
		jump()

func jump():
	jumping = true
	await get_tree().create_timer(.1).timeout
	can_snap = false
	velocity.y = 21
	await get_tree().create_timer(.1).timeout
	jumping = false

func land():
	print("land start "+str(land_power))
	dive_bomb_momentum = 0
	landing = true
	await get_tree().create_timer(.005*land_power).timeout
	land_power = 0
	print("land end "+str(land_power))

func gravity(delta):
	if !is_on_floor():
		begun_falling+=delta
		land_power = abs(velocity.y)
		landing = false
		can_snap = false
		if holding_item:
			if holding_item.name_=="Umbrella":
				velocity.y-=delta*FALL_SPEED/4
				velocity.y = clamp(velocity.y,-2,100000)
			#elif holding_item.name_=="Glider":
				#if velocity.y>0 and begun_falling>.75:
					#velocity.y-=delta*FALL_SPEED/4
				#velocity.y = clamp(velocity.y,-2,10)
		else:
			velocity.y-=delta*FALL_SPEED/4
	else:
		begun_falling = 0.0
		if !jumping:
			can_snap = true
			velocity.y= 0

func rotate_to_normal():
	if rotate_check_ray.is_colliding():
		#print("colliding")
		flattening = false
		var length = (global_position - rotate_check_ray.get_collision_point()).length()
		var normal = (rotate_check_ray.get_collision_normal()+Vector3.UP).normalized()
		var rotation_speed = 0
		rotation_speed = (8-clamp(length,0,8))
		#print(rotation_speed)
		basis.y = lerp(basis.y,normal,GameManager.global_delta*rotation_speed*3)
		basis.x = lerp(basis.x,-basis.z.cross(normal),GameManager.global_delta)
		basis = basis.orthonormalized()
		up_direction = normal
		#apply_floor_snap()
	else:
		#print("not colliding")
		flattening = true
		rotate_flatten()

func rotate_flatten():
		basis.y = lerp(basis.y,Vector3(0,1,0),GameManager.global_delta*30)
		basis.x = lerp(basis.x,-basis.z.cross(Vector3(0,1,0)),GameManager.global_delta*30)
		basis = basis.orthonormalized()
		up_direction = Vector3(0,1,0)

func rotate_flatten_root_node():
		$RootScene/RootNode.basis.y = lerp($RootScene/RootNode.basis.y,Vector3(0,1,0),GameManager.global_delta*30)
		$RootScene/RootNode.basis.x = lerp($RootScene/RootNode.basis.x,-$RootScene/RootNode.basis.z.cross(Vector3(0,1,0)),GameManager.global_delta*30)
		$RootScene/RootNode.basis = $RootScene/RootNode.basis.orthonormalized()
		#up_direction = Vector3(0,1,0)

func move_inputs(delta):
	move_direction = Vector3.ZERO
	rotation.y -= mouse_delta.x * TURN_SPEED * delta
	if Input.is_action_just_released("scrolldown"):
		camera.fov+=5
	elif Input.is_action_just_released("scrollup"):
		camera.fov-=5
	var normal = (rotate_check_ray.get_collision_normal()+Vector3.UP).normalized()
	var rotation_speed = 10
	#print(rotation_speed)
	camera.global_transform.basis.y = lerp(camera.global_transform.basis.y,camera_track.global_transform.basis.y,GameManager.global_delta*rotation_speed*3)
	camera.global_transform.basis.x = lerp(camera.global_transform.basis.x,-camera.global_transform.basis.z.cross(camera_track.global_transform.basis.y),GameManager.global_delta*rotation_speed*3)
	camera.basis = camera.basis.orthonormalized()
	if Input.is_action_pressed("forward"):
		move_direction += basis.z
	if Input.is_action_pressed("back"):
		move_direction -= basis.z
	if Input.is_action_pressed("right"):
		move_direction -= basis.x
	if Input.is_action_pressed("left"):
		move_direction += basis.x
	move_direction.y = 0
	move_direction = move_direction.normalized()
	var look_direction = Vector3.ZERO
	if is_gliding():
		move_direction = Vector3.ZERO
		move_direction += $RootScene/RootNode.global_basis.z
		look_direction += global_basis.z*4
		move_direction += Vector3.UP*tilt/2
		look_direction += Vector3.UP*tilt*4
		look_direction = look_direction.normalized()
		move_direction = move_direction.normalized()

	## rotate toward direction #############################
	#rotate_to_normal()
	var initial_rotation = $RootScene/RootNode.rotation
	flight_angle = 0
	if move_direction != Vector3.ZERO:
		if is_gliding():
			$RootScene/RootNode.look_at(global_position-look_direction*100)
			#look_at(global_position-move_direction*100)
			flight_angle = tilt
			flight_speed = lerp(flight_speed,flight_angle,delta)
			if flight_angle<0:
				dive_bomb_momentum+=delta*27*-flight_angle
			else:
				dive_bomb_momentum = lerp(dive_bomb_momentum,0.0,delta/2)
		else:
			$RootScene/RootNode.look_at($RootScene/RootNode.global_position-move_direction*100)
			flight_speed = 0
	var target_rotation = $RootScene/RootNode.rotation
	$RootScene/RootNode.rotation = initial_rotation
	$RootScene/RootNode.rotation.y = lerp_angle($RootScene/RootNode.rotation.y,target_rotation.y,delta*14)
	$RootScene/RootNode.rotation.x = lerp_angle($RootScene/RootNode.rotation.x,target_rotation.x,delta*14)
	$RootScene/RootNode.rotation.z = lerp_angle($RootScene/RootNode.rotation.z,0,delta*14)
	#$RootScene/RootNode.rotate(basis.y,target_rotation.y)
	####################velocity movement determine####################################
	if !is_gliding():
		# normalized direction * F/m * dt (we handle drag in physics process)
		velocity += move_direction*player_move_force/stats.mass*delta
	else:
		velocity = velocity.lerp(move_direction.normalized()*delta*50 +Vector3(move_direction.normalized().x,move_direction.normalized().y/2,move_direction.normalized().z)*dive_bomb_momentum*delta*180,delta*5)
		if flight_angle>0:
			velocity.y-=(flight_angle+1)*70*clamp(begun_falling-1,0,3)/(dive_bomb_momentum+1)*delta
		velocity+=stats.wind_vector/110*delta
		velocity.y+=stats.wind_vector.y/110*delta
	if !is_on_floor():
		print(dive_bomb_momentum)
		if !is_gliding():
			velocity+=Vector3(stats.wind_vector.x,stats.wind_vector.y/4,stats.wind_vector.z)/125*delta
	velocity.x = clamp(velocity.x,-MAX_SPEED,MAX_SPEED)
	velocity.z = clamp(velocity.z,-MAX_SPEED,MAX_SPEED)

func player_focus():
	match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				return true
			Input.MOUSE_MODE_HIDDEN:
				return true
			Input.MOUSE_MODE_VISIBLE:
				return false

func fully_actionable():
	if interacting == null:
		return true
	return false

func animate(delta):
	if holding_item != null:
		if holding_item.name_ == "Umbrella":
			if is_on_floor():
				left_hand_ik_active_target.transform = umbrella_ik_pos_left.transform
				right_hand_ik_active_target.transform = umbrella_ik_pos_right.transform
			else:
				right_hand_ik_active_target.transform = umbrella_hang_ik_pos_right.transform
				left_hand_ik_active_target.transform = umbrella_hang_ik_pos_left.transform
	if is_gliding():
		#$RootScene/RootNode.global_rotate($RootScene/RootNode.global_basis.z,velocity.dot($RootScene/RootNode.global_basis.x)*delta)
		$RootScene/AnimationPlayer.play("root|Gliding",.2)
		$RootScene/AnimationPlayer.speed_scale = velocity_export.length()/5
		return
	else:
		rotate_flatten_root_node()
	if is_on_floor() or floor_check_ray.is_colliding():
		rotate_flatten_root_node()
		rotate_flatten()
		if jumping:
			#print("a")
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = 3
		elif landing and land_power>0:
			#print(land_power)
			#print("b")
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = land_power*.2
		elif velocity_export.length()>5:
			$RootScene/AnimationPlayer.play("root|Run",.1)
			$RootScene/AnimationPlayer.speed_scale = velocity_export.length()/3
		elif velocity_export.length()>1:
			$RootScene/AnimationPlayer.play("root|Walk",.1)
			$RootScene/AnimationPlayer.speed_scale = velocity_export.length()/2
		else:
			$RootScene/AnimationPlayer.play("root|Idle",.1)
			$RootScene/AnimationPlayer.speed_scale = 1
	elif velocity.y>0:
		$RootScene/AnimationPlayer.play("root|Jump"+str(jump_index),.5)
		$RootScene/AnimationPlayer.speed_scale = 1
	elif $RootScene/AnimationPlayer.current_animation!="root|Jump"+str(jump_index):
		rotate_flatten_root_node()
		if !rotate_check_ray.is_colliding():
			$RootScene/RootNode.global_rotate($RootScene/RootNode.global_basis.z,velocity.dot($RootScene/RootNode.global_basis.x)*delta)
			$RootScene/AnimationPlayer.play("root|Gliding",.2)
			$RootScene/AnimationPlayer.speed_scale = velocity_export.length()/5
		else:
			$RootScene/AnimationPlayer.play("root|Jump"+str(jump_index),.5)
			$RootScene/AnimationPlayer.speed_scale = 1
			$RootScene/AnimationPlayer.seek(.5)


func _on_interact_area_body_entered(body):
	#print(body.name)
	if body == holding_item:
		return
	targeted_item = body

func _on_interact_area_body_exited(body):
	#print(body.name)
	if body == targeted_item:
		targeted_item = null

func _on_interact_area_area_entered(area):
	targeted_item = area.get_parent()

func _on_interact_area_area_exited(area):
	if area.get_parent() == targeted_item:
		targeted_item = null
