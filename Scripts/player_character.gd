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
		velocity.y = 30
		
func gravity(delta):
	if !is_on_floor():
		velocity.y-=clamp(delta*FALL_SPEED/2,0,10)
		
func moveInputs(delta):
	moveDirection = Vector3.ZERO
	rotation.y -= mouseDelta.x * TURN_SPEED * delta
	if Input.is_action_pressed("forward"):
		moveDirection += basis.z
	if Input.is_action_pressed("back"):
		moveDirection -= basis.z
	if Input.is_action_pressed("right"):
		moveDirection -= basis.x
	if Input.is_action_pressed("left"):
		moveDirection += basis.x
	moveDirection = moveDirection.normalized()
	## rotate toward direction #############################
	var initial_rotation = $RootScene/RootNode.global_rotation
	if moveDirection != Vector3.ZERO:
		$RootScene/RootNode.look_at($RootScene/RootNode.global_position-moveDirection*100)
	var target_rotation = $RootScene/RootNode.global_rotation
	$RootScene/RootNode.global_rotation = initial_rotation
	$RootScene/RootNode.global_rotation.y = lerp_angle($RootScene/RootNode.global_rotation.y,target_rotation.y,delta*14)
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
	if is_on_floor():
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
 
