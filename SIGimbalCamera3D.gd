#Gimbal Node based 3d Camera control script.
### WARNING ###
#This script changes node tree by adding two "gimbal" nodes at the camera position for easier rotation math.
### WARNING ###

class_name SIGimbalCamera3D extends Camera

#####################
#Constants / Defaults
#####################
const TWO_PIE:float = (2.0 * PI)

const DEFAULT_ROTATION_BASE_NAME:String = "CameraBase"# Yaw Node
const DEFAULT_ROTATION_ARM_NAME:String = "CameraArm"# Pitch Node

const DEFAULT_CAMERA_DISTANCE:float = 1.0
const DEFAULT_CAMERA_DISTANCE_MIN:float = 0.001#Very close but not disabled.
const DEFAULT_CAMERA_DISTANCE_MAX:float = 0.0#Disabled
const DEFAULT_CAMERA_DISTANCE_ACCELERATION:float = 20.0#No good justification just felt like a good value.

const DEFAULT_ROTATION_MIN:float = 0.0#Disabled
const DEFAULT_ROTATION_MAX:float = 0.0#Disabled
const DEFAULT_ROTATION_DEGREES_MIN:float = rad2deg(DEFAULT_ROTATION_MIN)
const DEFAULT_ROTATION_DEGREES_MAX:float = rad2deg(DEFAULT_ROTATION_MAX)
const DEFAULT_YAW:float = 0.0
const DEFAULT_PITCH:float = 0.0
const DEFAULT_ROLL:float = 0.0

const DEFAULT_DISTANCE_INCREASE_ACTION_NAME:String = "camera_distance_out"
const DEFAULT_DISTANCE_DECREASE_ACTION_NAME:String = "camera_distance_in"
const DEFAULT_YAW_INCREASE_ACTION_NAME:String = "camera_yaw_right"
const DEFAULT_YAW_DECREASE_ACTION_NAME:String = "camera_yaw_left"
const DEFAULT_PITCH_INCREASE_ACTION_NAME:String = "camera_pitch_down"
const DEFAULT_PITCH_DECREASE_ACTION_NAME:String = "camera_pitch_up"
const DEFAULT_ROLL_INCREASE_ACTION_NAME:String = "camera_roll_left"
const DEFAULT_ROLL_DECREASE_ACTION_NAME:String = "camera_roll_right"

const DEFAULT_PHYSICS_MASK:int = 1

const DEFAULT_SCROLL_WHEEL_USAGE:bool = true

###############################
#Variables / Exported Variables
###############################
export(bool) var debug_mode:bool = false
export(Mesh) var debug_mesh:Mesh = null
export(Color) var debug_base_color:Color = Color.crimson
export(Color) var debug_arm_color:Color = Color.aqua

# I was going to have these parent spatial node names be editable.
# This would allow the use of already existing parent spatial nodes by entering in the name of the nodes.
# However this allowed the values to be changed at runtime causing mismatching node values to expected script values.
# This may cause node lookup issues(?)
# This a couple ways I could fix this:
# #1.) I could ignore it and hope no one tries it or that it would work anyway.
# #2.) I could change the names of the parent nodes as the exported variables values change.(Keeps the nodes in sync with the script)
# #3.) I could just use any 2 parent spatial nodes as my gimbal nodes and read in their names/paths for lookup(if needed). (Problems if user doesnt know to create parent nodes. Could rotate/translate nodes that are not intended.)
# #4.) I could just always make the parent nodes with the same names, so that unless the user explicitly names their parent spatial node the same name as the script expects, already existing nodes wont be used. And generated node paths can't be changed externally.
# I am tring for #4.
#export(String)
var rotation_base_name:String = DEFAULT_ROTATION_BASE_NAME
#export(String)
var rotation_arm_name:String = DEFAULT_ROTATION_ARM_NAME
var rotation_base:Spatial = null
var rotation_arm:Spatial = null

#Camera Distance(in/out)
var distance_direction:float = 0.0#What direction in/out did we last get an input event for?
export(float) var distance:float = DEFAULT_CAMERA_DISTANCE setget distance_set# Current distance between camera and origin
export(String) var distance_increase_action_name:String = DEFAULT_DISTANCE_INCREASE_ACTION_NAME# Name of the input action group used in increase the target distance value
export(String) var distance_decrease_action_name:String = DEFAULT_DISTANCE_DECREASE_ACTION_NAME# Name of the input action group used in decrease the target distance value
export(float) var distance_target:float = DEFAULT_CAMERA_DISTANCE# Current distance from origin the camera should be moving to
export(float) var distance_min:float = DEFAULT_CAMERA_DISTANCE_MIN#TODO
export(float) var distance_max:float = DEFAULT_CAMERA_DISTANCE_MAX#TODO

