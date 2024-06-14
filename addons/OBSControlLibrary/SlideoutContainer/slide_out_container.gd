@tool
@icon("res://addons/OBSControlLibrary/SlideoutContainer/SlideoutContainer.svg")
extends Container
class_name SlideoutContainer


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal slide_started()
signal slide_finished()
signal slide_interrupted()


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
enum InitialAction {NONE=0, SLIDE_IN_VIEW=1, SLIDE_FROM_VIEW=2}
enum SlideEdge {TOP=0, RIGHT=1, BOTTOM=2, LEFT=3}
const DURATION_THRESHOLD : float = 0.0001

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("SlideoutContainer")
@export var initial_action : InitialAction = InitialAction.NONE
@export_subgroup("Setup")
@export var slide_edge : SlideEdge = SlideEdge.TOP:			set=set_slide_edge
@export var slide_duration : float = 0.0:					set=set_slide_duration
@export_range(0.0, 1.0) var slide_amount : float = 0.0:		set=set_slide_amount
@export var slide_from_viewport : bool = true:				set=set_slide_from_viewport

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _child_info : Dictionary = {}
var _tween : Tween = null
var _to_hidden : bool = false

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
func slide_to(target : float, duration : float = 0.0) -> void:
	stop_slide()
	
	if Engine.is_editor_hint():
		duration = 0.0
	elif duration < DURATION_THRESHOLD:
		duration = slide_duration
	
	target = clampf(target, 0.0, 1.0)
	
	var dist : float = abs(target - slide_amount)
	if dist <= 0.0001: return
	
	var dur : float = dist * duration
	
	if dur <= DURATION_THRESHOLD:
		slide_amount = target
	else:
		slide_started.emit()
		_tween = create_tween()
		_tween.tween_property(self, "slide_amount", target, dur)
		await _tween.finished
	slide_finished.emit()

func slide_in(duration : float = 0.0) -> void:
	slide_to(0.0, duration)

func slide_out(duration : float = 0.0) -> void:
	slide_to(1.0, duration)

func is_sliding() -> bool:
	return _tween != null

func stop_slide() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
		slide_interrupted.emit()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_tween_update(amount_hidden : float) -> void:
	slide_amount = amount_hidden
	for cinfo : Dictionary in _child_info:
		_UpdateChildOffset(cinfo.node, amount_hidden)

