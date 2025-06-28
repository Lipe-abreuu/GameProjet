# res://scripts/FixSceneStructure.gd
# Execute este script uma vez para corrigir a estrutura da cena

@tool
extends EditorScript

func _run():
	var root = get_scene()
	if not root:
		print("Erro: Nenhuma cena aberta")
		return
	
	print("=== CORRIGINDO ESTRUTURA DA CENA ===")
	
	# Encontrar o Control problemático
	var control = root.get_node_or_null("Control")
	if not control:
		print("Control não encontrado")
		return
	
	# Resetar a escala do Control
	control.scale = Vector2.ONE
	print("✅ Escala do Control resetada para 1,1")
	
	# Mover o mapa para fora do Control
	var map = control.get_node_or_null("NodeMapaSVG2D")
	if map:
		# Salvar a transformação global
		var global_transform = map.global_transform
		
		# Remover do Control e adicionar ao root
		control.remove_child(map)
		root.add_child(map)
		map.owner = root
		
		# Restaurar a transformação
		map.global_transform = global_transform
		print("✅ Mapa movido para fora do Control")
		
		# Adicionar Areas2D aos países se não existirem
		for country in map.get_children():
			if country is Polygon2D and not country.has_node("Area2D"):
				var area = Area2D.new()
				area.name = "Area2D"
				
				var collision = CollisionPolygon2D.new()
				collision.name = "CollisionPolygon2D"
				collision.polygon = country.polygon
				
				area.add_child(collision)
				country.add_child(area)
				
				area.owner = root
				collision.owner = root
				
				print("✅ Area2D adicionada a: %s" % country.name)
	
	print("=== CORREÇÃO CONCLUÍDA ===")
	print("Salve a cena para manter as mudanças!")