export(float) var distance_acceleration:float = DEFAULT_CAMERA_DISTANCE_ACCELERATION#How fast does the target distance change per input frame?
export(float) var distance_target_acceleration:float = self.distance_acceleration#How fast should the actual distance change towards the target distance?(Smoothing)
export(float) var distance_velocity:float = 0.0#How fast are we currently moving the target distance?
export(float) var distance_dampening:float = 0.1#How much should we slow down the distance velocity every frame?
#Left/Right
export(float) var yaw:float = DEFAULT_YAW setget yaw_set# Current yaw in radians
export(float) var yaw_degrees:float = rad2deg(yaw) setget yaw_degrees_set# Current yaw in degrees
export(String) var yaw_increase_action_name:String = DEFAULT_YAW_INCREASE_ACTION_NAME# Name of the input action group used in increase the target yaw value
export(String) var yaw_decrease_action_name:String = DEFAULT_YAW_DECREASE_ACTION_NAME# Name of the input action group used in decrease the target yaw value
export(float) var yaw_target:float = DEFAULT_YAW setget yaw_target_set# The current yaw value the camera should be rotating to in radians
export(float) var yaw_target_degrees:float = rad2deg(yaw_target) setget yaw_target_degrees_set# The current yaw value the camera should be rotating to in degrees
export(float) var yaw_min:float = DEFAULT_ROTATION_MIN setget yaw_min_set# Limit the minimum yaw value of the current camera in radians. Always positive.
export(float) var yaw_max:float = DEFAULT_ROTATION_MAX setget yaw_max_set# Limit the maximum yaw value of the current camera in radians. Always positive.
export(float) var yaw_degrees_min:float = DEFAULT_ROTATION_DEGREES_MIN setget yaw_degrees_min_set# Limit the minimum yaw value of the current camera in degrees. Always positive.
export(float) var yaw_degrees_max:float = DEFAULT_ROTATION_DEGREES_MAX setget yaw_degrees_max_set# Limit the maximum yaw value of the current camera in degrees. Always positive.
#Forward/Backward
export(float) var pitch:float = DEFAULT_YAW setget pitch_set# Current pitch in radians
export(float) var pitch_degrees:float = rad2deg(yaw) setget pitch_degrees_set# Current pitch in degrees
export(String) var pitch_increase_action_name:String = DEFAULT_PITCH_INCREASE_ACTION_NAME# Name of the input action group used in increase the target pitch value
export(String) var pitch_decrease_action_name:String = DEFAULT_PITCH_DECREASE_ACTION_NAME# Name of the input action group used in decrease the target pitch value
export(float) var pitch_target:float = DEFAULT_YAW# The current pitch value the camera should be rotating to in radians
export(float) var pitch_target_degrees:float = rad2deg(yaw_target)# The current pitch value the camera should be rotating to in degrees
export(float) var pitch_min:float = DEFAULT_ROTATION_MIN setget pitch_min_set# Limit the minimum pitch value of the current camera in radians. Always positive.
export(float) var pitch_max:float = DEFAULT_ROTATION_MAX setget pitch_max_set# Limit the maximum pitch value of the current camera in radians. Always positive.
export(float) var pitch_degrees_min:float = DEFAULT_ROTATION_DEGREES_MIN setget pitch_degrees_min_set# Limit the minimum pitch value of the current camera in degrees. Always positive.
export(float) var pitch_degrees_max:float = DEFAULT_ROTATION_DEGREES_MAX setget pitch_degrees_max_set# Limit the maximum pitch value of the current camera in degrees. Always positive.
#Roll
export(float) var roll:float = DEFAULT_YAW setget roll_set# Current roll in radians
export(float) var roll_degrees:float = rad2deg(yaw) setget roll_degrees_set# Current roll in degrees
export(String) var roll_increase_action_name:String = DEFAULT_ROLL_INCREASE_ACTION_NAME# Name of the input action group used in increase the target roll value
export(String) var roll_decrease_action_name:String = DEFAULT_ROLL_DECREASE_ACTION_NAME# Name of the input action group used in decrease the target roll value
export(float) var roll_target:float = DEFAULT_YAW# The current roll value the camera should be rotating to in radians
export(float) var roll_target_degrees:float = rad2deg(yaw_target)# The current roll value the camera should be rotating to in degrees
export(float) var roll_min:float = DEFAULT_ROTATION_MIN setget roll_min_set# Limit the minimum roll value of the current camera in radians. Always positive.
export(float) var roll_max:float = DEFAULT_ROTATION_MAX setget roll_max_set# Limit the maximum roll value of the current camera in radians. Always positive.
export(float) var roll_degrees_min:float = DEFAULT_ROTATION_DEGREES_MIN setget roll_degrees_min_set# Limit the minimum roll value of the current camera in degrees. Always positive.
export(float) var roll_degrees_max:float = DEFAULT_ROTATION_DEGREES_MAX setget roll_degrees_max_set# Limit the maximum roll value of the current camera in degrees. Always positive.

