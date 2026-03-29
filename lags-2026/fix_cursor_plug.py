import re

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_cafe_cyber.gd"
    with open(path, "r", encoding="utf-8") as f:
        gd = f.read()

    # 1. Add drag_plug_b cursor variable
    gd = gd.replace(
        "# Live drag cable\nvar drag_line: Line2D = null\nvar drag_plug_a: TextureRect = null\nvar drag_source_btn: TextureButton = null",
        "# Live drag cable\nvar drag_line: Line2D = null\nvar drag_plug_a: TextureRect = null\nvar drag_plug_b_cursor: Control = null  # cable-b sprite following mouse\nvar drag_source_btn: TextureButton = null\nvar drag_source_type: String = \"\""
    )

    # 2. Update _cancel_drag to also free drag_plug_b_cursor
    gd = gd.replace(
        "func _cancel_drag() -> void:\n\tif drag_line != null:\n\t\tdrag_line.queue_free()\n\t\tdrag_line = null\n\tif drag_plug_a != null:\n\t\tdrag_plug_a.queue_free()\n\t\tdrag_plug_a = null\n\tif drag_source_btn != null:\n\t\tdrag_source_btn.set_pressed_no_signal(false)\n\t\tdrag_source_btn.self_modulate = Color(1, 1, 1, 1)\n\t\tdrag_source_btn = null\n\tselected_source_type = \"\"\n\tselected_source_label.text = _t(\"selected_source_none\")",
        
        "func _cancel_drag() -> void:\n\tif drag_line != null:\n\t\tdrag_line.queue_free()\n\t\tdrag_line = null\n\tif drag_plug_a != null:\n\t\tdrag_plug_a.queue_free()\n\t\tdrag_plug_a = null\n\tif drag_plug_b_cursor != null:\n\t\tdrag_plug_b_cursor.queue_free()\n\t\tdrag_plug_b_cursor = null\n\tif drag_source_btn != null:\n\t\tdrag_source_btn.set_pressed_no_signal(false)\n\t\tdrag_source_btn.self_modulate = Color(1, 1, 1, 1)\n\t\tdrag_source_btn = null\n\tdrag_source_type = \"\"\n\tselected_source_type = \"\"\n\tselected_source_label.text = _t(\"selected_source_none\")"
    )

    # 3. Update _process to move drag_plug_b_cursor to mouse position
    gd = gd.replace(
        "\t\tif drag_line.material:\n\t\t\tdrag_line.material.set_shader_parameter(\"line_length\", curve.get_baked_length())\n\n\tif pending_next_round >= 0.0:",
        "\t\tif drag_line.material:\n\t\t\tdrag_line.material.set_shader_parameter(\"line_length\", curve.get_baked_length())\n\t\n\t# Move plug-b cursor icon to mouse position\n\tif drag_plug_b_cursor != null:\n\t\tdrag_plug_b_cursor.global_position = get_global_mouse_position() - drag_plug_b_cursor.size / 2.0\n\n\tif pending_next_round >= 0.0:"
    )

    # 4. Update _on_source_toggled to set drag_source_type and create cursor plug_b
    gd = gd.replace(
        "\t\tlines_container.add_child(line)\n\t\tdrag_line = line\n\telse:\n\t\tif selected_source_type == this_type:\n\t\t\t_cancel_drag()",
        "\t\tlines_container.add_child(line)\n\t\tdrag_line = line\n\t\tdrag_source_type = this_type\n\t\t\n\t\t# Create cursor plug-b icon\n\t\tvar plug_b_cursor = TextureRect.new()\n\t\tplug_b_cursor.texture = load(path_base + \"cable-b-\" + this_type + \".png\")\n\t\tplug_b_cursor.custom_minimum_size = Vector2(48, 48)\n\t\tplug_b_cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n\t\tplug_b_cursor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED\n\t\tplug_b_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\t\tadd_child(plug_b_cursor)\n\t\tdrag_plug_b_cursor = plug_b_cursor\n\telse:\n\t\tif selected_source_type == this_type:\n\t\t\t_cancel_drag()"
    )

    # 5. Fix _on_target_pressed unplug block to re-activate drag mode
    old_unplug_end = """\t\tif was_correct:
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
\t\t\treturn"""
    
    new_unplug_end = """\t\tif was_correct:
\t\t\tmatched_count -= 1
\t\t\tprogress_label.text = _t("progress") % [matched_count, expected_matches]
\t\t
\t\tconnected_cables.remove_at(existing_idx)
\t\t
\t\t# Re-activate the old cable as the current selection in drag mode
\t\tvar rescued_type := old_src.get_meta("cable_type", "") as String
\t\t# Cancel any existing drag first
\t\tif drag_line != null:
\t\t\tdrag_line.queue_free()
\t\t\tdrag_line = null
\t\tif drag_plug_a != null:
\t\t\tdrag_plug_a.queue_free()
\t\t\tdrag_plug_a = null
\t\tif drag_plug_b_cursor != null:
\t\t\tdrag_plug_b_cursor.queue_free()
\t\t\tdrag_plug_b_cursor = null
\t\t
\t\t# Set up new drag from the unplugged source
\t\tselected_source_type = rescued_type
\t\tdrag_source_type = rescued_type
\t\tdrag_source_btn = old_src
\t\told_src.disabled = false
\t\told_src.self_modulate = Color(1.4, 1.4, 1.4, 1.0)
\t\told_src.set_pressed_no_signal(true)
\t\tselected_source_label.text = _t("selected_source") % [_t("cable_" + rescued_type)]
\t\t
\t\tvar path_base_r := "res://assets/textures/minigame-cafe-cyber/"
\t\t# Add plug-a overlay back
\t\tvar plug_a_r = TextureRect.new()
\t\tplug_a_r.texture = load(path_base_r + "cable-a-" + rescued_type + ".png")
\t\tplug_a_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\tplug_a_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\t\tplug_a_r.set_anchors_preset(PRESET_FULL_RECT)
\t\tplug_a_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
\t\told_src.add_child(plug_a_r)
\t\tdrag_plug_a = plug_a_r
\t\t
\t\t# Rebuild ghost drag line
\t\tvar new_line = Line2D.new()
\t\tnew_line.texture = load(path_base_r + "cable-" + rescued_type + ".png")
\t\tnew_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
\t\tnew_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
\t\tnew_line.joint_mode = Line2D.LINE_JOINT_ROUND
\t\tnew_line.modulate.a = 0.7
\t\tif new_line.texture: new_line.width = float(new_line.texture.get_height())
\t\telse: new_line.width = 15.0
\t\tvar mat_r = ShaderMaterial.new()
\t\tmat_r.shader = ninepatch_shader
\t\tmat_r.set_shader_parameter("margin", 10.0)
\t\tif new_line.texture:
\t\t\tmat_r.set_shader_parameter("tex_width", float(new_line.texture.get_width()))
\t\tnew_line.material = mat_r
\t\tlines_container.add_child(new_line)
\t\tdrag_line = new_line
\t\t
\t\t# Create new cursor plug-b icon
\t\tvar plug_b_cur = TextureRect.new()
\t\tplug_b_cur.texture = load(path_base_r + "cable-b-" + rescued_type + ".png")
\t\tplug_b_cur.custom_minimum_size = Vector2(48, 48)
\t\tplug_b_cur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\tplug_b_cur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\t\tplug_b_cur.mouse_filter = Control.MOUSE_FILTER_IGNORE
\t\tadd_child(plug_b_cur)
\t\tdrag_plug_b_cursor = plug_b_cur
\t\treturn  # Done — don't place a new cable yet
\telse:
\t\t# No cable here - require source selected to place one
\t\tif selected_source_type == "":
\t\t\treturn"""

    if old_unplug_end in gd:
        gd = gd.replace(old_unplug_end, new_unplug_end)
    else:
        print("ERROR: unplug section not found")
        return

    # 6. Clean up drag_plug_b_cursor when placing a cable
    gd = gd.replace(
        "\t# Clear drag preview state\n\tif drag_line != null:\n\t\tdrag_line.queue_free()\n\t\tdrag_line = null\n\tdrag_source_btn = None\n\tselected_source_type = \"\"",
        "\t# Clear drag preview state\n\tif drag_line != null:\n\t\tdrag_line.queue_free()\n\t\tdrag_line = None\n\tif drag_plug_b_cursor != None:\n\t\tdrag_plug_b_cursor.queue_free()\n\t\tdrag_plug_b_cursor = None\n\tdrag_source_btn = None\n\tselected_source_type = \"\""
    )
    # Also handle the real variable names (GDScript uses null not None)
    gd = gd.replace(
        "\t# Clear drag preview state\n\tif drag_line != null:\n\t\tdrag_line.queue_free()\n\t\tdrag_line = null\n\tdrag_source_btn = null\n\tselected_source_type = \"\"",
        "\t# Clear drag preview state\n\tif drag_line != null:\n\t\tdrag_line.queue_free()\n\t\tdrag_line = null\n\tif drag_plug_b_cursor != null:\n\t\tdrag_plug_b_cursor.queue_free()\n\t\tdrag_plug_b_cursor = null\n\tdrag_source_btn = null\n\tdrag_source_type = \"\"\n\tselected_source_type = \"\""
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(gd)
    print("Done")

if __name__ == "__main__":
    fix()
