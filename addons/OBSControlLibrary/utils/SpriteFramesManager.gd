@tool
extends RefCounted
class_name SpriteFramesManager

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal texture_changed(texture : Texture2D)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CUSTOM_SPEED_THRESHOLD : float = 0.001

enum AnimationState {
	NONE=-1,
	PROCESSED=0,
	LOOPED=1,
	FINISHED=2
}

# ------------------------------------------------------------------------------
# "Public" Variables
# ------------------------------------------------------------------------------
var sprite_frames : SpriteFrames = null:	set=set_sprite_frames
var speed_scale : float = 1.0:				set=set_speed_scale
var animation : StringName = &"":			set=set_animation
var auto_play : bool = false:				set=set_auto_play

# ------------------------------------------------------------------------------
# "Private" Variables
# ------------------------------------------------------------------------------
var _anim_direction : int = 1
var _current_frame : int = 0
var _speed_scale : float = 1.0
var _frame_duration : float = 0.0
var _texture : Texture2D = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_sprite_frames(sf : SpriteFrames) -> void:
	sprite_frames = sf
	if sprite_frames != null:
		if Engine.is_editor_hint() and auto_play:
			_InitAnimVars(1.0, false)
	else:
		_texture = null
		texture_changed.emit(_texture)

func set_speed_scale(ss : float) -> void:
	if ss > 0.0:
		speed_scale = ss

func set_animation(anim_name : StringName) -> void:
	animation = anim_name
	if Engine.is_editor_hint() and auto_play:
		_InitAnimVars(1.0, false)

func set_auto_play(ap : bool) -> void:
	auto_play = ap
	if Engine.is_editor_hint() and auto_play:
		_InitAnimVars(1.0, false)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _CalcFrameDuration() -> float:
	if sprite_frames == null: return 0.0
	var fps : float = sprite_frames.get_animation_speed(animation) * _speed_scale
	if fps <= 0.0: return 0.0
	
	var reldur : float = sprite_frames.get_frame_duration(animation, _current_frame)
	return reldur / fps

func _InitAnimVars(custom_speed : float, from_end : bool) -> void:
	if sprite_frames == null or abs(custom_speed) <= CUSTOM_SPEED_THRESHOLD: return
	if not sprite_frames.has_animation(animation): return
	_speed_scale = speed_scale * abs(custom_speed)
	_anim_direction = -1 if custom_speed < 0 else 1
	_current_frame = sprite_frames.get_frame_count(animation) - 1 if from_end else 0
	_frame_duration = _CalcFrameDuration()
	_CheckTextureUpdate()

func _CheckTextureUpdate() -> void:
	if sprite_frames == null: return
	var tex : Texture2D = sprite_frames.get_frame_texture(animation, _current_frame)
	if tex != _texture:
		_texture = tex
		texture_changed.emit(_texture)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_play_speed() -> float:
	if sprite_frames == null: return 0.0
	if not sprite_frames.has_animation(animation): return 0.0
	return sprite_frames.get_animation_speed(animation) * _speed_scale * _anim_direction

func begin_animation(anim_name : StringName, custom_speed : float = 1.0, from_end : bool = false) -> void:
	if sprite_frames == null or abs(custom_speed) <= CUSTOM_SPEED_THRESHOLD: return
	if sprite_frames.has_animation(anim_name):
		animation = anim_name
		_InitAnimVars(custom_speed, from_end)

func reset_animation() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation): return
	_current_frame = sprite_frames.get_frame_count(animation) - 1 if _anim_direction < 0 else 0
	_frame_duration = _CalcFrameDuration()
	_CheckTextureUpdate()

func update_animation(delta : float) -> AnimationState:
	if sprite_frames == null: return AnimationState.NONE
	var astate : AnimationState = AnimationState.PROCESSED
	_frame_duration -= delta
	if _frame_duration <= 0.0:
		_current_frame += _anim_direction
		if _current_frame < 0 or _current_frame == sprite_frames.get_frame_count(animation):
			if sprite_frames.get_animation_loop(animation):
				astate = AnimationState.LOOPED
				#loop_finished.emit(_canim)
				_current_frame = 0 if _anim_direction > 0 else sprite_frames.get_frame_count(animation) - 1
			else:
				astate = AnimationState.FINISHED
				#animation_finished.emit(_canim)
		if astate != AnimationState.FINISHED:
			_frame_duration += _CalcFrameDuration()
			_CheckTextureUpdate()
		return astate
	return AnimationState.NONE

func get_texture() -> Texture2D:
	return _texture

func get_current_frame() -> int:
	return _current_frame