#Collision
export(int, LAYERS_3D_PHYSICS) var physics_mask:int = DEFAULT_PHYSICS_MASK
export(bool) var collide_camera:bool = false#TODO Camera collides with physics during movements/rotations.
#We will have to change distance directly no target distance to prevent visual clipping(no smooth).

var rotation_direction_vector:Vector3 = Vector3.ZERO#TODO What was the desired direction of rotation based upon the last input event(s).
export(Vector3) var rotation_velocity_vector:Vector3 = Vector3.ZERO#TODO How fast are we currently rotating the target each frame per axis?
export(Vector3) var rotation_target_acceleration_vector:Vector3 = Vector3(self.TWO_PIE, self.TWO_PIE, self.TWO_PIE)#Disabled How fast towards the target do we accelerate?
export(Vector3) var rotation_acceleration_vector:Vector3 = Vector3(PI / 16, PI / 16, PI / 16)#TODO How fast per frame do we change our velocity?
export(Vector3) var rotation_dampening_vector:Vector3 = Vector3(PI / 32, PI / 32, PI / 32)#TODO How much per frame should we slow down our velocity without input.

#Mouse
export(bool) var use_scroll_wheel:bool = DEFAULT_SCROLL_WHEEL_USAGE#TODO
export(bool) var use_mouse_movement:bool = false#TODO
export(float, -1.0, 3.0) var mouse_sensitivity:float = 1.0#Scalar
export(bool) var capture_mouse:bool = false#TODO
export(bool) var require_left_drag:bool = false#TODO
export(bool) var require_middle_drag:bool = false#TODO
export(bool) var require_right_drag:bool = false#TODO
var last_mouse_pos:Vector2 = Vector2.ZERO#TODO
var was_lmb_pressed:bool = false#TODO
var was_mmb_pressed:bool = false#TODO
var was_rmb_pressed:bool = false#TODO
#Updated via onWindowResize()
var last_viewport_size:Vector2 = Vector2.ZERO#TODO
var last_viewport_center:Vector2 = Vector2.ZERO#TODO
var radians_per_pixel:Vector2 = Vector2.ZERO#TODO
var degrees_per_pixel:Vector2 = Vector2.ZERO#TODO

#Movement
#TODO
export(bool) var allow_camera_movement:bool = false
export(bool) var move_parent:bool = false
var movement_direction_vector:Vector3 = Vector3.ZERO#TODO What was the desired direction of movement based upon the last input event(s).
export(String) var movement_forward_action_name:String = "camera_move_forward"#TODO
export(String) var movement_backward_action_name:String = "camera_move_backward"#TODO
export(String) var movement_left_action_name:String = "camera_move_left"#TODO
export(String) var movement_right_action_name:String = "camera_move_right"#TODO
export(String) var movement_up_action_name:String = "camera_move_up"#TODO
export(String) var movement_down_action_name:String = "camera_move_down"#TODO
export(Vector3) var movement_velocity_vector:Vector3 = Vector3.ZERO#TODO How fast are we currently moving the target position each frame per axis?
export(Vector3) var movement_acceleration_vector:Vector3 = Vector3(3.0, 3.0, 3.0)#TODO How fast per frame do we change our velocity?
export(Vector3) var movement_target_acceleration_vector:Vector3 = self.movement_acceleration_vector#Disabled How fast towards the target do we accelerate?
export(Vector3) var movement_dampening_vector:Vector3 = Vector3(0.1, 0.1, 0.1)#TODO How much per frame should we slow down our velocity without input.
export(Vector3) var movement_maximum_velocity:Vector3 = Vector3.INF#Disabled

##########
#Functions
##########
func printd(s:String, prefix:String = "[DEBUG]: "):
	#Prints out a debug message if in debug mode and s isn't empty.
	if(s == ""):
		return
	if(self.debug_mode):
		print(prefix + s)

func moveNumberTowardsNumber(value:float, target:float, speed:float):
	#Adds or subtracts based upon the target value your moving towards
	#Used for dampening of rotation.
	var delta:float = 0.0
	speed = abs(speed)
	if(target < value):
		delta = value - target
		if delta >= speed:
			return value - speed
	else:
		delta = target - value
		if delta >= speed:
			return value + speed
	#if delta < speed:
	return target
