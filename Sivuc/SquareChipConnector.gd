# Purpose: Instantuates scene instances per square sides of sprite for input/output.

extends Sprite

enum SQUARE_SIDES {
	SIDE_TOP = 0
	SIDE_RIGHT = 1
	SIDE_BOTTOM = 2
	SIDE_LEFT = 3
}

export var input_instance:PackedScene = null
export var output_instance:PackedScene = null
export var connection_padding:Vector2 = Vector2.ONE

export var top_inputs_count:int = 0
export var top_outputs_count:int = 0
export var right_inputs_count:int = 0
export var right_outputs_count:int = 0
export var bottom_inputs_count:int = 0
export var bottom_outputs_count:int = 0
export var left_inputs_count:int = 0
export var left_outputs_count:int = 0

var top_inputs:Array = Array()
var top_outputs:Array = Array()
var right_inputs:Array = Array()
var right_outputs:Array = Array()
var bottom_inputs:Array = Array()
var bottom_outputs:Array = Array()
var left_inputs:Array = Array()
var left_outputs:Array = Array()

# Returns 2D size of node instance
# Returns Vector2.ZERO on error
func get_node2d_size( node:Node2D ):
	var rsv:Vector2 = Vector2.ZERO
	if(node is Sprite):
		if(node.texture != null):
			rsv = node.texture.get_size() * node.transform.get_scale()
	return rsv

# Returns size of input packed scene instance(2D)
# Returns Vector2.ZERO on error
func get_input_size():
	var temporary_instance:Node = self.input_instance.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	if(temporary_instance is Node2D):
		return get_node2d_size(temporary_instance)
	return Vector2.ZERO

# Returns size of output packed scene instance(2D)
# Returns Vector2.ZERO on error
func get_output_size():
	var temporary_instance:Node = self.output_instance.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	if(temporary_instance is Node2D):
		return get_node2d_size(temporary_instance)
	return Vector2.ZERO

# Returns array of input instance(s) on a side identified by side_id.
# Returns empty array on error.
func get_side_input_instances(side_id:int):
	if(side_id == SQUARE_SIDES.SIDE_TOP):
		return self.top_inputs
	elif(side_id == SQUARE_SIDES.SIDE_RIGHT):
		return self.right_inputs
	elif(side_id == SQUARE_SIDES.SIDE_BOTTOM):
		return self.bottom_inputs
	elif(side_id == SQUARE_SIDES.SIDE_LEFT):
		return self.left_inputs
	return Array()

# Returns array of output instance(s) on a side identified by side_id.
# Returns empty array on error.
func get_side_output_instances(side_id:int):
	if(side_id == SQUARE_SIDES.SIDE_TOP):
		return self.top_outputs
	elif(side_id == SQUARE_SIDES.SIDE_RIGHT):
		return self.right_outputs
	elif(side_id == SQUARE_SIDES.SIDE_BOTTOM):
		return self.bottom_outputs
	elif(side_id == SQUARE_SIDES.SIDE_LEFT):
		return self.left_outputs
	return Array()

# Returns array of input/output instance(s) on a side identified by side_id.
# Returns empty array on error.
func get_side_instances(side_id:int):
	var buffer:Array = get_side_input_instances(side_id)
	buffer.append(get_side_output_instances(side_id))
	return buffer

# Returns the predicted distance between the first input and last output's position given the size and count.
# Returns 0.0 on error
func calculate_side_size(side_id:int, input_instance_count:int, output_instance_count:int, input_instance_size:Vector2, output_instance_size:Vector2, padding:Vector2 = Vector2.ZERO):
	var rfv:float = 0.0
	var total_count:int = input_instance_count + output_instance_count
	if(side_id == SQUARE_SIDES.SIDE_TOP || side_id == SQUARE_SIDES.SIDE_BOTTOM):
		rfv += (input_instance_size.x * input_instance_count)
		rfv += (output_instance_size.x * output_instance_count)
		if(total_count > 0):
			rfv += (padding.x * (total_count - 1))
	elif(side_id == SQUARE_SIDES.SIDE_LEFT || side_id == SQUARE_SIDES.SIDE_RIGHT):
		rfv += (input_instance_size.y * input_instance_count)
		rfv += (output_instance_size.y * output_instance_count)
		if(total_count > 0):
			rfv += (padding.y * (total_count - 1))
	return rfv

