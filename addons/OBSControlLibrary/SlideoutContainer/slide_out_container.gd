@tool
@icon("res://addons/OBSControlLibrary/SlideoutContainer/SlideoutContainer.svg")
extends Container
class_name SlideoutContainer

## A Container that tweens an offset of child positions outside of the container or the viewport.
##
## Container will take up the amount of space required to fit all children with their combined minimum
## sizes and anchors. Primarily to be used to offset those children from inside the container
## (see [member slide_amount]) to either outside the container or outside the viewport
## (see [member slide_from_viewport).

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
## Signal emitted when a slide is about to start.
signal slide_started()

## Signal emitted when a slide tween finishes.
signal slide_finished()

## Signal emitted when a slide tween is interrupted or stopped.
signal slide_interrupted()


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
## The initial tween state of the container.
enum InitialAction {
	## The container will not automatically begin a slide tween.
	NONE=0,
	
	## The container will automatically slide children from outside the container (or viewport) to inside the container.
	SLIDE_IN_VIEW=1,
	
	## The container will automatically slide children from inside the container to outside the container (or viewport).
	SLIDE_FROM_VIEW=2
}

## The edge off which children will be offset when sliding.
enum SlideEdge {
	## The container's top edge.
	TOP=0,
	## The container's right edge.
	RIGHT=1,
	## The container's Bottom edge.
	BOTTOM=2,
	## The container's left edge.
	LEFT=3
}

const DURATION_THRESHOLD : float = 0.0001

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
## The action the container will take at initialization. (Default to [enum InitialAction.NONE])
@export var initial_action : InitialAction = InitialAction.NONE


@export_subgroup("Config")
## The edge children will be offset during a slide.
@export var slide_edge : SlideEdge = SlideEdge.TOP:			set=set_slide_edge

## The duration (in seconds) of a complete slide (from [code]0.0[/code] to [code]1.0[/code] or vice versa) will take to complete.
@export var slide_duration : float = 0.0:					set=set_slide_duration

## The relative offset of the children in the container.[br][br]
## A value of [code]0.0[/code] is completely within the container.[br][br]
## A value of [code]1.0[/code] is completely outside of the container (or viewport).
@export_range(0.0, 1.0) var slide_amount : float = 0.0:		set=set_slide_amount

## If [code]true[/code] the [member slide_amount] will offset the children between the container and outside the viewport.[br]
## If [code]false[/code] the [member slide_amount] will offset the children between the container and outside the container.
@export var slide_from_viewport : bool = true:				set=set_slide_from_viewport


@export_subgroup("Tweening")
## The transition type to use during a slide tween. [b]NOTE:[/b] This value is ignored if a [member custom_curve]
## is defined.
@export var transition_type : Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR:	set=set_transition_type

## The easing type to use during a slide tween.[b]NOTE:[/b] This value is ignored if a [member custom_curve]
## is defined.
@export var ease_type : Tween.EaseType = Tween.EaseType.EASE_IN:						set=set_ease_type

## [b](OPTIONAL)[/b] A custom curve used to determine the [member slide_amount] during a slide tween.[br][br]
## If left undefined, the [member transition_type] and [member ease type] will be used.
@export var custom_curve : Curve = null:												set=set_custom_curve

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _child_info : Dictionary = {}
var _tween : Tween = null
var _to_target : float = 0.0

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_slide_edge(e : SlideEdge) -> void:
	slide_edge = e
	_UpdateChildrenOffsets(slide_amount)

func set_slide_duration(d : float) -> void:
	if d >= 0.0:
		slide_duration = d

func set_slide_amount(a : float) -> void:
	slide_amount = clampf(a, 0.0, 1.0)
	_UpdateChildrenOffsets(slide_amount)

func set_slide_from_viewport(sfv : bool) -> void:
	slide_from_viewport = sfv
	_UpdateChildrenOffsets(slide_amount)

func set_transition_type(t : Tween.TransitionType) -> void:
	transition_type = t
	if _tween != null and custom_curve == null:
		slide_to(_to_target)

func set_ease_type(e : Tween.EaseType) -> void:
	ease_type = e
	if _tween != null and custom_curve == null:
		slide_to(_to_target)

func set_custom_curve(c : Curve) -> void:
	custom_curve = c
	if custom_curve != null:
		if _tween == null:
			_UpdateChildrenOffsets(slide_amount)
	elif _tween != null:
		slide_to(_to_target)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if not Engine.is_editor_hint():
		match initial_action:
			InitialAction.SLIDE_IN_VIEW:
				slide_in()
			InitialAction.SLIDE_FROM_VIEW:
				slide_out()

func _enter_tree() -> void:
	var view : Viewport = get_viewport()
	if view == null: return
	if not view.size_changed.is_connected(_on_viewport_size_changed):
		view.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	var view : Viewport = get_viewport()
	if view == null: return
	if view.size_changed.is_connected(_on_viewport_size_changed):
		view.size_changed.disconnect(_on_viewport_size_changed)

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_SortChildren()

func _get_minimum_size() -> Vector2:
	var min_size : Vector2 = Vector2.ZERO
	for child : Node in get_children():
		if not child is Control: continue
		if not child.visible or child.top_level: continue
		var cms : Vector2 = child.get_combined_minimum_size()
		min_size.x = max(min_size.x, cms.x)
		min_size.y = max(min_size.y, cms.y)
	return min_size

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SortChildren() -> void:
	var csize : Vector2 = get_size()
	var rect : Rect2 = Rect2(Vector2.ZERO, csize)
	
	for child : Node in get_children():
		if child is Control:
			if not child.visible or child.top_level:
				_DropChildInfo(child.name)
			else:
				fit_child_in_rect(child, rect)
				_UpdateChildRect(child)
				_UpdateChildOffset(child, slide_amount)

