extends CharacterBody3D

const MOVE_SPEED = 10
const MAX_SPEED = 200
const FALL_SPEED = 200
const TURN_SPEED = 1
const DRAG = 10
@export var jumpIndex = 1
@export var gliding: bool
@export var velocityExport: Vector3
var mouseDelta: Vector2
var runToggle = 10
var moveDirection = Vector3.ZERO
var flattening = false
@export var camera: Camera3D
@export var cameraTrack: RayCast3D
@export var stats: Node
var canSnap = false
var jumping = false
var flightAngle = 0
var flightSpeed = 0
var landing = false
var holding_item = null
@export var landPower = 0
@export var rotateCheckRay: RayCast3D
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
@export var glider_extinguisher_IK_pos_left: Node3D
@export var glider_extinguisher_IK_pos_right: Node3D
@export var leftHandPhysicsBone: PhysicalBone3D
@export var rightHandPhysicsBone: PhysicalBone3D

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
	if GameManager.gameMode == "game":
		global_position = Vector3(0,600,0)
		GameManager.level.add_child(preload("res://Assets/Scenes/World.tscn").instantiate())
	print("authority: "+str(get_multiplayer_authority())+"|system: "+str(multiplayer.get_unique_id()))
	camera.reparent(get_node("/root"))
	$Camera3Dtrack.reparent(get_node("/root"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cameraTrack.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)
	cameraTrack.global_position.y = 4+ global_position.y-tilt*10
	camera.global_position = lerp(camera.global_position,cameraTrack.global_position,1)
	#while GameManager.stage == null:
	#	global_position = Vector3(280,115,-153)
	#	await get_tree().physics_frame

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	move_and_slide()
	velocityExport = velocity
	if snapCheckRay.is_colliding() and canSnap:
		pass
		apply_floor_snap()
	
	camera.fov = clamp(camera.fov,10,70)	
	tilt -= mouseDelta.y * TURN_SPEED * delta
	tilt = clamp(tilt,-2.1,2.1)
	#print(tilt)

	cameraTrack.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)
	cameraTrack.global_position.y = 4+ global_position.y-tilt*10
	cameraTrack.look_at(self.global_position)
	#cameraTrack.get_node("SpringArm").spring_length = (cameraTrack.global_position-global_position).length()*.9
	#var targetPos = global_position+(cameraTrack.get_node("SpringArm").get_node("target").global_position-global_position)*1
	if cameraTrack.is_colliding() or cameraTrack.get_node("Ray2").is_colliding():
		obstructionZoom+=delta/4
		camera.global_position = lerp(camera.global_position,global_position+(cameraTrack.get_node("SpringArm").get_node("target").global_position-camera.global_position)*(.95+obstructionZoom),delta*3)
	else:
		obstructionZoom-=delta/4
		camera.global_position = lerp(camera.global_position,cameraTrack.global_position,delta*3)
	obstructionZoom = clamp(obstructionZoom,0,1)
	camera.look_at(self.global_position+Vector3.UP*1.2)
	#camera.rotation.x = cameraTrack.rotation.x
	if is_on_floor() and !landing:
		land()
		
	if Input.is_action_just_pressed("pickup"):
		if targeted_item !=null:
			toggle_held_item(targeted_item)
			
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
			if holding_item.name_=="Glider" and !is_on_floor():
				gliding = true
				return true

func checkRun():
	if Input.is_action_pressed("run"):
		runToggle =4
	else:
		runToggle = 1
		
func checkJump():
	if Input.is_action_pressed("jump") and !jumping:
		if !is_on_floor():
			return
		match jumpIndex:
			1:
				jumpIndex = 2
			2:
				jumpIndex = 1
		jump()
		
func jump():
	jumping = true
	await get_tree().create_timer(.1).timeout
	canSnap = false
	velocity.y = 11
	await get_tree().create_timer(.1).timeout
	jumping = false

func land():
	landing = true
	await get_tree().create_timer(.005*landPower).timeout
	landPower = 0
		
func gravity(delta):
	if !is_on_floor():
		landPower = abs(velocity.y)
		landing = false
		canSnap = false
		velocity.y-=delta*FALL_SPEED/6
		if holding_item:
			if holding_item.name_=="Glider":
				velocity.y = clamp(velocity.y,-2,10)
	else:
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
	if is_gliding():
		moveDirection = Vector3.ZERO
		if Input.is_action_pressed("forward"):
			moveDirection += $RootScene/RootNode.global_basis.z
		if Input.is_action_pressed("right"):
			moveDirection -= basis.x
		if Input.is_action_pressed("left"):
			moveDirection += basis.x
		moveDirection += $RootScene/RootNode.global_basis.z
			
	## rotate toward direction #############################
	#rotateToNormal()
	var initial_rotation = $RootScene/RootNode.rotation
	flightAngle = 0
	if moveDirection != Vector3.ZERO:
		$RootScene/RootNode.look_at($RootScene/RootNode.global_position-moveDirection*100)
		if is_gliding():
			$RootScene/RootNode.look_at(global_position+camera.global_basis.z*100-moveDirection*100)
			flightAngle = $RootScene/RootNode.rotation.x*3
			flightSpeed -= (flightAngle+.7)*delta
		else:
			flightSpeed = 0
	var target_rotation = $RootScene/RootNode.rotation
	$RootScene/RootNode.rotation = initial_rotation
	$RootScene/RootNode.rotation.y = lerp_angle($RootScene/RootNode.rotation.y,target_rotation.y,delta*14)
	$RootScene/RootNode.rotation.x = lerp_angle($RootScene/RootNode.rotation.x,target_rotation.x,delta*14)
	$RootScene/RootNode.rotation.z = lerp_angle($RootScene/RootNode.rotation.z,0,delta*14)
	#$RootScene/RootNode.rotate(basis.y,target_rotation.y)
	########################################################
	if !is_gliding():
		velocity += moveDirection*runToggle/2
	else:
		velocity += 5/2.5*moveDirection.normalized()*(velocity.length()/200+1)*(clamp(-flightSpeed-2,0,7)+1)+5/2.5*Vector3.UP*(clamp(flightSpeed/2+flightAngle+1,-3,3)*(velocity.length()/200+1))
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
	return true

func animate(delta):
	if is_gliding():
		$RootScene/RootNode.global_rotate($RootScene/RootNode.global_basis.z,velocity.dot($RootScene/RootNode.global_basis.x)*delta)
		$RootScene/AnimationPlayer.play("root|Gliding",.2)
		$RootScene/AnimationPlayer.speed_scale = velocityExport.length()/5
		return
	else:
		rotateFlattenRootNode()
	if is_on_floor() or floorCheckRay.is_colliding():
		rotateFlattenRootNode()
		rotateFlatten()
		if jumping:
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = 3
		elif landing and landPower>0:
			#print(landPower)
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
