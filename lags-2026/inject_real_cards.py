import re

def main():
    path = "c:\\Users\\DrN\\Documents\\LAGS2026\\LAGS-GameJam2026\\lags-2026\\minijuego_store_search.tscn"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the BoardGridCenter node end
    match = re.search(r'\[node name="BoardGridCenter".*?\n(theme_override_constants/v_separation = 15\n)', content)
    if not match:
        print("Could not find BoardGridCenter")
        return
        
    truncate_pos = match.end()
    content = content[:truncate_pos] 

    ext_resources = ""
    uid_counter = 600
    
    needed_texs = [
        "res://assets/textures/minijuego-store-search/tarjeta_front.png",
        "res://assets/textures/minijuego-store-search/tarjeta_back.png",
        "res://assets/textures/minijuego-store-search/leche.png"
    ]
    
    for tex in needed_texs:
        if tex not in content:
            ext_resources += f'[ext_resource type="Texture2D" path="{tex}" id="{uid_counter}_tex"]\n'
            uid_counter += 1
            
    if ext_resources:
        content = re.sub(r'((\[ext_resource.*?\]\n)+)', r'\1' + ext_resources, content, count=1)
        
    id_map = {}
    for ext_match in re.finditer(r'\[ext_resource type="(?:Texture2D|PackedScene|FontFile|Script)" .*?path="(.*?)" id="(.*?)"\]', content):
        id_map[ext_match.group(1)] = ext_match.group(2)

    def get_id(p):
        return id_map.get(p, "1_tex")

    front_id = get_id("res://assets/textures/minijuego-store-search/tarjeta_front.png")
    back_id = get_id("res://assets/textures/minijuego-store-search/tarjeta_back.png")
    leche_id = get_id("res://assets/textures/minijuego-store-search/leche.png")

    for i in range(16):
        node_name = "CardTemplate" if i == 0 else f"Mockup_{i}"
        card_str = f"""
[node name="{node_name}" type="Control" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter"]
custom_minimum_size = Vector2(100, 130)
layout_mode = 2
mouse_filter = 2

[node name="Button" type="TextureButton" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/{node_name}"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
pivot_offset = Vector2(50, 65)
ignore_texture_size = true
stretch_mode = 5

[node name="Background" type="TextureRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/{node_name}/Button"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("{front_id}")
expand_mode = 1
stretch_mode = 5

[node name="Icon" type="TextureRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/{node_name}/Button"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = -30.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("{leche_id}")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/{node_name}/Button"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -30.0
offset_bottom = -5.0
grow_horizontal = 2
grow_vertical = 0
theme_override_colors/font_color = Color(0.2, 0.2, 0.2, 1)
theme_override_font_sizes/font_size = 16
text = "LECHE"
horizontal_alignment = 1
vertical_alignment = 1
"""
        content += card_str

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Done replacing gray mockups with real cards.")

if __name__ == "__main__":
    main()
