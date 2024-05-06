extends CharacterBody3D
class_name PlayerCharacter

const MOVE_SPEED = 10
const MAX_SPEED = 200
const FALL_SPEED = 200
const TURN_SPEED = 1
const DRAG = 10
@export var jumpIndex = 1
@export var gliding: bool
@export var velocityExport: Vector3
var run_force : float = 7000.0 # In newtons
var walk_force : float = 3500.0 # In newtons
var player_move_force : float

var mouseDelta: Vector2
var moveDirection = Vector3.ZERO
var flattening = false
var begunFalling = 0.0
@export var camera: Camera3D
@export var cameraTrack: RayCast3D
@export var cameraTrack2: RayCast3D
@export var stats: Node
var canSnap = false
var jumping = false
var flightAngle: float
var flightSpeed: float
var landing = false
var holding_item = null
var interacting = null
@export var landPower = 0
@export var rotateCheckRay: RayCast3D
@export var ceilCheckRay: RayCast3D
@export var floorCheckRay: RayCast3D
@export var snapCheckRay: RayCast3D
var tilt = -.6
var obstructionZoom: float
var targeted_item: Node3D
@export var leftHandIK: SkeletonIK3D
@export var rightHandIK: SkeletonIK3D
@export var leftHandIK_active_target: Node3D
@export var rightHandIK_active_target: Node3D
@export var fire_extinguisher_IK_pos_left: Node3D
@export var fire_extinguisher_IK_pos_right: Node3D
@export var umbrella_hang_IK_pos_left: Node3D
@export var umbrella_hang_IK_pos_right: Node3D
@export var umbrella_IK_pos_left: Node3D
@export var umbrella_IK_pos_right: Node3D
@export var glider_extinguisher_IK_pos_left: Node3D
@export var glider_extinguisher_IK_pos_right: Node3D
@export var leftHandPhysicsBone: PhysicalBone3D
@export var rightHandPhysicsBone: PhysicalBone3D
@export var rootPhysicsBone: PhysicalBone3D
@export var rightHandBoneAttach: BoneAttachment3D
var diveBombMomentum:= 0.0

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
	#if GameManager.gameMode == "game":
		#GameManager.ship.get_node("Scalar/Players").global_position
		#GameManager.level.add_child(preload("res://Assets/Scenes/World.tscn").instantiate())
		# NOTE: maybe makes desync between world weather systems
	print("authority: "+str(get_multiplayer_authority())+"|system: "+str(multiplayer.get_unique_id()))
	camera.reparent(get_node("/root"))
	$Camera3Dtrack.reparent(get_node("/root"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cameraTrack.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)*1.2
	cameraTrack.global_position.y = 4+ global_position.y-tilt*5
	camera.global_position = lerp(camera.global_position,cameraTrack.global_position,1)
	GameManager.main.clear_black()
	#while GameManager.stage == null:
	#	global_position = Vector3(280,115,-153)
	#	await get_tree().physics_frame

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print (global_position)
	pass

func toggle_held_item(holding):
	if holding.holderID != -1:
		return
	if holding == holding_item:
		return
	drop_item()
	if targeted_item == null:
		targeted_item = holding
	holding.rpc("update_holder_id",name.to_int())
	match holding.name_:
		"":
			leftHandIK.stop()
			rightHandIK.stop()
			return
		"Umbrella":
			leftHandIK_active_target.transform = umbrella_hang_IK_pos_left.transform
			leftHandIK.start()
			rightHandIK_active_target.transform = umbrella_hang_IK_pos_right.transform
			rightHandIK.start()
		"FireExtinguisher":
			leftHandIK_active_target.transform = fire_extinguisher_IK_pos_left.transform
			leftHandIK.start()
			rightHandIK_active_target.transform = fire_extinguisher_IK_pos_right.transform
			rightHandIK.start()
		"Glider":
			leftHandIK_active_target.transform = glider_extinguisher_IK_pos_left.transform
			leftHandIK.start()
			rightHandIK_active_target.transform = glider_extinguisher_IK_pos_right.transform
			rightHandIK.start()
	holding.global_position = rightHandIK_active_target.global_position-$RootScene.basis.x*.25
	#holding_item.reparent(rightHandIK_active_target)
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
	checkRun()
	gravity(delta)
	if playerFocus() and fullyActionable():
		moveInputs(delta)
		checkJump()
	velocity.x = lerpf(velocity.x,0.0,clamp(delta*DRAG,0,1))
	velocity.z = lerpf(velocity.z,0.0,clamp(delta*DRAG,0,1))
	velocity.y = lerpf(velocity.y,0.0,clamp(delta*DRAG/7,0,1))
	move_and_slide()
	velocityExport = velocity
	if snapCheckRay.is_colliding() and canSnap:
		apply_floor_snap()
	
	camera.fov = clamp(camera.fov,10,70)
	
	# Merge into other identical check Maybe
	if fullyActionable() and playerFocus():
		tilt -= mouseDelta.y * TURN_SPEED * delta
		if is_on_floor():
			tilt = clamp(tilt,-2.1,.5)
		else:
			tilt = clamp(tilt,-2.1,2.1)
	#print(tilt)

	cameraTrack.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)
	cameraTrack.global_position.y = 4+ global_position.y-tilt*10
	cameraTrack.look_at(self.global_position)
	#cameraTrack.get_node("SpringArm").spring_length = (cameraTrack.global_position-global_position).length()*.9
	#var targetPos = global_position+(cameraTrack.get_node("SpringArm").get_node("target").global_position-global_position)*1
	if cameraTrack.is_colliding():
		obstructionZoom+=delta/4
		camera.global_position = lerp(camera.global_position,global_position+(cameraTrack.get_node("SpringArm").get_node("target").global_position-camera.global_position)*(.95+obstructionZoom),delta*7)
	elif cameraTrack2.is_colliding():
		obstructionZoom-=delta/4
		camera.global_position.x = lerp(camera.global_position.x,cameraTrack.global_position.x,delta*4)
		camera.global_position.z = lerp(camera.global_position.z,cameraTrack.global_position.z,delta*4)
		camera.global_position.y = lerp(camera.global_position.y,cameraTrack2.get_collision_point().y+cameraTrack2.global_basis.y.y*3,delta*2)
		if tilt <0:
			camera.global_position.y = lerp(camera.global_position.y,cameraTrack.global_position.y,delta*2)
		
	else:
		obstructionZoom-=delta/4
		camera.global_position = lerp(camera.global_position,cameraTrack.global_position,delta*7)
	obstructionZoom = clamp(obstructionZoom,0,1)
	camera.look_at(self.global_position+Vector3.UP*1.2)
	#camera.rotation.x = cameraTrack.rotation.x
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
		leftHandIK.stop()
		rightHandIK.stop()
		
	mouseDelta = Vector2.ZERO
	
