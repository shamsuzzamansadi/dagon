#include "storage.hpp"

#include "core/window_fit.hpp"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstring>

using namespace godot;

namespace dagon::storage {

namespace {

const char *const SETTINGS_FILE = "settings.cfg";
const char *const SAVE_FILE = "save.dat";
const char *const SAVE_BACKUP_FILE = "save.bak";
const char *const TEMPORARY_SUFFIX = ".tmp";
const char *const STORAGE_DIR_VARIABLE = "DAGON_STORAGE_DIR";
const char *const SUBTITLES_META = "dagon_subtitles";
const char *const VIBRATION_META = "dagon_vibration";

// Left and Right stay on movement whatever the player rebinds (core::is_reserved_key).
bool is_fixed_key(const StringName &p_action, int p_key) {
	return (p_action == StringName("move_left") && p_key == core::KEY_CODE_LEFT) || (p_action == StringName("move_right") && p_key == core::KEY_CODE_RIGHT);
}

void set_bus_level(const char *p_bus, float p_volume) {
	AudioServer *audio = AudioServer::get_singleton();
	const int bus = audio->get_bus_index(p_bus);
	if (bus < 0) {
		ERR_PRINT("storage: the audio bus layout has no bus for this volume setting.");
		return;
	}
	audio->set_bus_mute(bus, p_volume <= 0.0f);
	if (p_volume > 0.0f) {
		audio->set_bus_volume_db(bus, static_cast<float>(UtilityFunctions::linear_to_db(p_volume)));
	}
}

void set_action_key(const StringName &p_action, int p_key) {
	InputMap *input_map = InputMap::get_singleton();
	if (!input_map->has_action(p_action)) {
		ERR_PRINT("storage: an action in the settings is missing from the project's InputMap.");
		return;
	}
	const TypedArray<InputEvent> events = input_map->action_get_events(p_action);
	for (int i = 0; i < events.size(); i++) {
		const Ref<InputEventKey> key = events[i];
		if (key.is_valid() && !is_fixed_key(p_action, static_cast<int>(key->get_physical_keycode()))) {
			input_map->action_erase_event(p_action, key);
		}
	}
	Ref<InputEventKey> event;
	event.instantiate();
	event->set_physical_keycode(static_cast<Key>(p_key));
	input_map->action_add_event(p_action, event);
}

} // namespace

String root() {
	const String override_dir = OS::get_singleton()->get_environment(STORAGE_DIR_VARIABLE);
	return override_dir.is_empty() ? String("user://") : override_dir;
}

bool read_file(const String &p_name, std::string &r_text) {
	const String path = root().path_join(p_name);
	if (!FileAccess::file_exists(path)) {
		return false;
	}
	// Bytes, not a String: decoding a damaged file would log an error before the parser could reject it.
	const PackedByteArray bytes = FileAccess::get_file_as_bytes(path);
	r_text.assign(reinterpret_cast<const char *>(bytes.ptr()), static_cast<std::size_t>(bytes.size()));
	return true;
}

// Writes the temporary file and checks what reached the disk.
static bool write_temporary(const String &p_name, const std::string &p_text) {
	const String directory = root();
	if (DirAccess::make_dir_recursive_absolute(directory) != OK) {
		return false;
	}
	const String temporary = directory.path_join(p_name) + String(TEMPORARY_SUFFIX);

	const Ref<FileAccess> file = FileAccess::open(temporary, FileAccess::WRITE);
	if (file.is_null()) {
		return false;
	}
	PackedByteArray bytes;
	bytes.resize(static_cast<int64_t>(p_text.size()));
	std::memcpy(bytes.ptrw(), p_text.data(), p_text.size());
	file->store_buffer(bytes);
	file->close();

	if (FileAccess::get_file_as_bytes(temporary) != bytes) {
		DirAccess::remove_absolute(temporary);
		return false;
	}
	return true;
}

// Moves a temporary file into place.
static bool move_temporary(const String &p_name) {
	const String path = root().path_join(p_name);
	const String temporary = path + String(TEMPORARY_SUFFIX);
	if (DirAccess::rename_absolute(temporary, path) != OK) {
		DirAccess::remove_absolute(temporary);
		return false;
	}
	return true;
}

bool replace_file(const String &p_name, const std::string &p_text) {
	return write_temporary(p_name, p_text) && move_temporary(p_name);
}

core::Settings load_settings() {
	std::string text;
	if (!read_file(SETTINGS_FILE, text)) {
		return core::Settings{};
	}
	const core::ParsedSettings parsed = core::parse_settings(text);
	if (parsed.status != core::ParseStatus::Ok) {
		print_verbose("dagon: settings file was damaged or from another version; defaults used where needed.");
	}
	return parsed.settings;
}

bool save_settings(const core::Settings &p_settings) {
	return replace_file(SETTINGS_FILE, core::serialize_settings(p_settings));
}

namespace {

// The game's picture, and the multiple of it the window opens at (project.godot: 480 x 270, in 1440 x 810).
constexpr int PICTURE_WIDTH = 480;
constexpr int PICTURE_HEIGHT = 270;
constexpr int PREFERRED_SCALE = 3;

bool is_fullscreen(DisplayServer::WindowMode p_mode) {
	return p_mode == DisplayServer::WINDOW_MODE_FULLSCREEN || p_mode == DisplayServer::WINDOW_MODE_EXCLUSIVE_FULLSCREEN;
}

// Whether the game has looked at its window yet in this run.
bool window_checked = false;

// The largest whole-number multiple of the picture that fits, centred, for: a window whose frame does not fit on its
// screen's usable area; one just back from fullscreen; and, the first time in a run, one that is not a whole multiple,
// as a window manager may already have squeezed the opening window to the screen. Later, a window that fits is left
// as the player sized it, and a maximized one is left alone.
void fit_window(DisplayServer *p_display, bool p_always) {
	print_verbose("dagon: window check mode=", p_display->window_get_mode(), " size=", p_display->window_get_size(), " with frame=", p_display->window_get_size_with_decorations(), " usable=", p_display->screen_get_usable_rect(p_display->window_get_current_screen()), " screen=", p_display->window_get_current_screen(), " first=", !window_checked);
	if (p_display->window_get_mode() != DisplayServer::WINDOW_MODE_WINDOWED) {
		return;
	}
	const Rect2i usable = p_display->screen_get_usable_rect(p_display->window_get_current_screen());
	const Vector2i size = p_display->window_get_size();
	// At start-up a window manager may already have shrunk the frame to the screen while the window's own size has
	// not caught up, which reads as a negative frame.
	const Vector2i frame = (p_display->window_get_size_with_decorations() - size).max(Vector2i());
	const bool fits = size.x + frame.x <= usable.size.x && size.y + frame.y <= usable.size.y;
	const bool whole = size.x % PICTURE_WIDTH == 0 && size.y % PICTURE_HEIGHT == 0 && size.x / PICTURE_WIDTH == size.y / PICTURE_HEIGHT;
	const bool first = !window_checked;
	window_checked = true;
	if (!p_always && fits && (whole || !first)) {
		return;
	}
	const core::WindowFit fit = core::fit_window(usable.size.x - frame.x, usable.size.y - frame.y, PICTURE_WIDTH, PICTURE_HEIGHT, PREFERRED_SCALE);
	const Vector2i fitted(fit.width, fit.height);
	p_display->window_set_size(fitted);
	// The frame's width is shared between the two sides; its height is mostly the title bar, above.
	p_display->window_set_position(usable.position + Vector2i((usable.size.x - fitted.x) / 2, (usable.size.y - fitted.y - frame.y) / 2 + frame.y));
	print_verbose("dagon: window fitted scale=", fit.scale, " size=", fitted, " usable=", usable.size, " frame=", frame);
}

// Fullscreen is the borderless kind: no change of the screen's own mode, so leaving it is instant and safe.
void apply_display(bool p_fullscreen) {
	DisplayServer *display = DisplayServer::get_singleton();
	if (display == nullptr || display->get_name() == "headless") {
		return;
	}
	const bool was_fullscreen = is_fullscreen(display->window_get_mode());
	if (p_fullscreen) {
		if (!was_fullscreen) {
			display->window_set_mode(DisplayServer::WINDOW_MODE_FULLSCREEN);
			print_verbose("dagon: display fullscreen");
		}
		return;
	}
	if (was_fullscreen) {
		display->window_set_mode(DisplayServer::WINDOW_MODE_WINDOWED);
		print_verbose("dagon: display windowed");
	}
	fit_window(display, was_fullscreen);
}

} // namespace

void apply_settings(const core::Settings &p_settings) {
	set_bus_level("Music", p_settings.music_volume);
	set_bus_level("Effects", p_settings.effects_volume);
	set_bus_level("Narration", p_settings.narration_volume);
	Engine *engine = Engine::get_singleton();
	engine->set_meta(SUBTITLES_META, p_settings.subtitles);
	engine->set_meta(VIBRATION_META, p_settings.vibration);
	for (int i = 0; i < core::GAME_ACTION_COUNT; i++) {
		set_action_key(core::action_name(static_cast<core::GameAction>(i)), p_settings.keys[static_cast<std::size_t>(i)]);
	}
	apply_display(p_settings.fullscreen);
}

bool subtitles_enabled() {
	return Engine::get_singleton()->get_meta(SUBTITLES_META, true);
}

bool vibration_enabled() {
	return Engine::get_singleton()->get_meta(VIBRATION_META, true);
}

LoadedSave load_game() {
	LoadedSave loaded;
	std::string text;
	if (read_file(SAVE_FILE, text)) {
		loaded.any_file = true;
		const core::ParsedSave parsed = core::parse_save(text);
		loaded.status = parsed.status;
		if (parsed.status == core::SaveStatus::Ok) {
			loaded.save = parsed.save;
			return loaded;
		}
	}
	std::string backup;
	if (read_file(SAVE_BACKUP_FILE, backup)) {
		loaded.any_file = true;
		const core::ParsedSave parsed = core::parse_save(backup);
		if (parsed.status == core::SaveStatus::Ok) {
			loaded.status = parsed.status;
			loaded.save = parsed.save;
			loaded.from_backup = true;
		} else if (loaded.status == core::SaveStatus::Missing) {
			loaded.status = parsed.status;
		}
	}
	return loaded;
}

bool save_game(const core::SaveData &p_save) {
	if (!core::is_savable(p_save.beat)) {
		return false;
	}
	const std::string text = core::serialize_save(p_save);
	if (!write_temporary(SAVE_FILE, text)) {
		return false;
	}
	if (core::parse_save(text).status != core::SaveStatus::Ok) {
		DirAccess::remove_absolute(root().path_join(SAVE_FILE) + String(TEMPORARY_SUFFIX));
		return false;
	}
	// Only a save known to be good may become the backup. A corrupt one leaves the old backup alone.
	std::string current;
	if (read_file(SAVE_FILE, current) && core::parse_save(current).status == core::SaveStatus::Ok && !replace_file(SAVE_BACKUP_FILE, current)) {
		DirAccess::remove_absolute(root().path_join(SAVE_FILE) + String(TEMPORARY_SUFFIX));
		return false;
	}
	return move_temporary(SAVE_FILE);
}

String displayed_key_name(int p_key, int p_layout_label, const Ref<Font> &p_font) {
	OS *os = OS::get_singleton();
	const String physical_name = os->get_keycode_string(static_cast<Key>(p_key));
	if (p_layout_label == KEY_NONE) {
		return physical_name;
	}
	const String label_name = os->get_keycode_string(static_cast<Key>(p_layout_label));
	if (p_font.is_valid()) {
		for (int i = 0; i < label_name.length(); i++) {
			if (!p_font->has_char(label_name[i])) {
				return physical_name;
			}
		}
	}
	return label_name;
}

String key_name(int p_key, const Ref<Font> &p_font) {
	DisplayServer *display = DisplayServer::get_singleton();
	// The headless server has no layouts, and logs an error if asked.
	const Key label = display->get_name() != String("headless") ? display->keyboard_get_label_from_physical(static_cast<Key>(p_key)) : KEY_NONE;
	return displayed_key_name(p_key, static_cast<int>(label), p_font);
}

int current_key(const StringName &p_action) {
	const TypedArray<InputEvent> events = InputMap::get_singleton()->action_get_events(p_action);
	for (int i = 0; i < events.size(); i++) {
		const Ref<InputEventKey> key = events[i];
		if (key.is_valid() && !is_fixed_key(p_action, static_cast<int>(key->get_physical_keycode()))) {
			return static_cast<int>(key->get_physical_keycode());
		}
	}
	return 0;
}

} // namespace dagon::storage
