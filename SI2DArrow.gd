extends Object

# Class used to draw 2D Arrow instance(s) on Node2D Canvases.
class SIArrow2D:
	# Constants
	const DEFAULT_COLOR:Color = Color.black
	const DEFAULT_LINE_WIDTH:float = 3.0
	const DEFAULT_LINE_RESOLUTION:int = 2
	const DEFAULT_ARROW_COUNT:int = 1
	const DEFAULT_ARROW_SIZE:Vector2 = Vector2(10.0, 8.0)
	# Variables
	var start:Vector2 = Vector2()
	var stop:Vector2 = Vector2()
	var line_width:float = DEFAULT_LINE_WIDTH
	var line_resolution:int = DEFAULT_LINE_RESOLUTION
	var color:Color = DEFAULT_COLOR
	var antialiased:bool = false
	var arrow_count:int = DEFAULT_ARROW_COUNT
	var arrow_size:Vector2 = DEFAULT_ARROW_SIZE
	var base_point_radius:float = 3.0
	var line_tween:FuncRef = funcref(self, "linear_tween")
	var arrow_tween:FuncRef = funcref(self, "parabolic_tween")
	# Constructors / Destructors
	func _init(end:Vector2 = Vector2.ZERO, start:Vector2 = Vector2.ZERO, color = Color.black, line_width:float = 3.0, antialiased:bool = false):
		self.start = start
		self.stop = end
		self.color = color
		self.line_width = line_width
		self.antialiased = antialiased
	# Functions
	func linear_tween(delta:float):
		return start + ((stop - start) * delta)
	func parabolic_tween(delta:float):
		return start + ((stop - start) * (delta * delta))
	func cubic_tween(delta:float):
		return start + ((stop - start) * (delta * delta * delta))
	# Draw an arrow using settings struct. (Call from _draw())
	static func draw_siarrow2d_struct(settings:SIArrow2D, canvas:CanvasItem):
		var dist:float = settings.start.distance_to(settings.stop)
		if(dist <= 0.0):
			return
		if(canvas == null):
			return
		var dist_per_point:float = dist / settings.line_resolution
		var angle_to_point:float = settings.start.angle_to_point(settings.stop)
		# Draw base point
		if(settings.base_point_radius > 0.0):
			canvas.draw_circle(settings.line_tween.call_funcv([0.0]), settings.base_point_radius, settings.color)
		# Draw line(s) from start to stop
		for i in range(settings.line_resolution):
			if(i < 1):
				continue
			canvas.draw_line(settings.line_tween.call_funcv([(i - 1) * (1.0 / (settings.line_resolution - 1))]),
			settings.line_tween.call_funcv([(i) * (1.0 / (settings.line_resolution - 1))]),
			settings.color, settings.line_width, settings.antialiased)
		# Draw arrows along line.
		for i in range(settings.arrow_count):
			var next_arrow_tip:Vector2 = settings.arrow_tween.call_funcv([((i + 1) * (1.0 / settings.arrow_count)) - 0.001])
			var arrow_left = Vector2(-settings.arrow_size.x / 2.0, -settings.arrow_size.y)
			var arrow_right = Vector2(settings.arrow_size.x / 2.0, -settings.arrow_size.y)
			canvas.draw_line(
				arrow_left.rotated((PI/2)+angle_to_point) + next_arrow_tip,
				next_arrow_tip,
				settings.color, settings.line_width, settings.antialiased)
			canvas.draw_line(
				arrow_right.rotated((PI/2)+angle_to_point) + next_arrow_tip,
				next_arrow_tip,
				settings.color, settings.line_width, settings.antialiased)
	# Helper Function
	func _draw(canvas:CanvasItem):
		draw_siarrow2d_struct(self, canvas)
