extends Control

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANIM_IDLE : StringName = &"idle"
const ANIM_RUN : StringName = &"run"

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _slideout_container : SlideoutContainer = %SlideoutContainer
@onready var _atex_rect: AnimatedTextureRect = %AnimatedTextureRect

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
