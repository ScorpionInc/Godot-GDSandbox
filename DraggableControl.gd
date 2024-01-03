"""
Purpose: Provides functions for draggable control nodes.
Version: 1.0.0
Updated: 20240103
Authors: ScorpionInc
TO-DO's:
"""

extends DraggableNode
class_name DraggableControl

var _is_selector_over:bool = false
var target_global_offset:Vector2 = Vector2.ZERO
var target_global_position:Vector2 = Vector2.INF

## Returns true when selector (object/cursor)'s position is within drag_buffer distance of target area.
## Returns false otherwise.
func is_selector_over() -> bool:
	return self._is_selector_over
func on_mouse_enters():
	self._is_selector_over = true
func on_mouse_exits():
	self._is_selector_over = false

# Inherited / Implemented Functions
func _ready():
	super()
	if not has_signal("mouse_entered"):
		# This should be caught by Godot breakpoint anyway but just in case something wierd happens, we'll output a message.
		print("[ERROR]: DraggableControl[" + str(get_path()) + "] encountered a fatal error!")
		print("[ERROR]: Using control-based script on a non-control node: '" + str(self) + "'!")#Debugging
		self.get_tree().quit(1)
	self.set_physics_process(drag_enabled)
	# These signals only exist for Control nodes(by default)
	self.mouse_entered.connect(self.on_mouse_enters)
	self.mouse_exited.connect(self.on_mouse_exits)
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
