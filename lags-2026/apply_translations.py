import re

def main():
    path = "c:\\Users\\DrN\\Documents\\LAGS2026\\LAGS-GameJam2026\\lags-2026\\minijuego_granel.tscn"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Ensure ext_resource exists
    if 'res://ui/components/localized_text.gd' not in content:
        ext = '[ext_resource type="Script" path="res://ui/components/localized_text.gd" id="100_loctext"]\n'
        # Insert after the last ext_resource
        content = re.sub(r'((\[ext_resource.*?\]\n)+)', r'\1' + ext, content, count=1)

    # Replacements (Regex match exact node paths or texts to append script properties)
    
    replacements = [
        # Title_1
        (r'(text = "PESAJE A GRANEL"\n)', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "title_granel"\n'),
        # Guia Rapida
        (r'(text = "GUÍA RÁPIDA"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "guia_rapida"\n'),
        # Instruccion Espacio
        (r'(text = "INCLINAR\\n(?:Y VERTER|E DESPEJAR|AND POUR)"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "instruccion_espacio"\n'),
        # Instruccion C
        (r'(text = "TOQUES DE\\nPRESICION"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "instruccion_c"\n'),
        # Instruccion R
        (r'(text = "DEVOLVER DE\\nLA BALANZA"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "instruccion_r"\n'),
        # Objetivos
        (r'(text = "OBJETIVOS"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "objetivos"\n'),
        # Resultados
        (r'(text = "RESULTADOS"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "resultados"\n'),
        # Boton Entregar Producto (Button_1)
        (r'(\[node name="Button" parent="HBoxContainer/Control2" .*?\]\n[\s\S]*?)(text = "ENTREGAR PRODUCTO"\n)', r'\1\2translation_category = "minigame_granel"\ntranslation_key = "entregar_producto"\n'),
        # Boton Continuar (Button_1)
        (r'(\[node name="Continuar" parent="HBoxContainer/Control3" .*?\]\n[\s\S]*?)(text = "CONTINUAR"\n)', r'\1\2translation_category = "minigame_granel"\ntranslation_key = "continuar"\n')
    ]

    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    # Note: We do not translate dynamic texts like "PESO OBJETIVO: %s" in the .tscn
    # because they are purely placeholders or handled perfectly by minijuego_granel.gd overwriting them!
    # Wait, the user specifically hated "hardcoded texts" in the scene.
    # What about "1° PEDIDO: 10.00kg" ? Let's clear its text and assign translated placeholders, or just translate it!
    content = re.sub(r'(text = "1° PEDIDO: 10\.00kg"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "primer_pedido_espera"\n', content)
    content = re.sub(r'(text = "SEGUNDO PEDIDO"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "segundo_pedido"\n', content)
    content = re.sub(r'(text = "TERCER PEDIDO"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "tercer_pedido"\n', content)
    content = re.sub(r'(text = "PESO OBJETIVO:\\n32\.34 KG"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "peso_objetivo"\n', content)
    content = re.sub(r'(text = "EXELENTE!"\n(?!script))', r'\1script = ExtResource("100_loctext")\ntranslation_category = "minigame_granel"\ntranslation_key = "r_excelente"\n', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Done rewriting tscn!")

if __name__ == "__main__":
    main()
