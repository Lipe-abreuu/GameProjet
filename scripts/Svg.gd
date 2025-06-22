@tool
extends Node2D

const SVG_FILE: String = "res://assets/maps/cone_sul_named.svg"

# Cores para as províncias - exatamente como aparecem na hierarquia
var region_colors = {
	"Buenos Aires": Color(0.3, 0.5, 0.8),    # Azul
	"Cordoba": Color(0.9, 0.5, 0.2),        # Laranja
	"Santiago": Color(0.8, 0.2, 0.2),       # Vermelho
	"Asuncion": Color(0.2, 0.7, 0.3),       # Verde
	"Montevideo": Color(0.7, 0.2, 0.7),     # Roxo
	"Lapaz": Color(0.9, 0.9, 0.2),          # Amarelo
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
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "path":
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
	var last_control_point: Vector2 = Vector2.ZERO # Para comandos S e T

	d = d.strip_edges().replace("\n", " ").replace("\t", " ")

	var i: int = 0
	while i < d.length():
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		if i >= d.length():
			break

		var command: String = d[i]
		i += 1
		while i < d.length() and d[i] in " ,\t\n":
			i += 1

		var is_absolute: bool = command == command.to_upper()
		var current_command = command.to_upper()

		# Hack para tratar múltiplos pares de coordenadas em "M" como "L"
		if current_command == "M" and points.size() > 0:
			current_command = "L"

		match current_command:
			"M": # MoveTo
				while true:
					var coords = parse_coordinates(d, i, 2)
					if coords.size() < 3: # [x, y, new_i]
						i = coords[coords.size() - 1]
						break
					
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					
					start_pos = current_pos
					points.append(current_pos)
					i = coords[2]

			"L": # LineTo
				while true:
					var coords = parse_coordinates(d, i, 2)
					if coords.size() < 3:
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
					if coords.size() < 2:
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
					if coords.size() < 2:
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
					if coords.size() < 7:
						i = coords[coords.size() - 1]
						break
					
					var p0 = current_pos
					var p1 = Vector2(coords[0], coords[1])
					var p2 = Vector2(coords[2], coords[3])
					var p3 = Vector2(coords[4], coords[5])
					
					if not is_absolute:
						p1 += p0
						p2 += p0
						p3 += p0
					
					last_control_point = p2

					for t_step in range(1, 11):
						var t = float(t_step) / 10.0
						var point = p0.cubic_interpolate(p3, p1, p2, t)
						points.append(point)
					
					current_pos = p3
					i = coords[6]

			"S": # Smooth Cubic Bezier
				while true:
					var coords = parse_coordinates(d, i, 4)
					if coords.size() < 5:
						i = coords[coords.size() - 1]
						break
					
					var p0 = current_pos
					var p1 = p0 + (p0 - last_control_point)
					var p2 = Vector2(coords[0], coords[1])
					var p3 = Vector2(coords[2], coords[3])
					
					if not is_absolute:
						p2 += p0
						p3 += p0
						
					last_control_point = p2

					for t_step in range(1, 11):
						var t = float(t_step) / 10.0
						var point = p0.cubic_interpolate(p3, p1, p2, t)
						points.append(point)
					
					current_pos = p3
					i = coords[4]

			"Q": # Quadratic Bezier
				while true:
					var coords = parse_coordinates(d, i, 4)
					if coords.size() < 5:
						i = coords[coords.size() - 1]
						break
						
					var p0 = current_pos
					var p1 = Vector2(coords[0], coords[1])
					var p2 = Vector2(coords[2], coords[3])
					
					if not is_absolute:
						p1 += p0
						p2 += p0

					last_control_point = p1
					
					for t_step in range(1, 11):
						var t = float(t_step) / 10.0
						var point = p0.quadratic_interpolate(p2, p1, t)
						points.append(point)
					
					current_pos = p2
					i = coords[4]
			
			"T": # Smooth Quadratic Bezier
				while true:
					var coords = parse_coordinates(d, i, 2)
					if coords.size() < 3:
						i = coords[coords.size() - 1]
						break
					
					var p0 = current_pos
					var p1 = p0 + (p0 - last_control_point)
					var p2 = Vector2(coords[0], coords[1])

					if not is_absolute:
						p2 += p0
					
					last_control_point = p1

					for t_step in range(1, 11):
						var t = float(t_step) / 10.0
						var point = p0.quadratic_interpolate(p2, p1, t)
						points.append(point)

					current_pos = p2
					i = coords[2]

			"A": # Arc (simplified - just move to the end point)
				while true:
					var coords = parse_coordinates(d, i, 7)
					if coords.size() < 8:
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
				# Use RegEx to find the next letter to avoid an infinite loop
				var regex = RegEx.new()
				regex.compile("[a-zA-Z]")
				var result = regex.search(d, i)
				if result:
					i = result.get_start()
				else:
					i = d.length() # End loop if no more commands found

	return points

func parse_coordinates(d: String, start_idx: int, count: int) -> Array:
	var coords: Array = []
	var i: int = start_idx
	
	while coords.size() < count and i < d.length():
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		
		if i >= d.length():
			break
		
		# Check if the character is a letter, which indicates a new command
		if d[i].to_upper() in "MLHVCSQTAZ":
			break
		
		# Manual number parsing logic (Godot 3 compatible)
		var num_str: String = ""
		var has_dot: bool = false
		var has_exp: bool = false
		var current_char_idx = i

		# Sign
		if d[current_char_idx] == "-" or d[current_char_idx] == "+":
			num_str += d[current_char_idx]
			current_char_idx += 1
		
		# Digits, dot, and exponent
		while current_char_idx < d.length():
			var char = d[current_char_idx]
			if char.is_digit():
				num_str += char
			elif char == "." and not has_dot:
				num_str += char
				has_dot = true
			elif (char == "e" or char == "E") and not has_exp:
				num_str += char
				has_exp = true
				has_dot = true # No more dots after exponent
				# Check for exponent sign
				if current_char_idx + 1 < d.length() and (d[current_char_idx+1] == "+" or d[current_char_idx+1] == "-"):
					current_char_idx += 1
					num_str += d[current_char_idx]
			else:
				break
			current_char_idx += 1
		
		if num_str != "" and num_str != "-" and num_str != "+":
			coords.append(float(num_str))
		
		i = current_char_idx

	coords.append(i) # Append the final index
	return coords
