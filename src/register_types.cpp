#include "camera_rig.hpp"
#include "game_director.hpp"
#include "game_session.hpp"
#include "hud.hpp"
#include "interactable.hpp"
#include "interactor.hpp"
#include "menu_controller.hpp"
#include "player_controller.hpp"
#include "settings_menu.hpp"
#include "story_trigger.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/godot.hpp>

// Catches a silent fallback to C++17. MSVC reports the true value only with
// /Zc:__cplusplus, which godot-cpp adds.
static_assert(__cplusplus >= 202002L, "dagon sources must compile as C++20");

using namespace godot;

namespace {

#if defined(_MSC_FULL_VER)
const int64_t COMPILER_VERSION = _MSC_FULL_VER;
const char *const COMPILER_NAME = "MSVC";
#elif defined(__clang__)
const int64_t COMPILER_VERSION = __clang_major__ * 10000 + __clang_minor__ * 100 + __clang_patchlevel__;
const char *const COMPILER_NAME = "clang";
#else
const int64_t COMPILER_VERSION = __GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__;
const char *const COMPILER_NAME = "gcc";
#endif

#if defined(DEBUG_ENABLED)
const char *const BUILD_TYPE = "debug";
#else
const char *const BUILD_TYPE = "release";
#endif

void initialize_dagon(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(dagon::PlayerController);
	GDREGISTER_CLASS(dagon::CameraRig);
	GDREGISTER_CLASS(dagon::Interactable);
	GDREGISTER_CLASS(dagon::Interactor);
	GDREGISTER_CLASS(dagon::StoryTrigger);
	GDREGISTER_CLASS(dagon::Hud);
	GDREGISTER_CLASS(dagon::GameDirector);
	GDREGISTER_CLASS(dagon::GameSession);
	GDREGISTER_CLASS(dagon::SettingsMenu);
	GDREGISTER_CLASS(dagon::MenuController);
	// Positive load proof for the release export check, which runs with --verbose.
	print_verbose("dagon: extension initialized build=", BUILD_TYPE, " compiler=", COMPILER_NAME, " ", COMPILER_VERSION, " __cplusplus=", static_cast<int64_t>(__cplusplus));
}

void uninitialize_dagon(ModuleInitializationLevel p_level) {
	(void)p_level;
}

} // namespace

extern "C" {

GDExtensionBool GDE_EXPORT dagon_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_dagon);
	init_obj.register_terminator(uninitialize_dagon);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
