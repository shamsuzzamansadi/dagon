# M6 verification: what holds each item (M6 plan, item 9)

The roadmap's "M6 verification": settings and save persistence, rebinding, menu focus, quit, relaunch and Continue, and display usability; with what M1 and M2 deferred to it. Each row names the tests or routes that hold it today. **Automated** means a script, not a person: the integration suites run headless on the editor build and on the exported pack, on GCC, Clang and MSVC in CI; the exported routes play the shipped build with window-system keys. **The owner's pass over the menus** (item 9's **P**) and the hardware rows are separate, and open until done.

Suite names are files in `project/tests/`; `native` is `scons unit_tests`.

## Settings and saves

| Item | Held by | Kind |
|---|---|---|
| Settings are saved, and a new process loads them | `test_settings`: `test_settings_survive_a_relaunch` (a second Godot process reads the file), `test_a_scene_loads_the_saved_settings`, `test_bindings_survive_restart_checkpoint`; native `test_settings_data` (every field round trip, old files, bad values) | automated |
| A damaged or unwritable settings file | `test_settings`: `test_damaged_files_fall_back_to_defaults_without_errors`, `test_a_failed_write_is_reported_and_the_change_still_applies`, `test_quitting_with_unsaved_settings_does_not_claim_they_are_kept`, `test_restore_defaults_reports_what_really_happened` | automated |
| Volumes | `test_settings`: `test_volumes_reach_their_own_buses`, `test_a_focused_slider_moves_with_the_keys_and_the_change_is_kept` | automated; **heard** only in the native checks |
| The Display setting | `test_settings`: `test_the_display_setting_is_shown_saved_and_restored`; native `test_window_fit`; on a private display at 1280 × 720 and 1920 × 1080 ([displays](displays/README.md)); **across a relaunch, on the exported build:** `tools/display_relaunch_check.py` (gap 1 below) | automated |
| A checkpoint is saved, truthfully | `test_session`: `test_a_checkpoint_is_saved_and_the_notice_is_truthful`, `test_saved_checkpoints_name_real_markers`, `test_an_autosave_failure_keeps_the_session_checkpoint_and_says_so` | automated |
| A save survives a crash at any step of writing it | `test_session`: `test_writing_keeps_the_old_save_as_the_backup`, `test_a_corrupt_save_never_overwrites_a_valid_backup`, `test_a_failure_at_each_step_of_replacing_leaves_a_usable_save`; `test_title`: `test_every_state_an_interrupted_replacement_can_leave_loads_a_usable_save` | automated |
| Old and future saves | `test_restore`: `test_the_save_format_has_not_changed_so_an_m2_save_still_continues`, `test_a_save_from_a_later_version_is_refused_and_left_alone` | automated |
| The player's real storage folder | CI's `user_dir_probe.gd` on each throwaway runner | automated |

## Rebinding

| Item | Held by | Kind |
|---|---|---|
| A rebound key drives the action, the old one does not, and nothing else happens | `test_settings`: `test_a_rebound_key_drives_the_action_and_the_old_one_does_not`, `test_a_captured_key_does_nothing_else`, `test_escape_cancels_a_capture_and_changes_nothing`, `test_a_gamepad_can_cancel_a_capture_and_cannot_wander_off`, `test_losing_focus_during_a_capture_changes_nothing` | automated |
| Reserved keys and conflicts | `test_settings`: `test_reserved_keys_are_refused_with_an_explanation`, `test_a_conflict_is_explained_and_can_be_swapped`, `test_cancelling_a_conflict_changes_nothing`, `test_focus_cannot_leave_a_conflict_choice`, `test_the_settings_screen_says_exactly_which_keys_are_kept` | automated |
| Menus and walking still work after rebinding | `test_settings`: `test_the_arrows_still_move_after_rebinding`, `test_up_and_down_can_be_rebound_and_the_menu_still_works`; `test_controller`: `test_arrow_keys_still_walk_and_navigate_after_rebinding`, `test_a_rebound_key_comes_back_after_using_a_controller` | automated |
| Every place a key is named follows the binding | `test_settings`: `test_the_prompt_names_a_rebound_key`; `test_title`: `test_controls_on_the_main_menu_show_a_rebound_key_at_once`, `test_the_introduction_can_be_closed_with_back_and_uses_the_current_keys`; `test_pause_menu`: `test_controls_open_from_the_pause_menu_with_the_current_keys`; `test_session`: `test_examine_follows_a_rebound_key_at_the_boat_and_the_fish` | automated |
| **Key names under another keyboard layout, on the shipped build** | `test_settings`: `test_a_key_is_named_even_when_the_font_cannot_draw_the_layout_letter`, `test_the_font_can_draw_every_ascii_key_name` (the naming rule, with layouts simulated); **`tools/layout_check.py` in CI's `desktop-checks` job**: the exported game with keys rebound onto Z, semicolon and Y, under US and then German, on Windows and Linux, Settings in both menus and the prompt compared as text, both Controls screens and How to Play screenshotted (item 5) | automated; **a real German keyboard only if the owner chooses** |

## Menu focus

| Item | Held by | Kind |
|---|---|---|
| Every row can be reached and nothing traps focus | `test_settings`: `test_focus_can_walk_every_row_and_nothing_traps_it`; `test_title`: `test_settings_controls_and_credits_open_and_back_returns_focus`, `test_every_button_is_connected_and_every_screen_fits`; `test_pause_menu`: `test_back_closes_one_level_and_focus_returns`, `test_every_button_is_connected` | automated |
| Focus lost (a click on nothing, a closed panel) comes back | `test_settings`: `test_focus_lost_in_settings_comes_back_to_a_usable_control`, `test_focus_lost_in_a_conflict_comes_back_inside_the_choice`, `test_recovering_focus_keeps_unsaved_settings`; `test_pause_menu`: `test_focus_comes_back_after_it_is_lost`, `test_focus_lost_after_leaving_settings_comes_back_to_a_visible_button`, `test_focus_lost_in_the_quit_confirmation_stays_in_it`, `test_clicking_empty_space_keeps_focus_and_the_keyboard_working` | automated |
| Dangerous choices ask first, with Cancel focused | `test_title`: `test_new_game_asks_first_with_cancel_focused_and_cancelling_changes_nothing`; `test_pause_menu`: `test_quit_asks_first_with_cancel_focused_and_says_what_is_kept` | automated |
| A controller can work every menu | `test_controller`: `test_a_controller_can_work_the_main_menu`, `test_a_controller_can_work_every_level_of_the_pause_menu`, `test_the_left_stick_moves_through_the_menu`; `test_route`: `test_the_ending_has_a_working_controller_route_and_back_does_nothing_at_its_root` | automated, **simulated input**; physical controllers are item 4 |
| Menus in fullscreen, by keys | [displays](displays/README.md): Settings walked by keys in fullscreen at both sizes | automated |

## Quit, relaunch and Continue

| Item | Held by | Kind |
|---|---|---|
| Quit to the main menu and to the desktop | `test_pause_menu`: `test_quit_to_desktop_exits_the_game`; `test_session`: `test_quitting_to_the_main_menu_unpauses_and_keeps_the_save`, `test_quitting_retries_a_failed_save_and_reports_the_result`; `test_title`: `test_quit_on_the_main_menu_exits_the_game` | automated |
| Continue after a relaunch, from every savable beat | `test_session`: `test_continue_restores_the_checkpoint_after_quitting_and_relaunching`; `test_restore`: `test_each_beat_saved_in_one_process_continues_correctly_in_another`, `test_from_every_savable_beat_the_keys_alone_reach_the_ending`, `test_the_final_sequence_in_one_process_leaves_awakened_for_the_next` | automated |
| **The shipped build: quit, relaunch, Continue** | `tools/route_check.py`, runs 3 and 4: a new process continues the save the first left, to the ending and after it; on Linux and Windows in CI, and on the downloaded baseline here | automated, on the exported build |
| Quitting during the final sequence says it will replay | `test_restore`: `test_quitting_during_the_final_sequence_says_it_will_replay`, `test_ordinary_quit_wording_stays_ordinary_before_the_final_sequence` | automated |

## Display usability

| Item | Held by | Kind |
|---|---|---|
| 1280 × 720 and 1920 × 1080, windowed and fullscreen: sharpness, shape, long captions, menus, back to a window | [displays](displays/README.md): 18 screenshots, every block one colour, exactly 16:9, black bars | automated, on a private display with a window manager; **the owner's screens: native checks** |
| Every screen fits and its text can be drawn | `test_title`: `test_every_button_is_connected_and_every_screen_fits`; `test_settings`: `test_the_audio_note_and_all_of_settings_fit_in_every_state`; `test_controller`: `test_the_longest_prompt_fits_on_screen`, `test_the_controls_screens_fit_on_every_layout`; `test_route`: `test_the_ending_screens_fit_and_their_text_can_be_drawn` | automated |

## Deferred to M6 from M1 and M2

| Item | State |
|---|---|
| Physical controllers: all PlayStation hardware; the individual Xbox actions, disconnecting and reconnecting | **Open: pending until someone tests the actual hardware** (item 4) |
| Key names under German on the real build | **Passed in CI** on the shipped Windows build of `77d5302` (push run 44786112032): the game's thread switched from 0x0409 to 0x0407, Settings showed Y D Ö Z under "German (de)", the prompt [Z]; the US control Z D Semicolon Y ([evidence](layouts/README.md)). Automated, window messages on a throwaway runner, not a person's keyboard |
| Native Linux hardware-accelerated rendering | **Open:** the owner's ThinkPad, [sheet](../../m6/native-checks/linux-thinkpad.md) (item 7) |

## Gaps found, and what was done

1. **A saved fullscreen opening the game fullscreen, and a window after switching back, across a relaunch.** Held only within one process before. Now `tools/display_relaunch_check.py`: the exported game started with fullscreen saved must open fullscreen; Display pressed in Settings must leave it for a window; Quit to Desktop; the game started again must open in a window, with `fullscreen=0` saved. Passed here on the exported Linux build, on private displays with a window manager at 1440 × 810 and 1920 × 1080; and in CI's `desktop-checks` job on `c1811ca` (push run 44792596086), on Windows, where the window fitted to 960 × 540 on the runner's 1024 × 768 screen, and on Linux. Without a window manager X11 never grants fullscreen, which the check reports as a failure, so the Linux run has Openbox, as any desktop has a window manager.
2. **Settings named the Examine key "Interact",** in its row and in its conflict message, while every prompt, How to Play and Controls say Examine (seen in item 5's screenshots). Renamed ([D124](../../decisions.md)), with `test_settings`: `test_settings_calls_the_examine_key_what_the_prompts_call_it`.
3. **Key names under German on the shipped Windows build,** deferred since M2: now in CI (item 5), above.

No other gap was found against the roadmap's list. **Not automated, and open:** the owner's pass over the menus (item 9's **P**), physical controllers, the owner's screens and machines.