# Returns the desired count of input instances per side on success.
# Returns -1 on error.
func get_side_target_input_count(side_id:int):
	var target_count:int = -1
	if(side_id == SQUARE_SIDES.SIDE_TOP):
		target_count = self.top_inputs_count
	elif(side_id == SQUARE_SIDES.SIDE_RIGHT):
		target_count = self.right_inputs_count
	elif(side_id == SQUARE_SIDES.SIDE_BOTTOM):
		target_count = self.bottom_inputs_count
	elif(side_id == SQUARE_SIDES.SIDE_LEFT):
		target_count = self.left_inputs_count
	else:
		# ERROR
		pass
	return target_count

# Returns the desired count of output instances per side on success.
# Returns -1 on error.
func get_side_target_output_count(side_id:int):
	var target_count:int = -1
	if(side_id == SQUARE_SIDES.SIDE_TOP):
		target_count = self.top_outputs_count
	elif(side_id == SQUARE_SIDES.SIDE_RIGHT):
		target_count = self.right_outputs_count
	elif(side_id == SQUARE_SIDES.SIDE_BOTTOM):
		target_count = self.bottom_outputs_count
	elif(side_id == SQUARE_SIDES.SIDE_LEFT):
		target_count = self.left_outputs_count
	else:
		# ERROR
		pass
	return target_count

# Returns the actual distance between the first input and last output's position of this instance.
# Returns 0.0 on error
func get_side_size(side_id:int, padding:Vector2 = Vector2.ZERO):
	var instances:Array = get_side_instances(side_id)
	var rfv:float = 0.0
	for i in instances:
		var next_size:Vector2 = get_node2d_size(i)
		if(side_id == SQUARE_SIDES.SIDE_TOP || side_id == SQUARE_SIDES.SIDE_BOTTOM):
			rfv += next_size.x
			if(instances.size() > 0):
				rfv += padding.x * (instances.size() - 1)
		elif(side_id == SQUARE_SIDES.SIDE_LEFT || side_id == SQUARE_SIDES.SIDE_RIGHT):
			rfv += next_size.y
			if(instances.size() > 0):
				rfv += padding.y * (instances.size() - 1)
	return rfv

# Returns 2D connection position relative to parent given all needed information.
func _calculate_connection_position(side_id:int, connection_index:int, input_instance_count:int, output_instance_count:int, self_top_left_offset:Vector2, self_bottom_right_offset:Vector2, self_size:Vector2, input_instance_size:Vector2, output_instance_size:Vector2, padding:Vector2 = Vector2.ZERO):
	var side_len:float = calculate_side_size(side_id, input_instance_count, output_instance_count, input_instance_size, output_instance_size, padding)
	var x:float = 0.0
	var y:float = 0.0
	var ic:int = 0
	var oc:int = 0
	var node_offset:Vector2 = Vector2.ZERO
	# How many of each type
	if(connection_index >= input_instance_count):
		ic = input_instance_count
		oc = connection_index - input_instance_count
		node_offset = get_node2d_bottom_right(output_instance.instance(PackedScene.GEN_EDIT_STATE_INSTANCE))
	else:
		ic = connection_index
		node_offset = get_node2d_bottom_right(input_instance.instance(PackedScene.GEN_EDIT_STATE_INSTANCE))
	if(oc >= output_instance_count):
		# ERROR
		# Silently continues...
		pass
	# Common Scalar Calculation
	if(side_id == SQUARE_SIDES.SIDE_TOP || side_id == SQUARE_SIDES.SIDE_BOTTOM):
		x = self_top_left_offset.x + (self_size.x / 2.0) + node_offset.x - (side_len / 2.0) + ((input_instance_size.x * ic) + (output_instance_size.x * oc) + ((ic + oc) * padding.x))
	elif(side_id == SQUARE_SIDES.SIDE_RIGHT || side_id == SQUARE_SIDES.SIDE_LEFT):
		y = self_top_left_offset.y + (self_size.y / 2.0) + node_offset.y - (side_len / 2.0) + ((input_instance_size.y * ic) + (output_instance_size.y * oc) + ((ic + oc) * padding.y))
	# Side Specific
	if(side_id == SQUARE_SIDES.SIDE_TOP):
		y = self_top_left_offset.y
	elif(side_id == SQUARE_SIDES.SIDE_RIGHT):
		x = self_bottom_right_offset.x
	elif(side_id == SQUARE_SIDES.SIDE_BOTTOM):
		y = self_bottom_right_offset.y
	elif(side_id == SQUARE_SIDES.SIDE_LEFT):
		x = self_top_left_offset.x
	return Vector2(x, y)

