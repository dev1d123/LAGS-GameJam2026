import os
import re

def main():
    proj_dir = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026"
    card_scene_path = os.path.join(proj_dir, "store_card.tscn")
    
    card_content = """[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://assets/textures/minijuego-store-search/tarjeta_front.png" id="1_tex"]
[ext_resource type="Texture2D" path="res://assets/textures/minijuego-store-search/leche.png" id="2_tex"]

[node name="StoreCard" type="Control"]
custom_minimum_size = Vector2(100, 130)
layout_mode = 3
anchors_preset = 0
mouse_filter = 2

[node name="Button" type="TextureButton" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
pivot_offset = Vector2(50, 65)
ignore_texture_size = true
stretch_mode = 5

[node name="Background" type="TextureRect" parent="Button"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("1_tex")
expand_mode = 1
stretch_mode = 5

[node name="Icon" type="TextureRect" parent="Button"]
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
texture = ExtResource("2_tex")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="Button"]
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
    with open(card_scene_path, 'w', encoding='utf-8') as f:
        f.write(card_content)

    main_scene = os.path.join(proj_dir, "minijuego_store_search.tscn")
    with open(main_scene, 'r', encoding='utf-8') as f:
        content = f.read()

    match = re.search(r'\[node name="CardTemplate"', content)
    if match:
        content = content[:match.start()]
    
    if "store_card.tscn" not in content:
        ext_res = '[ext_resource type="PackedScene" path="res://store_card.tscn" id="999_card"]\n'
        content = re.sub(r'((\[ext_resource.*?\]\n)+)', r'\1' + ext_res, content, count=1)
        
    id_map = {}
    for ext_match in re.finditer(r'\[ext_resource type="(?:Texture2D|PackedScene|FontFile|Script)" .*?path="(.*?)" id="(.*?)"\]', content):
        id_map[ext_match.group(1)] = ext_match.group(2)
        
    card_id = id_map.get("res://store_card.tscn", "999_card")

    for i in range(16):
        node_name = "CardTemplate" if i == 0 else f"Mockup_{i}"
        card_str = f"""[node name="{node_name}" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter" instance=ExtResource("{card_id}")]
layout_mode = 2

"""
        content += card_str

    with open(main_scene, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Store card scene extracted and linked.")

if __name__ == "__main__":
    main()
