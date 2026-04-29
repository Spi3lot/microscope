extends Control

@export var antialiasing_button: CheckButton
@export var persistence_slider: Slider
@export var width_slider: Slider
@export var glow_slider: Slider
@export var penalty_slider: Slider
@export var color_picker_button: ColorPickerButton

@export var pan_control: Control
@export var volume_control: Control

@onready var vectorscope: Vectorscope = %Vectorscope

func _ready() -> void:
    antialiasing_button.button_pressed = vectorscope.line_antialiasing
    width_slider.value = vectorscope.line_width
    glow_slider.value = vectorscope.line_glow
    penalty_slider.value = vectorscope.length_penalty
    persistence_slider.value = vectorscope.persistence
    color_picker_button.color = vectorscope.line_color
    get_tree().root.mouse_entered.connect(show)
    get_tree().root.mouse_exited.connect(hide)


func _on_volume_value_changed(value: float) -> void:
    vectorscope.audio_player.volume_db = value
    vectorscope.plot_scale = db_to_linear(value)


func _on_penalty_value_changed(value: float) -> void:
    vectorscope.length_penalty = value


func _on_width_value_changed(value: float) -> void:
    vectorscope.line_width = value


func _on_glow_value_changed(value: float) -> void:
    vectorscope.line_glow = value


func _on_antialiasing_toggled(toggled_on: bool) -> void:
    vectorscope.line_antialiasing = toggled_on


func _on_persistence_value_changed(value: float) -> void:
    vectorscope.persistence = value


func _on_color_changed(color: Color) -> void:
    vectorscope.line_color = color


func _on_pan_value_changed(value: float) -> void:
    var panner: AudioEffectPanner = AudioServer.get_bus_effect(vectorscope.bus_idx, 0)
    panner.pan = value


func _get_error_text(error: Error) -> String:
    match error:
        OK: return ""
        ERR_CANT_OPEN: return "Can't open audio device for loopback"
        ERR_CANT_RESOLVE: return "Can't decode audio stream"
        _: return "An error occurred"
