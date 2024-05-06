extends CharacterBody3D

const MOVE_SPEED = 10
const MAX_SPEED = 200
const FALL_SPEED = 500
const TURN_SPEED = 1
const DRAG = 10
var mouseDelta: Vector2
var runToggle = 10
var moveDirection = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
	move_and_slide()
	mouseDelta = Vector2.ZERO
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouseDelta.x = event.relative.x
		mouseDelta.y = event.relative.y
	
func checkRun():
	if Input.is_action_pressed("run"):
		runToggle = 30
	else:
		runToggle = 10
		
func gravity(delta):
	if !is_on_floor():
		velocity.y-=delta*FALL_SPEED
		
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
	velocity += moveDirection*runToggle
	velocity.x = clamp(velocity.x,-MAX_SPEED,MAX_SPEED)
	velocity.z = clamp(velocity.z,-MAX_SPEED,MAX_SPEED)
	if true:#moveDirection == Vector3.ZERO:
		velocity.x = lerpf(velocity.x,0.0,clamp(delta*DRAG,0,1))
		velocity.z = lerpf(velocity.z,0.0,clamp(delta*DRAG,0,1))
		#print("velocity: "+str(velocity))
		
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

