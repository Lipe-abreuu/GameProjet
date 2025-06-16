@tool
extends Node2D

const SVG_FILE: String = "res://assets/maps/cone_sul_named.svg"

# Cores para as províncias - exatamente como aparecem na hierarquia
var region_colors = {
	"Buenos Aires": Color(0.3, 0.5, 0.8),    # Azul
	"Cordoba": Color(0.9, 0.5, 0.2),         # Laranja
	"Santiago": Color(0.8, 0.2, 0.2),        # Vermelho
	"Asuncion": Color(0.2, 0.7, 0.3),        # Verde
	"Montevideo": Color(0.7, 0.2, 0.7),      # Roxo
	"Lapaz": Color(0.9, 0.9, 0.2),           # Amarelo
}

func _ready() -> void:
	if Engine.is_editor_hint():
		load_svg()

func load_svg() -> void:
	var file = FileAccess.open(SVG_FILE, FileAccess.READ)
	if file == null:
		push_error("SVG não encontrado: " + SVG_FILE)
		return
	
	var svg_data: String = file.get_as_text()
	file.close()
	
	print("=== CARREGANDO SVG ===")
	
	var parser: XMLParser = XMLParser.new()
	var err: int = parser.open_buffer(svg_data.to_utf8_buffer())
	if err != OK:
		push_error("Erro ao abrir SVG como XML: " + str(err))
		return
	
	# Limpa filhos anteriores
	for child in get_children():
		child.queue_free()
	
	var paths_found = 0
	var paths_loaded = 0
	
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT \
		and parser.get_node_name() == "path":
			paths_found += 1
			var path_data: String = ""
			var id_name: String = ""
			
			# Percorre atributos
			for i in parser.get_attribute_count():
				var attr_name: String = parser.get_attribute_name(i)
				var attr_value: String = parser.get_attribute_value(i)
				if attr_name == "d":
					path_data = attr_value
				elif attr_name == "id":
					id_name = attr_value
			
			print("Path encontrado: ", id_name, " (tem dados: ", path_data != "", ")")
			
			if path_data != "" and id_name != "":
				var points: PackedVector2Array = parse_svg_path(path_data)
				print("  - Pontos parseados: ", points.size())
				
				if points.size() > 2:
					var poly: Polygon2D = Polygon2D.new()
					poly.name = id_name
					poly.polygon = points
					
					# Define a cor baseada no ID
					if region_colors.has(id_name):
						poly.modulate = region_colors[id_name]
					else:
						# Cor aleatória se não encontrar
						poly.modulate = Color(randf(), randf(), randf(), 1.0)
						print("  ! Usando cor aleatória para: ", id_name)
					
					add_child(poly)
					paths_loaded += 1
					
					# Define owner para persistir no editor
					if Engine.is_editor_hint():
						poly.owner = get_tree().edited_scene_root
					
					print("  ✓ Carregado com sucesso!")
				else:
					print("  ✗ Ignorado - poucos pontos")
	
	print("\nRESUMO:")
	print("Paths encontrados: ", paths_found)
	print("Paths carregados: ", paths_loaded)

