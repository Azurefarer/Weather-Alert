extends CharacterBody3D

const MOVE_SPEED = 10
const MAX_SPEED = 200
const FALL_SPEED = 200
const TURN_SPEED = 1
const DRAG = 10
var jumpIndex = 1
var mouseDelta: Vector2
var runToggle = 10
var moveDirection = Vector3.ZERO
var flattening = false
@export var camera: Camera3D
@export var cameraTrack: Node3D
var canSnap = false
var jumping = false
var landing = false
var landPower = 0
@export var rotateCheckRay: RayCast3D
@export var floorCheckRay: RayCast3D
@export var snapCheckRay: RayCast3D
var tilt = -.6

# Called when the node enters the scene tree for the first time.
func _ready():
	camera.reparent(get_node("/root"))
	$Camera3Dtrack.reparent(get_node("/root"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
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
	if snapCheckRay.is_colliding() and canSnap:
		pass
		apply_floor_snap()
	animate()
	
	camera.fov = clamp(camera.fov,10,70)	
	tilt -= mouseDelta.y * TURN_SPEED * delta
	tilt = clamp(tilt,-1.1,.3)
	print(tilt)
	cameraTrack.global_position = global_position + Vector3(basis.z.x,0,basis.z.z)*(-12-tilt*5)
	cameraTrack.global_position.y = 2+ global_position.y-tilt*10
	camera.global_position = lerp(camera.global_position,cameraTrack.global_position,delta*50)
	camera.look_at(self.global_position+Vector3.UP*.5)
	#camera.rotation.x = cameraTrack.rotation.x
	if is_on_floor() and !landing:
		land()
	mouseDelta = Vector2.ZERO
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouseDelta.x = event.relative.x
		mouseDelta.y = event.relative.y
	
func checkRun():
	if Input.is_action_pressed("run"):
		runToggle = 3
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
	await get_tree().create_timer(.2).timeout
	canSnap = false
	velocity.y = 15
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
		#velocity.y = clamp(velocity.y,0,1)
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
		basis.y = lerp(basis.y,Vector3(0,1,0),GameManager.global_delta) 
		basis.x = lerp(basis.x,-basis.z.cross(Vector3(0,1,0)),GameManager.global_delta)
		basis = basis.orthonormalized()
		up_direction = Vector3(0,1,0)


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
	## rotate toward direction #############################
	rotateToNormal()
	var initial_rotation = $RootScene/RootNode.rotation
	if moveDirection != Vector3.ZERO:
		$RootScene/RootNode.look_at($RootScene/RootNode.global_position-moveDirection*100)
	var target_rotation = $RootScene/RootNode.rotation
	$RootScene/RootNode.rotation = initial_rotation
	$RootScene/RootNode.rotation.y = lerp_angle($RootScene/RootNode.rotation.y,target_rotation.y,delta*14)
	#$RootScene/RootNode.rotate(basis.y,target_rotation.y)
	########################################################
	velocity += moveDirection*runToggle/2
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

func animate():
	if is_on_floor() or floorCheckRay.is_colliding():
		if jumping:
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = 3
		elif landing and landPower>0:
			print(landPower)
			$RootScene/AnimationPlayer.play("root|Crouch",.1)
			$RootScene/AnimationPlayer.speed_scale = landPower*.2
		elif velocity.length()>5:
			$RootScene/AnimationPlayer.play("root|Run",.1)
			$RootScene/AnimationPlayer.speed_scale = velocity.length()/3
		elif velocity.length()>1:
			$RootScene/AnimationPlayer.play("root|Walk",.1)
			$RootScene/AnimationPlayer.speed_scale = velocity.length()/2
		else:
			$RootScene/AnimationPlayer.play("root|Idle",.1)
			$RootScene/AnimationPlayer.speed_scale = 1
	elif velocity.y>0:
		$RootScene/AnimationPlayer.play("root|Jump"+str(jumpIndex),.5)
		$RootScene/AnimationPlayer.speed_scale = 1
	else:
		if $RootScene/AnimationPlayer.current_animation!="root|Jump"+str(jumpIndex):
			$RootScene/AnimationPlayer.play("root|Jump"+str(jumpIndex),.5)
			$RootScene/AnimationPlayer.speed_scale = 1
			$RootScene/AnimationPlayer.seek(.5)
 
