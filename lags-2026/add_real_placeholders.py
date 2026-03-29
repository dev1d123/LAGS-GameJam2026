import re

def main():
    path = "c:\\Users\\DrN\\Documents\\LAGS2026\\LAGS-GameJam2026\\lags-2026\\minijuego_cafe_cyber.tscn"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove old placeholders
    content = re.sub(r'\[node name="Placeholder[^"]+" type="ColorRect" parent=".*?"\]\ncustom_minimum_size = Vector2\(100, 70\)\nlayout_mode = 2\ncolor = Color\(.*?\)\n', '', content)

    colors = ["amarillo", "verde", "negro", "morado", "azul", "rojo", "blanco", "naranja"]

    # 2. Add dependencies for textures if not exist
    ext_resources = ""
    uid_counter = 500
    for c in colors:
        for prefix in ["puerto-a-", "puerto-b-", "cable-a-", "cable-b-", "cable-"]:
            tex_path = f"res://assets/textures/minigame-cafe-cyber/{prefix}{c}.png"
            if tex_path not in content:
                ext_resources += f'[ext_resource type="Texture2D" path="{tex_path}" id="{uid_counter}_tex"]\n'
                uid_counter += 1

    if ext_resources:
        content = re.sub(r'((\[ext_resource.*?\]\n)+)', r'\1' + ext_resources, content, count=1)

    # Re-read to map IDs
    id_map = {}
    for match in re.finditer(r'\[ext_resource type="Texture2D" .*?path="(.*?)" id="(.*?)"\]', content):
        id_map[match.group(1)] = match.group(2)

    def get_id(tex_path):
        return id_map.get(tex_path, "1_tex") # fallback

    # 3. Build SourceGrid Nodes
    src_nodes = ""
    for c in colors:
        t_id = get_id(f"res://assets/textures/minigame-cafe-cyber/puerto-a-{c}.png")
        src_nodes += f"""[node name="PortA_{c}" type="TextureButton" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/SourceGrid"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2
toggle_mode = true
texture_normal = ExtResource("{t_id}")
ignore_texture_size = true
stretch_mode = 5
"""
        # Add plug to the first one as an example
        if c == "amarillo":
            p_id = get_id(f"res://assets/textures/minigame-cafe-cyber/cable-a-{c}.png")
            src_nodes += f"""
[node name="PlugA_Example" type="TextureRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/SourceGrid/PortA_{c}"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("{p_id}")
expand_mode = 1
stretch_mode = 5
"""

    # 4. Build TargetGrid Nodes
    tgt_nodes = ""
    for c in colors:
        t_id = get_id(f"res://assets/textures/minigame-cafe-cyber/puerto-b-{c}.png")
        tgt_nodes += f"""[node name="PortB_{c}" type="TextureButton" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/TargetGrid"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2
texture_normal = ExtResource("{t_id}")
ignore_texture_size = true
stretch_mode = 5
"""
        if c == "amarillo":
            p_id = get_id(f"res://assets/textures/minigame-cafe-cyber/cable-b-{c}.png")
            tgt_nodes += f"""
[node name="PlugB_Example" type="TextureRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/TargetGrid/PortB_{c}"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("{p_id}")
expand_mode = 1
stretch_mode = 5
"""

    # 5. Build LinesContainer and CableTemplate
    cable_tex_id = get_id("res://assets/textures/minigame-cafe-cyber/cable-amarillo.png")
    stylebox_id = "StyleBoxTexture_cable_template"
    
    stylebox_def = f"""
[sub_resource type="StyleBoxTexture" id="{stylebox_id}"]
texture = ExtResource("{cable_tex_id}")
texture_margin_left = 10.0
texture_margin_top = 0.0
texture_margin_right = 10.0
texture_margin_bottom = 0.0
axis_stretch_horizontal = 2
"""
    content = re.sub(r'((\[sub_resource.*?\]\n[\s\S]*?\n\n)+)', r'\1' + stylebox_def + '\n', content, count=1)

    lines_container = f"""
[node name="LinesContainer" type="Control" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea"]
layout_mode = 2
mouse_filter = 2

[node name="CableTemplate" type="PanelContainer" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/LinesContainer"]
layout_mode = 0
offset_right = 200.0
offset_bottom = 20.0
theme_override_styles/panel = SubResource("{stylebox_id}")
"""

    content = re.sub(r'(\[node name="SourceGrid" type="GridContainer" .*?\]\n[\s\S]*?\n\n)', r'\1' + src_nodes + '\n\n', content)
    content = re.sub(r'(\[node name="TargetGrid" type="GridContainer" .*?\]\n[\s\S]*?\n\n)', r'\1' + tgt_nodes + '\n\n', content)
    
    content = re.sub(r'(\[node name="Inner" type="HBoxContainer" .*?\]\n[\s\S]*?(?=\[node name="ActionRow"|$))', r'\1' + lines_container + '\n', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Successfully parsed and injected real asset nodes into Tscn.")

if __name__ == "__main__":
    main()
