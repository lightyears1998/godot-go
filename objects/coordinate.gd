extends Reference

class_name Coordinate

var row_index: int
var col_index: int

func _init(row_index, col_index):
	self.row_index = row_index
	self.col_index = col_index

func is_pass():
	return row_index == -1 && col_index ==  -1

func to_sgf_coordinate():
	# converts the coordinates to SGF coorindates
	# @see https://www.red-bean.com/sgf/go.html
	
	if is_pass():
		return ['', '']
	return [ char(ord('a') + col_index), char(ord('a') + row_index) ]
