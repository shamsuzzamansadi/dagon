#pragma once

namespace godot {
class Node;
class SceneTree;
} // namespace godot

namespace dagon {

// Engine-global state survives a scene change (docs/architecture.md §7 rule 8). This restores pause,
// time scale and mouse mode. Volumes and key bindings change only through the settings, so they are
// left alone, and a setting that could not be saved still lasts until the player quits.
// Returns true if anything had been left changed.
bool reset_global_state();

// The mixer lets go of a stopped sound only between frames. One still playing, or stopped in the very frame the
// engine shuts down, is reported as leaked. So every way out stops all sound first, and leaves a few frames.
void stop_all_sound(godot::Node *p_root);
// Stops all sound, and asks for a quit once enough real time has passed for the mixer to let it all go.
void quit_quietly(godot::SceneTree *p_tree);
// Polled each frame by whichever scene root is running, including the pause menu, which runs while paused.
bool is_quit_due();
// The checks end a headless run by setting DAGON_QUIT_AFTER_FRAMES, rather than with --quit-after, which the game
// cannot see coming. True once that many frames have run.
bool is_run_over();

} // namespace dagon
