extends RefCounted
class_name SimpleQrCode

const _ALPHANUMERIC_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
const _FORMAT_L_MASK_0 := 0b111011111000100

static var _gf_exp: PackedInt32Array = PackedInt32Array()
static var _gf_log: PackedInt32Array = PackedInt32Array()

static func make_texture(text: String, pixels_per_module: int = 8, quiet_zone: int = 4) -> Texture2D:
	var payload := text.to_upper()
	if not _is_alphanumeric(payload):
		return null

	var version := _pick_version(payload.length())
	if version == -1:
		return null

	var data_codewords := 19 if version == 1 else 34
	var ecc_codewords := 7 if version == 1 else 10

	var data_bits := _encode_alphanumeric(payload, version)
	var data := _bits_to_codewords(data_bits, data_codewords)
	var ecc := _reed_solomon_compute(data, ecc_codewords)

	var all_codewords: Array[int] = []
	all_codewords.append_array(data)
	all_codewords.append_array(ecc)

	var matrix := _build_matrix(version, all_codewords)
	return _matrix_to_texture(matrix, pixels_per_module, quiet_zone)

static func _pick_version(char_count: int) -> int:
	if char_count <= 25:
		return 1
	if char_count <= 47:
		return 2
	return -1

static func _is_alphanumeric(text: String) -> bool:
	for ch in text:
		if _ALPHANUMERIC_TABLE.find(ch) == -1:
			return false
	return true

static func _encode_alphanumeric(text: String, _version: int) -> PackedInt32Array:
	var bits: Array[int] = []
	_append_bits(bits, 0b0010, 4) # mode
	_append_bits(bits, text.length(), 9) # char count for version 1-9

	var i := 0
	while i < text.length():
		if i + 1 < text.length():
			var a := _ALPHANUMERIC_TABLE.find(text[i])
			var b := _ALPHANUMERIC_TABLE.find(text[i + 1])
			_append_bits(bits, a * 45 + b, 11)
			i += 2
		else:
			var c := _ALPHANUMERIC_TABLE.find(text[i])
			_append_bits(bits, c, 6)
			i += 1

	return PackedInt32Array(bits)

static func _bits_to_codewords(bits: PackedInt32Array, data_codewords: int) -> Array[int]:
	var out: Array[int] = []
	var bit_array: Array[int] = []
	bit_array.assign(bits)

	# Terminator
	var max_bits := data_codewords * 8
	var remaining := max_bits - bit_array.size()
	var terminator: int = clampi(remaining, 0, 4)
	for _i in range(terminator):
		bit_array.append(0)

	# Pad to byte
	while bit_array.size() % 8 != 0:
		bit_array.append(0)

	for i in range(0, bit_array.size(), 8):
		var v := 0
		for b in range(8):
			v = (v << 1) | bit_array[i + b]
		out.append(v)

	var pads := [0xEC, 0x11]
	var pad_index := 0
	while out.size() < data_codewords:
		out.append(pads[pad_index % 2])
		pad_index += 1

	return out

static func _build_matrix(version: int, codewords: Array[int]) -> Array:
	var size := 21 + (version - 1) * 4
	var matrix: Array = []
	var is_function: Array = []
	for y in range(size):
		matrix.append([])
		is_function.append([])
		for _x in range(size):
			matrix[y].append(false)
			is_function[y].append(false)

	_place_finder(matrix, is_function, 0, 0)
	_place_finder(matrix, is_function, size - 7, 0)
	_place_finder(matrix, is_function, 0, size - 7)
	_place_timing(matrix, is_function)
	_place_dark_module(matrix, is_function, version)
	_place_format_areas(is_function)
	if version >= 2:
		_place_alignment(matrix, is_function, 18, 18)

	var data_bits: Array[int] = []
	for cw in codewords:
		for bit in range(7, -1, -1):
			data_bits.append((cw >> bit) & 1)

	_place_data(matrix, is_function, data_bits)
	_apply_mask_0(matrix, is_function)
	_place_format_bits(matrix)
	return matrix

static func _place_finder(matrix: Array, is_function: Array, x0: int, y0: int) -> void:
	for y in range(-1, 8):
		for x in range(-1, 8):
			var xx := x0 + x
			var yy := y0 + y
			if yy < 0 or yy >= matrix.size() or xx < 0 or xx >= matrix.size():
				continue
			var is_border := x == -1 or x == 7 or y == -1 or y == 7
			var is_outer := x == 0 or x == 6 or y == 0 or y == 6
			var is_inner := x >= 2 and x <= 4 and y >= 2 and y <= 4
			var v := (is_outer or is_inner) and not is_border
			matrix[yy][xx] = v
			is_function[yy][xx] = true

static func _place_timing(matrix: Array, is_function: Array) -> void:
	var size := matrix.size()
	for i in range(8, size - 8):
		var v := i % 2 == 0
		matrix[6][i] = v
		matrix[i][6] = v
		is_function[6][i] = true
		is_function[i][6] = true

