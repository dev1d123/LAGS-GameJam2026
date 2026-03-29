import os
import re

def update_minigame():
    proj_dir = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026"
    tscn_path = os.path.join(proj_dir, "minijuego_store_search.tscn")
    gd_path = os.path.join(proj_dir, "minijuego_store_search.gd")

    with open(gd_path, "r", encoding="utf-8") as f:
        gd = f.read()

    gd = re.sub(r'@onready var card_template: Control = board_grid\.get_node_or_null\("CardTemplate"\) if board_grid else null\n', '', gd)
    gd = re.sub(r'\n\tif card_template:\n\t\tcard_template\.hide\(\)', '', gd)
    
    audio_vars = """
@onready var sfx_voltear: AudioStreamPlayer = $Audio/SFX_Voltear
@onready var sfx_fallo: AudioStreamPlayer = $Audio/SFX_Fallo
@onready var sfx_correcto: AudioStreamPlayer = $Audio/SFX_Correcto
@onready var sfx_ok_base: AudioStreamPlayer = $Audio/SFX_OkBase
@onready var sfx_error: AudioStreamPlayer = $Audio/SFX_Error
@onready var sfx_reloj: AudioStreamPlayer = $Audio/SFX_Reloj
var playing_reloj: bool = false
"""
    if "var sfx_voltear" not in gd:
        gd = re.sub(r'(@onready var finish_button: Button = .*?\n)', r'\1' + audio_vars, gd, count=1)
    
    old_child_free = r"""	for child in board_grid\.get_children\(\):
		if child != card_template:
			child\.queue_free\(\)"""
    new_child_free = r"""	for child in board_grid.get_children():
		child.queue_free()"""
    gd = re.sub(old_child_free, new_child_free, gd)

    old_res_free = r"""	for wrapper in board_grid\.get_children\(\):
		if wrapper == card_template: continue
		var button"""
    new_res_free = r"""	for wrapper in board_grid.get_children():
		var button"""
    gd = re.sub(old_res_free, new_res_free, gd)

    old_flip_child = r"""			for wrapper in board_grid\.get_children\(\):
				if wrapper == card_template: continue
				if is_instance_valid\(wrapper\):"""
    new_flip_child = r"""			for wrapper in board_grid.get_children():
				if is_instance_valid(wrapper):"""
    gd = re.sub(old_flip_child, new_flip_child, gd)

    old_start_child = r"""	for wrapper in board_grid\.get_children\(\):
		if wrapper == card_template: continue
		var btn"""
    new_start_child = r"""	for wrapper in board_grid.get_children():
		var btn"""
    gd = re.sub(old_start_child, new_start_child, gd)

    process_reloj = """
	var current_timer = 0.0
	if memorization_time_left > 0.0: current_timer = memorization_time_left
	elif not board_locked: current_timer = round_time_left
	
	if current_timer > 0.0 and current_timer <= 7.0:
		if not playing_reloj:
			playing_reloj = true
			sfx_reloj.play()
	else:
		if playing_reloj:
			playing_reloj = false
			sfx_reloj.stop()
"""
    if "var current_timer = 0.0" not in gd:
        gd = re.sub(r'(func _process\(delta: float\) -> void:\n\tif current_round <= 0:\n\t\treturn\n)', r'\1' + process_reloj, gd)
        
    gd = re.sub(r'(func _resolve_round\(success: bool, reason: String\) -> void:\n\tif pending_next_round >= 0\.0:\n\t\treturn\n)', r'\1\n\tif playing_reloj:\n\t\tplaying_reloj = false\n\t\tsfx_reloj.stop()\n', gd)
    gd = re.sub(r'(func _finish_minigame\(\) -> void:\n\tboard_locked = true)', r'\1\n\tif playing_reloj:\n\t\tplaying_reloj = false\n\t\tsfx_reloj.stop()\n', gd)

    gd = re.sub(r'(func _flip_card\(.*?\) -> void:\n\tif not is_instance_valid\(button\): return\n\tbutton\.set_meta\("is_flipped", face_up\)\n)', r'\1\tsfx_voltear.play()\n', gd)

    gd = re.sub(r'(found_label\.text = "Encontrados: %d / %d" % \[found_count, target_count\])', r'\1\n\t\t\tsfx_correcto.play()', gd)
    gd = re.sub(r'(button\.self_modulate = Color\(1\.5, 0\.5, 0\.5, 1\.0\))', r'\1\n\t\t\tsfx_fallo.play()', gd)

    gd = re.sub(r'(if success:\n\t\tscore \+= 1)', r'\1\n\t\tsfx_ok_base.play()', gd)
    gd = re.sub(r'(else:\n\t\tif reason == "timeout":)', r'else:\n\t\tsfx_error.play()\n\t\tif reason == "timeout":', gd)

    with open(gd_path, "w", encoding="utf-8") as f:
        f.write(gd)


    # NOW Tscn!
    with open(tscn_path, "r", encoding="utf-8") as f:
        tscn = f.read()

    tscn = re.sub(r'\[node name="(CardTemplate|Mockup_\d+)" parent="MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter" instance=ExtResource\("[\w_]+"\)\]\nlayout_mode = 2\n(?:size_flags_horizontal = 4\nsize_flags_vertical = 4\n)?\n?', '', tscn)

    audio_uid = 2000
    audio_assets = [
        ("voltear_carta", "res://assets/audio/minigame-store-search/voltear_carta.mp3"),
        ("fallo", "res://assets/audio/minigame-store-search/fallo.mp3"),
        ("correcto", "res://assets/audio/minigame-store-search/correcto.mp3"),
        ("ok_base", "res://assets/audio/minigame-store-search/ok_base.mp3"),
        ("error", "res://assets/audio/minigame-store-search/error.mp3"),
        ("reloj", "res://assets/audio/minigame-store-search/reloj.mp3")
    ]
    ext_resources = ""
    for name, path in audio_assets:
        if path not in tscn:
            ext_resources += f'[ext_resource type="AudioStream" path="{path}" id="{name}_aud"]\n'

    if ext_resources:
        tscn = re.sub(r'((\[ext_resource.*?\]\n)+)', r'\1' + ext_resources, tscn, count=1)

    id_map = {}
    for ext_match in re.finditer(r'\[ext_resource type="(?:Texture2D|PackedScene|FontFile|Script|AudioStream)" .*?path="(.*?)" id="(.*?)"\]', tscn):
        id_map[ext_match.group(1)] = ext_match.group(2)

    audio_nodes = r"""
[node name="Audio" type="Node" parent="."]

[node name="SFX_Voltear" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("voltear_carta_aud")
bus = &"SFX"

[node name="SFX_Fallo" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("fallo_aud")
bus = &"SFX"

[node name="SFX_Correcto" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("correcto_aud")
bus = &"SFX"

[node name="SFX_OkBase" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("ok_base_aud")
bus = &"SFX"

[node name="SFX_Error" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("error_aud")
bus = &"SFX"

[node name="SFX_Reloj" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("reloj_aud")
bus = &"SFX"
"""
    for name, path in audio_assets:
        audio_nodes = audio_nodes.replace(f'"{name}_aud"', f'"{id_map.get(path, name + "_aud")}"')

    tscn += audio_nodes
    
    with open(tscn_path, "w", encoding="utf-8") as f:
        f.write(tscn)

if __name__ == "__main__":
    update_minigame()
