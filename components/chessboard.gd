tool

extends Node2D

class_name Chessboard

signal side_switched()
signal chess_had_not_placed(row_index, column_index, side, why)
signal chess_placed(row_index, column_index, side)
signal repented(restored_history_index)

export(int) var chessboard_size = 880
export(int) var chessboard_rows = 19
export(Color) var chessboard_color = Color("f0d887")

var gap_width = chessboard_size / (chessboard_rows + 1)
var chess_radius = gap_width / 2.2
var cross_points = []

var mouse_hover_cross_point = null

var user_side = 0
var switch_side_after_move = false

var chess_colors = [ColorN("black"), ColorN("white")]

var next_chess_side = 0

var placed_chesses = []

var history = []

func is_playing_through_network():
	return get_tree().network_peer != null

func is_valid_chess_index(row_index, column_index):
	return row_index >= 0 && row_index < chessboard_rows && column_index >= 0 && column_index < chessboard_rows

func toggle_switch_side_after_move():
	switch_side_after_move = !switch_side_after_move

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
	update()

func request_synchronization():
	rpc("send_synchronization")

remote func send_synchronization():
	rpc("receive_synchronization", next_chess_side, placed_chesses, history)

remote func receive_synchronization(next_chess_side, placed_chesses, history):
	self.next_chess_side = next_chess_side
	self.placed_chesses = placed_chesses
	self.history = history

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
	placed_chesses = Util.new_2d_array(chessboard_rows, chessboard_rows, -1)

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
	if next_chess_side == user_side:
		if mouse_hover_cross_point:
			var row_index = mouse_hover_cross_point.row_index
			var column_index = mouse_hover_cross_point.column_index
			if !is_place_taken(placed_chesses, row_index, column_index):
				draw_chess(row_index, column_index, user_side, 0.6)

func draw_chess(row_index, column_index, side, chess_color_alpha = 1):
	var position = get_position_vector_from_index(row_index, column_index)
	var color = chess_colors[side]
	color.a = chess_color_alpha
	draw_circle(position, chess_radius, color)

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
					if user_side == next_chess_side:
						user_try_place_chess(row_index, column_index, user_side)
		else:
			mouse_hover_cross_point = null
		update()

func user_try_place_chess(row_index, column_index, side):
	try_place_chess(row_index, column_index, side)
	if is_playing_through_network():
		rpc("try_place_chess", row_index, column_index, side)

remote func try_place_chess(row_index, column_index, side):
	var err = can_place_chess(row_index, column_index, next_chess_side)
	if !err:
		place_chess(placed_chesses, row_index, column_index, next_chess_side)
		var dead_chesses = detect_dead_chess_indexes(placed_chesses, side)
		for chess_index in dead_chesses:
			remove_chess(placed_chesses, chess_index.x, chess_index.y)
		next_chess_side = 1 - next_chess_side
		if switch_side_after_move:
			switch_side()
		var record = {
			"placed_chesses": placed_chesses.duplicate(true),
			"last_move_by_side": side
		}
		history.push_back(record)
		emit_signal("chess_placed", row_index, column_index, side)
	else:
		emit_signal("chess_had_not_placed", row_index, column_index, side, err)
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

func is_place_taken(chesses, row_index, column_index):
	return chesses[row_index][column_index] != -1

func can_place_chess(row_index, column_index, side):
	# standard rule forbits placing stone over other stone
	if is_place_taken(placed_chesses, row_index, column_index):
		return "Place is already taken."
	
	# standard rule forbits suicide.
	var chesses = placed_chesses.duplicate(true)
	chesses[row_index][column_index] = side
	var dead_chess_indexes_after_play = detect_dead_chess_indexes(chesses, side)
	for dead_chess_index in dead_chess_indexes_after_play:
		if chesses[dead_chess_index.x][dead_chess_index.y] == side:
			return "Suicide is not permitted."
	remove_chesses(chesses, dead_chess_indexes_after_play)
	
	# standard rule forbits the same situation come out once again.
	for i in len(history):
		if chesses == history[i]["placed_chesses"]:
			return "Same situation happened in #%d, which is not permitted." % i
	
	return null

func place_chess(chesses, row_index, column_index, side):
	chesses[row_index][column_index] = side

func remove_chess(chesses, row_index, column_index):
	chesses[row_index][column_index] = -1

func remove_chesses(chesses, dead_chess_indexes):
	for index in dead_chess_indexes:
		chesses[index.x][index.y] = -1
	return chesses

func detect_dead_chess_indexes(chesses, last_move_side):
	var dead_chess_indexes = []

	var visited_black = Util.new_2d_array(chessboard_rows, chessboard_rows, false)
	var visited_white = Util.new_2d_array(chessboard_rows, chessboard_rows, false)
	for i in chessboard_rows:
		for j in chessboard_rows:
			if is_place_taken(chesses, i, j):
				var visited
				if chesses[i][j] == 0:
					visited = visited_black
				else:
					visited = visited_white
				if visited[i][j]:
					continue

				var side = chesses[i][j]
				var liberty = 0
				var group = []

				var queue = [Vector2(i, j)]
				visited[i][j] = true
				var visited_empty = []

				while len(queue) > 0:
					var current_place = queue.pop_front()
					if !is_place_taken(chesses, current_place.x, current_place.y):
						liberty += 1
						visited_empty.push_back(current_place)
					elif side == chesses[current_place.x][current_place.y]:
						group.push_back(current_place)
						for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
							var dx = d[0]
							var dy = d[1]
							var nx = current_place.x + dx
							var ny = current_place.y + dy
							if is_valid_chess_index(nx, ny) && !visited[nx][ny]:
								visited[nx][ny] = true
								queue.push_back(Vector2(nx, ny))

				for place in visited_empty:
					visited[place.x][place.y] = false
				if liberty == 0:
					dead_chess_indexes.append_array(group)
					
	var opponent_side = 1 - last_move_side
	var at_least_one_oppoent_chess_died = false
	for chess_index in dead_chess_indexes:
		if chesses[chess_index.x][chess_index.y] == opponent_side:
			at_least_one_oppoent_chess_died = true
			break
	if at_least_one_oppoent_chess_died:
		var opponent_dead_chess_indexes = []
		for index in dead_chess_indexes:
			if chesses[index.x][index.y] == opponent_side:
				opponent_dead_chess_indexes.push_back(index)
		dead_chess_indexes = opponent_dead_chess_indexes
	return dead_chess_indexes

func user_repent():
	repent()
	if is_playing_through_network():
		rpc("repent")

remote func repent():
	var last_record = history.pop_back()
	if last_record:
		placed_chesses = last_record["placed_chesses"]
		next_chess_side = 1 - last_record["last_move_by_side"]
	else:
		reset()
	emit_signal("repented", len(history))
	update()

func user_switch_side():
	switch_side()

func switch_side():
	user_side = 1 - user_side
	emit_signal("side_switched")
