extends KinematicBody

onready var eyes: Camera = $Eyes

var sensitivity: float = 3.0
var gravity: float = 15.0
var jump_height: float = 5.0
var speed: float = 5.715
var air_speed: float = 0.75
var acceleration: float = 0.25
var max_slope_angle: float = deg2rad(45.0)

var velocity: Vector3

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	eyes.set_as_toplevel(true)

func _process(_delta: float) -> void:
	eyes.translation = get_global_transform_interpolated().translated(Vector3(0.0, 1.3, 0.0)).origin

func _physics_process(delta: float) -> void:
	var eyes_yaw: Basis = Basis(Vector3.UP, eyes.rotation.y)
	var move_input: Vector2 = Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction: Vector3 = (eyes_yaw.x * move_input.x + eyes_yaw.z * move_input.y).normalized()
	var snap: Vector3 = Vector3.ZERO
	
	if is_on_floor():
		if Input.is_action_pressed("Jump"):
			velocity.y = jump_height
		else:
			var floor_normal: Vector3 = get_floor_normal()
			var slope_collision: KinematicCollision = move_and_collide(Vector3(velocity.x, 0.0, velocity.z) * delta, true, true, true)
			
			if slope_collision and Vector3.UP.angle_to(slope_collision.normal) <= max_slope_angle:
				floor_normal = slope_collision.normal
			
			velocity += (direction * speed - velocity) * acceleration
			velocity.y = -1.0 / floor_normal.y * (velocity.x * floor_normal.x + velocity.z * floor_normal.z)
			
			snap = -floor_normal * 0.25
	else:
		var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
		
		velocity.y -= gravity * delta
		velocity += direction * max(air_speed - horizontal_velocity.dot(direction) * float(horizontal_velocity.normalized().dot(direction) >= -0.5), 0.0)
		
		snap = Vector3.DOWN
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, max_slope_angle, true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		eyes.rotation_degrees.y = wrapf(eyes.rotation_degrees.y - event.relative.x * sensitivity * 0.022, -180.0, 180.0)
		eyes.rotation_degrees.x = clamp(eyes.rotation_degrees.x - event.relative.y * sensitivity * 0.022, -89.0, 89.0)
	
	if event is InputEventKey and event.is_pressed():
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