func _DropChildInfo(child_name : StringName) -> void:
	if child_name in _child_info:
		_child_info.erase(child_name)

func _UpdateChildRect(child : Control) -> void:
	if not child.name in _child_info:
		_child_info[child.name] = {"node": child, "rect": Rect2()}
	_child_info[child.name].rect = child.get_rect()

func _UpdateChildOffset(child : Control, amount_hidden : float) -> void:
	if not child.name in _child_info: return
	amount_hidden = clampf(amount_hidden, 0.0, 1.0)
	if custom_curve != null:
		amount_hidden = custom_curve.sample(amount_hidden)
	var container_size : Vector2 = get_size()
	var crect : Rect2 = _child_info[child.name].rect
	var pvr : Rect2 = get_viewport_rect()
	var pos : Vector2 = crect.position
	var target_pos : Vector2 = crect.position
	
	match slide_edge:
		SlideEdge.TOP:
			if slide_from_viewport:
				target_pos.y = (-global_position.y) - crect.size.y
			else:
				target_pos.y = -crect.size.y
		SlideEdge.LEFT:
			if slide_from_viewport:
				target_pos.x = (-global_position.x) - crect.size.x
			else:
				target_pos.x = -crect.size.x
		SlideEdge.BOTTOM:
			if slide_from_viewport:
				target_pos.y = (pvr.size.y - global_position.y) - crect.position.y
			else:
				target_pos.y = container_size.y
		SlideEdge.RIGHT:
			if slide_from_viewport:
				target_pos.x = (pvr.size.x - global_position.x) - crect.position.x
			else:
				target_pos.x = container_size.x
	
	var dist : Vector2 = target_pos - pos
	child.position = crect.position + (dist * amount_hidden)

func _UpdateChildrenOffsets(amount_hidden : float) -> void:
	for child : Node in get_children():
		if child is Control:
			if not child.name in _child_info: continue
			_UpdateChildOffset(child, slide_amount)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
## Initiates a slide for all children within the container.[br][br]
## [param target] - The target relative offset (see [member slide_amount]) to tween to.[br][br]
## [param duration] - [i](Optional)[/i] The duration (in seconds) a tween from [code]0.0[/code] to [code]1.0[/code] (and vice versa) should take.[br]
##    If no value given (or the value is less than or equal to [code]0.0[/code]), the value [member slide_duration] will be used.[br]
##    [b]NOTE:[/b] The actual duration is adjusted for the existing offset of the children.[br][br]
## [param ignore_distance] = [i](Optional)[/i] If [code]true[/code], duration will [i]NOT[/i] be adjusted for distance. 
func slide_to(target : float, duration : float = 0.0, ignore_distance : bool = false) -> void:
	stop_slide()
	
	if Engine.is_editor_hint():
		duration = 0.0
	elif duration < DURATION_THRESHOLD:
		duration = slide_duration
	
	target = clampf(target, 0.0, 1.0)
	_to_target = target
	
	var dist : float = abs(target - slide_amount)
	if dist <= 0.0001: return
	
	var dur : float = duration if ignore_distance else dist * duration
	
	if dur <= DURATION_THRESHOLD:
		slide_amount = target
	else:
		slide_started.emit()
		_tween = create_tween()
		if custom_curve == null:
			_tween.set_trans(transition_type)
			_tween.set_ease(ease_type)
		_tween.tween_property(self, "slide_amount", target, dur)
		await _tween.finished
		_tween = null
	slide_finished.emit()

## Slides all children into the container.[br]
## This is equivolent to [code]slide_to(0.0, duration, ignore_distance)[/code][br][br]
## [param duration] - [i](Optional)[/i] The duration (in seconds) a tween from [code]0.0[/code] to [code]1.0[/code] (and vice versa) should take.[br]
##    If no value given (or the value is less than or equal to [code]0.0[/code]), the value [member slide_duration] will be used.[br]
##    [b]NOTE:[/b] The actual duration is adjusted for the existing offset of the children.[br][br]
## [param ignore_distance] = [i](Optional)[/i] If [code]true[/code], duration will [i]NOT[/i] be adjusted for distance.
func slide_in(duration : float = 0.0, ignore_distance : bool = false) -> void:
	slide_to(0.0, duration, ignore_distance)

## Slides all children outside of the container (or viewport).[br]
## This is equivolent to [code]slide_to(1.0, duration, ignore_distance)[/code][br][br]
## [param duration] - [i](Optional)[/i] The duration (in seconds) a tween from [code]0.0[/code] to [code]1.0[/code] (and vice versa) should take.[br]
##    If no value given (or the value is less than or equal to [code]0.0[/code]), the value [member slide_duration] will be used.[br]
##    [b]NOTE:[/b] The actual duration is adjusted for the existing offset of the children.[br][br]
## [param ignore_distance] = [i](Optional)[/i] If [code]true[/code], duration will [i]NOT[/i] be adjusted for distance.
func slide_out(duration : float = 0.0, ignore_distance : bool = false) -> void:
	slide_to(1.0, duration, ignore_distance)

## Returns [code]true[/code] if a slide tween is active.[br]
## Returns [code]false[/code] if no slide tween is active.
func is_sliding() -> bool:
	return _tween != null

## Stops any active slide tween. Childrens' offsets will remain where they were at the point the slide
## was stopped.
func stop_slide() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
		slide_interrupted.emit()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_viewport_size_changed() -> void:
	_UpdateChildrenOffsets.call_deferred(slide_amount)

#func _on_tween_update(amount_hidden : float) -> void:
	#slide_amount = amount_hidden
	#for cinfo : Dictionary in _child_info:
		#_UpdateChildOffset(cinfo.node, amount_hidden)

