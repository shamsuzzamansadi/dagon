#include "spike.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <concepts>
#include <numeric>
using namespace godot;
namespace {
template <std::integral T>
T total(std::span<const T> v) { return std::accumulate(v.begin(), v.end(), T{}); }
struct Opts { int a = 0; int b = 0; };
}
namespace dagon {
int SpikeNode::sum_steps() const {
	constexpr Opts o{ .a = 1, .b = 2 };  // designated initializers (C++20)
	return total<int>(steps_) + o.a + o.b;
}
void SpikeNode::_bind_methods() {
	ClassDB::bind_method(D_METHOD("sum_steps"), &SpikeNode::sum_steps);
	ClassDB::bind_method(D_METHOD("get_cplusplus"), &SpikeNode::get_cplusplus);
	ADD_SIGNAL(MethodInfo("probe", PropertyInfo(Variant::INT, "value")));
}
}