func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		mouseDelta.x = event.relative.x
		mouseDelta.y = event.relative.y

func is_gliding():
	gliding = false
	if holding_item != null: 
			if holding_item.name_=="Glider" and !is_on_floor() and begunFalling > .15:
				gliding = true
				return true

func checkRun():
	if Input.is_action_pressed("run"):
		player_move_force = run_force
	else:
		player_move_force = walk_force
		
func checkJump():
	if Input.is_action_pressed("jump") and !jumping:
		if !is_on_floor():
			return
		match jumpIndex:
			1:
				jumpIndex = 2 # left and right knee jump stuff
			2:
				jumpIndex = 1
		jump()
		
func jump():
	jumping = true
	await get_tree().create_timer(.1).timeout
	canSnap = false
	velocity.y = 21
	await get_tree().create_timer(.1).timeout
	jumping = false

func land():
	print("land start "+str(landPower))	
	diveBombMomentum = 0
	landing = true
	await get_tree().create_timer(.005*landPower).timeout
	landPower = 0
	print("land end "+str(landPower))
		
func gravity(delta):
	if !is_on_floor():
		begunFalling+=delta
		landPower = abs(velocity.y)
		landing = false
		canSnap = false
		if holding_item:
			if holding_item.name_=="Umbrella":
				velocity.y-=delta*FALL_SPEED/4
				velocity.y = clamp(velocity.y,-2,100000)
			#elif holding_item.name_=="Glider":
				#if velocity.y>0 and begunFalling>.75:
					#velocity.y-=delta*FALL_SPEED/4
				#velocity.y = clamp(velocity.y,-2,10)
		else:
			velocity.y-=delta*FALL_SPEED/4
	else:
		begunFalling = 0.0
		if !jumping:
			canSnap = true
			velocity.y= 0