func parse_svg_path(d: String) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var current_pos: Vector2 = Vector2.ZERO
	var start_pos: Vector2 = Vector2.ZERO
	
	# Remove espaços extras e normaliza
	d = d.strip_edges().replace("\n", " ").replace("\t", " ")
	
	var i: int = 0
	while i < d.length():
		# Pula espaços
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		
		if i >= d.length():
			break
		
		# Pega o comando
		var command: String = d[i]
		i += 1
		
		# Pula espaços após comando
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		
		var is_absolute: bool = command == command.to_upper()
		
		match command.to_upper():
			"M": # MoveTo
				var coords = parse_coordinates(d, i, 2)
				if coords.size() >= 2:
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					start_pos = current_pos
					points.append(current_pos)
					i = coords[2]
					
					# MoveTo com múltiplos pontos vira LineTo
                                        while true:
                                                var more_coords = parse_coordinates(d, i, 2)
                                                if more_coords.size() < 2:
                                                        i = more_coords[more_coords.size() - 1]
                                                        break
						if is_absolute:
							current_pos = Vector2(more_coords[0], more_coords[1])
						else:
							current_pos += Vector2(more_coords[0], more_coords[1])
						points.append(current_pos)
						i = more_coords[2]
			
			"L": # LineTo
                                while true:
                                        var coords = parse_coordinates(d, i, 2)
                                        if coords.size() < 2:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					points.append(current_pos)
					i = coords[2]
			
			"H": # Horizontal LineTo
                                while true:
                                        var coords = parse_coordinates(d, i, 1)
                                        if coords.size() < 1:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos.x = coords[0]
					else:
						current_pos.x += coords[0]
					points.append(current_pos)
					i = coords[1]
			
			"V": # Vertical LineTo
                                while true:
                                        var coords = parse_coordinates(d, i, 1)
                                        if coords.size() < 1:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos.y = coords[0]
					else:
						current_pos.y += coords[0]
					points.append(current_pos)
					i = coords[1]
			
			"C": # Cubic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 6)
                                        if coords.size() < 6:
                                                i = coords[coords.size() - 1]
                                                break
					
					# Adiciona alguns pontos intermediários para melhor aproximação
					var p0 = current_pos
					var p1 = Vector2(coords[0], coords[1])
					var p2 = Vector2(coords[2], coords[3])
					var p3 = Vector2(coords[4], coords[5])
					
					if not is_absolute:
						p1 = p0 + p1
						p2 = p0 + p2
						p3 = p0 + p3
					
					# Aproxima a curva com vários pontos
					for t in range(1, 11):
						var t_norm = float(t) / 10.0
						var one_minus_t = 1.0 - t_norm
						
						var point = p0 * pow(one_minus_t, 3) + \
								   p1 * 3 * pow(one_minus_t, 2) * t_norm + \
								   p2 * 3 * one_minus_t * pow(t_norm, 2) + \
								   p3 * pow(t_norm, 3)
						
						points.append(point)
					
					current_pos = p3
					i = coords[6]
			
			"S": # Smooth Cubic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 4)
                                        if coords.size() < 4:
                                                i = coords[coords.size() - 1]
                                                break
					
					# Aproxima com pontos intermediários
					var p0 = current_pos
					var p2 = Vector2(coords[0], coords[1])
					var p3 = Vector2(coords[2], coords[3])
					
					if not is_absolute:
						p2 = p0 + p2
						p3 = p0 + p3
					
					# Adiciona pontos intermediários
					for j in range(1, 6):
						var t = float(j) / 5.0
						var point = p0.lerp(p3, t)
						points.append(point)
					
					current_pos = p3
					i = coords[4]
			
			"Q": # Quadratic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 4)
                                        if coords.size() < 4:
                                                i = coords[coords.size() - 1]
                                                break
					
					# Aproxima a curva quadrática
					var p0 = current_pos
					var p1 = Vector2(coords[0], coords[1])
					var p2 = Vector2(coords[2], coords[3])
					
					if not is_absolute:
						p1 = p0 + p1
						p2 = p0 + p2
					
					# Adiciona pontos intermediários
					for j in range(1, 6):
						var t = float(j) / 5.0
						var one_minus_t = 1.0 - t
						
						var point = p0 * pow(one_minus_t, 2) + \
								   p1 * 2 * one_minus_t * t + \
								   p2 * pow(t, 2)
						
						points.append(point)
					
					current_pos = p2
					i = coords[4]
			
			"T": # Smooth Quadratic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 2)
                                        if coords.size() < 2:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					points.append(current_pos)
					i = coords[2]
			
			"A": # Arc (simplificado - apenas pega o ponto final)
                                while true:
                                        var coords = parse_coordinates(d, i, 7)
                                        if coords.size() < 7:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos = Vector2(coords[5], coords[6])
					else:
						current_pos += Vector2(coords[5], coords[6])
					points.append(current_pos)
					i = coords[7]
			
			"Z", "z": # ClosePath
				if points.size() > 0 and current_pos.distance_to(start_pos) > 0.1:
					points.append(start_pos)
				current_pos = start_pos
			
			_:
				push_warning("Comando SVG não reconhecido: " + command)
	
	return points

func parse_coordinates(d: String, start_idx: int, count: int) -> Array:
	var coords: Array = []
	var i: int = start_idx
	
	while coords.size() < count and i < d.length():
		# Pula espaços e vírgulas
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		
		if i >= d.length():
			break
		
		# Verifica se é um novo comando (letra)
		if d[i].to_upper() in "MLHVCSQTAZ":
			break
		
		# Parse do número
		var num_str: String = ""
		var has_dot: bool = false
		
		# Sinal negativo
		if d[i] == "-" or d[i] == "+":
			num_str += d[i]
			i += 1
		
		# Parte inteira e decimal
		while i < d.length():
			if d[i] >= "0" and d[i] <= "9":
				num_str += d[i]
			elif d[i] == "." and not has_dot:
				num_str += d[i]
				has_dot = true
			elif d[i] == "e" or d[i] == "E":
				# Notação científica
				num_str += d[i]
				i += 1
				if i < d.length() and (d[i] == "+" or d[i] == "-"):
					num_str += d[i]
					i += 1
				continue
			else:
				break
			i += 1
		
		if num_str != "" and num_str != "-" and num_str != "+":
			coords.append(float(num_str))
	
	# Adiciona o índice final
	coords.append(i)
	return coords
