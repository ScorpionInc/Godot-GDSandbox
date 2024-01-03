"""
Purpose: Provides functions for draggable node2ds.
Version: 1.0.0
Updated: 20240103
Authors: ScorpionInc
TO-DO's: alot.
"""

extends DraggableNode
class_name DraggableNode2D

var target_global_offset:Vector2 = Vector2.ZERO
var target_global_position:Vector2 = Vector2.INF

## Returns the visual size of a Node2D Element based upon its type, texture(s) and transform.
## Doesn't (yet) consider node's rotation. TODO
func get_node2d_visual_aabb_shallow(node, default_size:Vector2 = Vector2.ONE) -> Rect2:
	var node_position:Vector2 = node.global_position
	var node_size:Vector2 = default_size
	# Find Current Visual Size.
	if node is Sprite2D:
		if node.texture != null:
			node_size = node.texture.get_size()
			if node.region_enabled:
				node_size = node.region_rect.size
			node_size.x /= node.hframes
			node_size.y /= node.vframes
			if node.centered:
				node_position -= (node_size / 2.0)
	elif node is AnimatedSprite2D:
		if node.sprite_frames != null:
			var node_texture = node.sprite_frames.get_frame_texture(node.animation, node.frame)
			if node_texture != null:
				node_size = node_texture.get_size()
				if node.centered:
					node_position -= (node_size / 2.0)
	return Rect2(node_position, node_size * node.scale)

## Returns visual aabb of node and all of the nodes children using each nodes type, texture(s), and transform.
## Doesn't (yet) consider node's rotation. TODO
func get_node2d_visual_aabb_recursive(node, default_size:Vector2 = Vector2.ONE) -> Rect2:
	var current_visual_aabb:Rect2 = get_node2d_visual_aabb_shallow(node, default_size)
	for child in node.get_children():
		var child_visual_aabb:Rect2 = get_node2d_visual_aabb_recursive(child, default_size)
		current_visual_aabb = child_visual_aabb.merge(current_visual_aabb)
	return current_visual_aabb

## Returns true when selector (object/cursor)'s position is within drag_buffer distance of target area.
## Returns false otherwise.
func is_selector_over() -> bool:
	var visual_bounds:Rect2 = get_node2d_visual_aabb_recursive(self)
	var lmp:Vector2 = self.get_last_mouse_position()
	var rbv:bool = visual_bounds.has_point(lmp)
	#print("Rect: " + str(visual_bounds) + " contains point: " + str(lmp) + "? " + str(rbv))#Debugging
	return rbv

# Inherited / Implemented Functions
func _ready():
	super()
	if not has_signal("item_rect_changed"):
		# This should be caught by Godot breakpoint anyway but just in case something wierd happens, we'll output a message.
		print("[ERROR]: DraggableNode2D[" + str(get_path()) + "] encountered a fatal error!")
		print("[ERROR]: Using node2d-based script on a non-node2d node: '" + str(self) + "'!")#Debugging
		self.get_tree().quit(1)
	self.set_physics_process(true)
	self.dragging_start.connect(self.on_dragging_start)
	self.dragging.connect(self.on_dragging)

func _physics_process(_delta):
	if(self.drag_enabled and self.target_global_position != Vector2.INF):
		self.global_position = self.target_global_position

# Signals / Events
func on_dragging_start(global_pos:Vector2):
	self.target_global_offset = self.global_position - global_pos

func on_dragging(global_pos:Vector2):
	self.target_global_position = global_pos + self.target_global_offset
