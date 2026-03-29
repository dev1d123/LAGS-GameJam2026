import os
import re

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_store_search.gd"
    with open(path, "r", encoding="utf-8") as f:
        gd = f.read()

    # 1. Update _clear_board_animated to add 0.5s interval
    clear_old = r"""	if final_tween:
		final_tween\.tween_callback\(callback\)"""
    clear_new = """	if final_tween:
		final_tween.tween_interval(0.5)
		final_tween.tween_callback(callback)"""
    gd = re.sub(clear_old, clear_new, gd)

    # 2. Update _start_round
    start_old = r"""	# Colocar las cartas BOCA ARRIBA
	for wrapper in board_grid\.get_children\(\):
		var btn = wrapper\.get_node_or_null\("Button"\)
		if btn: _flip_card\(btn, true, false\)
		
	memorization_time_left = -1\.0
	timer_label\.text = "Repartiendo..."
	var anim_delay = 0\.0
	var last_tween: Tween = null
	for wrapper in board_grid\.get_children\(\):
		wrapper\.pivot_offset = wrapper\.custom_minimum_size / 2\.0
		var t = create_tween\(\)\.set_trans\(Tween\.TRANS_BACK\)\.set_ease\(Tween\.EASE_OUT\)
		t\.tween_interval\(anim_delay\)
		t\.tween_property\(wrapper, "scale", Vector2\.ONE, 0\.25\)
		anim_delay \+= 0\.03
		last_tween = t
		
	if last_tween:
		var mem_time = max\(2\.5, 6\.0 - float\(current_round\) \* 0\.6\)
		last_tween\.tween_callback\(func\(\): 
			if is_instance_valid\(self\):
				memorization_time_left = mem_time
		\)"""
        
    start_new = """	memorization_time_left = -1.0
	timer_label.text = "Repartiendo..."
	var anim_delay = 0.0
	var last_tween: Tween = null
	for wrapper in board_grid.get_children():
		wrapper.pivot_offset = wrapper.custom_minimum_size / 2.0
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_interval(anim_delay)
		t.tween_property(wrapper, "scale", Vector2.ONE, 0.25)
		anim_delay += 0.03
		last_tween = t
		
	if last_tween:
		var mem_time = max(2.5, 6.0 - float(current_round) * 0.6)
		last_tween.tween_callback(func(): 
			if is_instance_valid(self):
				for w in board_grid.get_children():
					var b = w.get_node_or_null("Button")
					if b: _flip_card(b, true, true)
				
				get_tree().create_timer(0.35).timeout.connect(func():
					if is_instance_valid(self):
						memorization_time_left = mem_time
				)
		)"""
        
    gd = re.sub(start_old, start_new, gd)

    # 3. Remove accidental sfx_correcto.play() from _start_round
    gd = gd.replace('\tfound_label.text = "Encontrados: %d / %d" % [found_count, target_count]\n\tsfx_correcto.play()', 
                    '\tfound_label.text = "Encontrados: %d / %d" % [found_count, target_count]')


    with open(path, "w", encoding="utf-8") as f:
        f.write(gd)

if __name__ == "__main__":
    fix()
