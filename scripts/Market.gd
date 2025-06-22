extends Node

var goods = {
	"Food": {"supply": 100.0, "demand": 80.0, "base_price": 10.0},
	"Manufactured": {"supply": 30.0, "demand": 60.0, "base_price": 20.0}
}

func next_month():
	print("--- MÊS NOVO ---")
	for g in goods.keys():
		var data = goods[g]
		var price = data.base_price * (data.demand / data.supply)
		print("%s: %.2f" % [g, price])
		
func update_prices(current_month: int):
	# TODO: Implementar a lógica de atualização de preços de commodities aqui.
	# Por enquanto, apenas imprimimos uma mensagem para saber que a função foi chamada.
	print("📈 Market: Atualizando preços para o mês %d." % current_month)
	pass
