#include "storage.hpp"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/display_server.hpp>
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
const char *const STORAGE_DIR_VARIABLE = "DAGON_STORAGE_DIR";

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

bool replace_file(const String &p_name, const std::string &p_text) {
	const String directory = root();
	if (DirAccess::make_dir_recursive_absolute(directory) != OK) {
		return false;
	}
	const String path = directory.path_join(p_name);
	const String temporary = path + String(".tmp");

	const Ref<FileAccess> file = FileAccess::open(temporary, FileAccess::WRITE);
	if (file.is_null()) {
		return false;
	}
	PackedByteArray bytes;
	bytes.resize(static_cast<int64_t>(p_text.size()));
	std::memcpy(bytes.ptrw(), p_text.data(), p_text.size());
	file->store_buffer(bytes);
	file->close();

	if (FileAccess::get_file_as_bytes(temporary) != bytes || DirAccess::rename_absolute(temporary, path) != OK) {
		DirAccess::remove_absolute(temporary);
		return false;
	}
	return true;
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

void apply_settings(const core::Settings &p_settings) {
	set_bus_level("Music", p_settings.music_volume);
	set_bus_level("Effects", p_settings.effects_volume);
	for (int i = 0; i < core::GAME_ACTION_COUNT; i++) {
		set_action_key(core::action_name(static_cast<core::GameAction>(i)), p_settings.keys[static_cast<std::size_t>(i)]);
	}
}

String key_name(int p_key) {
	const Key physical = static_cast<Key>(p_key);
	DisplayServer *display = DisplayServer::get_singleton();
	// The name on the player's own keyboard layout. The headless server has none, and logs an error if asked.
	const Key label = display->get_name() != String("headless") ? display->keyboard_get_label_from_physical(physical) : KEY_NONE;
	return OS::get_singleton()->get_keycode_string(label != KEY_NONE ? label : physical);
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
