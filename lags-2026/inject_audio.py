import sys

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_store_search.tscn"
    with open(path, 'r', encoding='utf-8') as f:
        tscn = f.read()

    if '[node name="Audio"' in tscn:
        print("Already has audio")
        return

    last_ext = tscn.rfind("[ext_resource")
    end_of_last_ext = tscn.find("\n", last_ext) + 1
    
    ext_resources = """[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/voltear_carta.mp3" id="voltear_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/fallo.mp3" id="fallo_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/correcto.mp3" id="correcto_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/ok_base.mp3" id="ok_base_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/error.mp3" id="error_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/reloj.mp3" id="reloj_aud"]
"""
    tscn = tscn[:end_of_last_ext] + ext_resources + tscn[end_of_last_ext:]

    audio_nodes = """
[node name="Audio" type="Node" parent="."]

[node name="SFX_Voltear" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("voltear_aud")
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
    tscn += audio_nodes
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(tscn)

if __name__ == "__main__":
    fix()
