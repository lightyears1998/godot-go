extends Control


func _ready():
	$Chessboard.connect("side_changed", self, "_on_side_changed")
	$RepentButton.connect("pressed", $Chessboard, "repent")
	$SwitchSideButton.connect("pressed", $Chessboard, "switch_user_side")
	$AutoSwitchSideCheckBox.connect("pressed", $Chessboard, "toggle_switch_side_after_move")

func _on_side_changed(new_side):
	var sides = ["Black", "White"]
	$SideLabel.set_text(sides[new_side])
