# Purpose: Provides interactive example on SI2DArrow Code usage.

extends Sprite

export var arrow_start:Vector2 = Vector2.ZERO
export var arrow_color:Color = Color.aliceblue
var arrowSettings = preload("res://Scripts/SI2DArrow.gd").SIArrow2D.new()

func _ready():
	pass

var last_mouse_position:Vector2 = Vector2.ZERO
func _input(event):
	if(event is InputEventMouseMotion):
		last_mouse_position = (event.global_position / self.global_scale) - (self.global_position / self.global_scale)
		#print("[DEBUG]: ArrowSpriteExample \tEvent: '" + str(event.global_position) + "'\t last_mouse_position: '" + str(last_mouse_position) + "'.")#Debugging

func _process(_delta):
	self.update()

func _draw():
	arrowSettings.start = self.arrow_start
	arrowSettings.stop = last_mouse_position
	arrowSettings.color = arrow_color
	arrowSettings.arrow_count = 4
	arrowSettings.antialiased = true
	arrowSettings.scalar = Vector2(1.0 / self.global_scale.x, 1.0 / self.global_scale.y)
	arrowSettings._draw(self)