func rotateToNormal():
	if rotateCheckRay.is_colliding():
		#print("colliding")
		flattening = false
		var length = (global_position - rotateCheckRay.get_collision_point()).length()
		var normal = (rotateCheckRay.get_collision_normal()+Vector3.UP).normalized()
		var rotationSpeed = 0
		rotationSpeed = (8-clamp(length,0,8))
		#print(rotationSpeed)
		basis.y = lerp(basis.y,normal,GameManager.global_delta*rotationSpeed*3) 
		basis.x = lerp(basis.x,-basis.z.cross(normal),GameManager.global_delta)
		basis = basis.orthonormalized()
		up_direction = normal
		#apply_floor_snap()
	else:
		#print("not colliding")
		flattening = true		
		rotateFlatten()

func rotateFlatten():
		basis.y = lerp(basis.y,Vector3(0,1,0),GameManager.global_delta*30) 
		basis.x = lerp(basis.x,-basis.z.cross(Vector3(0,1,0)),GameManager.global_delta*30)
		basis = basis.orthonormalized()
		up_direction = Vector3(0,1,0)

func rotateFlattenRootNode():
		$RootScene/RootNode.basis.y = lerp($RootScene/RootNode.basis.y,Vector3(0,1,0),GameManager.global_delta*30) 
		$RootScene/RootNode.basis.x = lerp($RootScene/RootNode.basis.x,-$RootScene/RootNode.basis.z.cross(Vector3(0,1,0)),GameManager.global_delta*30)
		$RootScene/RootNode.basis = $RootScene/RootNode.basis.orthonormalized()
		#up_direction = Vector3(0,1,0)

func moveInputs(delta):
	moveDirection = Vector3.ZERO
	rotation.y -= mouseDelta.x * TURN_SPEED * delta
	if Input.is_action_just_released("scrolldown"):
		camera.fov+=5
	elif Input.is_action_just_released("scrollup"):
		camera.fov-=5
	var normal = (rotateCheckRay.get_collision_normal()+Vector3.UP).normalized()
	var rotationSpeed = 10
	#print(rotationSpeed)
	camera.global_transform.basis.y = lerp(camera.global_transform.basis.y,cameraTrack.global_transform.basis.y,GameManager.global_delta*rotationSpeed*3) 
	camera.global_transform.basis.x = lerp(camera.global_transform.basis.x,-camera.global_transform.basis.z.cross(cameraTrack.global_transform.basis.y),GameManager.global_delta*rotationSpeed*3)
	camera.basis = camera.basis.orthonormalized()
	if Input.is_action_pressed("forward"):
		moveDirection += basis.z
	if Input.is_action_pressed("back"):
		moveDirection -= basis.z
	if Input.is_action_pressed("right"):
		moveDirection -= basis.x
	if Input.is_action_pressed("left"):
		moveDirection += basis.x
	moveDirection.y = 0
	moveDirection = moveDirection.normalized()
	var lookDirection = Vector3.ZERO
	if is_gliding():
		moveDirection = Vector3.ZERO
		moveDirection += $RootScene/RootNode.global_basis.z
		lookDirection += global_basis.z*4
		moveDirection += Vector3.UP*tilt/2
		lookDirection += Vector3.UP*tilt*4
		lookDirection = lookDirection.normalized()
		moveDirection = moveDirection.normalized()
			
	## rotate toward direction #############################
	#rotateToNormal()
	var initial_rotation = $RootScene/RootNode.rotation
	flightAngle = 0
	if moveDirection != Vector3.ZERO:
		if is_gliding():
			$RootScene/RootNode.look_at(global_position-lookDirection*100)
			#look_at(global_position-moveDirection*100)
			flightAngle = tilt
			flightSpeed = lerp(flightSpeed,flightAngle,delta)
			if flightAngle<0:
				diveBombMomentum+=delta*27*-flightAngle
			else:
				diveBombMomentum = lerp(diveBombMomentum,0.0,delta/2)
		else:
			$RootScene/RootNode.look_at($RootScene/RootNode.global_position-moveDirection*100)
			flightSpeed = 0
	var target_rotation = $RootScene/RootNode.rotation
	$RootScene/RootNode.rotation = initial_rotation
	$RootScene/RootNode.rotation.y = lerp_angle($RootScene/RootNode.rotation.y,target_rotation.y,delta*14)
	$RootScene/RootNode.rotation.x = lerp_angle($RootScene/RootNode.rotation.x,target_rotation.x,delta*14)
	$RootScene/RootNode.rotation.z = lerp_angle($RootScene/RootNode.rotation.z,0,delta*14)
	#$RootScene/RootNode.rotate(basis.y,target_rotation.y)
	####################velocity movement determine####################################
	if !is_gliding():
		# normalized direction * F/m * dt (we handle drag in physics process)
		velocity += moveDirection*player_move_force/stats.mass*delta
	else:
		velocity = velocity.lerp(moveDirection.normalized()*delta*50 +Vector3(moveDirection.normalized().x,moveDirection.normalized().y/2,moveDirection.normalized().z)*diveBombMomentum*delta*180,delta*5)
		if flightAngle>0:
			velocity.y-=(flightAngle+1)*70*clamp(begunFalling-1,0,3)/(diveBombMomentum+1)*delta
		velocity+=stats.wind_vector/110*delta
		velocity.y+=stats.wind_vector.y/110*delta
	if !is_on_floor():
		print(diveBombMomentum)
		if !is_gliding():
			velocity+=Vector3(stats.wind_vector.x,stats.wind_vector.y/4,stats.wind_vector.z)/125*delta
	velocity.x = clamp(velocity.x,-MAX_SPEED,MAX_SPEED)
	velocity.z = clamp(velocity.z,-MAX_SPEED,MAX_SPEED)
		
