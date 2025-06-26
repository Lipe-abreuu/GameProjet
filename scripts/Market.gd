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
        """Atualiza preços simulando variação mensal de oferta e demanda."""
        print("📈 Market: Atualizando preços para o mês %d." % current_month)
        for g in goods.keys():
                var data = goods[g]

                # Pequenas flutuações mensais na oferta e demanda
                data.supply *= randf_range(0.95, 1.05)
                data.demand *= randf_range(0.95, 1.05)

                # Calcula e salva o novo preço
                var price = data.base_price * (data.demand / max(data.supply, 1.0))
                data.price = price

                goods[g] = data
                print("   %s: %.2f" % [g, price])
