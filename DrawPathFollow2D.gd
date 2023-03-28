#DrawPathFollow2D.gd
#Quick script to make PathFollow2D nodes visible in-game.
#Godot Version: 4.0.1 stable
#Author: ScorpionInc
#Created: 20230328
#Updated: 20230328

extends PathFollow2D

@export var draw_enable:bool = true
@export var draw_segments:int = 10
@export var draw_color:Color = Color.BLUE
@export var draw_width:float = -1.0
@export var draw_antialiased:bool = false

func _draw():
	if(not self.draw_enable):
		return
	if(self.draw_segments <= 0):
		#Don't divide by zero or use negative quantities of points.
		return
	var percentage_per_point:float = 1.0 / self.draw_segments
	var original_ratio:float = self.progress_ratio#Used to reset to whatever it was after _draw() is done.
	var original_position:Vector2 = self.position
	var original_rotation:float = self.rotation
	#print("[DEBUG]: Original Position Vector: " + str(original_position))#Debugging
	self.progress_ratio = 0.0#Start at the beginning.
	var next_point:Vector2
	var last_point:Vector2 = (self.position - original_position).rotated(-original_rotation)
	for i in range(1, self.draw_segments + 1):#1->30
		self.progress_ratio = percentage_per_point * i
		next_point = (self.position - original_position).rotated(-original_rotation)
		#print("[DEBUG]: Next Point[" + str(i) + "] is: " + str(next_point) + " @ " + str(round(self.progress_ratio * 100.0)) + "%.")#Debugging
		self.draw_line(last_point, next_point, self.draw_color, self.draw_width, self.draw_antialiased)
		last_point = next_point
	self.progress_ratio = original_ratio

###OPTIONAL CODE###
#Used for demo/testing purposes
func _process(delta):
	if(not self.draw_enable):
		#self.set_process(false)
		pass
	self.progress_ratio += 0.1 * delta
	self.queue_redraw()#Must redraw each time the progress changes.
	if(self.progress_ratio >= 1.0):
		self.set_process(false)