func moveVector3TowardsNumber(value:Vector3, target:float, speed:float):
	#Helper Function
	#[DEPRECATED]
	value.x = self.moveNumberTowardsNumber(value.x, target, speed)
	value.y = self.moveNumberTowardsNumber(value.y, target, speed)
	value.z = self.moveNumberTowardsNumber(value.z, target, speed)
	return value
func moveVector3TowardsVector3(value:Vector3, target:Vector3, speed:Vector3):
	#Helper Function
	value.x = self.moveNumberTowardsNumber(value.x, target.x, speed.x)
	value.y = self.moveNumberTowardsNumber(value.y, target.y, speed.y)
	value.z = self.moveNumberTowardsNumber(value.z, target.z, speed.z)
	return value

func moveNumberTowardsNumberWithBounds(value:float, target:float, speed:float, bound:float):
	#Moves value towards target value by speed amount with a rollover of bounds.
	#E.g. when bound is 360, 5 is closer to 355 than 340.0 is. (-10 vs 15)
	#Used to apply rotational velocity towards target rotation in _physics_process()
	#Note: Doesn't apply bounds as a limit.
	speed = abs(speed)
	bound = abs(bound)
	#First we determine which direction is "closer"
	var neg_distance:float = 0.0
	var pos_distance:float = 0.0
	if(target < value):
		neg_distance = value - target
		pos_distance = (bound - value) + target
	else:
		neg_distance = value + (bound - target)
		pos_distance = target - value
	if(neg_distance < pos_distance):
		#We decrease by speed
		if(value - speed <= target):
			return target
		else:
			return value - speed
	else:
		#We increase by speed
		if(value + speed >= target):
			return target
		else:
			return value + speed
func moveVector3TowardsNumberWithBounds(value:Vector3, target:float, speed:float, bounds:float):
	#Helper Function
	value.x = self.moveNumberTowardsNumberWithBounds(value.x, target, speed, bounds)
	value.y = self.moveNumberTowardsNumberWithBounds(value.y, target, speed, bounds)
	value.z = self.moveNumberTowardsNumberWithBounds(value.z, target, speed, bounds)
	return value
func moveVector3TowardsVector3WithBounds(value:Vector3, target:Vector3, speed:float, bounds:float):
	#Helper Function
	value.x = self.moveNumberTowardsNumberWithBounds(value.x, target.x, speed, bounds)
	value.y = self.moveNumberTowardsNumberWithBounds(value.y, target.y, speed, bounds)
	value.z = self.moveNumberTowardsNumberWithBounds(value.z, target.z, speed, bounds)
	return value

func isBaseSpatial( node:Node ):
	# Is node a spatial that is named rotation_base_name?
	if not node is Spatial:
		return false
	return node.name == rotation_base_name
func hasBaseSpatial():
	# Does the rotation_arm spatial/node have a parent spatial named rotation_base_name?
	if self.rotation_arm == null:
		return false
	return self.isBaseSpatial(self.rotation_arm.get_parent())

func isArmSpatial( node:Node ):
	# Is node a spatial that is named rotation_arm_name?
	if not node is Spatial:
		return false
	return node.name == rotation_arm_name
func hasArmParent():
	# Is this camera a child of a spatial node named rotation_arm_name?
	return isArmSpatial(self.get_parent())

func setupCameraRotationNodes():
	# Conduct node and camera setup
	# Should only be called once. Called from _ready() method.
	# The cameras current translation is used as the origin.
	var current_parent_node:Node = self.get_parent()
	if(not hasArmParent()):
		self.rotation_arm = MeshInstance.new()#Spatial.new()#Later on may make visible for debugging
		if(not self.debug_mesh == null):
			self.rotation_arm.mesh = self.debug_mesh.duplicate(true)
			if(self.rotation_arm.mesh.material == null):
				self.rotation_arm.mesh.material = SpatialMaterial.new()
			if(self.rotation_arm.mesh.material is SpatialMaterial):
				self.rotation_arm.mesh.material.albedo_color = self.debug_arm_color
		self.rotation_arm.visible = self.debug_mode
		self.rotation_arm.name = self.rotation_arm_name
		var _returned_connect_value = rotation_arm.connect("tree_entered", self, "onArmAdded")
		self.rotation_arm.translation = self.translation#Move arm node to camera
		self.rotation_arm.rotation.x = self.pitch# Initialize rotation
		# Reparenting of camera node to a child of the generated arm spatial node.
		#Must be defered if called from _ready()
		current_parent_node.call_deferred("add_child", rotation_arm)
		current_parent_node.call_deferred("remove_child", self)
		rotation_arm.call_deferred("add_child", self)
	#Arm should be defined. May or may not be in the tree if just created.(probably not)
	if(not hasBaseSpatial()):
		self.rotation_base = MeshInstance.new()#Spatial.new()#Later on may make visible for debugging
		if(not self.debug_mesh == null):
			self.rotation_base.mesh = self.debug_mesh.duplicate(true)
			if(self.rotation_base.mesh.material == null):
				self.rotation_base.mesh.material = SpatialMaterial.new()
			if(self.rotation_base.mesh.material is SpatialMaterial):
				self.rotation_base.mesh.material.albedo_color = self.debug_base_color
		self.rotation_base.visible = self.debug_mode
		self.rotation_base.name = self.rotation_base_name
		var _returned_connect_value = rotation_base.connect("tree_entered", self, "onBaseAdded")
		self.rotation_base.translation = rotation_arm.translation#Move base node to the arm
		self.rotation_arm.translation = Vector3.ZERO#Reset the arm's translation to the base
		self.rotation_base.rotation.y = self.yaw# Initialize rotation
		current_parent_node.call_deferred("add_child", self.rotation_base)
		current_parent_node.call_deferred("remove_child", self.rotation_arm)
		self.rotation_base.call_deferred("add_child", self.rotation_arm)
	self.translation = Vector3(0.0, 0.0, self.distance)#Initialize distance
	self.rotation.z = self.roll# Initialize rotation
	return self

