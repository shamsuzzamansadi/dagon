#include "spike.hpp"
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
using namespace godot;
static void init(ModuleInitializationLevel l) { if (l == MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(dagon::SpikeNode); }
static void deinit(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT spike_init(GDExtensionInterfaceGetProcAddress p, GDExtensionClassLibraryPtr lib, GDExtensionInitialization *r) {
	GDExtensionBinding::InitObject o(p, lib, r);
	o.register_initializer(init); o.register_terminator(deinit);
	o.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return o.init();
}
