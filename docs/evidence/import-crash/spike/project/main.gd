extends Node
func _ready():
	var n = ClassDB.instantiate("SpikeNode")
	print("EXPORT_SMOKE class=", n != null, " sum=", n.sum_steps() if n else -1)
	if n: n.free()
	get_tree().quit(0 if n else 1)
