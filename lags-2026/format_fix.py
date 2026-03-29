import os

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_store_search.gd"
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Start round
    c = c.replace(
        '\tfound_label.text = "Encontrados: %d / %d" % [found_count, target_count]\n\t\t\tsfx_correcto.play()\n\t\n\tinstruction_label',
        '\tfound_label.text = "Encontrados: %d / %d" % [found_count, target_count]\n\t\n\tinstruction_label'
    )

    # 2. Match correct sound
    c = c.replace(
        '\t\tfound_count += 1\n\t\tfound_label.text = "Encontrados: %d / %d" % [found_count, target_count]\n\t\t\tsfx_correcto.play()\n\t\t\n\t\tif found_count >= target_count:',
        '\t\tfound_count += 1\n\t\tfound_label.text = "Encontrados: %d / %d" % [found_count, target_count]\n\t\tsfx_correcto.play()\n\t\t\n\t\tif found_count >= target_count:'
    )

    # 3. Match fail sound
    c = c.replace(
        '\t\tbutton.self_modulate = Color(1.5, 0.5, 0.5, 1.0)\n\t\t\tsfx_fallo.play()\n\t\t\n\t\terrors_count += 1',
        '\t\tbutton.self_modulate = Color(1.5, 0.5, 0.5, 1.0)\n\t\tsfx_fallo.play()\n\t\t\n\t\terrors_count += 1'
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

if __name__ == "__main__":
    fix()
