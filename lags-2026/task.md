# Task List - Options Menu & Global Settings

## Phase 1: Analysis
- [ ] Review `main_menu.tscn` and `main_menu.gd`.
- [ ] Review `options_menu.tscn` (and script if it exists).
- [ ] Review `locale_manager.gd` and `menu_texts.json`.

## Phase 2: Global Config System
- [ ] Create `core/autoload/config_manager.gd` (Singleton).
- [ ] Implement save/load logic for language, music_volume, sfx_volume using `ConfigFile`.
- [ ] Register `ConfigManager` in `project.godot`.

## Phase 3: Localization Enhancements
- [ ] Update `menu_texts.json` with missing keys (languages, UI texts for options).
- [ ] Ensure a clean, reusable way to assign translation keys to any Label or Button (e.g., a generic component or extending `LocaleManager`).

## Phase 4: Options Menu Implementation
- [ ] Create/Update `options_menu.gd`.
- [ ] Implement local state for unsaved changes.
- [ ] Connect `<` and `>` buttons for Language, Music, SFX.
- [ ] Implement Save (apply to `ConfigManager` and close) and Cancel (close only).

## Phase 5: Main Menu Connectivity
- [ ] Connect `Btn_Options` in `main_menu.gd` to open the modal.
- [ ] Add dark overlay (ColorRect) to dim background when modal is open.
- [ ] Hide modal when "Save" or "Cancel" is clicked.

## Phase 6: Reporting
- [ ] Provide full detailed breakdown of changes for the user.
