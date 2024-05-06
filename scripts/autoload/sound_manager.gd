extends Node

var audio_stream_path := "res://assets/prefabs/sound_player.tscn"
var audio_stream_3d_path := "res://assets/prefabs/sound_player_3d.tscn"

func play_sound(path, volume, pitch, pitch_range, duration):
	var this_sound = load(audio_stream_path).instantiate()
	get_node("/root").add_child(this_sound)
	this_sound.volume_db = float(volume)
	var final_pitch = pitch+GameManager.rng.randf_range(-pitch_range/2,pitch_range/2)
	this_sound.volume_db = volume
	this_sound.pitch_scale = final_pitch
	this_sound.stream = load(path)
	this_sound.play()
	var t = 0
	while(t<duration):
		t+=GameManager.global_delta
		await get_tree().physics_frame
	get_node("/root").remove_child(this_sound)
	this_sound.queue_free()
	
func play_sound_3d(path, volume, pitch, pitch_range, duration, pos):
	var this_sound = load(audio_stream_3d_path).instantiate()
	get_node("/root").add_child(this_sound)
	this_sound.volume_db = float(volume)
	var final_pitch = pitch+GameManager.rng.randf_range(-pitch_range/2,pitch_range/2)
	this_sound.volume_db = volume
	this_sound.pitch_scale = final_pitch
	this_sound.stream = load(path)
	this_sound.global_position = pos
	this_sound.play()
	var t = 0
	while(t<duration):
		t+=GameManager.global_delta
		await get_tree().physics_frame
	get_node("/root").remove_child(this_sound)
	this_sound.queue_free()
