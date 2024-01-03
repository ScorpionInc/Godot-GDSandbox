"""
Purpose: Provides shared functions for draggable nodes.
Version: 1.0.0
Updated: 20240103
Authors: ScorpionInc
TO-DO's: Allow for other input positions than the mouse. (E.G. in-game cursor/sprite)
"""

extends Node
class_name DraggableNode

# We emit more signals than is strictly needed.
# This is done to limit re-testing of game state in inherited classes.
# Since we have to test these inputs anyway no need for any child class to also have to handle them.
signal mouse_move(event:InputEventMouseMotion)
signal mouse_button(event:InputEventMouseButton)
signal dragging_start(global_pos:Vector2)
signal dragging(global_pos:Vector2)
signal dragging_stop(global_pos:Vector2)

## Enable the ability for this node to be dragged around by user input.
@export var drag_enabled:bool = true :
	set(new_value):
		self.set_process_input(self.drag_enabled)
		drag_enabled = new_value
## How far must position change from the down action before it's detected as drag and not a press.
@export var drag_buffer:float = 1.0

@export_group("Mouse Draggable", "draggable_")
## Should all inputs be required or just any one of these inputs?
@export var draggable_require_all:bool = false
## Can this node be dragged with the left mouse button?
@export var draggable_lmb:bool = true
## Can this node be dragged with the middle mouse button?
@export var draggable_mmb:bool = false
## Can this node be dragged with the right mouse button?
@export var draggable_rmb:bool = false
## Input action that can be used to start/release dragging. [optional]
@export var draggable_action_name:String = ""

var last_mouse_position:Vector2 = Vector2.ZERO
var last_drag_down:Vector2 = Vector2.INF
var last_drag_up:Vector2 = Vector2.ZERO
var _is_dragging:bool = false

## Intended to be overridden based upon node type.
## Returns true when selector (object/cursor)'s position is within drag_buffer distance of target area.
## Returns false otherwise.
func is_selector_over() -> bool:
	# OVERRIDE ME!
	return self.drag_enabled

## Returns true when all defined draggable inputs are pressed and at least one is defined.
## Returns false otherwise.
func is_all_drag_pressed() -> bool:
	if self.draggable_lmb and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		return false
	if self.draggable_mmb and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
		return false
	if self.draggable_rmb and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		return false
	if not self.draggable_action_name.is_empty():
		if not Input.is_action_pressed(self.draggable_action_name):
			return false
	if (not self.draggable_lmb) and (not self.draggable_mmb) and (not self.draggable_rmb) and (self.draggable_action_name.is_empty()):
		# Require at least one input option to be set.
		return false
	return true

## Returns true when any one defined draggable inputs are/is pressed.
## Returns false otherwise.
func is_any_drag_pressed():
	if self.draggable_lmb and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return true
	if self.draggable_mmb and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		return true
	if self.draggable_rmb and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return true
	if not self.draggable_action_name.is_empty():
		if Input.is_action_pressed(self.draggable_action_name):
			return true
	return false

## Returns true when requirements are met for drag input event(doesn't do position tests).
## Returns false otherwise.
func is_drag_pressed():
	if(self.draggable_require_all):
		return self.is_all_drag_pressed()
	return self.is_any_drag_pressed()

## Returns value of internal last_mouse_position value for read-only access.
func get_last_mouse_position() -> Vector2:
	return self.last_mouse_position

## Returns value of internal _is_dragging value for read-only access.
func is_dragging() -> bool:
	return self._is_dragging

## Returns value of internal last_drag_down value for read-only access.
func get_drag_start() -> Vector2:
	return self.last_drag_down

## Returns value of internal last_drag_up value for read-only access.
func get_drag_stop() -> Vector2:
	return self.last_drag_up

## Start dragging (regardless of input state)
func drag_start():
	self._is_dragging = true
	if(self.drag_enabled):
		self.dragging_start.emit(self.last_drag_down)

## Stop dragging (regardless of input state)
func drag_stop():
	if self._is_dragging:
		self._is_dragging = false
		if(self.drag_enabled):
			self.dragging_stop.emit(self.last_drag_up)
		self.last_drag_down = Vector2.INF

# Inherited / Implemented Functions / Methods
func _ready():
	self.set_process(false)
	self.set_process_input(self.drag_enabled)

func _input(event):
	if event is InputEventMouse:
		self.last_mouse_position = event.global_position
		if event is InputEventMouseMotion:
			self.mouse_move.emit(event)
			if(self.is_drag_pressed()):
				if self.is_dragging():
					if(self.drag_enabled):
						self.dragging.emit(self.last_mouse_position)
				elif self.last_drag_down != Vector2.INF:
					if self.last_drag_down.distance_to(self.last_mouse_position) >= self.drag_buffer:
						drag_start()
			#END if InputEventMouseMotion
		elif event is InputEventMouseButton:
			self.mouse_button.emit(event)
			if self.is_drag_pressed():
				if self.is_selector_over():
					last_drag_down = event.global_position
			elif self._is_dragging:
				self.last_drag_up = event.global_position
				drag_stop()
			#END elif InputEventMouseButton
		#END if InputEventMouse
	#END _input()
