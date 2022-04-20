extends Node2D

var Coordinate = preload("res://objects/coordinate.gd")

func _ready():
	var c = Coordinate.new(1, 1)
	print(c.to_sgf_coordinate())
	
	var p = Util.make_pass()
	print(p.is_pass())
	print(p.to_sgf_coordinate())
