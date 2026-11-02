#pragma once
#include <godot_cpp/classes/node.hpp>
#include <array>
#include <span>
namespace dagon {
class SpikeNode : public godot::Node {
	GDCLASS(SpikeNode, godot::Node)
public:
	int sum_steps() const;
	int get_cplusplus() const { return static_cast<int>(__cplusplus); }
protected:
	static void _bind_methods();
private:
	std::array<int, 3> steps_{ 1, 2, 3 };
};
}
