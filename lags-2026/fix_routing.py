import re

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_cafe_cyber.gd"
    with open(path, "r", encoding="utf-8") as f:
        gd = f.read()

    # Find and replace _on_target_pressed function entirely
    # Find start
    start_marker = "func _on_target_pressed(button: TextureButton) -> void:"
    end_marker = "func _on_submit_button_pressed()"
    
    start_idx = gd.find(start_marker)
    end_idx = gd.find(end_marker)
    
    if start_idx == -1 or end_idx == -1:
        print("ERROR: Could not find markers")
        print("start:", start_idx, "end:", end_idx)
        return

    new_func = '''func _on_target_pressed(button: TextureButton) -> void:
\tif is_round_locked:
\t\treturn
\t
\tvar target_type: String = String(button.get_meta("cable_type", ""))
\t
\t# --- UNPLUG existing cable from this target (reroute) ---
\tvar existing_idx := -1
\tfor i in connected_cables.size():
\t\tif connected_cables[i]["tgt_btn"] == button:
\t\t\texisting_idx = i
\t\t\tbreak
\t
\tif existing_idx >= 0:
\t\tvar old = connected_cables[existing_idx]
\t\tvar old_line: Line2D = old["line"]
\t\tvar old_src: TextureButton = old["src_btn"]
\t\tvar was_correct: bool = old.get("correct", false)
\t\t
\t\tif is_instance_valid(old_line): old_line.queue_free()
\t\t
\t\t# Remove plug overlays, re-enable ports
\t\tif is_instance_valid(old_src):
\t\t\tfor ch in old_src.get_children():
\t\t\t\tif ch is TextureRect: ch.queue_free()
\t\t\told_src.disabled = false
\t\t\told_src.self_modulate = Color(1, 1, 1, 1)
\t\tfor ch in button.get_children():
\t\t\tif ch is TextureRect: ch.queue_free()
\t\tbutton.self_modulate = Color(1, 1, 1, 1)
\t\t
\t\tif was_correct:
\t\t\tmatched_count -= 1
\t\t\tprogress_label.text = _t("progress") % [matched_count, expected_matches]
\t\t
\t\tconnected_cables.remove_at(existing_idx)
\t\t
\t\t# If no source selected, just unplugged - done
\t\tif selected_source_type == "":
\t\t\treturn
\telse:
\t\t# No cable here - require source selected to place one
\t\tif selected_source_type == "":
\t\t\treturn
\t
\t# --- PLACE new cable from selected source to this target ---
\tvar src_btn: TextureButton = source_buttons_by_type.get(selected_source_type)
\tif src_btn == null:
\t\treturn
\t
\tvar is_correct: bool = (target_type == selected_source_type)
\tvar path_base := "res://assets/textures/minigame-cafe-cyber/"
\t
\t# Lock source port visually
\tsrc_btn.disabled = true
\tsrc_btn.set_pressed_no_signal(false)
\tsrc_btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
\t# Remove any drag-preview plug overlay
\tif drag_plug_a != null:
\t\tdrag_plug_a.queue_free()
\t\tdrag_plug_a = null
\tvar plug_a = TextureRect.new()
\tplug_a.texture = load(path_base + "cable-a-" + selected_source_type + ".png")
\tplug_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\tplug_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\tplug_a.set_anchors_preset(PRESET_FULL_RECT)
\tplug_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tsrc_btn.add_child(plug_a)
\t
\t# Place plug-b with source cable color (not target color)
\tbutton.self_modulate = Color(1.0, 1.0, 1.0, 1.0) if is_correct else Color(1.3, 0.6, 0.6, 1.0)
\tvar plug_b = TextureRect.new()
\tplug_b.texture = load(path_base + "cable-b-" + selected_source_type + ".png")
\tplug_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\tplug_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\tplug_b.set_anchors_preset(PRESET_FULL_RECT)
\tplug_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tbutton.add_child(plug_b)
\t
\t# Build permanent cable line
\tvar line = Line2D.new()
\tline.texture = load(path_base + "cable-" + selected_source_type + ".png")
\tline.texture_mode = Line2D.LINE_TEXTURE_STRETCH
\tline.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
\tline.joint_mode = Line2D.LINE_JOINT_ROUND
\tif not is_correct: line.modulate = Color(1.2, 0.6, 0.6, 1.0)
\tif line.texture: line.width = float(line.texture.get_height())
\telse: line.width = 15.0
\t
\tvar mat = ShaderMaterial.new()
\tmat.shader = ninepatch_shader
\tmat.set_shader_parameter("margin", 10.0)
\tif line.texture:
\t\tmat.set_shader_parameter("tex_width", float(line.texture.get_width()))
\tline.material = mat
\tlines_container.add_child(line)
\t
\tconnected_cables.append({
\t\t"line": line,
\t\t"src_btn": src_btn,
\t\t"tgt_btn": button,
\t\t"correct": is_correct
\t})
\tsfx_enchufado.play()
\t
\tif is_correct:
\t\tmatched_count += 1
\telse:
\t\tround_time_left = max(0.0, round_time_left - 1.5)
\t\tsfx_fallo.play()
\t
\t# Clear drag preview state
\tif drag_line != null:
\t\tdrag_line.queue_free()
\t\tdrag_line = null
\tdrag_source_btn = null
\tselected_source_type = ""
\tselected_source_label.text = _t("selected_source_none")
\tprogress_label.text = _t("progress") % [matched_count, expected_matches]
\t
\tif matched_count >= expected_matches:
\t\t_resolve_round(true, "all_matched")


'''

    gd = gd[:start_idx] + new_func + gd[end_idx:]
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(gd)
    print("Done")

if __name__ == "__main__":
    fix()
