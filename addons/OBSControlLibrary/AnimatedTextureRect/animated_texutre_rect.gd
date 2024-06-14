@tool
@icon("res://addons/OBSControlLibrary/AnimatedTextureRect/AnimatedTextureRect.svg")
extends TextureRect
class_name AnimatedTextureRect

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal animation_finished(anim_name : StringName)
signal loop_finished(anim_name : StringName)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const CUSTOM_SPEED_THRESHOLD : float = 0.001

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Animated Texture Rect")

@export_subgroup("Animation")
@export var sprite_frames : SpriteFrames = null
@export var animation : StringName = &"default":				set = set_animation
@export_range(0.0, INF, 0.01) var speed_scale : float = 1.0
@export var auto_play : bool = false:							set = set_auto_play

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _canim : StringName = &""
var _cframe : int = 0
var _frame_dur : float = 0.0
var _sscale : float = 1.0
var _dir : int = 1

var _playing : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_sprite_frames(sf : SpriteFrames) -> void:
	sprite_frames = sf
	if not Engine.is_editor_hint(): return
	if sprite_frames != null and sprite_frames.has_animation(animation) and auto_play:
		play(animation)

func set_animation(anim_name : StringName) -> void:
	animation = anim_name
	if sprite_frames != null:
		if not sprite_frames.has_animation(animation):
			animation = &"default"
		if not Engine.is_editor_hint(): return
		if auto_play:
			play(animation)


func set_auto_play(ap : bool) -> void:
	auto_play = ap
	if not Engine.is_editor_hint(): return
	if auto_play and sprite_frames != null and sprite_frames.has_animation(animation):
		play(animation)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if auto_play and sprite_frames != null and sprite_frames.has_animation(animation):
		play(animation)

func _process(delta: float) -> void:
	if not is_playing(): return
	_frame_dur -= delta
	if _frame_dur <= 0.0:
		_cframe += _dir
		if _cframe < 0 or _cframe == sprite_frames.get_frame_count(_canim):
			if sprite_frames.get_animation_loop(_canim):
				loop_finished.emit(_canim)
				_cframe = 0 if _dir > 0 else sprite_frames.get_frame_count(_canim) - 1
			else:
				animation_finished.emit(_canim)
				_playing = false
		if _playing:
			_frame_dur += _CalcFrameDuration()
			_UpdateFrame()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFrame() -> void:
	if sprite_frames == null: return
	var tex : Texture2D = sprite_frames.get_frame_texture(_canim, _cframe)
	if tex != null:
		texture = tex

func _CalcFrameDuration() -> float:
	if sprite_frames == null: return 0.0
	var fps : float = sprite_frames.get_animation_speed(_canim) * _sscale
	if fps <= 0.0: return 0.0
	
	var reldur : float = sprite_frames.get_frame_duration(_canim, _cframe)
	return reldur / fps

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_playing_speed() -> float:
	if sprite_frames == null or not _playing: return 0.0
	if not sprite_frames.has_animation(_canim): return 0.0
	return sprite_frames.get_animation_speed(_canim) * _sscale * _dir

func is_playing() -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(_canim):
		return false
	return _playing

func play(anim_name : StringName, custom_speed : float = 1.0, from_end : bool = false) -> void:
	if sprite_frames == null or abs(custom_speed) <= CUSTOM_SPEED_THRESHOLD: return
	if sprite_frames.has_animation(anim_name):
		_canim = anim_name
		_sscale = speed_scale * abs(custom_speed)
		_dir = -1 if custom_speed < 0 else 1
		_cframe = sprite_frames.get_frame_count(_canim) - 1 if from_end else 0
		_frame_dur = _CalcFrameDuration()
		_UpdateFrame()
		_playing = true

func play_backwards(anim_name : StringName) -> void:
	play(anim_name, -1.0, true)

func stop() -> void:
	_playing = false

func set_frame_and_progress(frame : int, progress : float) -> void:
	if sprite_frames == null or _canim.is_empty(): return
	var frames : int = sprite_frames.get_frame_count(_canim)
	if frame >= 0 and frame < frames:
		_cframe = frame
		_frame_dur = _CalcFrameDuration() * (1.0 - progress)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------



