"""
Purpose: Provides functions for draggable 2d node using child CollisionPolygon2D shape.
Version: 1.0.0
Updated: 20240313
Authors: ScorpionInc
TO-DO's: alot.
"""

extends DraggableNode
class_name DraggableArea2D

var draggable_area:CollisionPolygon2D = null
var target_global_offset:Vector2 = Vector2.ZERO
var target_global_position:Vector2 = Vector2.INF

## Returns true when selector (object/cursor)'s position is within drag_buffer distance of target area.
## Returns false otherwise.
func is_selector_over() -> bool:
	#var lmp:Vector2 = self.get_last_mouse_position() # Godot 4
	var lmp:Vector2 = self.get_node_or_null("/root").get_mouse_position() # Godot 3
	var rbv:bool = false
	if(self.draggable_area != null):
		rbv = Geometry.is_point_in_polygon(lmp - self.global_position, self.draggable_area.polygon)
	return rbv

# Recursively checks for a child node of type CollisionPolygon2D and returns the first matching node.
# Returns null on error.
func find_collision_shape(n:Node = self):
	for c in n.get_children():
		if(c is CollisionPolygon2D):
			return c
		if(c.get_child_count() > 0):
			var nc = find_collision_shape(c)
			if(nc != null):
				return nc
	return null

# Inherited / Implemented Functions
func _ready():
	#super() # Godot 4
	if not has_signal("item_rect_changed"):
		# This should be caught by Godot breakpoint anyway but just in case something wierd happens, we'll output a message.
		print("[ERROR]: DraggableCollisionPolygon2D[" + str(get_path()) + "] encountered a fatal error!")
		print("[ERROR]: Using node2d-based script on a non-node2d node: '" + str(self) + "'!")#Debugging
		self.get_tree().quit(1)
	self.set_physics_process(true)
	#self.dragging_start.connect(self.on_dragging_start) # Godot 4
	self.connect("dragging_start", self, "on_dragging_start") # Godot 3
	#self.dragging.connect(self.on_dragging) # Godot 4
	self.connect("dragging", self, "on_dragging") # Godot 3
	var cn = find_collision_shape()
	if(cn != null):
		self.draggable_area = cn

func _physics_process(_delta):
	if(self.drag_enabled and self.target_global_position != Vector2.INF):
		self.global_position = self.target_global_position

# Signals / Events
func on_dragging_start(global_pos:Vector2):
	self.target_global_offset = self.global_position - global_pos

func on_dragging(global_pos:Vector2):
	self.target_global_position = global_pos + self.target_global_offset
