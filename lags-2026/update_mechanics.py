import os
import re

def main():
    proj_dir = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026"
    
    # FIX: store_card.tscn layout synchronizer
    path_tscn = os.path.join(proj_dir, "store_card.tscn")
    with open(path_tscn, 'r', encoding='utf-8') as f:
        content = f.read()

    w_match = re.search(r'offset_right = ([\d\.]+)', content)
    h_match = re.search(r'offset_bottom = ([\d\.]+)', content)
    if w_match and h_match:
        width = float(w_match.group(1))
        height = float(h_match.group(1))

        block_end = content.find("\n\n")
        root_block = content[:block_end]
        root_block = re.sub(r'custom_minimum_size = Vector2\([\d\.\,\ ]+\)\n', '', root_block)
        root_block = re.sub(r'(\[node name="StoreCard" type="Control"\]\n)', f'\\1custom_minimum_size = Vector2({width}, {height})\n', root_block)
        content = root_block + content[block_end:]
        
        # Eliminate static offsets to let the root Custom_Minimum handle bounding
        content = re.sub(r'(\[node name="Button" type="TextureButton" parent="\."\]\n)(custom_minimum_size = Vector2\([\d\.\,\ ]+\)\n)?', r'\1', content)
        content = re.sub(r'pivot_offset = Vector2\([\d\.\,\ ]+\)\n', '', content)
        with open(path_tscn, 'w', encoding='utf-8') as f:
            f.write(content)

    # FIX: minijuego_store_search.gd mechanics upgrade
    path_gd = os.path.join(proj_dir, "minijuego_store_search.gd")
    with open(path_gd, 'r', encoding='utf-8') as f:
        gd = f.read()

    if "var target_count: int =" not in gd:
        gd = gd.replace("var target_item: String = \"\"", "var target_item: String = \"\"\nvar target_count: int = 1")
        
    gd = re.sub(r'found_label\.text = _t\("found"\) \% \[found_count\]', r'found_label.text = "Encontrados: %d / %d" % [found_count, target_count]', gd)

    old_build = r"""	var translated_target = _t\("item_" \+ target_item\)
	if translated_target == "item_" \+ target_item:
		translated_target = target_item\.to_upper\(\)
	request_label\.text = "BUSCAR: " \+ translated_target

	var cell_count: int = min\(20, 4 \+ \(round_number - 1\) \* 3\) # R1: 4, R2: 7, R3: 10, R4: 13, R5: 16
	var target_index: int = randi_range\(0, cell_count - 1\)

	if cell_count <= 8: board_grid\.columns = 4
	elif cell_count <= 12: board_grid\.columns = 4
	else: board_grid\.columns = 5

	var possible_fillers = item_types\.duplicate\(\)
	possible_fillers\.erase\(target_item\)

	for i in cell_count:
		var item_type: String = target_item if i == target_index else possible_fillers\[randi_range\(0, possible_fillers\.size\(\) - 1\)\]"""
    
    new_build = """	var translated_target = _t("item_" + target_item)
	if translated_target == "item_" + target_item:
		translated_target = target_item.to_upper()

	var cell_count: int = min(24, 8 + (round_number - 1) * 4) 
	if round_number == 1: target_count = 2
	elif round_number == 2: target_count = 3
	elif round_number == 3: target_count = 4
	elif round_number == 4: target_count = 4
	else: target_count = 5

	request_label.text = "BUSCAR %d: %s" % [target_count, translated_target]

	if cell_count <= 8: board_grid.columns = 4
	elif cell_count <= 12: board_grid.columns = 4
	elif cell_count <= 16: board_grid.columns = 4
	elif cell_count <= 20: board_grid.columns = 5
	else: board_grid.columns = 6

	var possible_fillers = item_types.duplicate()
	possible_fillers.erase(target_item)

	var target_indices: Array[int] = []
	var all_indices = range(cell_count)
	all_indices.shuffle()
	for i in range(target_count):
		target_indices.append(all_indices[i])

	for i in cell_count:
		var item_type: String = target_item if i in target_indices else possible_fillers[randi_range(0, possible_fillers.size() - 1)]"""
        
    gd = re.sub(old_build, new_build, gd, count=1)

    old_click = r"""	if item_type == target_item:
		board_locked = true
		_flip_card\(button, true, true\)
		
		# Efecto de victoria en la carta correcta
		var t = create_tween\(\)\.set_trans\(Tween\.TRANS_ELASTIC\)
		t\.tween_property\(button, "scale", Vector2\(1\.2, 1\.2\), 0\.3\)
		t\.tween_property\(button, "scale", Vector2\(1\.0, 1\.0\), 0\.3\)
		
		found_count \+= 1
		found_label\.text = "Encontrados: %d / %d" % \[found_count, target_count\]
		
		t\.tween_callback\(func\(\): _resolve_round\(true, "found"\)\)"""
        
    new_click = """	if item_type == target_item:
		_flip_card(button, true, true)
		
		# Efecto de victoria en la carta correcta
		var t = create_tween().set_trans(Tween.TRANS_ELASTIC)
		t.tween_property(button, "scale", Vector2(1.2, 1.2), 0.3)
		t.tween_property(button, "scale", Vector2(1.0, 1.0), 0.3)
		
		found_count += 1
		found_label.text = "Encontrados: %d / %d" % [found_count, target_count]
		
		if found_count >= target_count:
			board_locked = true
			t.tween_callback(func(): _resolve_round(true, "found"))"""
            
    gd = re.sub(old_click, new_click, gd, count=1)

    old_flip = r"""	if not is_instance_valid\(button\): return
	button\.set_meta\("is_flipped", face_up\)"""
    
    new_flip = """	if not is_instance_valid(button): return
	button.set_meta("is_flipped", face_up)
	if button.size.x > 0:
		button.pivot_offset = button.size / 2.0"""
        
    gd = re.sub(old_flip, new_flip, gd, count=1)

    with open(path_gd, 'w', encoding='utf-8') as f:
        f.write(gd)
    print("Updates complete.")

if __name__ == "__main__":
    main()
