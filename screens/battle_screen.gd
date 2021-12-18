extends Control

const SIDES = ["Black", "White"]

const HOST_PORT = 5752

const MODES = ["Host", "Client"]
var mode = null

func _ready():
	setup_network_callbacks()
	connect_chessboard()

func setup_network_callbacks():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func connect_chessboard():
	$Chessboard.connect("side_switched", self, "_on_side_changed")
	$Chessboard.connect("chess_placed", self, "_on_chess_placed")
	$Chessboard.connect("chess_had_not_placed", self, "_on_chess_had_not_placed")
	$HostButton.connect("pressed", self, "host")
	$ConnectButton.connect("pressed", self, "connect_to_host_or_disconnect")
	$RepentButton.connect("pressed", $Chessboard, "user_repent")
	$SyncButton.connect("pressed", $Chessboard, "send_synchronization")
	$SwitchSideButton.connect("pressed", $Chessboard, "user_switch_side")
	$AutoSwitchSideCheckBox.connect("pressed", $Chessboard, "toggle_switch_side_after_move")
	$SendChatButton.connect("pressed", self, "_on_send_chat_button_pressed")
	$ResetButton.connect("pressed", $Chessboard, "reset")

func _on_side_changed():
	update_side_label()

func _on_send_chat_button_pressed():
	var text = $ChatLineEdit.text
	if text:
		print_log(text)

func _on_chess_placed(row_index, column_index, side):
	print_log("%s plays at (%s, %s)" % [SIDES[side], row_index, column_index])

func _on_chess_had_not_placed(row_index, column_index, side, why):
	print_log("%s cannot play at (%s, %s): %s" % [SIDES[side], row_index, column_index, why])

func update_side_label():
	var user_side = $Chessboard.user_side
	var next_side = $Chessboard.next_chess_side
	$SideLabel.set_text("Side: %s\nNext: %s" % [SIDES[user_side], SIDES[next_side]])

func print_log(text):
	$ChatLineEdit.text = ""
	$ChatLabel.add_text(text)
	$ChatLabel.newline()

func _player_connected(id):
	print_log("Player connected: %s" % id)

func _player_disconnected(id):
	print_log("Player disconnected: %s" % id)

func _connected_ok():
	print_log("Connection ok.")
	if mode == "Client":
		$Chessboard.request_synchronization()
		print_log("Chessboard is syncing from host.")

func _server_disconnected():
	print_log("Server disconnected.")

func _connected_fail():
	print_log("Connection failed.")

func host():
	if mode == null:
		var peer = NetworkedMultiplayerENet.new()
		var err = peer.create_server(HOST_PORT, 32)
		if err:
			print_log('Error creating server.')
			return
		get_tree().network_peer = peer
		print_log("Hosting on %s, port %s." % [get_ip(), HOST_PORT])
		mode = "Host"
	else:
		print_log("Current mode is %s." % mode)

func connect_to_host_or_disconnect():
	if mode == null:
		var peer = NetworkedMultiplayerENet.new()
		var server_ip = $IPLineEdit.text
		var err = peer.create_client(server_ip, HOST_PORT)
		if err:
			print_log("Fail to connect to host (%s)" % err)
			return
		get_tree().network_peer = peer
		mode = "Client"
	elif mode == "Client":
		get_tree().network_peer = null
		mode = null
	else:
		print_log("Current mode is %s." % mode)

func get_ip():
	return IP.get_local_addresses()
