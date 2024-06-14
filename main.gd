extends Control


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _slideout_container : SlideoutContainer = %SlideoutContainer


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_btn_slide_in_pressed():
	if _slideout_container == null: return
	_slideout_container.slide_in()

func _on_btn_slide_out_pressed():
	if _slideout_container == null: return
	_slideout_container.slide_out()
