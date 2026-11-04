#pragma once

#include "core/narration.hpp"

#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>

// Stateless: the one script of spoken lines, and the audio that belongs to each. A line with no audio file is
// simply a text line, so the game never needs a file to go on (docs/architecture.md §5, Narration).
namespace dagon::narration {

core::ParsedScript load_script();
godot::String line_text(const godot::StringName &p_id);

// Null if this line has no audio. That is not an error: most lines have none until the voice is approved.
godot::Ref<godot::AudioStream> line_audio(const godot::StringName &p_id);

} // namespace dagon::narration
