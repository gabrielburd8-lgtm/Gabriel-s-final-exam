extends Node2D

var kind := "dash"
var color_value := Color(1.0, 0.2, 0.2)

func _ready() -> void:
    _refresh_visuals()

func setup(type_name: String, color: Color) -> void:
    kind = type_name
    color_value = color
    _refresh_visuals()

func _refresh_visuals() -> void:
    if not is_inside_tree():
        return

    var points := PackedVector2Array()
    points = PackedVector2Array([
        Vector2(0, -18),
        Vector2(18, 0),
        Vector2(0, 18),
        Vector2(-18, 0),
    ])
    $Body.polygon = points
    $Body.color = color_value
    $Label.text = kind.to_upper()
    $Label.position = Vector2(-26, -20)
