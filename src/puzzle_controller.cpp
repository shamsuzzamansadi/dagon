#include "puzzle_controller.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>
#include <godot_cpp/variant/string.hpp>

#include <string>
#include <utility>

using namespace godot;

namespace dagon {

void PuzzleController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("submit", "id"), &PuzzleController::submit);
	ClassDB::bind_method(D_METHOD("reset"), &PuzzleController::reset);
	ClassDB::bind_method(D_METHOD("is_solved"), &PuzzleController::is_solved);
	ClassDB::bind_method(D_METHOD("is_rejecting"), &PuzzleController::is_rejecting);
	ClassDB::bind_method(D_METHOD("get_progress"), &PuzzleController::get_progress);
	ClassDB::bind_method(D_METHOD("restore_solved"), &PuzzleController::restore_solved);

	ClassDB::bind_method(D_METHOD("set_solution", "ids"), &PuzzleController::set_solution);
	ClassDB::bind_method(D_METHOD("get_solution"), &PuzzleController::get_solution);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_STRING_ARRAY, "solution"), "set_solution", "get_solution");
	ClassDB::bind_method(D_METHOD("set_reset_delay", "seconds"), &PuzzleController::set_reset_delay);
	ClassDB::bind_method(D_METHOD("get_reset_delay"), &PuzzleController::get_reset_delay);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "reset_delay"), "set_reset_delay", "get_reset_delay");
	ClassDB::bind_method(D_METHOD("set_indicators", "paths"), &PuzzleController::set_indicators);
	ClassDB::bind_method(D_METHOD("get_indicators"), &PuzzleController::get_indicators);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "indicators"), "set_indicators", "get_indicators");
	ClassDB::bind_method(D_METHOD("set_stones", "paths"), &PuzzleController::set_stones);
	ClassDB::bind_method(D_METHOD("get_stones"), &PuzzleController::get_stones);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "stones"), "set_stones", "get_stones");

	ADD_SIGNAL(MethodInfo("step_accepted", PropertyInfo(Variant::INT, "index")));
	ADD_SIGNAL(MethodInfo("failed"));
	ADD_SIGNAL(MethodInfo("solved"));
}

void PuzzleController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	configure();
	for (int i = 0; i < indicator_paths_.size(); i++) {
		NodeRef<CanvasItem> indicator;
		indicator.set(get_node<CanvasItem>(indicator_paths_[i]));
		if (indicator.get() == nullptr) {
			ERR_PRINT("PuzzleController: an entry in indicators does not point to a CanvasItem.");
		}
		indicators_.push_back(indicator);
	}
	for (int i = 0; i < stone_paths_.size(); i++) {
		NodeRef<Interactable> stone;
		stone.set(get_node<Interactable>(stone_paths_[i]));
		if (stone.get() == nullptr) {
			ERR_PRINT("PuzzleController: an entry in stones does not point to an Interactable.");
		}
		stones_.push_back(stone);
	}
	if (solved_before_ready_) {
		restore_solved();
	} else {
		show_lit(0);
	}
}

void PuzzleController::configure() {
	if (configured_) {
		return;
	}
	configured_ = true;
	std::vector<std::string> ids;
	ids.reserve(static_cast<std::size_t>(solution_.size()));
	for (int i = 0; i < solution_.size(); i++) {
		ids.emplace_back(solution_[i].utf8().get_data());
	}
	puzzle_.configure(std::move(ids), reset_delay_);
}

void PuzzleController::_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	elapsed_ += p_delta;
	if (puzzle_.update(elapsed_)) {
		set_stones_enabled(true);
	}
}

PackedStringArray PuzzleController::_get_configuration_warnings() const {
	PackedStringArray warnings = Node::_get_configuration_warnings();
	if (solution_.is_empty()) {
		warnings.push_back("solution is empty, so this puzzle can never be solved.");
	}
	if (indicator_paths_.size() != solution_.size()) {
		warnings.push_back("indicators should have one entry for each step of the solution.");
	}
	return warnings;
}

void PuzzleController::submit(const StringName &p_id) {
	configure();
	const String id = p_id;
	const CharString id_text = id.utf8();
	const std::string_view id_view(id_text.get_data(), static_cast<std::size_t>(id_text.length()));
	if (!puzzle_.knows(id_view)) {
		// A wiring bug: this stone's interaction_id is not in the solution.
		ERR_PRINT("PuzzleController: a stone submitted an id that is not in the solution.");
		return;
	}
	const std::size_t before = puzzle_.progress();
	switch (puzzle_.submit(id_view, elapsed_)) {
		case core::PuzzleResult::Accepted:
			show_lit(puzzle_.progress());
			print_verbose("dagon: puzzle accepted step=", static_cast<int64_t>(before));
			emit_signal("step_accepted", static_cast<int>(before));
			break;
		case core::PuzzleResult::Rejected:
			// Dark at once, and no prompt until the lockout ends, so it can be read without sound.
			show_lit(0);
			set_stones_enabled(false);
			print_verbose("dagon: puzzle rejected");
			emit_signal("failed");
			break;
		case core::PuzzleResult::Solved:
			show_lit(puzzle_.progress());
			set_stones_enabled(false);
			print_verbose("dagon: puzzle solved");
			emit_signal("step_accepted", static_cast<int>(before));
			emit_signal("solved");
			break;
		case core::PuzzleResult::Ignored:
			break;
	}
}

void PuzzleController::reset() {
	if (puzzle_.is_solved()) {
		return;
	}
	puzzle_.reset();
	show_lit(0);
	set_stones_enabled(true);
}

void PuzzleController::restore_solved() {
	configure();
	puzzle_.restore_solved();
	if (!is_node_ready()) {
		solved_before_ready_ = true;
		return;
	}
	show_lit(puzzle_.progress());
	set_stones_enabled(false);
}

void PuzzleController::show_lit(std::size_t p_count) {
	for (std::size_t i = 0; i < indicators_.size(); i++) {
		if (CanvasItem *indicator = indicators_[i].get()) {
			indicator->set_visible(i < p_count);
		}
	}
}

void PuzzleController::set_stones_enabled(bool p_enabled) {
	for (const NodeRef<Interactable> &reference : stones_) {
		if (Interactable *stone = reference.get()) {
			stone->set_enabled(p_enabled);
		}
	}
}

} // namespace dagon
