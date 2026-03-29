import os
import re

def add_animations():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_store_search.gd"
    with open(path, "r", encoding="utf-8") as f:
        gd = f.read()

    # 1. Update _process to call _clear_board_animated
    process_old = r"""	if pending_next_round >= 0\.0:
		pending_next_round -= delta
		if pending_next_round <= 0\.0:
			pending_next_round = -1\.0
			_start_round\(\)"""
    
    process_new = """	if pending_next_round >= 0.0:
		pending_next_round -= delta
		if pending_next_round <= 0.0:
			pending_next_round = -1.0
			_clear_board_animated(Callable(self, "_start_round"))"""
            
    gd = re.sub(process_old, process_new, gd)
    
    # 2. Add _clear_board_animated safely
    clear_func = """
func _clear_board_animated(callback: Callable) -> void:
	var children = board_grid.get_children()
	if children.is_empty():
		callback.call()
		return
		
	var delay = 0.0
	var final_tween: Tween = null
	for wrapper in children:
		if is_instance_valid(wrapper):
			wrapper.pivot_offset = wrapper.custom_minimum_size / 2.0
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			t.tween_interval(delay)
			t.tween_property(wrapper, "scale", Vector2.ZERO, 0.15)
			delay += 0.02
			final_tween = t
			
	if final_tween:
		final_tween.tween_callback(callback)
	else:
		callback.call()
"""
    gd = re.sub(r'(\nfunc _update_static_texts\(\) -> void:)', clear_func + r'\1', gd)

    # 3. Prevent 1-frame popping during spawn
    build_old = r"""		var wrapper = preload\("res://store_card\.tscn"\)\.instantiate\(\)
		wrapper\.show\(\)"""
    
    build_new = """		var wrapper = preload("res://store_card.tscn").instantiate()
		wrapper.scale = Vector2.ZERO
		wrapper.show()"""
    if "wrapper.scale = Vector2.ZERO" not in gd:
        gd = re.sub(build_old, build_new, gd)

    # 4. Instant Queue Free extraction
    free_old = r"""	for child in board_grid\.get_children\(\):
		child\.queue_free\(\)"""
    free_new = """	for child in board_grid.get_children():
		board_grid.remove_child(child)
		child.queue_free()"""
    gd = re.sub(free_old, free_new, gd)

    # 5. Connect the Entrance Tween block properly
    start_old = r"""	for wrapper in board_grid\.get_children\(\):
		var btn = wrapper\.get_node_or_null\("Button"\)
		if btn: _flip_card\(btn, true, false\)
		
	memorization_time_left = max\(2\.5, 6\.0 - float\(current_round\) \* 0\.6\)"""
    
    start_new = """	for wrapper in board_grid.get_children():
		var btn = wrapper.get_node_or_null("Button")
		if btn: _flip_card(btn, true, false)
		
	memorization_time_left = -1.0
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
				memorization_time_left = mem_time
		)
	else:
		memorization_time_left = max(2.5, 6.0 - float(current_round) * 0.6)"""

    gd = re.sub(start_old, start_new, gd)

    with open(path, "w", encoding="utf-8") as f:
        f.write(gd)
        
if __name__ == "__main__":
    add_animations()
