#pragma once

namespace dagon {

// Engine-global state survives a scene change (docs/architecture.md §7 rule 8). This restores pause,
// time scale and mouse mode. Volumes and key bindings change only through the settings, so they are
// left alone, and a setting that could not be saved still lasts until the player quits.
// Returns true if anything had been left changed.
bool reset_global_state();

} // namespace dagon
