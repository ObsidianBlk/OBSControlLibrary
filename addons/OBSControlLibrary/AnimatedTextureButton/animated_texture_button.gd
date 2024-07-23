@tool
@icon("res://addons/OBSControlLibrary/AnimatedTextureButton/AnimatedTextureButton.svg")
extends BaseButton
class_name AnimatedTextureButton

## Button displayed using animated sprite frames
##
## Used for creating buttons where the various buttons states are displayed as animations.
## Utilizes a SpriteFrames resourse for texture and animation data. Buttons states are defined
## as the animation within the defined SpriteFrames resource to use for any specific state.


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
## Signal emitted when a non-looped animation finishes.
signal animation_finished(anim_name : StringName)
## Signal emitted when a loop animation finished a sequence and is about to start again.
signal animation_looped(anim_name : StringName)


# ------------------------------------------------------------------------------
# Constants and ENUms
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
## The texture and animations resource used for the visual representations of the button.
@export var sprite_frames : SpriteFrames = null:										set=set_sprite_frames, get=get_sprite_frames
## If true, the size of the texture won't be considered for minimum size calculations, allowing the AnimatedTextureButton to be shrunk down past the texture size.
@export var ignore_texture_size : bool = false:											set=set_ignore_texture_size
## Controls the texture's behaviour when resizing the node's bounding rectangle. 
@export var stretch_mode : TextureHelper.StretchMode = TextureHelper.StretchMode.KEEP:	set=set_stretch_mode
## If true, flips the texture horizontally.
@export var flip_h : bool = false:														set=set_flip_h
## If true, flips the texture vertically.
@export var flip_v : bool = false:														set=set_flip_v
## If true, will play animation in editor window.
@export var playing : bool = true


@export_subgroup("Animations")
## Animation to play by default when not pressed, toggled, or in the hover state.
@export var normal_animation : StringName = &"":		set=set_normal_animation
## Animation to play on mouse down over the node, or the node has keyboard focus and the user pressed the Enter or BaseButton.shortcut key.
@export var pressed_animation : StringName = &"":		set=set_pressed_animation
## Animation to play when pressed on and toggle_mode is true. If animation is not looping, upon completion, the pressed state will become active.
@export var toggle_animation : StringName = &"":		set=set_toggle_animation
## Animation to play when pressed off and toggle_mode is true. If animation is not looping, upon completion, animation will change to normal or hover depending on mouse state.
@export var untoggle_animation : StringName = &"":		set=set_untoggle_animation
## Animation to play when mouse hovers the node.
@export var hover_animation : StringName = &"":			set=set_hover_animation
## Animation to play when node is disabled.
@export var disabled_animation : StringName = &"":		set=set_disabled_animation
## Animation to play when node has mouse or keyboard focus. Animation will be displayed over the base animation.
@export var focused_animation : StringName = &"":		set=set_focused_animation

# NOTE: This is commented out until I fully figure out how to (or if I can) handle animated click masks
# Animation to use for click detection. Each frame of the animation should be pure black and white image.
#@export var click_mask_animation : StringName = &"":	set=set_click_mask_animation

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _sfm : SpriteFramesManager = SpriteFramesManager.new()
var _sfm_focus : SpriteFramesManager = SpriteFramesManager.new()
var _sfm_click_mask : SpriteFramesManager = SpriteFramesManager.new()
var _mouse_hover : bool = false
var _lock_animation : bool = false
var _toggled : bool = false

# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_sprite_frames(sf : SpriteFrames) -> void:
	_sfm.sprite_frames = sf

func get_sprite_frames() -> SpriteFrames:
	return _sfm.sprite_frames

func set_ignore_texture_size(its : bool) -> void:
	ignore_texture_size = its
	update_minimum_size()
	queue_redraw()

func set_stretch_mode(sm : TextureHelper.StretchMode) -> void:
	stretch_mode = sm
	queue_redraw()
	update_minimum_size()

func set_flip_h(fh : bool) -> void:
	flip_h = fh
	queue_redraw()

func set_flip_v(fv : bool) -> void:
	flip_v = fv
	queue_redraw()

func set_playing(p : bool) -> void:
	playing = p
	_sfm.auto_play = playing
	_sfm_focus.auto_play = playing
	_sfm_click_mask.auto_play = playing

func set_normal_animation(anim_name : StringName) -> void:
	normal_animation = anim_name
	_UpdateActiveAnimation()

func set_pressed_animation(anim_name : StringName) -> void:
	pressed_animation = anim_name
	_UpdateActiveAnimation()

func set_toggle_animation(anim_name : StringName) -> void:
	toggle_animation = anim_name
	_UpdateActiveAnimation()

func set_untoggle_animation(anim_name : StringName) -> void:
	untoggle_animation = anim_name
	_UpdateActiveAnimation()

func set_hover_animation(anim_name : StringName) -> void:
	hover_animation = anim_name
	_UpdateActiveAnimation()

func set_disabled_animation(anim_name : StringName) -> void:
	disabled_animation = anim_name
	_UpdateActiveAnimation()

