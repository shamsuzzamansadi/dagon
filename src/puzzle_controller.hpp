#pragma once

#include "core/sequence_puzzle.hpp"
#include "interactable.hpp"
#include "node_ref.hpp"

#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string_name.hpp>

#include <vector>

namespace dagon {

// The stones at the monolith. The rules are core::SequencePuzzle, and this adds their lights, their
// prompts and the signals. Time accumulates in _process, so the lockout stops while the game is paused.
class PuzzleController : public godot::Node {
	GDCLASS(PuzzleController, godot::Node)

public:
	void _ready() override;
	void _process(double p_delta) override;
	godot::PackedStringArray _get_configuration_warnings() const override;

	// From each stone's Interactable.interacted.
	void submit(const godot::StringName &p_id);

	// Clears the current attempt. A solved puzzle stays solved.
	void reset();
	bool is_solved() const { return puzzle_.is_solved(); }
	int get_progress() const { return static_cast<int>(puzzle_.progress()); }
	bool is_rejecting() const { return puzzle_.state() == core::PuzzleState::Rejecting; }

	// The stable state for a world restored from a checkpoint, or the end of the Awakened beat.
	// Emits nothing, so no event or cue can replay.
	void restore_solved();

	void set_solution(const godot::PackedStringArray &p_value) { solution_ = p_value; }
	godot::PackedStringArray get_solution() const { return solution_; }
	void set_reset_delay(double p_value) { reset_delay_ = p_value; }
	double get_reset_delay() const { return reset_delay_; }
	void set_indicators(const godot::Array &p_value) { indicator_paths_ = p_value; }
	godot::Array get_indicators() const { return indicator_paths_; }
	void set_stones(const godot::Array &p_value) { stone_paths_ = p_value; }
	godot::Array get_stones() const { return stone_paths_; }

protected:
	static void _bind_methods();

private:
	void configure();
	void show_lit(std::size_t p_count);
	void set_stones_enabled(bool p_enabled);

	godot::PackedStringArray solution_;
	double reset_delay_ = 1.0;
	// In solution order.
	godot::Array indicator_paths_;
	godot::Array stone_paths_;

	std::vector<NodeRef<godot::CanvasItem>> indicators_;
	std::vector<NodeRef<Interactable>> stones_;
	core::SequencePuzzle puzzle_;
	double elapsed_ = 0.0;
	bool configured_ = false;
	bool solved_before_ready_ = false;
};

} // namespace dagon
