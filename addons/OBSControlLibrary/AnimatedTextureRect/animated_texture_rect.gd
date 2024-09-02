@tool
@icon("res://addons/OBSControlLibrary/AnimatedTextureRect/AnimatedTextureRect.svg")
extends Control
class_name AnimatedTextureRect

## A control that displays an animation in a GUI
##
## A control similar to a TextureRect node, but displays the selected animation from a SpriteFrames
## resource. Can be used for animated icons within a GUI. The texture's placement can be controlled
## with the stretch_mode property. It can scale, tile, or stay centered inside its bounding rectangle.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
## Signal emitted when a non-looped animation finishes.
signal animation_finished(anim_name : StringName)

## Signal emitted when a loop animation finished a sequence and is about to start again.
signal animation_looped(anim_name : StringName)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const CUSTOM_SPEED_THRESHOLD : float = 0.001

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_subgroup("Animation")
## The SpriteFrames resource containing the animation(s)
@export var sprite_frames : SpriteFrames = null
## Current animation from the SpriteFrames resource.
@export var animation : StringName = &"default":				set = set_animation
## The speed scaling ratio. For example, if this value is 1, then the animation plays at normal speed. If it's 0.5, animation plays at half speed. If it's 2, the animation plays at double speed.
@export var speed_scale : float = 1.0:							set = set_speed_scale
## The current frame in the active animation. If no animation is defined, the index will be [code]0[/code]
@export var frame : int:										set=set_frame, get=get_frame
## The progress through the current frame in the active animation. If no animation is defined, the value will be [code]0.0[/code]
@export var frame_progress : float:								set=set_frame_progress, get=get_frame_progress
## Automatically play animation in the editor and on startup.
@export var auto_play : bool = false:							set = set_auto_play

@export_subgroup("Display")
## Controls the texture's behaviour when resizing the node's bounding rectangle. 
@export var stretch_mode : TextureHelper.StretchMode = TextureHelper.StretchMode.KEEP:		set=set_stretch_mode
## Defines how minimum size is determined based on texture size.
@export var expand_mode : TextureHelper.ExpandMode = TextureHelper.ExpandMode.KEEP_SIZE:	set=set_expand_mode
## If true, flips the texture horizontally.
@export var flip_h : bool = false:															set=set_flip_h
## If true, flips the texture vertically.
@export var flip_v : bool = false:															set=set_flip_v

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _texture : Texture = null

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
	if sprite_frames != null:
		if sprite_frames.has_animation(animation):
			if auto_play:
				play(animation)
			else:
				set_frame_and_progress(0, 0.0)
	else:
		_texture = null
		queue_redraw()
		update_minimum_size()

func set_speed_scale(s : float) -> void:
	if s >= 0.0:
		speed_scale = s
		_sscale = speed_scale

func set_animation(anim_name : StringName) -> void:
	animation = anim_name
	if sprite_frames != null:
		if sprite_frames.has_animation(animation):
			if not Engine.is_editor_hint(): return
			if auto_play:
				play(animation)
			else:
				_canim = animation
				set_frame_and_progress(0, 0.0)


func set_auto_play(ap : bool) -> void:
	auto_play = ap
	if not Engine.is_editor_hint(): return
	if auto_play and sprite_frames != null and sprite_frames.has_animation(animation):
		play(animation)
	elif not auto_play:
		stop()

func set_flip_h(f : bool) -> void:
	flip_h = f
	queue_redraw()

func set_flip_v(f : bool) -> void:
	flip_v = f
	queue_redraw()

func set_stretch_mode(mode : TextureHelper.StretchMode) -> void:
	if mode != stretch_mode:
		stretch_mode = mode
		queue_redraw()
		update_minimum_size()

func set_expand_mode(mode : TextureHelper.ExpandMode) -> void:
	if mode != expand_mode:
		expand_mode = mode
		queue_redraw()
		update_minimum_size()

func set_frame(f : int) -> void:
	if sprite_frames == null: return
	if not sprite_frames.has_animation(_canim): return
	if f >= 0 and f < sprite_frames.get_frame_count(_canim):
		set_frame_and_progress(f, 0.0)

func get_frame() -> int:
	if sprite_frames != null and sprite_frames.has_animation(_canim):
		return _cframe
	return 0.0

func set_frame_progress(p : float) -> void:
	p = max(0, min(p, 1.0))
	set_frame_and_progress(_cframe, p)

func get_frame_progress() -> float:
	if sprite_frames != null and sprite_frames.has_animation(_canim):
		var total_dur : float = sprite_frames.get_frame_duration(_canim, _cframe)
		if total_dur > 0.0:
			return 1.0 - (_frame_dur / total_dur)
	return 0.0

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
				animation_looped.emit(_canim)
				_cframe = 0 if _dir > 0 else sprite_frames.get_frame_count(_canim) - 1
			else:
				animation_finished.emit(_canim)
				_playing = false
		if _playing:
			_frame_dur += _CalcFrameDuration()
			_UpdateFrame()

func _notification(what : int) -> void:
	match (what):
		NOTIFICATION_RESIZED:
			update_minimum_size()

