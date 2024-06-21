@tool
extends Button
class_name AnimatedTextureButton

# TODO: To support the <finish_before_transition> property, I may need to overload the
#   _gui_input() method... not sure yet.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal animation_finished(anim_name : StringName)
signal animation_looped(anim_name : StringName)


# ------------------------------------------------------------------------------
# Constants and ENUms
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var sprite_frames : SpriteFrames = null:										set=set_sprite_frames, get=get_sprite_frames
@export var ignore_texture_size : bool = false:											set=set_ignore_texture_size
@export var stretch_mode : TextureHelper.StretchMode = TextureHelper.StretchMode.KEEP:	set=set_stretch_mode
@export var flip_h : bool = false:														set=set_flip_h
@export var flip_v : bool = false:														set=set_flip_v
@export var playing : bool = true

@export_subgroup("Animations")
@export var finish_before_transition : bool = false
@export var normal_animation : StringName = &"":		set=set_normal_animation
@export var pressed_animation : StringName = &"":		set=set_pressed_animation
@export var hover_animation : StringName = &"":			set=set_hover_animation
@export var disabled_animation : StringName = &"":		set=set_disabled_animation
@export var focused_animation : StringName = &"":		set=set_focused_animation
@export var click_mask_animation : StringName = &"":	set=set_click_mask_animation

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _sfm : SpriteFramesManager = SpriteFramesManager.new()
var _sfm_focus : SpriteFramesManager = SpriteFramesManager.new()
var _sfm_click_mask : SpriteFramesManager = SpriteFramesManager.new()
var _mouse_hover : bool = false

# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_sprite_frames(sf : SpriteFrames) -> void:
	_sfm.sprite_frames = sf

func get_sprite_frames() -> SpriteFrames:
	return _sfm.sprite_frames

func set_ignore_texture_size(its : bool) -> void:
	ignore_texture_size = its
	queue_redraw()
	update_minimum_size()

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

func set_normal_animation(anim_name : StringName) -> void:
	normal_animation = anim_name
	_UpdateActiveEditorAnimation()

func set_pressed_animation(anim_name : StringName) -> void:
	pressed_animation = anim_name
	_UpdateActiveEditorAnimation()

func set_hover_animation(anim_name : StringName) -> void:
	hover_animation = anim_name
	_UpdateActiveEditorAnimation()

func set_disabled_animation(anim_name : StringName) -> void:
	disabled_animation = anim_name
	_UpdateActiveEditorAnimation()

func set_focused_animation(anim_name : StringName) -> void:
	focused_animation = anim_name
	if focused_animation.is_empty():
		_sfm_focus.sprite_frames = null
	else:
		_sfm_focus.sprite_frames = sprite_frames
		_sfm_focus.animation = focused_animation

func set_click_mask_animation(anim_name : StringName) -> void:
	click_mask_animation = anim_name
	if click_mask_animation.is_empty():
		_sfm_click_mask.sprite_frames = null
	else:
		_sfm_click_mask.sprite_frames = sprite_frames
		_sfm_click_mask.animation = click_mask_animation

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_sfm.texture_changed.connect(_on_texture_changed)
	_sfm_focus.texture_changed.connect(_on_texture_changed)
	_sfm_click_mask.texture_changed.connect(_on_texture_changed.bind(false))

func _process(delta : float) -> void:
	if not playing: return
	var res : SpriteFramesManager.AnimationState = _sfm.update_animation(delta)
	_EmitSignalByState(_sfm.animation, res)
	
	res = _sfm_focus.update_animation(delta)
	_EmitSignalByState(_sfm_focus.animation, res)

func _get_minimum_size() -> Vector2:
	var msize : Vector2 = super.get_minimum_size()
	
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
	
	var draw_focused : bool = focus_texture.is_valid() and has_focus()
	var draw_focused_only : bool = not texture.is_valid() and draw_focused
	
	var tex : Texture2D = texture if texture.is_valid() else focus_texture
	
	var sdata : Dictionary = {}
	if tex.is_valid():
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
			if disabled:
				_sfm.begin_animation(disabled_animation)
			else:
				_sfm.begin_animation(hover_animation)
		NOTIFICATION_MOUSE_EXIT:
			_mouse_hover = false
			if disabled:
				_sfm.begin_animation(disabled_animation)
			elif not button_pressed:
				_sfm.begin_animation(normal_animation)
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

func _UpdateActiveEditorAnimation() -> void:
	if not Engine.is_editor_hint(): return
	
	if not normal_animation.is_empty():
		_sfm.animation = normal_animation
		return
	
	if not hover_animation.is_empty():
		_sfm.animation = hover_animation
		return
	
	if not pressed_animation.is_empty():
		_sfm.animation = pressed_animation
		return
	
	if not disabled_animation.is_empty():
		_sfm.animation = disabled_animation
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

func _on_self_button_toggled(toggle_on : bool) -> void:
	if disabled: return
	if _mouse_hover:
		_sfm.begin_animation(hover_animation)
	else:
		_sfm.begin_animation(normal_animation)
	
