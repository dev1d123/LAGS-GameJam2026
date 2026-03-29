def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_cafe_cyber.gd"
    with open(path, "r", encoding="utf-8") as f:
        gd = f.read()

    # 1. Add preview_time_left variable
    gd = gd.replace(
        "var is_round_locked: bool = false",
        "var is_round_locked: bool = false\nvar preview_time_left: float = -1.0  # Locked preview before round starts"
    )

    # 2. Make cursor plug-b bigger (both occurrences)
    gd = gd.replace(
        "\t\tplug_b_cursor.custom_minimum_size = Vector2(48, 48)",
        "\t\tplug_b_cursor.custom_minimum_size = Vector2(96, 96)"
    )
    gd = gd.replace(
        "\t\tplug_b_cur.custom_minimum_size = Vector2(48, 48)",
        "\t\tplug_b_cur.custom_minimum_size = Vector2(96, 96)"
    )

    # 3. In _start_round: lock board, show preview, compute time from cable count
    old_start = """\tcurrent_round += 1
\tis_round_locked = false
\tround_result_label.visible = false
\tsubmit_button.disabled = false
\tselected_source_type = ""

\t_build_round_board(current_round)

\trounds_label.text = _t("rounds") % [current_round, total_rounds]
\tround_time_left = max(9.0, round_time_base - float(current_round - 1) * 1.7)
\ttimer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
\tselected_source_label.text = _t("selected_source_none")
\tprogress_label.text = _t("progress") % [matched_count, expected_matches]"""

    new_start = """\tcurrent_round += 1
\tis_round_locked = true  # Locked during preview
\tround_result_label.visible = false
\tsubmit_button.disabled = true
\tselected_source_type = ""

\t_build_round_board(current_round)

\trounds_label.text = _t("rounds") % [current_round, total_rounds]
\t# Time scales with cable count: 4s per cable + 6s buffer, reduced by round
\tvar time_per_cable := max(2.5, 4.5 - float(current_round - 1) * 0.35)
\tround_time_left = max(10.0, time_per_cable * float(expected_matches) + 5.0)
\ttimer_label.text = "Observa: 2s"
\tpreview_time_left = 2.0
\tselected_source_label.text = _t("selected_source_none")
\tprogress_label.text = _t("progress") % [matched_count, expected_matches]"""

    if old_start in gd:
        gd = gd.replace(old_start, new_start)
    else:
        print("ERROR: _start_round block not found")
        return

    # 4. Handle preview phase in _process (before the main timer logic)
    old_process_check = """\tif not is_round_locked:
\t\tround_time_left = max(0.0, round_time_left - delta)
\t\ttimer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
\t\t
\t\tif round_time_left > 0.0 and round_time_left <= 7.0:
\t\t\tif not playing_reloj:
\t\t\t\tplaying_reloj = true
\t\t\t\tsfx_reloj.play()
\t\telse:
\t\t\tif playing_reloj:
\t\t\t\tplaying_reloj = false
\t\t\t\tsfx_reloj.stop()
\t\t\t\t
\t\tif round_time_left <= 0.0:
\t\t\t_resolve_round(false, "timeout")
\t\t\treturn"""

    new_process_check = """\t# Preview phase countdown
\tif preview_time_left > 0.0:
\t\tpreview_time_left -= delta
\t\ttimer_label.text = "Observa: %ss" % snappedf(preview_time_left, 0.1)
\t\tif preview_time_left <= 0.0:
\t\t\tpreview_time_left = -1.0
\t\t\tis_round_locked = false
\t\t\tsubmit_button.disabled = false
\t\t\ttimer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
\t\treturn

\tif not is_round_locked:
\t\tround_time_left = max(0.0, round_time_left - delta)
\t\ttimer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
\t\t
\t\tif round_time_left > 0.0 and round_time_left <= 7.0:
\t\t\tif not playing_reloj:
\t\t\t\tplaying_reloj = true
\t\t\t\tsfx_reloj.play()
\t\telse:
\t\t\tif playing_reloj:
\t\t\t\tplaying_reloj = false
\t\t\t\tsfx_reloj.stop()
\t\t\t\t
\t\tif round_time_left <= 0.0:
\t\t\t_resolve_round(false, "timeout")
\t\t\treturn"""

    if old_process_check in gd:
        gd = gd.replace(old_process_check, new_process_check)
    else:
        print("ERROR: _process timer block not found")
        return

    with open(path, "w", encoding="utf-8") as f:
        f.write(gd)
    print("Done")

if __name__ == "__main__":
    fix()