# Helper Function
func calculate_connection_position(side_id:int, connection_index:int, input_instance_count:int, output_instance_count:int):
	return _calculate_connection_position(side_id, connection_index, input_instance_count,
		output_instance_count, get_node2d_top_left(self), get_node2d_bottom_right(self),
		get_node2d_size(self), get_input_size(), get_output_size(), self.connection_padding
	)

# Returns top left point of visuals for Node2D
func get_node2d_top_left( node:Node2D ):
	if(node is Sprite):
		if(node.centered):
			return get_node2d_size(node) / -2.0
		else:
			return Vector2.ZERO
	return Vector2.ZERO

# Returns bottom right point of visuals for Node2D
# Returns Vector2.ZERO on error
func get_node2d_bottom_right( node:Node2D ):
	if(node is Sprite):
		var node_size:Vector2 = get_node2d_size(node)
		if(node.centered):
			return node_size / 2.0
		else:
			return node_size
	return Vector2.ZERO

func validate_side_inputs(side_id:int) -> void:
	var delta:int = 0
	var target_array:Array = get_side_input_instances(side_id)
	var target_input_count:int = get_side_target_input_count(side_id)
	var target_output_count:int = get_side_target_output_count(side_id)
	delta = target_input_count - target_array.size()
	# Remove (as needed)
	for i in range(delta * -1):
		self.remove_child(self.target_array[i])
		target_array.remove(self.target_array.size() - 1)
	# Add (as needed)
	var current_i:int = target_array.size()
	for i in range(delta):
		if self.input_instance == null:
			break
		var next_child = self.input_instance.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
		next_child.position = calculate_connection_position(side_id, current_i + i, target_input_count, target_output_count)
		self.add_child(next_child)
		target_array.append(next_child)

func validate_side_outputs(side_id:int) -> void:
	var delta:int = 0
	var target_array:Array = get_side_output_instances(side_id)
	var target_input_count:int = get_side_target_input_count(side_id)
	var target_output_count:int = get_side_target_output_count(side_id)
	delta = target_output_count - target_array.size()
	# Remove (as needed)
	for i in range(delta * -1):
		self.remove_child(self.target_array[i])
		target_array.remove(self.target_array.size() - 1)
	# Add (as needed)
	var current_i:int = get_side_input_instances(side_id).size() + target_array.size()
	for i in range(delta):
		if self.output_instance == null:
			break
		var next_child = self.output_instance.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
		next_child.position = calculate_connection_position(side_id, current_i + i, target_input_count, target_output_count)
		self.add_child(next_child)
		target_array.append(next_child)

func validate_side(side_id:int) -> void:
	validate_side_inputs(side_id)
	validate_side_outputs(side_id)

func validate_sides() -> void:
	for side_counter in range(4):
		validate_side(side_counter)

func _ready():
	validate_sides()