func set_focused_animation(anim_name : StringName) -> void:
	focused_animation = anim_name
	if focused_animation.is_empty():
		_sfm_focus.sprite_frames = null
	else:
		_sfm_focus.sprite_frames = sprite_frames
		_sfm_focus.animation = focused_animation

#func set_click_mask_animation(anim_name : StringName) -> void:
	#click_mask_animation = anim_name
	#if click_mask_animation.is_empty():
		#_sfm_click_mask.sprite_frames = null
	#else:
		#_sfm_click_mask.sprite_frames = sprite_frames
		#_sfm_click_mask.animation = click_mask_animation

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_sfm.texture_changed.connect(_on_texture_changed)
	_sfm_focus.texture_changed.connect(_on_texture_changed)
	_sfm_click_mask.texture_changed.connect(_on_texture_changed.bind(false))
	toggled.connect(_on_self_button_toggled)
	pressed.connect(_on_self_button_pressed)
	_UpdateActiveAnimation()

func _process(delta : float) -> void:
	if not playing: return
	var res : SpriteFramesManager.AnimationState = _sfm.update_animation(delta)
	_EmitSignalByState(_sfm.animation, res)
	
	res = _sfm_focus.update_animation(delta)
	_EmitSignalByState(_sfm_focus.animation, res)

func _get_minimum_size() -> Vector2:
	var msize : Vector2 = Vector2.ZERO
	
	if not ignore_texture_size:
		var tex : Texture2D = _sfm.get_texture()
		if tex == null:
			tex = _sfm_click_mask.get_texture()
		
		if tex != null:
			msize = tex.get_size()
	
	return msize.abs()

func _draw() -> void:
	var texture : Texture2D = _sfm.get_texture()
	var focus_texture : Texture2D = _sfm_focus.get_texture()
	
	var draw_focused : bool = focus_texture != null and has_focus()
	var draw_focused_only : bool = texture == null and draw_focused
	
	var tex : Texture2D = texture if texture != null else focus_texture
	
	var sdata : Dictionary = {}
	if tex != null:
		sdata = TextureHelper.Get_Texture_Stretch_Data(
			tex,
			get_size(),
			stretch_mode,
			flip_h, flip_v
		)
	if sdata.is_empty(): return
	
	if not draw_focused_only:
		if sdata.tiled:
			draw_texture_rect(tex, sdata.rect, true)
		else:
			draw_texture_rect_region(tex, sdata.rect, sdata.region)
	
	if draw_focused:
		draw_texture_rect(focus_texture, sdata.rect, sdata.tiled)

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT:
			queue_redraw()
		NOTIFICATION_MOUSE_ENTER:
			_mouse_hover = true
			_UpdateActiveAnimation()
			update_minimum_size()
		NOTIFICATION_MOUSE_EXIT:
			_mouse_hover = false
			_UpdateActiveAnimation()
		NOTIFICATION_RESIZED:
			update_minimum_size()
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()
			update_minimum_size()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _EmitSignalByState(anim_name : StringName, anim_state : SpriteFramesManager.AnimationState) -> void:
	match anim_state:
		SpriteFramesManager.AnimationState.FINISHED:
			animation_finished.emit(anim_name)
		SpriteFramesManager.AnimationState.LOOPED:
			animation_looped.emit(anim_name)

func _UpdateActiveAnimation() -> void:
	if _lock_animation: return
	
	if disabled:
		if not disabled_animation.is_empty() and _sfm.animation != disabled_animation:
			_sfm.animation = disabled_animation
			return
	
	elif button_pressed:
		if toggle_mode:
			if not toggle_animation.is_empty() and _sfm.animation != toggle_animation:
				_sfm.animation = toggle_animation
				return
		else:
			if not pressed_animation.is_empty() and _sfm.animation != pressed_animation:
				_sfm.animation = pressed_animation
				return
	
	elif _mouse_hover:
		if not hover_animation.is_empty() and _sfm.animation != hover_animation:
			_sfm.animation = hover_animation
			return
	
	else:
		if not normal_animation.is_empty() and _sfm.animation != normal_animation:
			_sfm.animation = normal_animation
			return

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_texture_changed(texture : Texture2D, redraw : bool = true) -> void:
	if redraw:
		queue_redraw()
	update_minimum_size()

func _on_self_button_pressed() -> void:
	if disabled or not _sfm.has_animation(pressed_animation): return
	if toggle_mode: return
	_sfm.begin_animation(pressed_animation)
	if not _sfm.is_animation_looped():
		_lock_animation = true
		await _sfm.animation_finished
		_lock_animation = false
	_UpdateActiveAnimation()


func _on_self_button_toggled(toggle_on : bool) -> void:
	if disabled: return
	if toggle_on:
		if not _toggled:
			_toggled = true
			if _sfm.has_animation(toggle_animation):
				_sfm.begin_animation(toggle_animation)
				if not _sfm.is_animation_looped():
					_lock_animation = true
					await _sfm.animation_finished
					_lock_animation = false
			_UpdateActiveAnimation()
	else:
		_toggled = false
		if _sfm.has_animation(untoggle_animation):
			_sfm.begin_animation(untoggle_animation)
			if not _sfm.is_animation_looped():
				_lock_animation = true
				await _sfm.animation_finished
				_lock_animation = false
		_UpdateActiveAnimation()
