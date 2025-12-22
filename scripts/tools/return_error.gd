class_name RetErr extends Resource

var ret: Variant:
	get:
		if err == OK:
			return val
		else:
			return err
	set(value):
		if value is Error:
			err = value
		else:
			ret = value
var val: Variant
var err: Error

func _init(value: Variant = null, error: Error = OK) -> void:
	val = value
	err = error
