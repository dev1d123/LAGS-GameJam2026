import os
import re

def fix():
    # 1. Update TSCN
    tscn_path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_cafe_cyber.tscn"
    with open(tscn_path, 'r', encoding='utf-8') as f:
        tscn = f.read()

    if '[node name="Audio"' not in tscn:
        last_ext = tscn.rfind("[ext_resource")
        if last_ext != -1:
            end_of_last_ext = tscn.find("\n", last_ext) + 1
            ext_resources = """[ext_resource type="AudioStream" path="res://assets/audio/minigame-cafe-cyber/enchufado.mp3" id="enchufado_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-cafe-cyber/error.mp3" id="error_cyb_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-cafe-cyber/fallo.mp3" id="fallo_cyb_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-cafe-cyber/ok_base.mp3" id="ok_base_cyb_aud"]
[ext_resource type="AudioStream" path="res://assets/audio/minigame-store-search/reloj.mp3" id="reloj_aud"]
"""
            tscn = tscn[:end_of_last_ext] + ext_resources + tscn[end_of_last_ext:]

            audio_nodes = """
[node name="Audio" type="Node" parent="."]

[node name="SFX_Enchufado" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("enchufado_aud")
bus = &"SFX"

[node name="SFX_Fallo" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("fallo_cyb_aud")
bus = &"SFX"

[node name="SFX_OkBase" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("ok_base_cyb_aud")
bus = &"SFX"

[node name="SFX_Error" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("error_cyb_aud")
bus = &"SFX"

[node name="SFX_Reloj" type="AudioStreamPlayer" parent="Audio"]
stream = ExtResource("reloj_aud")
volume_db = -12.0
bus = &"SFX"
"""
            tscn += audio_nodes
            
        with open(tscn_path, 'w', encoding='utf-8') as f:
            f.write(tscn)

    # 2. Update GDScript
    gd_path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_cafe_cyber.gd"
    with open(gd_path, 'r', encoding='utf-8') as f:
        gd = f.read()

    if "sfx_enchufado: AudioStreamPlayer" not in gd:
        # A. At top:
        var_old = r"""@onready var finish_button: Button = \$MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton"""
        var_new = """@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

@onready var sfx_enchufado: AudioStreamPlayer = $Audio/SFX_Enchufado
@onready var sfx_fallo: AudioStreamPlayer = $Audio/SFX_Fallo
@onready var sfx_ok_base: AudioStreamPlayer = $Audio/SFX_OkBase
@onready var sfx_error: AudioStreamPlayer = $Audio/SFX_Error
@onready var sfx_reloj: AudioStreamPlayer = $Audio/SFX_Reloj
var playing_reloj: bool = false"""
        gd = re.sub(var_old, var_new, gd)

        # B. _process clock timer
        proc_old = r"""	if not is_round_locked:
		round_time_left = max\(0\.0, round_time_left - delta\)
		timer_label\.text = _t\("timer"\) % \[snappedf\(round_time_left, 0\.1\)\]
		if round_time_left <= 0\.0:
			_resolve_round\(false, "timeout"\)
			return"""
        proc_new = """	if not is_round_locked:
		round_time_left = max(0.0, round_time_left - delta)
		timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
		
		if round_time_left > 0.0 and round_time_left <= 7.0:
			if not playing_reloj:
				playing_reloj = true
				sfx_reloj.play()
		else:
			if playing_reloj:
				playing_reloj = false
				sfx_reloj.stop()
				
		if round_time_left <= 0.0:
			_resolve_round(false, "timeout")
			return"""
        gd = re.sub(proc_old, proc_new, gd)

        # C. _on_target_pressed / plugging logic
        plug_old = r"""			connected_cables\.append\(\{
				"line": line,
				"src_btn": src_btn,
				"tgt_btn": tgt_btn
			\}\)

		matched_count \+= 1"""
        plug_new = """			connected_cables.append({
				"line": line,
				"src_btn": src_btn,
				"tgt_btn": tgt_btn
			})
			sfx_enchufado.play()

		matched_count += 1"""
        gd = re.sub(plug_old, plug_new, gd)

        err_old = r"""	else:
		round_time_left = max\(0\.0, round_time_left - 1\.5\)"""
        err_new = """	else:
		round_time_left = max(0.0, round_time_left - 1.5)
		sfx_fallo.play()"""
        gd = re.sub(err_old, err_new, gd)

        # D. _resolve_round logic
        res_old = r"""	is_round_locked = true
	submit_button\.disabled = true

	for child in source_grid\.get_children\(\):"""
        res_new = """	is_round_locked = true
	submit_button.disabled = true

	if playing_reloj:
		playing_reloj = false
		sfx_reloj.stop()

	for child in source_grid.get_children():"""
        gd = re.sub(res_old, res_new, gd)

        res2_old = r"""	if success:
		score \+= 1
		round_result_label\.text = _t\("correct"\)
		round_result_label\.modulate = Color\(0\.55, 1\.0, 0\.55, 1\.0\)
	else:
		if reason == "timeout":"""
        res2_new = """	if success:
		score += 1
		sfx_ok_base.play()
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		sfx_error.play()
		if reason == "timeout":"""
        gd = re.sub(res2_old, res2_new, gd)

        # E. _finish_minigame logic
        fin_old = r"""func _finish_minigame\(\) -> void:
	is_round_locked = true
	submit_button\.disabled = true

	var success: bool = score >= int\(ceil\(float\(total_rounds\) \* 0\.6\)\)"""
        fin_new = """func _finish_minigame() -> void:
	is_round_locked = true
	submit_button.disabled = true

	if playing_reloj:
		playing_reloj = false
		sfx_reloj.stop()

	var success: bool = score >= int(ceil(float(total_rounds) * 0.6))"""
        gd = re.sub(fin_old, fin_new, gd)

        with open(gd_path, 'w', encoding='utf-8') as f:
            f.write(gd)

if __name__ == "__main__":
    fix()
