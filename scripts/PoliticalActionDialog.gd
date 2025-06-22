# PoliticalActionDialog.gd
extends Control

# Referências aos nós da UI
@onready var action_title = $ActionTitleLabel
@onready var description_label = $DescriptionLabel
@onready var risk_label = $RiskLabel
@onready var cost_label = $CostLabel
@onready var execute_button = $ExecuteButton
@onready var cancel_button = $CancelButton

# Ação atual
var current_action = {
	"id": "public_speech",
	"name": "Fazer Discurso Público",
	"description": "Aumenta carisma e apoio",
	"costs": {"connections": 5},
	"effects": {"charisma": 2, "random_support": 3},
	"risk": 5,
	"available": true
}

func _ready():
	# Conectar sinais
	execute_button.pressed.connect(_on_execute_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Configurar UI
	update_ui()

func update_ui():
	action_title.text = "Executar: " + current_action.get("name", "Ação")
	description_label.text = "Descrição: " + current_action.get("description", "")
	risk_label.text = "Risco: " + str(current_action.get("risk", 0)) + "%"
	
	# Formatar custos
	var costs = current_action.get("costs", {})
	var cost_text = "Custos: "
	for cost_type in costs:
		cost_text += cost_type + ": " + str(costs[cost_type]) + " "
	cost_label.text = cost_text

func _on_execute_pressed():
	print("✅ Executando ação: " + current_action.get("name", ""))
	
	# Simulação simples de sucesso/falha
	var success = randf() > (current_action.get("risk", 0) / 100.0)
	
	if success:
		print("✅ Ação bem-sucedida!")
		OS.alert("Ação bem-sucedida!\n\nVocê ganhou carisma e apoio.", "Sucesso")
	else:
		print("❌ Ação falhou!")
		OS.alert("Ação falhou!\n\nVocê perdeu recursos mas não ganhou benefícios.", "Falha")
	
	# Fechar o diálogo
	hide()

func _on_cancel_pressed():
	print("❌ Ação cancelada")
	hide()