func _updateYaw():
	#Called by setter method to apply changed value to node(s).
	if(self.rotation_base == null):
		printd("Attempted to update camera yaw before the base gimbal node was initialized!", "[WARN]: ")#Debugging
		return
	self.rotation_base.rotation.y = self.yaw
func _updatePitch():
	#Called by setter method to apply changed value to node(s).
	if(self.rotation_arm == null):
		printd("Attempted to update camera pitch before the arm gimbal node was initialized!", "[WARN]: ")#Debugging
		return
	self.rotation_arm.rotation.x = self.pitch
func _updateRoll():
	#Called by setter method to apply changed value to node(s).
	self.rotation.z = self.roll
func _updateRotation():
	#Originally all nodes rotations were set each time any one of these values changed.
	#Now each update function is only called as needed.
	#As such this method is no longer used and may be removed[DEPRICATED].
	self._updateYaw()
	self._updatePitch()
	self._updateRoll()

func applyMinimumWithPossibleMaximum(value:float, minimum:float, maximum:float = 0.0):
	#Helper Function
	#Used by setter methods to apply rotational limits to values.
	minimum = abs(minimum)#Shouldn't be needed at this point but better safe than sorry
	maximum = abs(maximum)#Shouldn't be needed at this point but better safe than sorry
	if(minimum == 0.0):
		#Assume there is no minimum
		if(maximum <= minimum):
			#Assume there is no minimum, no maximum
			return value
		else:
			#There is a maximum, no minimum
			if(abs(value) < maximum):
				return value
			else:
				#Larger than the maximum
				if(value < 0.0):
					return -maximum
				else:
					return maximum
	else:
		#There is a minimum.
		if(maximum <= minimum):
			#Assume there is no maximum, is a minimum
			if abs(value) < minimum:
				#Smaller than the minimum
				if value < 0.0:
					return -minimum
				else:
					return minimum
			else:
				return value
		else:
			#There is a maximum and minimum
			return clamp(value, minimum, maximum)

func divide_float_by_vector2(value:float, divider:Vector2):
	#Helper Function
	#Used by _input(delta)
	return Vector2(value / divider.x, value / divider.y)

func mouse_btn_active():
	#Returns true if required mouse buttons were pressed as of the last input events.
	#Or if and mouse buttons being held are unrequired for mouse movement.
	#Otherwise returns false.
	if(self.require_left_drag and not self.was_lmb_pressed):
		return false
	if(self.require_middle_drag and not self.was_mmb_pressed):
		return false
	if(self.require_right_drag and not self.was_rmb_pressed):
		return false
	return true

############################
#Inherited Methods/Functions
############################
func _ready():
	var _crv = self.get_tree().get_root().connect("size_changed", self, "onWindowResize")
	self.onWindowResize()#Initialize viewport rect value.
	self.setupCameraRotationNodes()
	self.set_process_input(true)
	self.set_process(false)
	self.set_physics_process(true)
	#Doesn't receive mouse events?
	#if(Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and self.capture_mouse):#TODO
	#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)#TODO

