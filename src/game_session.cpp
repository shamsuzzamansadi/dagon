#include "game_session.hpp"

#include "menu_controller.hpp"
#include "storage.hpp"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/print_string.hpp>

using namespace godot;

namespace dagon {

namespace {

const char *const WORLD_NODE_NAME = "World";
const char *const SAVED_NOTICE = "Checkpoint saved";
const char *const SAVE_FAILED_NOTICE = "Could not save this checkpoint";

} // namespace

void GameSession::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_start", "beat", "persisted", "show_intro"), &GameSession::set_start);
	ClassDB::bind_method(D_METHOD("set_active_device", "device"), &GameSession::set_active_device);
	ClassDB::bind_method(D_METHOD("get_active_device"), &GameSession::get_active_device);
	ClassDB::bind_method(D_METHOD("restart_checkpoint"), &GameSession::restart_checkpoint);
	ClassDB::bind_method(D_METHOD("retry_save"), &GameSession::retry_save);
	ClassDB::bind_method(D_METHOD("is_checkpoint_saved"), &GameSession::is_checkpoint_saved);
	ClassDB::bind_method(D_METHOD("has_any_save"), &GameSession::has_any_save);
	ClassDB::bind_method(D_METHOD("is_in_final_sequence"), &GameSession::is_in_final_sequence);
	ClassDB::bind_method(D_METHOD("get_session_beat"), &GameSession::get_session_beat);
	ClassDB::bind_method(D_METHOD("get_persisted_beat"), &GameSession::get_persisted_beat);
	ClassDB::bind_method(D_METHOD("get_world"), &GameSession::get_world);
	ClassDB::bind_method(D_METHOD("get_director"), &GameSession::get_director);

	ClassDB::bind_method(D_METHOD("set_world_scene", "scene"), &GameSession::set_world_scene);
	ClassDB::bind_method(D_METHOD("get_world_scene"), &GameSession::get_world_scene);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "world_scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_world_scene", "get_world_scene");
	ClassDB::bind_method(D_METHOD("set_director_path", "path"), &GameSession::set_director_path);
	ClassDB::bind_method(D_METHOD("get_director_path"), &GameSession::get_director_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "director_path"), "set_director_path", "get_director_path");
	ClassDB::bind_method(D_METHOD("set_menu_path", "path"), &GameSession::set_menu_path);
	ClassDB::bind_method(D_METHOD("get_menu_path"), &GameSession::get_menu_path);
	ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "menu_path"), "set_menu_path", "get_menu_path");
}

void GameSession::set_start(int p_beat, bool p_persisted, bool p_show_intro) {
	session_beat_ = p_beat;
	persisted_beat_ = p_persisted ? p_beat : -1;
	show_intro_ = p_show_intro;
}

void GameSession::set_active_device(int p_device) {
	active_device_ = p_device;
	if (GameDirector *director = director_.get()) {
		director->set_input_device(p_device);
	}
}

void GameSession::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	print_verbose("dagon: session start beat=", session_beat_, " persisted=", persisted_beat_);
	build_world();
	MenuController *menu = menu_path_.is_empty() ? nullptr : get_node<MenuController>(menu_path_);
	if (menu != nullptr) {
		menu->set_active_device(active_device_);
		if (show_intro_) {
			menu->show_intro();
		}
	}
}

void GameSession::build_world() {
	ERR_FAIL_COND_MSG(world_scene_.is_null(), "GameSession: world_scene is not set; there is nothing to play.");
	Node *world = world_scene_->instantiate();
	ERR_FAIL_NULL(world);
	world->set_name(WORLD_NODE_NAME);

	// Everything the world needs is in place before it enters the tree, so its _ready sees the right beat.
	GameDirector *director = world->get_node<GameDirector>(director_path_);
	if (director != nullptr) {
		director->set_start_beat(session_beat_);
		director->connect("checkpoint_reached", callable_mp(this, &GameSession::on_checkpoint_reached));
	} else {
		ERR_PRINT("GameSession: director_path does not point to a GameDirector in the world.");
	}

	add_child(world);
	move_child(world, 0);
	world_.set(world);
	director_.set(director);
	if (director != nullptr) {
		director->set_input_device(active_device_);
	}
}

void GameSession::remove_world() {
	Node *world = world_.get();
	if (world == nullptr) {
		return;
	}
	// The old world can no longer reach the session, and leaving the tree stops all its processing,
	// physics and input at once. Its timers and tweens are bound to its nodes and die with them.
	if (GameDirector *director = director_.get()) {
		director->disconnect("checkpoint_reached", callable_mp(this, &GameSession::on_checkpoint_reached));
	}
	remove_child(world);
	world->queue_free();
	world_.set(nullptr);
	director_.set(nullptr);
}

void GameSession::restart_checkpoint() {
	remove_world();
	build_world();
	if (GameDirector *director = director_.get()) {
		director->fade_in();
	}
}

void GameSession::on_checkpoint_reached(int p_beat) {
	// The final sequence is not a checkpoint: quitting or restarting during it replays it.
	if (!core::is_savable(static_cast<core::Beat>(p_beat))) {
		return;
	}
	// First the session value, so a failed write cannot lose it.
	session_beat_ = p_beat;
	const bool saved = write_session_checkpoint();
	if (GameDirector *director = director_.get()) {
		director->show_notice(saved ? SAVED_NOTICE : SAVE_FAILED_NOTICE);
	}
}

bool GameSession::write_session_checkpoint() {
	// Never during a cinematic, or with the player locked. Closing then returns to the previous checkpoint.
	const GameDirector *director = director_.get();
	if (director != nullptr && !director->is_safe_to_save()) {
		return false;
	}
	core::SaveData save;
	save.beat = static_cast<core::Beat>(session_beat_);
	if (!storage::save_game(save)) {
		return false;
	}
	persisted_beat_ = session_beat_;
	return true;
}

bool GameSession::retry_save() {
	return is_checkpoint_saved() || write_session_checkpoint();
}

} // namespace dagon
