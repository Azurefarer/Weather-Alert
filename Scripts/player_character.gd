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
@export var rotateCheckRay: RayCast3D
@export var floorCheckRay: RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
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
	if floorCheckRay.is_colliding():
		apply_floor_snap()
	mouseDelta = Vector2.ZERO
	animate()
	
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
	if Input.is_action_pressed("jump"):
		if !is_on_floor():
			return
		match jumpIndex:
			1:
				jumpIndex = 2
			2:
				jumpIndex = 1
		velocity.y = 15
		
func gravity(delta):
	if !is_on_floor():
		velocity.y-=clamp(delta*FALL_SPEED/6,0,10)
	else:
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
		basis.y = lerp(basis.y,normal,GameManager.global_delta*rotationSpeed*30) 
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
		$Camera3D.fov+=5
	elif Input.is_action_just_released("scrollup"):
		$Camera3D.fov-=5
	$Camera3D.fov = clamp($Camera3D.fov,10,70)	
	$Camera3D.rotation.x -= mouseDelta.y * TURN_SPEED * delta
	$Camera3D.rotation.x = clamp($Camera3D.rotation.x,-1.1,.3)
	$Camera3D.position.y = 2-$Camera3D.rotation.x*10
	$Camera3D.position.z = -12-$Camera3D.rotation.x*5
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
	velocity += moveDirection*runToggle
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
		if velocity.length()>10:
			$RootScene/AnimationPlayer.play("root|Run",.5)
			$RootScene/AnimationPlayer.speed_scale = velocity.length()/6
		elif velocity.length()>1:
			$RootScene/AnimationPlayer.play("root|Walk",.5)
			$RootScene/AnimationPlayer.speed_scale = velocity.length()/4
		else:
			$RootScene/AnimationPlayer.play("root|Idle",.5)
			$RootScene/AnimationPlayer.speed_scale = 1
	elif velocity.y>0:
		$RootScene/AnimationPlayer.play("root|Jump"+str(jumpIndex),.5)
		$RootScene/AnimationPlayer.speed_scale = 1
	else:
		if $RootScene/AnimationPlayer.current_animation!="root|Jump"+str(jumpIndex):
			$RootScene/AnimationPlayer.play("root|Jump"+str(jumpIndex),.5)
			$RootScene/AnimationPlayer.speed_scale = 1
			$RootScene/AnimationPlayer.seek(.5)
 