func playerFocus():
	match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				return true
			Input.MOUSE_MODE_HIDDEN:
				return true
			Input.MOUSE_MODE_VISIBLE:
				return false
	
func fullyActionable():
	if interacting == null:
		return true
	return false 

func animate(delta):
	if holding_item != null:
		if holding_item.name_ == "Umbrella":
			if is_on_floor():
				leftHandIK_active_target.transform = umbrella_IK_pos_left.transform
				rightHandIK_active_target.transform = umbrella_IK_pos_right.transform
			else:
				rightHandIK_active_target.transform = umbrella_hang_IK_pos_right.transform
				leftHandIK_active_target.transform = umbrella_hang_IK_pos_left.transform
	if is_gliding():
		#$RootScene/RootNode.global_rotate($RootScene/RootNode.global_basis.z,velocity.dot($RootScene/RootNode.global_basis.x)*delta)
		$RootScene/AnimationPlayer.play("root|Gliding",.2)
		$RootScene/AnimationPlayer.speed_scale = velocityExport.length()/5
		return
	else:
		rotateFlattenRootNode()
	if is_on_floor() or floorCheckRay.is_colliding():
		rotateFlattenRootNode()
		rotateFlatten()
		if jumping:
			#print("a")
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = 3
		elif landing and landPower>0:
			#print(landPower)
			#print("b")
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = landPower*.2
		elif velocityExport.length()>5:
			$RootScene/AnimationPlayer.play("root|Run",.1)
			$RootScene/AnimationPlayer.speed_scale = velocityExport.length()/3
		elif velocityExport.length()>1:
			$RootScene/AnimationPlayer.play("root|Walk",.1)
			$RootScene/AnimationPlayer.speed_scale = velocityExport.length()/2
		else:
			$RootScene/AnimationPlayer.play("root|Idle",.1)
			$RootScene/AnimationPlayer.speed_scale = 1
	elif velocity.y>0:
		$RootScene/AnimationPlayer.play("root|Jump"+str(jumpIndex),.5)
		$RootScene/AnimationPlayer.speed_scale = 1
	elif $RootScene/AnimationPlayer.current_animation!="root|Jump"+str(jumpIndex):
		rotateFlattenRootNode()
		if !rotateCheckRay.is_colliding():
			$RootScene/RootNode.global_rotate($RootScene/RootNode.global_basis.z,velocity.dot($RootScene/RootNode.global_basis.x)*delta)
			$RootScene/AnimationPlayer.play("root|Gliding",.2)
			$RootScene/AnimationPlayer.speed_scale = velocityExport.length()/5
		else:
			$RootScene/AnimationPlayer.play("root|Jump"+str(jumpIndex),.5)
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
