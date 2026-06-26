@tool
extends PanelContainer

var _fade_after: float = 3.0
var _fading: bool = false
var _fade_duration: float = 1.0
var _fade_timer: float = 0.0
var _paused: bool = false

var interactable: bool = true

func _ready() -> void:
	if interactable:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_paused = true

func _on_mouse_exited() -> void:
	_paused = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fading = true
		_fade_timer = _fade_duration

func _process(delta: float) -> void:
	if not _fading and not _paused:
		_fade_after -= delta
		if _fade_after <= 0.0 and _fade_timer <= 0.0:
			_fade_timer = _fade_duration
			_fading = true
	
	if _fading:
		if _fade_timer > 0.0:
			_fade_timer -= delta
			var alpha = clamp(_fade_timer / _fade_duration, 0.0, 1.0)
			modulate.a = alpha
		else:
			queue_free()
