# res://scenes/ChoiceDialog.gd
extends PanelContainer

# Sinal que avisa qual escolha foi feita
signal choice_made(consequence)

# Conecte estes nós no Inspetor arrastando-os da árvore de cena
@export var title_label: Label
@export var description_label: Label
@export var buttons_container: VBoxContainer

func setup_choices(title: String, description: String, choices: Array):
	title_label.text = title
	description_label.text = description
	
	for child in buttons_container.get_children():
		child.queue_free()
		
	for choice_data in choices:
		var button = Button.new()
		button.text = choice_data["text"]
		button.pressed.connect(_on_button_pressed.bind(choice_data["consequence"]))
		buttons_container.add_child(button)

func _on_button_pressed(consequence: String):
	emit_signal("choice_made", consequence)
	queue_free()
