#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/object.hpp>

#include <cstdint>

namespace dagon {

// A stored reference to a node owned by the scene tree. Any node can be freed
// independently of its parent, so no raw node pointer is kept past the current
// call: get() returns nullptr once the node is gone, and callers check it.
template <typename T>
class NodeRef {
public:
	NodeRef() = default;

	void set(T *p_node) {
		instance_id_ = p_node != nullptr ? p_node->get_instance_id() : 0;
	}

	T *get() const {
		if (instance_id_ == 0) {
			return nullptr;
		}
		return godot::Object::cast_to<T>(godot::ObjectDB::get_instance(instance_id_));
	}

private:
	uint64_t instance_id_ = 0;
};

} // namespace dagon
