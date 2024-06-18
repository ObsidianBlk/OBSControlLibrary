@tool
@icon("res://addons/OBSControlLibrary/AnimatedTextureRect/AnimatedTextureRect.svg")
extends Control
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
@export var speed_scale : float = 1.0:							set = set_speed_scale
@export var auto_play : bool = false:							set = set_auto_play

@export_subgroup("Display")
@export var stretch_mode : TextureRect.StretchMode = TextureRect.STRETCH_KEEP:		set=set_stretch_mode
@export var expand_mode : TextureRect.ExpandMode = TextureRect.EXPAND_KEEP_SIZE:	set=set_expand_mode
@export var flip_h : bool = false:													set=set_flip_h
@export var flip_v : bool = false:													set=set_flip_v

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
		if sprite_frames.has_animation(animation) and auto_play:
			play(animation)
	else:
		_texture = null
		queue_redraw()
		update_minimum_size()

func set_speed_scale(s : float) -> void:
	if s >= 0.0:
		speed_scale = s

func set_animation(anim_name : StringName) -> void:
	animation = anim_name
	if sprite_frames != null:
		if sprite_frames.has_animation(animation):
			if not Engine.is_editor_hint(): return
			if auto_play:
				play(animation)


func set_auto_play(ap : bool) -> void:
	auto_play = ap
	if not Engine.is_editor_hint(): return
	if auto_play and sprite_frames != null and sprite_frames.has_animation(animation):
		play(animation)

func set_flip_h(f : bool) -> void:
	flip_h = f
	queue_redraw()

func set_flip_v(f : bool) -> void:
	flip_v = f
	queue_redraw()

func set_stretch_mode(mode : TextureRect.StretchMode) -> void:
	if mode != stretch_mode:
		stretch_mode = mode
		queue_redraw()
		update_minimum_size()

func set_expand_mode(mode : TextureRect.ExpandMode) -> void:
	if mode != expand_mode:
		expand_mode = mode
		queue_redraw()
		update_minimum_size()

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

func _notification(what : int) -> void:
	match (what):
		NOTIFICATION_RESIZED:
			update_minimum_size()

func _draw() -> void:
	if _texture == null: return
	
	var tex_size : Vector2 = Vector2.ZERO
	var tex_pos : Vector2 = Vector2.ZERO
	var region : Rect2 = Rect2()
	var tile : bool = false
	
	match(stretch_mode):
		TextureRect.STRETCH_SCALE:
			tex_size = get_size()
		TextureRect.STRETCH_TILE:
			tex_size = get_size()
			tile = true
		TextureRect.STRETCH_KEEP:
			tex_size = _texture.get_size()
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT:
			var csize : Vector2 = get_size()
			var tw : float = _texture.get_width() * (csize.y / _texture.get_height())
			var th : float = csize.y
			
			if tw > csize.x:
				tw = csize.x
				th = _texture.get_height() * (csize.x / _texture.get_width())
			
			if stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
				tex_pos = Vector2(
					(csize.x - tw) * 0.5,
					(csize.y - th) * 0.5
				)
			
			tex_size.x = tw
			tex_size.y = th
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			var csize : Vector2 = get_size()
			var tsize : Vector2 = _texture.get_size()
			var scale_size : Vector2 = Vector2(
				csize.x / tsize.x,
				csize.y / tsize.y
			)
			var nscale : float = max(scale_size.x, scale_size.y)
			tex_size = tsize * nscale
			region.position = ((tex_size - csize) / nscale).abs() * 2.0
			region.size = csize / nscale
		
	#if not region.has_area():
		#var scale_size : Vector2 = Vector2(
			#tex_size.x / _texture.get_width(),
			#tex_size.y / _texture.get_height()
		#)
		#if flip_h:
			#tex_pos = _texture
		#Size2 scale_size(size.width / texture->get_width(), size.height / texture->get_height());
		#offset.width += hflip ? p_atlas->get_margin().get_position().width * scale_size.width * 2 : 0;
		#offset.height += vflip ? p_atlas->get_margin().get_position().height * scale_size.height * 2 : 0;
	
	tex_size.x *= -1.0 if flip_h else 1.0
	tex_size.y *= -1.0 if flip_v else 1.0
	
	if region.has_area():
		draw_texture_rect_region(_texture, Rect2(tex_pos, tex_size), region)
	else:
		draw_texture_rect(_texture, Rect2(tex_pos, tex_size), tile)


func _get_minimum_size() -> Vector2:
	if _texture != null:
		match(expand_mode):
			TextureRect.EXPAND_KEEP_SIZE:
				return _texture.get_size()
			TextureRect.EXPAND_IGNORE_SIZE:
				return Vector2.ZERO
			TextureRect.EXPAND_FIT_WIDTH:
				return Vector2(get_size().y, 0)
			TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL:
				var ratio : float = _texture.get_width() / _texture.get_height()
				return Vector2(get_size().y * ratio, 0)
			TextureRect.EXPAND_FIT_HEIGHT:
				return Vector2(0, get_size().x)
			TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL:
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



