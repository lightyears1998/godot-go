tool

extends Node

static func new_2d_array(shape0: int, shape1: int, initial_value):
	assert(shape0 >= 0)
	assert(shape1 >= 0)

	var arr = []
	for i in shape0:
		arr.push_back([])
		arr[i].resize(shape1)
		for j in shape1:
			arr[i][j] = initial_value
	return arr

static func clone(data):
	return bytes2var(var2bytes(data))
