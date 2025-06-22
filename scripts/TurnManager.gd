extends Node
"""
TurnManager – controla avanço de tempo e aciona subsistemas.
Compatível com:
  • Market (update_prices)
  • EventRegistry (check_for_event)
  • AutoTimer  (opcional: avança mês automático)
"""

signal month_advanced(mes, ano)

var current_month: int = 1
var current_year:  int = 1836

@onready var market          = $"../Market"
@onready var event_registry  = $"../Events"
@onready var auto_timer      = $"../AutoTimer"  # opcional

func _ready() -> void:
	print("⏳ TurnManager iniciado: %d/%d" % [current_month, current_year])
	if auto_timer:
		auto_timer.timeout.connect(_on_timer_tick)

# --- API pública ---------------------------------------------------------
func next_month() -> void:
	_advance_time()
	_update_subsystems()
	emit_signal("month_advanced", current_month, current_year)

# --- Interno -------------------------------------------------------------
func _advance_time() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year  += 1
	print("📅 Novo turno: %02d/%d" % [current_month, current_year])

func _update_subsystems() -> void:
	if market:
		market.update_prices(current_month)
	if event_registry:
		event_registry.check_for_event(current_month, current_year)

# --- Timer opcional ------------------------------------------------------
func _on_timer_tick() -> void:
	next_month()
