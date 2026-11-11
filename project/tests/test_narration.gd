extends RefCounted
## Spoken lines and captions, and the controller's vibration. The headless runs have a dummy audio driver, so these prove
## what is asked of the audio and when, and never how anything sounds. Vibration is the same: requests, not feel.

const ARENA := "res://tests/fixtures/story_arena.tscn"
const WORLD := "res://scenes/level/shore.tscn"
const GAME := "res://scenes/level/game.tscn"
const SAVE_FILE := "save.dat"
const SETTINGS_FILE := "settings.cfg"
## The lines spoken in voice A, the owner's choice of 2026-11-10: the three of the audition, the rest of the epilogue,
## and, in M4, the prologue. A line is added here when it is spoken, so nothing is voiced without being named.
const VOICED := {
	"prologue.raider": "a raider took our ship",
	"prologue.escape": "I took a boat",
	"prologue.drift": "I stopped counting the days",
	"prologue.dry": "the sea had gone",
	"shore.boat": "My boat lies on bare seabed",
	"shore.fish": "Dead fish",
	"shore.talisman": "Something small",
	"cave.carving": "The same eye",
	"ending.found": "A steamer found me",
	"ending.listen": "I have stopped arguing",
	"ending.innsmouth": "called Innsmouth",
	"ending.rising": "finished rising",
}
const PROLOGUE := "res://scenes/ui/prologue.tscn"
const VOICED_LINE := &"shore.talisman"
## Two lines that are captions only. What he examines in the Abyss stays text in M4.
const TEXT_LINE := &"abyss.fossil_a"
const OTHER_TEXT_LINE := &"abyss.footprint"
const STORY_LINE := &"abyss.ritual"
const TALISMAN_X := 349.0
const FISH_X := 189.0
const MONOLITH := 2
const AWAKENED := 3
const WITNESS_X := 860.0
const DEVICE := 0


func _arena(h, beat := 0) -> Node2D:
	var arena: Node2D = (load(ARENA) as PackedScene).instantiate()
	arena.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(arena)
	await h.landed_on_floor(arena.get_node("Player"))
	return arena


func _world(h, beat := 0) -> Node2D:
	var world: Node2D = (load(WORLD) as PackedScene).instantiate()
	world.get_node("GameDirector").set_start_beat(beat)
	await h.load_with(world)
	await h.landed_on_floor(world.get_node("Player"))
	return world


func _hud(h) -> Node:
	return h.fixture.get_node("Hud")


func _caption(h) -> Label:
	return h.fixture.get_node("Hud/Caption")


func _voice(h) -> AudioStreamPlayer:
	return h.fixture.get_node("Hud/Voice")


func _player(h) -> CharacterBody2D:
	return h.fixture.get_node("Player")


func _script_text(id: String) -> String:
	for line in FileAccess.get_file_as_string("res://narration/script.txt").split("\n"):
		if line.begins_with(id + "|"):
			return line.split("|", true, 2)[2]
	return ""


func _vibration(_h) -> Vector2:
	return Input.get_joy_vibration_strength(DEVICE)


## ---- The script ----


func test_every_line_in_the_script_is_used_and_every_id_used_is_in_the_script(h) -> void:
	var world := await _world(h)
	var ids := {}
	for line in FileAccess.get_file_as_string("res://narration/script.txt").split("\n"):
		if not line.is_empty() and not line.begins_with("#"):
			ids[line.split("|")[0]] = false
	h.check(ids.size() > 20, "only %d lines" % ids.size())
	for interactable in world.find_children("*", "Interactable", true, false):
		if interactable.line_id != &"":
			h.check(ids.has(String(interactable.line_id)), "%s uses %s, which is not in the script" % [interactable.name, interactable.line_id])
			ids[String(interactable.line_id)] = true
	ids["mural.after"] = true
	ids["monolith.first"] = true
	h.check(ids.has(String(world.get_node("GameDirector").crossing_line)), "the crossing's line is not in the script")
	ids[String(world.get_node("GameDirector").crossing_line)] = true
	for player_name in ["Cinematics", "Background", "Atmosphere"]:
		var player: AnimationPlayer = world.get_node(player_name)
		for clip in player.get_animation_list():
			var animation := player.get_animation(clip)
			for track in animation.get_track_count():
				if animation.track_get_type(track) != Animation.TYPE_METHOD:
					continue
				for key in animation.track_get_key_count(track):
					if animation.method_track_get_name(track, key) == &"say":
						var id := String(animation.method_track_get_params(track, key)[0])
						h.check(ids.has(id), "%s says %s, which is not in the script" % [clip, id])
						ids[id] = true
	for scene in ["res://scenes/ui/ending.tscn", "res://scenes/ui/prologue.tscn"]:
		var sequence: Node = (load(scene) as PackedScene).instantiate()
		for id in sequence.ending_lines:
			h.check(ids.has(id), "%s uses %s, which is not in the script" % [scene, id])
			ids[id] = true
		sequence.free()
	for id: String in ids:
		h.check(ids[id], "nothing uses %s" % id)


