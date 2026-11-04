#include "narration.hpp"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

#include <string>

using namespace godot;

namespace dagon::narration {

namespace {

const char *const SCRIPT_PATH = "res://narration/script.txt";
const char *const AUDIO_FOLDER = "res://assets/narration/";
const char *const AUDIO_EXTENSION = ".ogg";

} // namespace

core::ParsedScript load_script() {
	const PackedByteArray bytes = FileAccess::get_file_as_bytes(SCRIPT_PATH);
	if (bytes.is_empty()) {
		ERR_PRINT("narration: the script could not be read, so no line has any words.");
		return core::ParsedScript{};
	}
	const std::string text(reinterpret_cast<const char *>(bytes.ptr()), static_cast<std::size_t>(bytes.size()));
	return core::parse_narration_script(text);
}

String line_text(const StringName &p_id) {
	const core::ParsedScript script = load_script();
	const String id = p_id;
	const core::NarrationLine *line = core::find_line(script.lines, id.utf8().get_data());
	if (line == nullptr) {
		ERR_PRINT(String("narration: no line in the script has the id '") + id + "'.");
		return String();
	}
	return String::utf8(line->text.c_str());
}

Ref<AudioStream> line_audio(const StringName &p_id) {
	const String path = String(AUDIO_FOLDER) + String(p_id) + AUDIO_EXTENSION;
	ResourceLoader *loader = ResourceLoader::get_singleton();
	if (!loader->exists(path)) {
		return Ref<AudioStream>();
	}
	return loader->load(path);
}

} // namespace dagon::narration
