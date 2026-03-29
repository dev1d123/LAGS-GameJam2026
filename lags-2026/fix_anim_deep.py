import os
import re

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_store_search.gd"
    with open(path, "r", encoding="utf-8") as f:
        gd = f.read()

    # In _build_round_board, remove wrapper scale and use modulate
    build_old = r"""		var wrapper = preload\("res://store_card\.tscn"\)\.instantiate\(\)
		wrapper\.scale = Vector2\.ZERO
		wrapper\.show\(\)"""
    
    build_new = """		var wrapper = preload("res://store_card.tscn").instantiate()
		wrapper.modulate.a = 0.0
		wrapper.show()"""
    gd = re.sub(build_old, build_new, gd)

    # In _start_round, add await process_frame and use descendant scaling
    start_old = r"""	memorization_time_left = -1\.0
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
				for w in board_grid\.get_children\(\):
					var b = w\.get_node_or_null\("Button"\)
					if b: _flip_card\(b, true, true\)
				
				get_tree\(\)\.create_timer\(0\.35\)\.timeout\.connect\(func\(\):
					if is_instance_valid\(self\):
						memorization_time_left = mem_time
				\)
		\)"""
    
    start_new = """	memorization_time_left = -1.0
	timer_label.text = "Repartiendo..."
	
	await get_tree().process_frame
	
	var anim_delay = 0.0
	var last_tween: Tween = null
	for wrapper in board_grid.get_children():
		wrapper.modulate.a = 1.0
		var btn = wrapper.get_node_or_null("Button")
		if btn:
			btn.pivot_offset = btn.size / 2.0
			btn.scale = Vector2.ZERO
			var t1 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t1.tween_interval(anim_delay)
			t1.tween_property(btn, "scale", Vector2.ONE, 0.25)
			last_tween = t1
			
		var lbl = wrapper.get_node_or_null("Label")
		if lbl:
			lbl.pivot_offset = lbl.size / 2.0
			lbl.scale = Vector2.ZERO
			var t2 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t2.tween_interval(anim_delay)
			t2.tween_property(lbl, "scale", Vector2.ONE, 0.25)
			
		anim_delay += 0.03
		
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

    # In _clear_board_animated, map scaling directly to inner children
    clear_old = r"""func _clear_board_animated\(callback: Callable\) -> void:
	var children = board_grid\.get_children\(\)
	if children\.is_empty\(\):
		callback\.call\(\)
		return
		
	var delay = 0\.0
	var final_tween: Tween = null
	for wrapper in children:
		if is_instance_valid\(wrapper\):
			wrapper\.pivot_offset = wrapper\.custom_minimum_size / 2\.0
			var t = create_tween\(\)\.set_trans\(Tween\.TRANS_BACK\)\.set_ease\(Tween\.EASE_IN\)
			t\.tween_interval\(delay\)
			t\.tween_property\(wrapper, "scale", Vector2\.ZERO, 0\.15\)
			delay \+= 0\.02
			final_tween = t"""

    clear_new = """func _clear_board_animated(callback: Callable) -> void:
	var children = board_grid.get_children()
	if children.is_empty():
		callback.call()
		return
		
	var delay = 0.0
	var final_tween: Tween = null
	for wrapper in children:
		if is_instance_valid(wrapper):
			var btn = wrapper.get_node_or_null("Button")
			if btn:
				btn.pivot_offset = btn.size / 2.0
				var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				t.tween_interval(delay)
				t.tween_property(btn, "scale", Vector2.ZERO, 0.15)
				final_tween = t
			var lbl = wrapper.get_node_or_null("Label")
			if lbl:
				lbl.pivot_offset = lbl.size / 2.0
				var t2 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				t2.tween_interval(delay)
				t2.tween_property(lbl, "scale", Vector2.ZERO, 0.15)
			delay += 0.02"""

    gd = re.sub(clear_old, clear_new, gd)

    with open(path, "w", encoding="utf-8") as f:
        f.write(gd)

if __name__ == "__main__":
    fix()
