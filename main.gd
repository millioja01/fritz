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
var tracking_constant := 0.1
var tracking_weighting := 0.0166667

var is_testing := false
var allowed_error := deg_to_rad(22.5)
var total_tries := 20
var deviance := 2.0
var x_error := 0.0
var y_error := 0.0
var current_try := 1
var successes := 0
var max_allowed_error := 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hide"):
		$CanvasLayer/Control.visible = not $CanvasLayer/Control.visible


func _physics_process(delta: float) -> void:
	if is_testing:
		testing(delta)
		return
	
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
	
	$Dog.position.x = get_sum_of_dog_change(delta, simulation_time) + dog_x_offset
	update_dog_angle(simulation_time, $Dog.position.x)


func _on_simulate_button_pressed() -> void:
	max_allowed_error = 0.0
	x_error = (randf() - 0.5) * deviance * 2.0
	y_error = (randf() - 0.5) * deviance * 2.0
	current_try = 1
	successes = 0
	simulation_time = 0.0
	is_testing = true


func testing(delta: float) -> void:
	if current_try > total_tries:
			print(str(successes) + "/" + str(total_tries))
			print(float(successes) / float(total_tries) * 100.0, "% success rate")
			print("Max allowed error: ", max_allowed_error)
			is_testing = false
			return
	
	if $Dog/Area3D.has_overlapping_bodies():
		var angle := atan(get_y_velocity(simulation_time) / -get_x_velocity(simulation_time))
		angle -= get_dog_angle(simulation_time, get_sum_of_dog_change(delta, simulation_time) + dog_x_offset)
		angle = abs(angle)
		
		if angle <= allowed_error:
			successes += 1
			if Vector2(x_error, y_error).length() > max_allowed_error:
				max_allowed_error = Vector2(x_error, y_error).length()
			print("success")
		else:
			print("angle is incorrect")
		
		x_error = (randf() - 0.5) * deviance * 2.0
		y_error = (randf() - 0.5) * deviance * 2.0
		simulation_time = 0.0
		current_try += 1
	elif get_y_position(simulation_time) < 0.0:
		x_error = (randf() - 0.5) * deviance * 2.0
		y_error = (randf() - 0.5) * deviance * 2.0
		simulation_time = 0.0
		current_try += 1
		print("hit ground")
	
	simulation_time += delta * $CanvasLayer/Control/TimePanel/TimeMultiplier.text.to_float()
	
	set_object_position(get_x_position(simulation_time), get_y_position(simulation_time))
	set_object_velocity(get_x_velocity(simulation_time), get_y_velocity(simulation_time))
	
	$Dog.position.x = get_sum_of_dog_change(delta, simulation_time) + dog_x_offset
	update_dog_angle(simulation_time, $Dog.position.x)


func set_object_position(x_position: float, y_position: float) -> void:
	$Object.position.x = x_position
	$Object.position.y = y_position


func set_object_velocity(x_velocity: float, y_velocity: float) -> void:
	$Object/VelocityArrow.basis.y.x = x_velocity
	$Object/VelocityArrow.basis.y.y = y_velocity


func get_x_position(time: float) -> float:
	var k := (-drag_coefficient * area_of_cross_section) / (2.0 * volume)
	var n := initial_velocity * cos(initial_angle)
	var c2 := -n / k
	
	return (n / k) * pow(e, k * time) + c2 + object_x_offset


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
	var positive_angle := atan(get_y_position(time) / abs(dog_x_position - (get_x_position(time))))
	
	if dog_x_position - (get_x_position(time)) < 0.0:
		return TAU / 2 - positive_angle
	
	return positive_angle


func get_velocity_angle(time: float, dog_x_position: float) -> float:
	return atan(get_y_velocity(time) / get_x_velocity(time)) + get_dog_angle(time, dog_x_position)


func get_tracking_angle(time: float, dog_x_position: float) -> float:
	var velocity_point := Vector2(get_x_position(time), get_y_position(time))
	velocity_point += tracking_constant * Vector2(get_x_velocity(time) + x_error, get_y_velocity(time) + y_error)
	var angle := atan(velocity_point.y / (velocity_point.x - dog_x_position))
	
	if angle < 0.0:
		angle += TAU / 2
	if velocity_point.y < 0.0:
		angle += TAU / 2
	
	return angle


func update_dog_angle(time: float, dog_x_position: float) -> void:
	$Dog.rotation.z = get_dog_angle(time, dog_x_position)


func get_change_in_dog_position(time: float, dog_x_position: float) -> float:
	return 0.1 * cos(get_tracking_angle(time, dog_x_position))


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


func _on_weight_edit_text_changed(new_text: String) -> void:
	if new_text.to_float() == 0.0:
		return
	
	tracking_weighting = new_text.to_float()


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
