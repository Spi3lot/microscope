@tool
extends Control
class_name Vectorscope

@export_group("Configuration")
@export_range(0.01, 10.0, 0.01) var buffer_length := 0.1:
    set(value):
        buffer_length = value
        if capture: capture.buffer_length = value

@export var line_antialiasing := true:
    set(value):
        line_antialiasing = value
        _optimize_line_width()

        if line_antialiasing and line_width < 0:
            line_width = 1.0

@export_range(1.0, 10.0) var line_width := 1.0:
    set(value):
        line_width = value
        _optimize_line_width()

@export_range(0.0, 1.0) var line_glow := 0.25
@export_range(0.0, 100.0) var length_penalty := 20.0
@export_range(0.0, 1.0)  var persistence := 0.5
@export var line_color := Color.GREEN

@export_group("Nodes")
@export var audio_player: AudioStreamPlayer
@export var sub_viewport_container: FixedSubViewportContainer

const ZOOM_FACTOR := 4.0 / 3.0
const MAX_ZOOM := 64.0
const MAX_SCALE := Vector2(MAX_ZOOM, MAX_ZOOM)

var plot_scale := 1.0
var vector_transform := Transform2D.IDENTITY

@onready var bus_idx := AudioServer.get_bus_index(&"Player")
@onready var capture_idx := AudioServer.get_bus_effect_count(bus_idx) - 1
@onready var capture: AudioEffectCapture = AudioServer.get_bus_effect(bus_idx, capture_idx)

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    get_window().size_changed.connect(_clear_sub_viewport)


func _unhandled_input(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        return

    if event is InputEventMouseMotion and not is_zero_approx(event.pressure):
        _handle_input_event_mouse_motion(event)
    elif event is InputEventMouseButton and event.pressed:
        _handle_input_event_mouse_button(event)
    elif event is InputEventKey and event.pressed and not event.echo:
        _handle_input_event_key(event)


func _handle_input_event_mouse_motion(event: InputEventMouseMotion) -> void:
    vector_transform.origin += event.relative


func _handle_input_event_mouse_button(event: InputEventMouseButton) -> void:
    match event.button_index:
        MouseButton.MOUSE_BUTTON_WHEEL_UP: _apply_zoom(ZOOM_FACTOR)
        MouseButton.MOUSE_BUTTON_WHEEL_DOWN: _apply_zoom(1.0 / ZOOM_FACTOR)
        MouseButton.MOUSE_BUTTON_MIDDLE: _reset_zoom()


func _handle_input_event_key(event: InputEventKey) -> void:
    match event.keycode:
        KEY_R:
            _reset_zoom()


func _apply_zoom(multiplier: float) -> void:
    var mouse_pos := sub_viewport_container.get_local_mouse_position()

    var trans := Transform2D() \
        .translated(-mouse_pos) \
        .scaled(Vector2(multiplier, multiplier)) \
        .translated(mouse_pos)

    vector_transform = trans * vector_transform


func _reset_zoom() -> void:
    vector_transform = Transform2D.IDENTITY


func _clear_sub_viewport():
    sub_viewport_container.sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE


func _optimize_line_width() -> void:
    if not line_antialiasing and is_equal_approx(line_width, 1.0):
        line_width = -1.0