func _draw() -> void:
	if _texture == null: return
	
	var sdata : Dictionary = TextureHelper.Get_Texture_Stretch_Data(
		_texture,
		get_size(),
		stretch_mode,
		flip_h, flip_v
	)
	if sdata.is_empty(): return
	
	if sdata.region.has_area():
		draw_texture_rect_region(_texture, sdata.rect, sdata.region)
	else:
		draw_texture_rect(_texture, sdata.rect, sdata.tiled)


func _get_minimum_size() -> Vector2:
	if _texture != null:
		match(expand_mode):
			TextureHelper.ExpandMode.KEEP_SIZE:
				return _texture.get_size()
			TextureHelper.ExpandMode.IGNORE_SIZE:
				return Vector2.ZERO
			TextureHelper.ExpandMode.FIT_WIDTH:
				return Vector2(get_size().y, 0)
			TextureHelper.ExpandMode.FIT_WIDTH_PROPORTIONAL:
				var ratio : float = _texture.get_width() / _texture.get_height()
				return Vector2(get_size().y * ratio, 0)
			TextureHelper.ExpandMode.FIT_HEIGHT:
				return Vector2(0, get_size().x)
			TextureHelper.ExpandMode.FIT_HEIGHT_PROPORTIONAL:
				var ratio : float = _texture.get_height() / _texture.get_width()
				return Vector2(0, get_size().x * ratio)
	return Vector2.ZERO

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFrame() -> void:
	if sprite_frames == null: return
	var tex : Texture2D = sprite_frames.get_frame_texture(_canim, _cframe)
	if tex != null:
		_texture = tex
		queue_redraw()
		update_minimum_size()

func _CalcFrameDuration() -> float:
	if sprite_frames == null: return 0.0
	var fps : float = sprite_frames.get_animation_speed(_canim) * _sscale
	if fps <= 0.0: return 0.0
	
	var reldur : float = sprite_frames.get_frame_duration(_canim, _cframe)
	return reldur / fps

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
## Returns the actual playing speed of current animation or 0 if not playing.
## This speed is the speed_scale property multiplied by custom_speed argument
## specified when calling the play method.[br]
## Returns a negative value if the current animation is playing backwards.
func get_playing_speed() -> float:
	if sprite_frames == null or not _playing: return 0.0
	if not sprite_frames.has_animation(_canim): return 0.0
	return sprite_frames.get_animation_speed(_canim) * _sscale * _dir

## Returns [code]true[/code] if an animation is currently playing
## (even if speed_scale and/or [code]custom_speed[/code] are [code]0[/code]).
func is_playing() -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(_canim):
		return false
	return _playing

## Plays the animation with key name. If [param custom_speed] is negative and [param from_end] is
## [code]true[/code], the animation will play backwards (which is equivalent to calling
## [method play_backwards]).
## [br]
## If this method is called with that same animation name, or with no name parameter,
## the assigned animation will resume playing if it was paused.
func play(anim_name : StringName = &"", custom_speed : float = 1.0, from_end : bool = false) -> void:
	if sprite_frames == null or abs(custom_speed) <= CUSTOM_SPEED_THRESHOLD: return
	if anim_name.is_empty() and not _canim.is_empty():
		_playing = true
		return
	
	if sprite_frames.has_animation(anim_name):
		_canim = anim_name
		_sscale = speed_scale * abs(custom_speed)
		_dir = -1 if custom_speed < 0 else 1
		_cframe = sprite_frames.get_frame_count(_canim) - 1 if from_end else 0
		_frame_dur = _CalcFrameDuration()
		_UpdateFrame()
		_playing = true

## Plays the animation with key name in reverse.
## [br]
## This method is a shorthand for [method play] with [code]custom_speed = -1.0[/code]
## and [code]from_end = true[/code], so see its description for more information.
func play_backwards(anim_name : StringName = &"") -> void:
	play(anim_name, -1.0, true)

## Pauses the currently playing animation. 
## Calling [method pause], or calling [method play] or [method play_backwards] without arguments
## will resume the animation from the current playback position.
## [br]
## See also [method stop].
func pause() -> void:
	if not _canim.is_empty():
		_playing = not _playing

## Stops the currently playing animation.
## The animation position is reset to [code]0[/code] and the [param custom_speed] is reset to [code]1.0[/code].
## See also [method pause].
func stop() -> void:
	_playing = false
	if not _canim.is_empty():
		_cframe = sprite_frames.get_frame_count(_canim) - 1 if _dir < 0 else 0
		_sscale = speed_scale

## The setter of [member frame] resets the [member frame_progress] to [code]0.0[/code] implicitly, but this method avoids that.[br]
## This is useful when you want to carry over the current [member frame_progress] to another [member frame].
func set_frame_and_progress(frame : int, progress : float) -> void:
	if sprite_frames == null or _canim.is_empty(): return
	var frames : int = sprite_frames.get_frame_count(_canim)
	if frame >= 0 and frame < frames:
		_cframe = frame
		_frame_dur = _CalcFrameDuration() * (1.0 - progress)
		if not auto_play:
			_UpdateFrame()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------