#(x,y,z) => (pitch,yaw,roll)
func _input(_event):
	#It makes me sad that Input map doesn't work as well as hard coding some inputs.
	#For example press and release are both actions with no way to change it in the map.
	#And there is no axis for the mouse movements.
	if(_event.is_action(self.distance_increase_action_name)):#camera_distance_out
		self.distance_direction = 1.0
	elif(_event.is_action(self.distance_decrease_action_name)):#camera_distance_in
		self.distance_direction = -1.0
	else:
		self.distance_direction = 0.0
	#Reset rotation direction vector
	self.rotation_direction_vector = Vector3.ZERO
	if(_event.is_action(self.yaw_increase_action_name)):#camera_yaw_right
		self.rotation_direction_vector.y += 1.0
	if(_event.is_action(self.yaw_decrease_action_name)):#camera_yaw_left
		self.rotation_direction_vector.y -= 1.0
	if(_event.is_action(self.pitch_increase_action_name)):#camera_pitch_down
		self.rotation_direction_vector.x += 1.0
	if(_event.is_action(self.pitch_decrease_action_name)):#camera_pitch_up
		self.rotation_direction_vector.x -= 1.0
	if(_event.is_action(self.roll_increase_action_name)):#camera_roll_left
		self.rotation_direction_vector.z += 1.0
	if(_event.is_action(self.roll_decrease_action_name)):#camera_roll_right
		self.rotation_direction_vector.z -= 1.0
	#Camera/Parent movements
	#TODO
	#Reset movement direction vector
	self.movement_direction_vector = Vector3.ZERO
	if(_event.is_action(self.movement_forward_action_name)):#camera_move_forward
		self.movement_direction_vector.z -= 1.0
	if(_event.is_action(self.movement_backward_action_name)):#camera_move_backward
		self.movement_direction_vector.z += 1.0
	if(_event.is_action(self.movement_left_action_name)):#camera_move_left
		self.movement_direction_vector.x -= 1.0
	if(_event.is_action(self.movement_right_action_name)):#camera_move_right
		self.movement_direction_vector.x += 1.0
	if(_event.is_action(self.movement_up_action_name)):#camera_move_up
		self.movement_direction_vector.y += 1.0
	if(_event.is_action(self.movement_down_action_name)):#camera_move_down
		self.movement_direction_vector.y -= 1.0
	#Mouse movements
	if(_event is InputEventMouseButton):
		if(_event.pressed):
			if(_event.button_index == BUTTON_LEFT):
				self.was_lmb_pressed = true
			elif(_event.button_index == BUTTON_MIDDLE):
				self.was_mmb_pressed = true
			elif(_event.button_index == BUTTON_RIGHT):
				self.was_rmb_pressed = true
		else:
			if(_event.button_index == BUTTON_LEFT):
				self.was_lmb_pressed = false
			elif(_event.button_index == BUTTON_MIDDLE):
				self.was_mmb_pressed = false
			elif(_event.button_index == BUTTON_RIGHT):
				self.was_rmb_pressed = false
	if(_event is InputEventMouseMotion):
		#TODO
		#I'd like to handle this in physics_process() but its not until this point that
		#we can safely say what the event type is to apply the rotation.
		if(self.use_mouse_movement):
			if(not self.require_left_drag and not self.require_middle_drag and not self.require_right_drag):
				#No mouse buttons being held are required so movement is always active.
				self.yaw_target   = (_event.position.x * radians_per_pixel.x * self.mouse_sensitivity) - PI
				self.pitch_target = (_event.position.y * radians_per_pixel.y * self.mouse_sensitivity) - PI
			elif(self.mouse_btn_active()):
				#Uses change in mouse position to change target rotation.
				var mouse_delta = _event.position - self.last_mouse_pos
				self.yaw_target   -= mouse_delta.x * radians_per_pixel.x * self.mouse_sensitivity
				self.pitch_target += mouse_delta.y * radians_per_pixel.y * self.mouse_sensitivity
		self.last_mouse_pos = _event.position