func test_a_prop_shows_the_scripts_words_exactly(h) -> void:
	var world := await _world(h)
	for pair in [["Props/Talisman", "shore.talisman"], ["Props/TabletWave", "abyss.tablet_wave"], ["Monolith/Mural", "mural.before"]]:
		h.check(world.get_node(pair[0]).caption == _script_text(pair[1]), "%s reads '%s'" % [pair[0], world.get_node(pair[0]).caption])


## Only the lines named above have audio, each in the chosen voice. Nothing else is generated in bulk.
func test_only_the_lines_spoken_in_the_chosen_voice_have_audio(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	var files := DirAccess.get_files_at("res://assets/narration") as Array
	var audio := files.filter(func(f: String) -> bool: return f.ends_with(".ogg") or f.ends_with(".ogg.remap") or f.ends_with(".ogg.import")).map(func(f: String) -> String: return f.get_slice(".ogg", 0))
	for id: String in VOICED:
		h.check(audio.has(id), "no audio for %s" % id)
		h.check(_script_text(id).contains(VOICED[id]), "%s reads '%s'" % [id, _script_text(id)])
	for id in audio:
		h.check(VOICED.has(id), "audio for %s, which was not asked for" % id)


## ---- Playback ----


func test_a_voiced_line_plays_its_audio_and_shows_its_words_together(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	h.check(_hud(h).is_speaking(), "not speaking")
	h.check(_hud(h).get_current_line() == VOICED_LINE, "the line is %s" % _hud(h).get_current_line())
	h.check(_voice(h).stream != null, "no audio was set")
	h.check(_voice(h).playing, "the audio is not playing")
	h.check(_voice(h).bus == &"Narration", "the voice is on %s" % _voice(h).bus)
	h.check(_caption(h).visible and _caption(h).text == _script_text(VOICED_LINE), "the caption reads '%s'" % _caption(h).text)


func test_a_voiced_caption_lasts_through_the_audio_and_a_brief_margin(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	var length: float = _voice(h).stream.get_length()
	h.check(length > 1.0, "the sample is %.2f s long" % length)
	# Reading time and audio are both covered: the caption is still up at the end of the spoken line.
	await h.steps(int(length * 60.0))
	h.check(_caption(h).visible, "the caption ended before the voice did")
	h.check(_hud(h).is_speaking(), "the line ended before the voice did")
	await h.wait_until(func() -> bool: return not _hud(h).is_speaking(), 120, "the line to end")
	h.check(not _caption(h).visible, "the caption stayed")
	h.check(not _voice(h).playing, "the voice went on")


func test_a_line_with_no_audio_is_a_usable_text_line(h) -> void:
	await _arena(h)
	_hud(h).say(TEXT_LINE)
	h.check(not _voice(h).playing, "something played")
	h.check(_caption(h).visible and _caption(h).text == _script_text(TEXT_LINE), "the caption reads '%s'" % _caption(h).text)
	h.check(_hud(h).is_speaking(), "not counted as speaking")
	# Reading time, not a fixed moment: 80 characters at 15 a second.
	await h.steps(300)
	h.check(_caption(h).visible, "the caption did not last its reading time")
	await h.wait_until(func() -> bool: return not _hud(h).is_speaking(), 120, "the line to end")
	h.check(not _caption(h).visible, "the caption stayed")


func test_an_id_not_in_the_script_is_a_reported_bug_with_no_effect(h) -> void:
	await _arena(h)
	h.expect_error("no line in the script")
	_hud(h).say(&"no.such.line")
	h.check(not _hud(h).is_speaking(), "speaking an unknown line")
	h.check(not _caption(h).visible, "a caption for an unknown line")


func test_asking_again_for_the_same_line_never_stacks_or_restarts(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	await h.steps(30)
	var position := _voice(h).get_playback_position()
	var stream := _voice(h).stream
	for i in 5:
		_hud(h).say(VOICED_LINE)
	await h.steps(1)
	h.check(_voice(h).stream == stream, "the audio was replaced")
	h.check(_voice(h).get_stream_playback() != null and _voice(h).get_playback_position() >= position, "the audio restarted: %.2f, was %.2f" % [_voice(h).get_playback_position(), position])
	h.check(_caption(h).modulate.a > 0.9, "the caption faded in again: %.2f" % _caption(h).modulate.a)


func test_an_optional_line_replaces_an_optional_line_audio_and_caption_together(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	await h.steps(5)
	_hud(h).say(TEXT_LINE)
	h.check(not _voice(h).playing, "the old audio went on under the new line")
	h.check(_caption(h).text == _script_text(TEXT_LINE), "the caption reads '%s'" % _caption(h).text)
	h.check(_hud(h).get_current_line() == TEXT_LINE, "the line is %s" % _hud(h).get_current_line())


func test_an_optional_line_cannot_touch_a_story_moment_and_is_not_queued(h) -> void:
	await _arena(h)
	_hud(h).say(STORY_LINE)
	for i in 4:
		_hud(h).say(TEXT_LINE)
		_hud(h).say(VOICED_LINE)
	h.check(_hud(h).get_current_line() == STORY_LINE, "the line is %s" % _hud(h).get_current_line())
	h.check(_caption(h).text == _script_text(STORY_LINE), "the caption reads '%s'" % _caption(h).text)
	h.check(not _voice(h).playing, "an optional line's audio played over a story moment")
	await h.wait_until(func() -> bool: return not _hud(h).is_speaking(), 500, "the story moment to end")
	await h.steps(10)
	h.check(not _caption(h).visible and not _voice(h).playing, "something queued played afterwards: '%s'" % _caption(h).text)


func test_a_story_moment_replaces_anything(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	await h.steps(5)
	_hud(h).say(STORY_LINE)
	h.check(_hud(h).get_current_line() == STORY_LINE, "the line is %s" % _hud(h).get_current_line())
	h.check(not _voice(h).playing, "the old audio went on")


func test_feedback_the_player_just_caused_replaces_what_is_being_said(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	await h.steps(5)
	_hud(h).show_caption("The stones grind and go dark.")
	h.check(not _voice(h).playing, "the voice went on under feedback")
	h.check(not _hud(h).is_speaking(), "feedback counted as a spoken line")
	h.check(_caption(h).text == "The stones grind and go dark.", "the caption reads '%s'" % _caption(h).text)


## ---- Skipping ----


func test_examining_again_skips_the_line_and_does_nothing_else(h) -> void:
	var world := await _world(h)
	var talisman: Node = world.get_node("Props/Talisman")
	var examined := [0]
	talisman.interacted.connect(func(_id: StringName) -> void: examined[0] += 1)
	var jumps := [0]
	_player(h).jumped.connect(func() -> void: jumps[0] += 1)
	await h.stand_at(_player(h), Vector2(TALISMAN_X, -2))
	await h.tap_key(KEY_E)
	h.check(examined[0] == 1, "the first press examined %d times" % examined[0])
	h.check(_voice(h).playing, "no audio")
	await h.wait_until(talisman.is_available, 40, "the cooldown")
	await h.tap_key(KEY_E)
	h.check(not _hud(h).is_speaking(), "the second press did not skip")
	h.check(not _voice(h).playing and not _caption(h).visible, "the audio or caption outlived the skip")
	h.check(examined[0] == 1, "skipping examined again: %d" % examined[0])
	h.check(jumps[0] == 0, "skipping jumped")
	# And a press with nothing to skip examines as usual.
	await h.wait_until(talisman.is_available, 40, "the cooldown")
	await h.tap_key(KEY_E)
	h.check(examined[0] == 2, "the third press examined %d times in all" % examined[0])


func test_a_press_at_something_else_examines_it_at_once_and_replaces_the_line(h) -> void:
	var world := await _world(h)
	await h.stand_at(_player(h), Vector2(TALISMAN_X, -2))
	await h.tap_key(KEY_E)
	h.check(_voice(h).playing, "no audio")
	var talisman: AudioStream = _voice(h).stream
	await h.stand_at(_player(h), Vector2(FISH_X, -2))
	await h.tap_key(KEY_E)
	h.check(_voice(h).stream != talisman, "the old audio went on")
	h.check(_voice(h).playing and _voice(h).stream == load("res://assets/narration/shore.fish.ogg"), "the fish's line is not the one being spoken")
	h.check(_caption(h).text == world.get_node("Props/FishNearRock").caption, "the caption reads '%s'" % _caption(h).text)


func test_during_a_story_moment_a_press_only_skips_and_never_examines(h) -> void:
	var world := await _world(h)
	var fish: Node = world.get_node("Props/FishNearRock")
	var examined := [0]
	fish.interacted.connect(func(_id: StringName) -> void: examined[0] += 1)
	await h.stand_at(_player(h), Vector2(FISH_X, -2))
	_hud(h).say(STORY_LINE)
	await h.tap_key(KEY_E)
	h.check(not _hud(h).is_speaking(), "the press did not skip the story moment")
	h.check(examined[0] == 0, "a press during a story moment examined")
	await h.tap_key(KEY_E)
	h.check(examined[0] == 1, "the next press did not examine")


## A stone is a move in the game, not something optional: speech must never swallow it. Found by the exported route.
func test_a_stone_press_during_a_story_line_still_presses_the_stone(h) -> void:
	await _world(h, MONOLITH)
	var puzzle: Node = h.fixture.get_node("Monolith/Puzzle")
	await h.stand_at(_player(h), Vector2(4170, -2))
	_hud(h).say(STORY_LINE)
	await h.tap_key(KEY_E)
	h.check(puzzle.get_progress() == 1, "speech swallowed the press: progress %d" % puzzle.get_progress())
	h.check(_caption(h).text == "The stone lights, and holds.", "the caption reads '%s'" % _caption(h).text)
	h.check(not _hud(h).is_speaking(), "the story line went on under the stone's response")


func test_during_a_cinematic_a_press_skips_the_line_and_cannot_reach_a_stone(h) -> void:
	await _world(h, MONOLITH)
	var puzzle: Node = h.fixture.get_node("Monolith/Puzzle")
	await h.stand_at(_player(h), Vector2(4170, -2))
	var signals := [0]
	for id in [&"glyph_wave", &"glyph_kneel", &"glyph_eye"]:
		puzzle.submit(id)
	puzzle.step_accepted.connect(func(_index: int) -> void: signals[0] += 1)
	puzzle.failed.connect(func() -> void: signals[0] += 1)
	await h.wait_until(func() -> bool: return _hud(h).get_current_line() == &"story.awakened", 60, "the line to start")
	await h.tap_key(KEY_E)
	h.check(not _hud(h).is_speaking(), "the press did not skip")
	h.check(h.fixture.get_node("GameDirector").is_cinematic_active(), "skipping ended the cinematic")
	h.check(signals[0] == 0, "the press reached a stone")


## ---- Pause, restart and scene changes ----


func test_pausing_holds_the_voice_and_the_caption_and_resuming_carries_on(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	await h.steps(10)
	h.tree.paused = true
	await h.steps(3)
	h.check(_voice(h).stream_paused, "the voice was not paused")
	h.check(_hud(h).is_speaking(), "pausing ended the line")
	h.check(_caption(h).visible, "pausing hid the caption")
	var modulate_a: float = _caption(h).modulate.a
	await h.steps(600)
	h.check(_hud(h).is_speaking(), "the line ran out while paused")
	h.check(is_equal_approx(_caption(h).modulate.a, modulate_a), "the caption changed while paused")
	h.tree.paused = false
	await h.steps(3)
	h.check(not _voice(h).stream_paused, "the voice stayed paused")
	h.check(_voice(h).playing, "the voice did not carry on")
	await h.wait_until(func() -> bool: return not _hud(h).is_speaking(), 900, "the line to end")


func test_a_fall_stops_what_was_being_said(h) -> void:
	await _arena(h)
	_hud(h).say(VOICED_LINE)
	await h.steps(5)
	h.fixture.get_node("GameDirector").restart_checkpoint()
	h.check(not _hud(h).is_speaking() and not _voice(h).playing and not _caption(h).visible, "the line outlived the respawn")


func test_restarting_a_checkpoint_clears_the_voice_and_caption_and_replays_nothing(h) -> void:
	h.write_storage_file(SAVE_FILE, "dagon_save=1\nbeat=shore\ncheckpoint=Shore\n".to_utf8_buffer())
	var session: Node = await h.load_fixture(GAME)
	var world: Node = session.get_world()
	var player: CharacterBody2D = world.get_node("Player")
	await h.stand_at(player, Vector2(TALISMAN_X, -2))
	await h.tap_key(KEY_E)
	var old_voice: AudioStreamPlayer = world.get_node("Hud/Voice")
	h.check(old_voice.playing, "no audio")
	session.get_node("PauseLayer/PauseMenu").restart_checkpoint()
	h.check(not old_voice.is_inside_tree(), "the old voice is still in the tree")
	await h.steps(5)
	var hud: Node = session.get_world().get_node("Hud")
	h.check(not hud.is_speaking(), "the new world is speaking")
	h.check(not hud.get_node("Voice").playing, "the new world's voice is playing")
	h.check(not hud.get_node("Caption").visible, "the new world shows a caption")


func test_restoring_a_beat_says_nothing_until_asked(h) -> void:
	for beat in [0, 1, 2, 3]:
		var session: Node = (load(GAME) as PackedScene).instantiate()
		session.set_start(beat, true, false)
		await h.load_with(session)
		await h.steps(40)
		var hud: Node = session.get_world().get_node("Hud")
		h.check(not hud.is_speaking(), "restoring beat %d said %s" % [beat, hud.get_current_line()])
		h.check(not hud.get_node("Voice").playing, "restoring beat %d played audio" % beat)
		h.check(not hud.get_node("Caption").visible, "restoring beat %d showed '%s'" % [beat, hud.get_node("Caption").text])
		await h.unload_fixture()


func test_quitting_to_the_main_menu_stops_the_voice(h) -> void:
	await h.load_main_fixture(GAME)
	var session: Node = h.fixture
	var world: Node = session.get_world()
	await h.landed_on_floor(world.get_node("Player"))
	await h.stand_at(world.get_node("Player"), Vector2(TALISMAN_X, -2))
	await h.tap_key(KEY_E)
	var voice: AudioStreamPlayer = world.get_node("Hud/Voice")
	h.check(voice.playing, "no audio")
	await h.tap_key(KEY_ESCAPE)
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	menu.ask_quit_to_main_menu()
	menu.confirm()
	await h.wait_for_scene("MenuController")
	h.check(not is_instance_valid(voice), "the old voice was not freed")
	h.check(h.tree.root.find_children("*", "AudioStreamPlayer", true, false).filter(func(player: AudioStreamPlayer) -> bool: return player.playing).is_empty(), "something is still playing")


## ---- The epilogue ----


## Every line of the epilogue is spoken, in its own recording, under its own words. The card waits for the voice; Continue
## moves on and the next voice replaces the last; the credits and the main menu are silent of it.
func test_every_line_of_the_epilogue_is_spoken_and_moving_on_replaces_it(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	var voice: AudioStreamPlayer = ending.get_node("Voice")
	h.check(voice.bus == &"Narration", "the voice is on %s" % voice.bus)
	for line in ending.ending_lines.size():
		await h.steps(2)
		var id: String = ending.ending_lines[line]
		var path := "res://assets/narration/%s.ogg" % id
		h.check(ResourceLoader.exists(path), "%s has no recording" % id)
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path)
		h.check(voice.playing and voice.stream == stream, "%s is not being spoken" % id)
		var words: String = ending.get_node("Center/Card/Items/Lines").get_child(0).text
		var script_text := FileAccess.get_file_as_string("res://narration/script.txt")
		h.check(script_text.contains("%s|story|%s" % [id, words]), "the card under %s does not show its line" % id)
		# A recording much faster or slower than speech cannot be those words.
		var pace := words.length() / stream.get_length()
		h.check(pace > 9.0 and pace < 17.0, "%s: %.1f characters a second" % [id, pace])
		# The card does not move on before the voice could have ended.
		await h.steps(int((stream.get_length() - 0.3) * 60.0))
		h.check(ending.get_ending_line() == line, "%s was cut short by the next line" % id)
		if line + 1 < ending.ending_lines.size():
			await h.tap_key(KEY_ENTER)
			h.check(ending.get_ending_line() == line + 1, "Continue did not move on from %s" % id)
	await h.tap_key(KEY_ENTER)
	h.check(ending.get_node("Center/Credits").visible, "no credits")
	h.check(not voice.playing, "the voice went on into the credits")
	await h.tap_key(KEY_ENTER)
	var menu: Node = await h.wait_for_scene("MenuController")
	await h.steps(3)
	h.check(menu.has_method("continue_game") and menu.get_node_or_null("Voice") == null or not menu.get_node("Voice").playing, "a voice plays on the main menu")
	h.check(h.tree.root.find_children("*", "AudioStreamPlayer", true, false).filter(func(player: AudioStreamPlayer) -> bool: return player.playing and player.bus == &"Narration").is_empty(), "narration still plays on the main menu")


func test_opening_the_credits_stops_a_voiced_line(h) -> void:
	var ending: Node = await h.load_main_fixture("res://scenes/ui/ending.tscn")
	await h.steps(3)
	var voice: AudioStreamPlayer = ending.get_node("Voice")
	await h.tap_key(KEY_ENTER)
	await h.tap_key(KEY_ENTER)
	h.check(voice.playing, "the Innsmouth line is not being spoken")
	ending.open_credits()
	h.check(not voice.playing, "the voice went on into the credits")


## ---- The prologue ----


func _narration_playing(h) -> Array:
	return h.tree.root.find_children("*", "AudioStreamPlayer", true, false).filter(func(player: AudioStreamPlayer) -> bool: return player.playing and player.bus == &"Narration")


## Every line of the prologue is spoken, in its own recording, under its own words and over its own picture, with the
## music and that picture's sound still playing beneath it. The card waits for the voice; Continue moves on and the
## next voice replaces the last; the game begins with none of it still speaking.
func test_every_line_of_the_prologue_is_spoken_over_its_picture_and_moving_on_replaces_it(h) -> void:
	var prologue: Node = await h.load_main_fixture(PROLOGUE)
	var voice: AudioStreamPlayer = prologue.get_node("Voice")
	var panels: Node = prologue.get_node("Panels")
	h.check(voice.bus == &"Narration", "the voice is on %s" % voice.bus)
	for line in prologue.ending_lines.size():
		await h.steps(2)
		var id: String = prologue.ending_lines[line]
		var path := "res://assets/narration/%s.ogg" % id
		h.check(ResourceLoader.exists(path), "%s has no recording" % id)
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path)
		h.check(voice.playing and voice.stream == stream, "%s is not being spoken" % id)
		var words: String = prologue.get_node("Card/Items/Lines").get_child(0).text
		h.check(words == _script_text(id), "the card under %s reads '%s'" % [id, words])
		for index in panels.get_child_count():
			h.check(panels.get_child(index).visible == (index == line), "%s is spoken over the wrong picture" % id)
		var beneath: Array = panels.get_child(line).get_children().filter(func(node: Node) -> bool: return node is AudioStreamPlayer and node.playing and node.bus == &"Effects")
		h.check(not beneath.is_empty(), "nothing of the picture sounds beneath %s" % id)
		h.check(prologue.get_node("Music").playing and prologue.get_node("Music").bus == &"Music", "no music beneath %s" % id)
		# A recording much faster or slower than speech cannot be those words.
		var pace := words.length() / stream.get_length()
		h.check(pace > 9.0 and pace < 17.0, "%s: %.1f characters a second" % [id, pace])
		# The card does not move on before the voice could have ended.
		await h.steps(int((stream.get_length() - 0.3) * 60.0))
		h.check(prologue.get_ending_line() == line, "%s was cut short by the next line" % id)
		if line + 1 < prologue.ending_lines.size():
			await h.tap_key(KEY_ENTER)
			h.check(prologue.get_ending_line() == line + 1, "Continue did not move on from %s" % id)
			h.check(voice.stream != stream, "%s is still the recording after Continue" % id)
	await h.tap_key(KEY_ENTER)
	await h.wait_for_scene("GameSession")
	h.check(h.prologues_skipped == 0, "Continue on the last line did not start the game")
	await h.steps(3)
	h.check(_narration_playing(h).is_empty(), "the prologue's voice went on into the game")


## Left alone, the prologue lets each recording run to its end, and a moment more, before the next picture.
func test_the_prologue_left_alone_waits_for_each_voice(h) -> void:
	var prologue: Node = await h.load_main_fixture(PROLOGUE)
	var voice: AudioStreamPlayer = prologue.get_node("Voice")
	for line in prologue.ending_lines.size() - 1:
		var stream: AudioStream = load("res://assets/narration/%s.ogg" % prologue.ending_lines[line])
		var waited := 0
		while prologue.get_ending_line() == line and waited < 60 * 40:
			await h.steps(1)
			waited += 1
		h.check(prologue.get_ending_line() == line + 1, "line %d never gave way" % line)
		h.check(waited >= int(stream.get_length() * 60.0), "line %d gave way after %d steps, before its %.1f s of voice" % [line, waited, stream.get_length()])
		h.check(voice.stream != stream, "line %d's recording is still set" % line)


func test_skipping_the_prologue_stops_its_voice_at_once(h) -> void:
	for line in 4:
		var prologue: Node = await h.load_main_fixture(PROLOGUE)
		var voice: AudioStreamPlayer = prologue.get_node("Voice")
		for step in line:
			await h.steps(5)
			prologue.advance_ending()
		await h.steps(10)
		h.check(voice.playing, "line %d is not being spoken" % line)
		# Skip, as its button does. Read at once, while the prologue is still there to ask.
		prologue.get_node("Card/Items/Buttons/Skip").pressed.emit()
		h.check(not is_instance_valid(voice) or not voice.playing, "Skip left line %d speaking" % line)
		await h.wait_for_scene("GameSession")
		h.check(h.prologues_skipped == 0, "Skip did not start the game")
		await h.steps(3)
		h.check(_narration_playing(h).is_empty(), "line %d's voice went on into the game" % line)
		await h.unload_fixture()


## ---- Settings ----


func test_subtitles_off_hides_only_what_can_be_heard(h) -> void:
	h.write_storage_file(SETTINGS_FILE, "dagon_settings=1\nsubtitles=0\n".to_utf8_buffer())
	var session: Node = await h.load_fixture(GAME)
	var hud: Node = session.get_world().get_node("Hud")
	var caption: Label = hud.get_node("Caption")
	hud.say(VOICED_LINE)
	h.check(hud.is_speaking() and hud.get_node("Voice").playing, "the voice did not play")
	h.check(not caption.visible, "subtitles are off, and the caption shows")
	hud.hide_caption()
	# Nothing can be heard, so the words must show, or the line would be lost.
	hud.say(TEXT_LINE)
	h.check(caption.visible and caption.text == _script_text(TEXT_LINE), "a text line was hidden: '%s'" % caption.text)
	hud.hide_caption()
	hud.show_caption("feedback")
	h.check(caption.visible, "gameplay feedback was hidden")
	# The prompt is essential, and always shows.
	var player: CharacterBody2D = session.get_world().get_node("Player")
	await h.stand_at(player, Vector2(FISH_X, -2))
	h.check(hud.get_node("Prompt").visible, "no prompt with subtitles off")


func test_a_subtitled_line_ends_on_time_with_subtitles_off_too(h) -> void:
	h.write_storage_file(SETTINGS_FILE, "dagon_settings=1\nsubtitles=0\n".to_utf8_buffer())
	var session: Node = await h.load_fixture(GAME)
	var hud: Node = session.get_world().get_node("Hud")
	hud.say(VOICED_LINE)
	await h.wait_until(func() -> bool: return not hud.is_speaking(), 1200, "the unseen line to end")
	h.check(not hud.get_node("Voice").playing, "the voice went on")


func test_the_narration_volume_sets_its_own_bus(h) -> void:
	h.write_storage_file(SETTINGS_FILE, "dagon_settings=1\nmusic_volume=1\neffects_volume=1\nnarration_volume=0.5\n".to_utf8_buffer())
	await h.load_fixture(GAME)
	var bus := AudioServer.get_bus_index("Narration")
	h.check(bus >= 0, "no Narration bus")
	h.check_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.05, "the Narration bus")
	h.check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), 0.0, 0.01, "the Music bus, unchanged")


func test_music_and_effects_duck_for_narration_when_they_exist(h) -> void:
	await h.load_fixture("res://tests/fixtures/movement_arena.tscn")
	for bus_name in ["Music", "Effects"]:
		var bus := AudioServer.get_bus_index(bus_name)
		h.check(AudioServer.get_bus_effect_count(bus) == 1, "%s has %d effects" % [bus_name, AudioServer.get_bus_effect_count(bus)])
		var effect: AudioEffectCompressor = AudioServer.get_bus_effect(bus, 0)
		h.check(effect.sidechain == &"Narration", "%s ducks for %s" % [bus_name, effect.sidechain])
		h.check(effect.ratio <= 4.0, "%s ducks hard: %.1f to 1" % [bus_name, effect.ratio])


## ---- Vibration ----


func _session_with_controller(h) -> Node:
	h.use_controller("Xbox Wireless Controller")
	var session: Node = ClassDB.instantiate("GameSession")
	session.world_scene = load(ARENA)
	session.director_path = NodePath("GameDirector")
	session.set_start(MONOLITH, true, false)
	session.set_active_device(DEVICE)
	h.fixture = session
	h.probe = preload("res://tests/step_probe.gd").new()
	h.tree.root.add_child(h.probe)
	h.tree.root.add_child(session)
	await h.steps(2)
	return session


func test_the_controller_in_use_gets_the_cue_and_no_other(h) -> void:
	var session := await _session_with_controller(h)
	session.get_director().haptic_cue(&"reveal")
	h.check(_vibration(h).length() > 0.1, "the controller in use did not vibrate: %s" % _vibration(h))
	h.check(Input.get_joy_vibration_strength(DEVICE + 1) == Vector2.ZERO, "another controller vibrated")


func test_a_cue_is_brief_and_restrained(h) -> void:
	var session := await _session_with_controller(h)
	for cue in [&"awaken", &"reveal", &"collapse"]:
		session.get_director().haptic_cue(cue)
		var strength := _vibration(h)
		h.check(strength.length() > 0.1 and strength.x <= 0.8 and strength.y <= 0.8, "%s is %s" % [cue, strength])
		h.check(Input.get_joy_vibration_duration(DEVICE) > 0.0 and Input.get_joy_vibration_duration(DEVICE) <= 1.0, "%s lasts %.2f s" % [cue, Input.get_joy_vibration_duration(DEVICE)])


func test_repeating_a_cue_replaces_it_and_cannot_stack(h) -> void:
	var session := await _session_with_controller(h)
	session.get_director().haptic_cue(&"awaken")
	var once := _vibration(h)
	for i in 5:
		session.get_director().haptic_cue(&"awaken")
	h.check(_vibration(h) == once, "five repeats gave %s, one gave %s" % [_vibration(h), once])


func test_a_keyboard_player_gets_nothing(h) -> void:
	var session := await _session_with_controller(h)
	session.set_active_device(-1)
	session.get_director().haptic_cue(&"reveal")
	h.check(_vibration(h) == Vector2.ZERO, "a keyboard player's cue vibrated: %s" % _vibration(h))
	h.check(Input.get_joy_vibration_strength(-1) == Vector2.ZERO, "a cue reached the keyboard's device number")


func test_the_setting_switches_it_off(h) -> void:
	h.write_storage_file(SETTINGS_FILE, "dagon_settings=1\nvibration=0\n".to_utf8_buffer())
	var session: Node = (load(GAME) as PackedScene).instantiate()
	session.set_active_device(DEVICE)
	await h.load_with(session)
	session.get_director().haptic_cue(&"reveal")
	h.check(_vibration(h) == Vector2.ZERO, "switched off, it still vibrated: %s" % _vibration(h))


func test_an_unknown_cue_is_a_reported_bug_with_no_effect(h) -> void:
	var session := await _session_with_controller(h)
	h.expect_error("no cue named")
	session.get_director().haptic_cue(&"no_such_cue")
	h.check(_vibration(h) == Vector2.ZERO, "an unknown cue vibrated")


func test_pausing_stops_it_and_resuming_does_not_bring_it_back(h) -> void:
	var session := await _session_with_controller(h)
	session.get_director().haptic_cue(&"reveal")
	h.check(_vibration(h).length() > 0.1, "no vibration")
	h.tree.paused = true
	await h.steps(2)
	h.check(_vibration(h) == Vector2.ZERO, "pausing did not stop it")
	h.tree.paused = false
	await h.steps(5)
	h.check(_vibration(h) == Vector2.ZERO, "resuming brought it back")


func test_changing_device_stops_it_on_the_old_controller(h) -> void:
	var session := await _session_with_controller(h)
	session.get_director().haptic_cue(&"reveal")
	session.set_active_device(-1)
	h.check(_vibration(h) == Vector2.ZERO, "the old controller kept vibrating")


## By emitting the engine's signal, as a test cannot unplug anything. The physical check is in the owner's list.
func test_a_disconnect_stops_it_and_hands_back_to_the_keyboard(h) -> void:
	h.use_controller("Xbox Wireless Controller")
	var session: Node = (load(GAME) as PackedScene).instantiate()
	await h.load_with(session)
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	menu.set_active_device(DEVICE)
	session.get_director().haptic_cue(&"reveal")
	h.check(_vibration(h).length() > 0.1, "no vibration")
	Input.joy_connection_changed.emit(DEVICE, false)
	h.check(_vibration(h) == Vector2.ZERO, "a disconnect did not stop it")
	h.check(session.get_active_device() == -1, "the session still has device %d" % session.get_active_device())
	session.get_director().haptic_cue(&"reveal")
	h.check(_vibration(h) == Vector2.ZERO, "a cue reached the controller that left")


func test_restarting_stops_it(h) -> void:
	var session := await _session_with_controller(h)
	session.get_director().haptic_cue(&"reveal")
	session.restart_checkpoint()
	h.check(_vibration(h) == Vector2.ZERO, "restarting did not stop it")
	await h.steps(5)
	h.check(_vibration(h) == Vector2.ZERO, "the new world started it again")


func test_a_clip_cues_it_once_and_a_paused_or_abandoned_clip_cannot(h) -> void:
	var session := await _session_with_controller(h)
	var director: Node = session.get_director()
	var clips: AnimationPlayer = session.get_world().get_node("Cinematics")
	# Paused before its key arrives: nothing, until the clip carries on.
	director.start_cinematic(&"haptic")
	h.tree.paused = true
	await h.steps(30)
	h.check(_vibration(h) == Vector2.ZERO, "a paused clip vibrated")
	h.tree.paused = false
	await h.wait_until(func() -> bool: return _vibration(h).length() > 0.1, 15, "the clip to reach its cue")
	Input.stop_joy_vibration(DEVICE)
	await h.wait_until(func() -> bool: return not director.is_cinematic_active(), 60, "the clip to finish")
	h.check(_vibration(h) == Vector2.ZERO, "the cue fired twice")
	h.check(not clips.is_playing(), "the clip is still playing")


func test_the_scene_change_to_the_ending_stops_it(h) -> void:
	var session := await _session_with_controller(h)
	h.tree.current_scene = session
	session.get_director().haptic_cue(&"collapse")
	session.queue_free()
	await h.tree.process_frame
	await h.tree.process_frame
	h.check(_vibration(h) == Vector2.ZERO, "leaving the world did not stop it")
	h.tree.current_scene = null
	h.fixture = null


func test_the_vibration_clips_name_cues_that_exist_and_each_appears_once(h) -> void:
	await _world(h)
	var clips: AnimationPlayer = h.fixture.get_node("Cinematics")
	var cues := []
	for clip in clips.get_animation_list():
		var animation := clips.get_animation(clip)
		for track in animation.get_track_count():
			if animation.track_get_type(track) == Animation.TYPE_METHOD:
				for key in animation.track_get_key_count(track):
					if animation.method_track_get_name(track, key) == &"haptic_cue":
						cues.append(String(animation.method_track_get_params(track, key)[0]))
	cues.sort()
	h.check(cues == ["awaken", "collapse", "reveal"], "the clips cue %s" % str(cues))


func test_the_settings_rows_save_and_come_back(h) -> void:
	var session: Node = await h.load_fixture(GAME)
	var menu: Control = session.get_node("PauseLayer/PauseMenu")
	menu.open()
	menu.open_settings()
	await h.steps(2)
	var items := "PauseLayer/PauseMenu/Settings/Center/Panel/Items/Columns/Audio/"
	var subtitles: Button = session.get_node(items + "Subtitles")
	var vibration: Button = session.get_node(items + "Vibration")
	h.check(subtitles.text == "Subtitles: On" and vibration.text == "Controller vibration: On", "the defaults read '%s' and '%s'" % [subtitles.text, vibration.text])
	h.check(session.get_node(items + "VibrationNote").text.contains("supported controller"), "the note reads '%s'" % session.get_node(items + "VibrationNote").text)
	subtitles.grab_focus()
	await h.tap_key(KEY_ENTER)
	vibration.grab_focus()
	await h.tap_key(KEY_ENTER)
	session.get_node(items + "Narration/Slider").value = 0.3
	h.check(subtitles.text == "Subtitles: Off" and vibration.text == "Controller vibration: Off", "they read '%s' and '%s'" % [subtitles.text, vibration.text])
	var text: String = h.read_storage_file(SETTINGS_FILE)
	h.check(text.contains("subtitles=0") and text.contains("vibration=0") and text.contains("narration_volume=0.3"), "the file holds:\n%s" % text)
	h.check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Narration")), linear_to_db(0.3), 0.05, "the Narration bus")
	session.get_node("PauseLayer/PauseMenu/Settings").restore_defaults()
	h.check(subtitles.text == "Subtitles: On" and vibration.text == "Controller vibration: On", "the defaults came back as '%s' and '%s'" % [subtitles.text, vibration.text])
