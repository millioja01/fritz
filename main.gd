extends Node


const e := 2.7182818284

@onready var object_x_offset: float = $Object.position.x
@onready var dog_x_offset: float = $Dog.position.x

var initial_velocity := 2.26
var initial_angle := deg_to_rad(45)
var initial_height := 1.0

var gravity := 9.8 # g
var volume := 0.0052 # l
var drag_coefficient := 0.47 # Cd
var area_of_cross_section := 0.008 # Ac
var simulation_time := 0.0 # t
var tracking_constant := -0.03


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hide"):
		$CanvasLayer/Control.visible = not $CanvasLayer/Control.visible


func _physics_process(delta: float) -> void:
	if %TimeCheckBox.button_pressed:
		simulation_time += delta * %TimeMultiplier.text.to_float()
		if simulation_time > %TimeSlider.max_value:
			%TimeCheckBox.button_pressed = false
			simulation_time = %TimeSlider.max_value
		simulation_time = clamp(simulation_time, 0.0, %TimeSlider.max_value)
		%TimeSlider.editable = false
		%TimeSlider.value = simulation_time
	else:
		%TimeSlider.editable = true
		simulation_time = %TimeSlider.value
	
	set_object_position(get_x_position(simulation_time), get_y_position(simulation_time))
	set_object_velocity(get_x_velocity(simulation_time), get_y_velocity(simulation_time))
	
	update_dog_angle(simulation_time, $Dog.position.x)
	$Dog.position.x = get_sum_of_dog_change(delta, simulation_time) + dog_x_offset


func set_object_position(x_position: float, y_position: float) -> void:
	$Object.position.x = x_position + object_x_offset
	$Object.position.y = y_position


func set_object_velocity(x_velocity: float, y_velocity: float) -> void:
	$Object/VelocityArrow.basis.y.x = x_velocity
	$Object/VelocityArrow.basis.y.y = y_velocity


func get_x_position(time: float) -> float:
	var k := (-drag_coefficient * area_of_cross_section) / (2.0 * volume)
	var n := initial_velocity * cos(initial_angle)
	var c2 := -n / k
	
	return (n / k) * pow(e, k * time) + c2


func get_x_velocity(time: float) -> float:
	var v := initial_velocity * cos(initial_angle)
	var k := (-drag_coefficient * area_of_cross_section) / (2.0 * volume)
	
	return v * pow(e, k * time)


func get_y_position(time: float) -> float:
	var k := (-drag_coefficient * area_of_cross_section) / (2.0 * volume)
	var m := initial_velocity * sin(initial_angle)
	var c1 := initial_height - m - (gravity / k)
	
	return m * pow(e, time) + gravity * pow(e, time) / k - gravity * time / k + c1
#	return 1.6 * pow(e, time) + (gravity / k) * pow(e, time) - (gravity * time) / k + c1


func get_y_velocity(time: float) -> float:
	var v := initial_velocity * sin(initial_angle)
	var k := (-drag_coefficient * area_of_cross_section) / (2.0 * volume)
	
	return ((k * v + gravity) * pow(e, time) - gravity) / k


func get_dog_angle(time: float, dog_x_position: float) -> float:
	var positive_angle := atan(get_y_position(time) / abs(dog_x_position - (get_x_position(time) + object_x_offset)))
	
	if dog_x_position - (get_x_position(time) + object_x_offset) < 0.0:
		return TAU / 2 - positive_angle
	
	return positive_angle


func get_velocity_angle(time: float, dog_x_position: float) -> float:
	return atan(get_y_velocity(time) / get_x_velocity(time)) + get_dog_angle(time, dog_x_position)


func update_dog_angle(time: float, dog_x_position: float) -> void:
	$Dog.rotation.z = get_dog_angle(time, dog_x_position)


func get_change_in_dog_position(time: float, dog_x_position: float) -> float:
	return tracking_constant * get_x_velocity(time) * cos(get_velocity_angle(time, dog_x_position) - get_dog_angle(time, dog_x_position))


func get_sum_of_dog_change(delta: float, time: float) -> float:
	var sum_of_change := 0.0
	var current_time := 0.0
	while current_time <= time:
		sum_of_change += get_change_in_dog_position(current_time, sum_of_change + dog_x_offset)
		current_time += delta
	
	return sum_of_change


func _on_volume_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	volume = new_text.to_float()


func _on_drag_edit_x_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	drag_coefficient = new_text.to_float()


func _on_cross_section_area_x_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	area_of_cross_section = new_text.to_float()


func _on_drag_edit_y_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	drag_coefficient = new_text.to_float()


func _on_cross_section_area_y_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	area_of_cross_section = new_text.to_float()


func _on_object_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	object_x_offset = new_text.to_float()


func _on_dog_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	dog_x_offset = new_text.to_float()


func _on_tracking_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	tracking_constant = new_text.to_float()


func _on_velocity_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	initial_velocity = new_text.to_float()


func _on_angle_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	initial_angle = deg_to_rad(new_text.to_float())


func _on_height_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	initial_height = new_text.to_float()