func _physics_process(_delta):
	#Distance
	self.distance_velocity += self.distance_acceleration * self.distance_direction * _delta
	self.distance_direction = 0.0#Reset Input Direction Vector
	self.distance_target += self.distance_velocity
	self.distance = self.moveNumberTowardsNumber(self.distance, self.distance_target, self.distance_acceleration * _delta)
	self.distance_velocity = self.moveNumberTowardsNumber(self.distance_velocity, 0.0, self.distance_dampening)
	#Rotation
	#Apply acceleration based upon rotation direction
	self.rotation_velocity_vector += self.rotation_acceleration_vector * self.rotation_direction_vector * _delta
	self.rotation_direction_vector = Vector3.ZERO#Reset Input Direction Vector
	#Applies rotation to camera's target rotation.
	self.pitch_target += self.rotation_velocity_vector.x
	self.yaw_target += self.rotation_velocity_vector.y
	self.roll_target += self.rotation_velocity_vector.z
	#Move values towards target values by target acceleration.
	self.pitch = self.moveNumberTowardsNumberWithBounds(self.pitch, self.pitch_target, self.rotation_target_acceleration_vector.x * _delta, TWO_PIE)
	self.yaw = self.moveNumberTowardsNumberWithBounds(self.yaw, self.yaw_target, self.rotation_target_acceleration_vector.y * _delta, TWO_PIE)
	self.roll = self.moveNumberTowardsNumberWithBounds(self.roll, self.roll_target, self.rotation_target_acceleration_vector.z * _delta, TWO_PIE)
	#Apply rotational velocity dampening
	self.rotation_velocity_vector = self.moveVector3TowardsVector3(self.rotation_velocity_vector, Vector3.ZERO, self.rotation_dampening_vector)
	#Camera/Parent Movements
	#TODO
	self.movement_velocity_vector += self.movement_acceleration_vector * self.movement_direction_vector * _delta
	self.movement_direction_vector = Vector3.ZERO#Reset movement direction vector
	#Apply movement
	if(self.allow_camera_movement):
		if(self.move_parent):
			if(self.hasArmParent() and self.hasBaseSpatial()):
				self.rotation_base.get_parent_spatial().translation += self.movement_velocity_vector.rotated(Vector3.UP, self.yaw)
			else:
				self.get_parent_spatial().translation += self.movement_velocity_vector.rotated(Vector3.UP, self.yaw)
		else:
			if(self.hasArmParent() and self.hasBaseSpatial()):
				self.rotation_base.translation += self.movement_velocity_vector.rotated(Vector3.UP, self.yaw)
			else:
				self.translation += self.movement_velocity_vector.rotated(Vector3.UP, self.yaw)
	#Apply Movement Velocity Dampening
	self.movement_velocity_vector = self.moveVector3TowardsVector3(self.movement_velocity_vector, Vector3.ZERO, self.movement_dampening_vector)
	#Handle collision(s)
	#Can't use positions of nodes to collide a raycast if nodes aren't done being setup yet.
	if(not self.hasArmParent() or not self.hasBaseSpatial() or not self.collide_camera):
		return
	#Cast ray from base to camera, not the other way around. This will collide with the closest/nearest object first.
	var space_state = self.get_world().direct_space_state
	var collision = space_state.intersect_ray(self.rotation_base.global_translation, self.global_translation, [self, self.rotation_arm, self.rotation_base], self.physics_mask)
	if(not collision.empty()):
		self.distance = self.rotation_base.global_translation.distance_to(collision.position)

########
#Signals
########
func onWindowResize():
	#Called when window is resized.
	#Updates viewport rectangle, and rotation per viewport pixel size.
	printd("Window has been resized.")#Debugging
	self.last_viewport_size = self.get_viewport().size
	self.last_viewport_center = self.last_viewport_size / 2.0
	self.radians_per_pixel = self.divide_float_by_vector2(TWO_PIE, self.last_viewport_size)
	self.degrees_per_pixel = self.divide_float_by_vector2(360.0, self.last_viewport_size)
func onBaseAdded():
	#Method is called when the defered call to add the rotation_base node to the tree is completed.
	#Had some weirdness with this at one point. This is here just in case I see it again.
	#TODO: Remove this.
	printd("Camera rotation base has been added to the current tree.")#Debugging
func onArmAdded():
	#Method is called when the defered call to add the rotation_arm node to the tree is completed.
	#Had some weirdness with this at one point. This is here just in case I see it again.
	#TODO: Remove this.
	printd("Camera rotation arm has been added to the current tree.")#Debugging

##########################
#SetGets Methods/Functions
##########################
#Distance(in/out)
func distance_set( new_value:float ):
	#Apply limits
	distance = self.applyMinimumWithPossibleMaximum(new_value, self.distance_min, self.distance_max)
	#Apply only after nodes are initialized
	if(not self.hasArmParent() or not self.hasArmParent()):
		return
	self.translation.z = distance

#Left/Right(Yaw)
#Changes to current values should be immediately applied to nodes, as well as updating their conterparts values.
func yaw_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, self.TWO_PIE)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.yaw_min, self.yaw_max)
	#Update
	yaw_degrees = rad2deg(new_value)
	yaw = new_value
	#Apply
	self._updateYaw()
func yaw_degrees_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, 360.0)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.yaw_degrees_min, self.yaw_degrees_max)
	#Update
	yaw = deg2rad(new_value)
	yaw_degrees = new_value
	#Apply
	self._updateYaw()

# Changes to target values should only update their corresponding conterpart.
func yaw_target_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, self.TWO_PIE)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.yaw_min, self.yaw_max)
	#Update
	yaw_target_degrees = rad2deg(new_value)
	yaw_target = new_value
