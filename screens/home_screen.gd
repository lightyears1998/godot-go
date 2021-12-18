extends Control

var SIDES = ["Black", "White"]
var HOST_PORT = 5752

func _ready():
	_setup_network_callbacks()
	$Chessboard.connect("side_changed", self, "_on_side_changed")
	$Chessboard.connect("chess_placed", self, "_on_chess_placed")
	$Chessboard.connect("chess_had_not_placed", self, "_on_chess_had_not_placed")
	$HostButton.connect("pressed", self, "host")
	$ConnectButton.connect("pressed", self, "connect_to_host")
	$RepentButton.connect("pressed", $Chessboard, "repent")
	$SwitchSideButton.connect("pressed", $Chessboard, "switch_user_side")
	$AutoSwitchSideCheckBox.connect("pressed", $Chessboard, "toggle_switch_side_after_move")
	$SendChatButton.connect("pressed", self, "_on_send_chat_button_pressed")
	$ResetButton.connect("pressed", $Chessboard, "reset")

func _setup_network_callbacks():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _update_side_label():
	var user_side = $Chessboard.user_side
	var next_side = $Chessboard.next_chess_side
	$SideLabel.set_text("Side: %s\nNext: %s" % [SIDES[user_side], SIDES[next_side]])

func _on_side_changed():
	_update_side_label()

func _on_send_chat_button_pressed():
	var text = $ChatLineEdit.text
	if text:
		print_log(text)

func _on_chess_placed(row_index, column_index, side):
	print_log("%s plays at (%s, %s)" % [SIDES[side], row_index, column_index])

func _on_chess_had_not_placed(row_index, column_index, side, why):
	print_log("%s cannot play at (%s, %s): %s" % [SIDES[side], row_index, column_index, why])

func print_log(text):
	$ChatLineEdit.text = ""
	$ChatLabel.add_text(text)
	$ChatLabel.newline()

func _player_connected(id):
	print_log("Player connected: %s" % id)

func _player_disconnected(id):
	print_log("Player disconnected: %s" % id)

func _connected_ok():
	pass

func _server_disconnected():
	pass

func _connected_fail():
	pass

func host():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(HOST_PORT, 32)
	get_tree().network_peer = peer
	print_log("Hosting on %s, port %s." % [get_ip(), HOST_PORT])

func connect_to_host():
	var peer = NetworkedMultiplayerENet.new()
	var server_ip = $IPLineEdit.text
	var err = peer.create_client(server_ip, HOST_PORT)
	if err:
		print_log("Fail to connect to host (%s)" % err)
		return
	get_tree().network_peer = peer

func get_ip():
	return IP.get_local_addresses()
