#DrawPath2D.gd
#Quick script to make Path2D nodes visible in-game.
#Godot Version: 4.0.1 stable
#Author: ScorpionInc
#Created: 20230328
#Updated: 20230328

extends Path2D

@export var draw_enable:bool = true
@export var draw_segments:int = 10
@export var draw_color:Color = Color.BLUE
@export var draw_width:float = -1.0
@export var draw_antialiased:bool = false

func _draw():
	if(not self.draw_enable):
		return
	if(not self.curve):
		return
	if(self.draw_segments <= 0):
		return
	var progress_distance:float = 0.0
	var next_point:Vector2
	var last_point:Vector2 = self.curve.sample_baked(progress_distance)
	var baked_length:float = self.curve.get_baked_length()
	var distance_per_point:float = baked_length / self.draw_segments
	for i in range(1, self.draw_segments + 1):#1->30
		progress_distance = distance_per_point * i
		next_point = self.curve.sample_baked(progress_distance)
		#print("[DEBUG]: Next Point[" + str(i) + "] is: " + str(next_point) + " @ " + str(round(progress_distance / baked_length)) + "%.")#Debugging
		self.draw_line(last_point, next_point, self.draw_color, self.draw_width, self.draw_antialiased)
		last_point = next_point
