extends Control


@onready var camera := get_viewport().get_camera_3d()

@export_node_path("Node3D") var dog_path: NodePath
@export_node_path("Node3D") var object_path: NodePath
@export_node_path("Node3D") var velocity_path: NodePath
@export_node_path("LineEdit") var tracking_path: NodePath
@onready var dog: Node3D = get_node(dog_path)
@onready var object: Node3D = get_node(object_path)
@onready var velocity: Node3D = get_node(velocity_path)
@onready var tracking_constant: float = get_node(tracking_path).text.to_float()


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var dog_position := camera.unproject_position(dog.position)
	draw_circle(dog_position, 4.0, Color.RED)
	
	var object_position := camera.unproject_position(object.position)
	draw_circle(object_position, 4.0, Color.RED)
	
	var arrow_vector := Vector3(velocity.basis.y.x, velocity.basis.y.y, 0.0)
	var velocity_position := camera.unproject_position(velocity.global_position + arrow_vector)
	draw_circle(velocity_position, 4.0, Color.BLUE)
	
	draw_line(dog_position, object_position, Color.RED, 2.0)
	draw_line(object_position, velocity_position, Color.BLUE, 2.0)
	draw_line(dog_position, Vector2(dog_position.x - 50.0, dog_position.y), Color.RED, 2.0) # for the angle
	
	draw_arc(dog_position, 50.0, deg_to_rad(180.0), deg_to_rad(180.0) + _get_dog_angle(), 12, Color.RED)
	draw_arc(object_position, 50.0, -_get_velocity_angle(), _get_dog_angle(), 12, Color.BLUE)
	
	var default_font := ThemeDB.fallback_font
	var dog_angle_position := Vector2(dog_position.x - 50.0, dog_position.y + 20.0)
	var dog_angle := rad_to_deg(_get_dog_angle())
	var velocity_angle_position := Vector2(object_position.x + 50.0, object_position.y)
	var velocity_angle := (rad_to_deg(_get_dog_angle()) + rad_to_deg(_get_velocity_angle()))
	draw_string(default_font, dog_angle_position, "%.02f°" % dog_angle)
	draw_string(default_font, velocity_angle_position, "%.02f°" % velocity_angle)
	
	var formula_string := "tracking_constant * x_velocity * cos(velocity_angle - dog_angle)"
	var actual_formula := "%.02f * %.02f * cos(%.02f° - %.02f°)" % [tracking_constant, velocity.basis.y.x, velocity_angle, dog_angle]
	var simplified_formula := "%.02f * %.02f" % [tracking_constant * velocity.basis.y.x, cos(deg_to_rad(velocity_angle - dog_angle))]
	draw_string(default_font, Vector2(dog_position.x + 80.0, dog_position.y - 50.0), formula_string)
	draw_string(default_font, Vector2(dog_position.x + 80.0, dog_position.y - 30.0), actual_formula)
	draw_string(default_font, Vector2(dog_position.x + 80.0, dog_position.y - 10.0), simplified_formula)


func _get_dog_angle() -> float:
	var positive_angle := atan(object.position.y / abs(dog.position.x - object.position.x))
	
	if dog.position.x - (object.position.x) < 0.0:
		return TAU / 2 - positive_angle
	
	return positive_angle


func _get_velocity_angle() -> float:
	return atan(velocity.basis.y.y / velocity.basis.y.x)