func yaw_target_degrees_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, 360.0)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.yaw_degrees_min, self.yaw_degrees_max)
	#Update
	yaw_target = deg2rad(new_value)
	yaw_target_degrees = new_value

func yaw_min_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, self.TWO_PIE))#Wraps around using modulo
	#Update
	yaw_degrees_min = rad2deg(new_value)
	yaw_min = new_value
func yaw_max_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, self.TWO_PIE))#Wraps around using modulo
	#Update
	yaw_degrees_max = rad2deg(new_value)
	yaw_max = new_value
func yaw_degrees_min_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, 360.0))#Wraps around using modulo
	#Update
	yaw_min = deg2rad(new_value)
	yaw_degrees_min = new_value
func yaw_degrees_max_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, 360.0))#Wraps around using modulo
	#Update
	yaw_max = deg2rad(new_value)
	yaw_degrees_max = new_value

#Forward/Backward(Pitch)
#Changes to current values should be immediately applied to nodes, as well as updating their conterparts values.
func pitch_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, self.TWO_PIE)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.pitch_min, self.pitch_max)
	#Update
	pitch_degrees = rad2deg(new_value)
	pitch = new_value
	#Apply
	self._updatePitch()
func pitch_degrees_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, 360.0)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.pitch_degrees_min, self.pitch_degrees_max)
	#Update
	pitch = deg2rad(new_value)
	pitch_degrees = new_value
	#Apply
	self._updatePitch()

# Changes to target values should only update their corresponding conterpart.
func pitch_target_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, self.TWO_PIE)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.pitch_min, self.pitch_max)
	#Update
	pitch_target_degrees = rad2deg(new_value)
	pitch_target = new_value
func pitch_target_degrees_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, 360.0)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.pitch_degrees_min, self.pitch_degrees_max)
	#Update
	pitch_target = deg2rad(new_value)
	pitch_target_degrees = new_value

func pitch_min_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, self.TWO_PIE))#Wraps around using modulo
	#Update
	pitch_degrees_min = rad2deg(new_value)
	pitch_min = new_value
func pitch_max_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, self.TWO_PIE))#Wraps around using modulo
	#Update
	pitch_degrees_max = rad2deg(new_value)
	pitch_max = new_value
func pitch_degrees_min_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, 360.0))#Wraps around using modulo
	#Update
	pitch_min = deg2rad(new_value)
	pitch_degrees_min = new_value
func pitch_degrees_max_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, 360.0))#Wraps around using modulo
	#Update
	pitch_max = deg2rad(new_value)
	pitch_degrees_max = new_value

#Roll(Roll)
#Changes to current values should be immediately applied to nodes, as well as updating their conterparts values.
func roll_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, self.TWO_PIE)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.roll_min, self.roll_max)
	#Update
	roll_degrees = rad2deg(new_value)
	roll = new_value
	#Apply
	self._updateRoll()
func roll_degrees_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, 360.0)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.roll_degrees_min, self.roll_degrees_max)
	#Update
	roll = deg2rad(new_value)
	roll_degrees = new_value
	#Apply
	self._updateRoll()

# Changes to target values should only update their corresponding conterpart.
func roll_target_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, self.TWO_PIE)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.roll_min, self.roll_max)
	#Update
	roll_target_degrees = rad2deg(new_value)
	roll_target = new_value
func roll_target_degrees_set( new_value:float ):
	#Apply limits
	new_value = fmod(new_value, 360.0)#Wraps around using modulo
	new_value = self.applyMinimumWithPossibleMaximum(new_value, self.roll_degrees_min, self.roll_degrees_max)
	#Update
	roll_target = deg2rad(new_value)
	roll_target_degrees = new_value

func roll_min_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, self.TWO_PIE))#Wraps around using modulo
	#Update
	roll_degrees_min = rad2deg(new_value)
	roll_min = new_value
func roll_max_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, self.TWO_PIE))#Wraps around using modulo
	#Update
	roll_degrees_max = rad2deg(new_value)
	roll_max = new_value
func roll_degrees_min_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, 360.0))#Wraps around using modulo
	#Update
	roll_min = deg2rad(new_value)
	roll_degrees_min = new_value
func roll_degrees_max_set( new_value:float ):
	#Apply limits
	new_value = abs(fmod(new_value, 360.0))#Wraps around using modulo
	#Update
	roll_max = deg2rad(new_value)
	roll_degrees_max = new_value

#Scratch Area please ignore:
#Target values can go past value limits. Leading to slow responsiveness when direction of rotation is reversed.
#Distance can ignore minimum distance. Bug TODO
#Movement is buggy but implemented. Direction not relative to camera. Only reading one key at a time. TODO BUG
#I may move smoothing/lerp/interpolation stuff to a seperate class to shrink this script as its getting bloated. TODO
