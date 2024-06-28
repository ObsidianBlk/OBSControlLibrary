extends Control

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANIM_IDLE : StringName = &"idle"
const ANIM_RUN : StringName = &"run"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _button_group : ButtonGroup = ButtonGroup.new()

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _slideout_container : SlideoutContainer = %SlideoutContainer
@onready var _atex_rect: AnimatedTextureRect = %AnimatedTextureRect
@onready var _abtn_toggle_1 : AnimatedTextureButton = %ABTN_Toggle_1
@onready var _abtn_toggle_2 : AnimatedTextureButton = %ABTN_Toggle_2
@onready var _abtn_toggle_3 : AnimatedTextureButton = %ABTN_Toggle_3

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_abtn_toggle_1.button_group = _button_group
	_abtn_toggle_2.button_group = _button_group
	_abtn_toggle_3.button_group = _button_group

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_slide_ended() -> void:
	_atex_rect.play(ANIM_IDLE)

func _on_btn_slide_in_pressed():
	if _slideout_container == null: return
	if _slideout_container.slide_amount > 0.05 and not _slideout_container.is_sliding():
		_atex_rect.play(ANIM_RUN)
		_atex_rect.flip_h = false
		_slideout_container.slide_in()

func _on_btn_slide_out_pressed():
	if _slideout_container == null: return
	if _slideout_container.slide_amount < 0.95 and not _slideout_container.is_sliding():
		_atex_rect.play(ANIM_RUN)
		_atex_rect.flip_h = true
		_slideout_container.slide_out()
