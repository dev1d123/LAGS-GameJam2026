import os

def main():
    path = "c:\\Users\\DrN\\Documents\\LAGS2026\\LAGS-GameJam2026\\lags-2026\\minijuego_store_search.tscn"
    
    with open(path, 'a', encoding='utf-8') as f:
        # Add dependency if not explicitly there, Godot often handles it or we can fallback to 1_tex if uid is missing.
        # But to be clean, let's just append the CenterContainer and the 16 cards.
        # For simplicity and preventing 16 huge node structures, we will append 1 "CardTemplate" and 15 lightweight placeholders, or 16 full ones.
        # The user wants to see the layout limit. 16 full ones is great.
        
        # Ext resources for tests
        item = "leche"
        front = "tarjeta_front"
        back = "tarjeta_back"
        
        block = f"""
[node name="Center" type="CenterContainer" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField"]
layout_mode = 2

[node name="BoardGridCenter" type="GridContainer" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center"]
layout_mode = 2
columns = 4
theme_override_constants/h_separation = 15
theme_override_constants/v_separation = 15
"""
        f.write(block)
        
        # We write 1 template that the script will clone.
        template = """
[node name="CardTemplate" type="Control" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter"]
custom_minimum_size = Vector2(100, 130)
layout_mode = 2
mouse_filter = 2

[node name="Button" type="TextureButton" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/CardTemplate"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
pivot_offset = Vector2(50, 65)
ignore_texture_size = true
stretch_mode = 5

[node name="Background" type="TextureRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/CardTemplate/Button"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
expand_mode = 1
stretch_mode = 5

[node name="Icon" type="TextureRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/CardTemplate/Button"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 10.0
offset_bottom = -30.0
grow_horizontal = 2
grow_vertical = 2
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter/CardTemplate/Button"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -30.0
offset_bottom = -5.0
grow_horizontal = 2
grow_vertical = 0
theme_override_colors/font_color = Color(0.203922, 0.203922, 0.203922, 1)
theme_override_font_sizes/font_size = 16
text = "ITEM"
horizontal_alignment = 1
vertical_alignment = 1
"""
        f.write(template)
        
        # Add 15 mockups
        for i in range(1, 16):
            f.write(f"""
[node name="Mockup{i}" type="ColorRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter"]
custom_minimum_size = Vector2(100, 130)
layout_mode = 2
color = Color(0.2, 0.2, 0.2, 0.5)
""")

    print("Success injected mockups.")

if __name__ == "__main__":
    main()
