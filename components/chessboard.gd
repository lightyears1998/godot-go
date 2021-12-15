tool

extends Node2D

class_name Chessboard

export(int) var chessboard_size = 880
export(int) var chessboard_rows = 19
export(Color) var chessboard_color = Color("f0d887")

var gap_width = chessboard_size / (chessboard_rows + 1)
var chess_radius = gap_width / 2.2
var cross_points = []

var mouse_hover_cross_point = null

var chess_colors = [ColorN("black"), ColorN("white")]
var next_chess_side = 0

var placed_chesses = []

var history = []

func get_position_vector_from_index(row_index, column_index):
	return Vector2((column_index + 1) * gap_width, (row_index + 1) * gap_width)

func _init():
	init_cross_points()
	reset()

func reset():
	mouse_hover_cross_point = null
	next_chess_side = 0
	reset_placed_chesses()
	history = []

func init_cross_points():
	var columns = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]
	for i in range(1, 20):
		for j in range(1, 20):
			var row = str(20 - i)
			var column = columns[j-1]
			var row_index = i - 1
			var column_index = j - 1
			var position = get_position_vector_from_index(row_index, column_index)
			cross_points.push_back({
				"row": row,
				"column": column,
				"position": position,
				"row_index": row_index,
				"column_index": column_index
			})

func reset_placed_chesses():
	placed_chesses = []
	for i in chessboard_rows:
		placed_chesses.push_back([])
		placed_chesses[i].resize(chessboard_rows)
		for j in chessboard_rows:
			placed_chesses[i][j] = -1

func _draw():
	# draw background
	draw_rect(Rect2(0, 0, chessboard_size, chessboard_size), chessboard_color)
	
	# draw cross lines
	for i in range(1, 20):
		draw_line(Vector2(gap_width, i * gap_width), Vector2(chessboard_size - gap_width, i * gap_width), ColorN("black"))
		draw_line(Vector2(i * gap_width, gap_width), Vector2(i * gap_width, chessboard_size - gap_width), ColorN("black"))
		
	# draw special cross points
	for i in 3:
		for j in 3:
			var x = 3 + i * 6
			var y = 3 + j * 6
			var v = get_position_vector_from_index(x, y)
			draw_circle(v, 4, ColorN("black"))
	
	# draw placed chess
	for i in chessboard_rows:
		for j in chessboard_rows:
			if placed_chesses[i][j] != -1:
				draw_chess(i, j, placed_chesses[i][j])
	
	# draw mouse-hover chess
	if mouse_hover_cross_point and !is_place_taken(mouse_hover_cross_point.row_index, mouse_hover_cross_point.column_index):
		var draw_color = Color(chess_colors[next_chess_side])
		draw_color.a = 0.6
		draw_circle(mouse_hover_cross_point.position, chess_radius, draw_color)

func draw_chess(row_index, column_index, color):
	var position = get_position_vector_from_index(row_index, column_index)
	draw_circle(position, chess_radius, chess_colors[color])

func _unhandled_input(event):
	if event is InputEventMouse:
		var position = make_input_local(event).position
		if position.x >= 0 && position.y >= 0 && position.x <= chessboard_size && position.y <= chessboard_size:
			var nearest_cross_point_and_distance = find_nearest_cross_point_and_distance(position)
			var distance = nearest_cross_point_and_distance["distance"]
			var nearest_cross_point = nearest_cross_point_and_distance["cross_point"]

			if distance < chess_radius:
				mouse_hover_cross_point = nearest_cross_point
			else:
				mouse_hover_cross_point = null

			if event is InputEventMouseButton:
				if event.button_index == BUTTON_LEFT && !event.is_pressed() && mouse_hover_cross_point:
					var row_index = nearest_cross_point["row_index"]
					var column_index = nearest_cross_point["column_index"]
					if can_place_chess(row_index, column_index, next_chess_side):
						place_chess(row_index, column_index, next_chess_side)
						next_chess_side = 1 - next_chess_side 
			update()
			
func find_nearest_cross_point_and_distance(position):
	var min_distance = chessboard_size
	var nearest_cross_point = cross_points[0]
	
	for cross_point in cross_points:
		var current_distance = position.distance_to(cross_point.position)
		if current_distance < min_distance:
			min_distance = current_distance
			nearest_cross_point = cross_point
			
	return {
		"distance": min_distance,
		"cross_point": nearest_cross_point
	}

func is_place_taken(row_index, column_index):
	return placed_chesses[row_index][column_index] != -1

func can_place_chess(row_index, column_index, side):
	return !is_place_taken(row_index, column_index)

func place_chess(row_index, column_index, side):
	placed_chesses[row_index][column_index] = side

func remove_chess(row_index, column_index):
	placed_chesses[row_index][column_index] = -1