static func _place_dark_module(matrix: Array, is_function: Array, version: int) -> void:
	var y := 4 * version + 9
	matrix[y][8] = true
	is_function[y][8] = true

static func _place_format_areas(is_function: Array) -> void:
	var size := is_function.size()
	for i in range(9):
		if i != 6:
			is_function[8][i] = true
			is_function[i][8] = true
	for i in range(8):
		is_function[8][size - 1 - i] = true
		if i != 6:
			is_function[size - 1 - i][8] = true

static func _place_alignment(matrix: Array, is_function: Array, cx: int, cy: int) -> void:
	for y in range(-2, 3):
		for x in range(-2, 3):
			var xx := cx + x
			var yy := cy + y
			if is_function[yy][xx]:
				continue
			var d: int = maxi(absi(x), absi(y))
			matrix[yy][xx] = d != 1
			is_function[yy][xx] = true

static func _place_data(matrix: Array, is_function: Array, bits: Array[int]) -> void:
	var size := matrix.size()
	var bit_index := 0
	var x := size - 1
	var upward := true
	while x > 0:
		if x == 6:
			x -= 1
		for step in range(size):
			var y := size - 1 - step if upward else step
			for dx in range(2):
				var xx := x - dx
				if is_function[y][xx]:
					continue
				var bit := 0
				if bit_index < bits.size():
					bit = bits[bit_index]
					bit_index += 1
				matrix[y][xx] = bit == 1
		upward = not upward
		x -= 2

static func _apply_mask_0(matrix: Array, is_function: Array) -> void:
	var size := matrix.size()
	for y in range(size):
		for x in range(size):
			if is_function[y][x]:
				continue
			if (x + y) % 2 == 0:
				matrix[y][x] = not matrix[y][x]

static func _place_format_bits(matrix: Array) -> void:
	var size := matrix.size()
	var bits: Array[int] = []
	for i in range(14, -1, -1):
		bits.append((_FORMAT_L_MASK_0 >> i) & 1)

	# Around top-left finder
	var idx := 0
	for x in [0, 1, 2, 3, 4, 5, 7, 8]:
		matrix[8][x] = bits[idx] == 1
		idx += 1
	for y in [7, 5, 4, 3, 2, 1, 0]:
		matrix[y][8] = bits[idx] == 1
		idx += 1

	# Mirrored format info
	idx = 0
	for y in range(size - 1, size - 8, -1):
		matrix[y][8] = bits[idx] == 1
		idx += 1
	for x in range(size - 8, size):
		matrix[8][x] = bits[idx] == 1
		idx += 1

static func _append_bits(bits: Array[int], value: int, count: int) -> void:
	for i in range(count - 1, -1, -1):
		bits.append((value >> i) & 1)

static func _init_gf() -> void:
	if _gf_exp.size() > 0:
		return
	_gf_exp.resize(512)
	_gf_log.resize(256)
	var x := 1
	for i in range(255):
		_gf_exp[i] = x
		_gf_log[x] = i
		x <<= 1
		if x & 0x100:
			x ^= 0x11D
	for i in range(255, 512):
		_gf_exp[i] = _gf_exp[i - 255]

static func _gf_mul(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return _gf_exp[_gf_log[a] + _gf_log[b]]

static func _reed_solomon_compute(data: Array[int], ecc_len: int) -> Array[int]:
	_init_gf()
	var gen := _build_generator(ecc_len)
	var rem: Array[int] = []
	for _i in range(ecc_len):
		rem.append(0)

	for d in data:
		var factor := d ^ rem[0]
		for i in range(ecc_len - 1):
			rem[i] = rem[i + 1]
		rem[ecc_len - 1] = 0
		for i in range(ecc_len):
			rem[i] = rem[i] ^ _gf_mul(gen[i], factor)
	return rem

static func _build_generator(degree: int) -> Array[int]:
	var poly: Array[int] = [1]
	for i in range(degree):
		var next: Array[int] = []
		next.resize(poly.size() + 1)
		for j in range(next.size()):
			next[j] = 0
		for j in range(poly.size()):
			next[j] = next[j] ^ _gf_mul(poly[j], 1)
			next[j + 1] = next[j + 1] ^ _gf_mul(poly[j], _gf_exp[i])
		poly = next
	poly.remove_at(0)
	return poly

static func _matrix_to_texture(matrix: Array, pixels_per_module: int, quiet_zone: int) -> Texture2D:
	var size := matrix.size()
	var full_size := (size + quiet_zone * 2) * pixels_per_module
	var image := Image.create(full_size, full_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)

	for y in range(size):
		for x in range(size):
			if not matrix[y][x]:
				continue
			var px := (x + quiet_zone) * pixels_per_module
			var py := (y + quiet_zone) * pixels_per_module
			for yy in range(pixels_per_module):
				for xx in range(pixels_per_module):
					image.set_pixel(px + xx, py + yy, Color.BLACK)

	return ImageTexture.create_from_image(image)
