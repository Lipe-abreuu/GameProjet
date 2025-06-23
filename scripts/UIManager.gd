# =====================================
#  UIMANAGER.GD - GERENCIADOR DE UI
# =====================================
class_name UIManager
extends Node

var date_label: Label
var money_label: Label
var support_label: Label
var position_label: Label
var speed_label: Label
var info_container: VBoxContainer

func setup_ui_references(main_node: Node):
	# Usa caminhos mais robustos
	var canvas = main_node.get_node_or_null("CanvasLayer")
	if not canvas:
		push_error("CanvasLayer não encontrado!")
		return
	
	# TopBar
	var topbar = canvas.get_node_or_null("TopBar/HBoxContainer")
	if topbar:
		date_label = topbar.get_node_or_null("DateLabel")
		money_label = topbar.get_node_or_null("MoneyLabel")
		support_label = topbar.get_node_or_null("StabilityLabel")
		position_label = topbar.get_node_or_null("PositionLabel")
	
	# Speed indicator
	var bottombar = canvas.get_node_or_null("BottomBar/HBoxContainer")
	if bottombar:
		speed_label = bottombar.get_node_or_null("SpeedLabel")
	
	# Info panel
	var sidepanel = canvas.get_node_or_null("Sidepanel")
	if sidepanel:
		info_container = sidepanel.get_node_or_null("InfoContainer")

func update_date(month: String, year: int):
	if date_label:
		date_label.text = "%s %d" % [month, year]

func update_wealth_display(wealth: int):
	if money_label:
		money_label.text = "💰 %d" % wealth

func update_support_display(average_support: float):
	if support_label:
		support_label.text = "📊 %.1f%%" % average_support

func update_position_display(position: String):
	if position_label:
		position_label.text = "👤 " + position

func update_speed_display(speed: int) -> void:
	if speed_label:
		match speed:
			0: # PAUSED
				speed_label.text = "⏸️ Pausado"
			4: # SLOW
				speed_label.text = "▶ Devagar"
			2: # NORMAL
				speed_label.text = "▶▶ Normal"
			1: # FAST
				speed_label.text = "▶▶▶ Rápido"
