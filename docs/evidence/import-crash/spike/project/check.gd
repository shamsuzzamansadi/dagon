extends SceneTree
func _init():
	var ok := ClassDB.class_exists("SpikeNode")
	print("class_exists=", ok)
	if ok:
		var n = ClassDB.instantiate("SpikeNode")
		print("sum_steps=", n.sum_steps(), " __cplusplus=", n.get_cplusplus(), " has_signal=", n.has_signal("probe"))
		n.free()
	quit(0 if ok else 1)
