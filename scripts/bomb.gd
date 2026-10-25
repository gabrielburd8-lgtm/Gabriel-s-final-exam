extends Node2D

signal bomb_exploded(bomb, explosion_position, explosion_radius)

var countdown := 2.6
var explosion_radius := 100.0
var active := true

func _ready() -> void:
    _refresh_visuals()

func _process(delta: float) -> void:
    if not active:
        return

    countdown -= delta
    _refresh_visuals()

    if countdown <= 0.0:
        active = false
        emit_signal("bomb_exploded", self, global_position, explosion_radius)
        queue_free()

func _refresh_visuals() -> void:
    if not is_inside_tree():
        return

    $Body.polygon = _circle_points(16, 20)
    $Body.color = Color(0.92, 0.48, 0.1, 1.0)

    if countdown <= 1.0:
        $Body.color = Color(1.0, 0.25, 0.25, 1.0)

    var label_text := str(max(1, int(ceil(countdown))))
    $CountdownLabel.text = label_text

    var warning_scale := 1.0 + (1.0 - countdown / 2.6) * 0.2
    scale = Vector2(warning_scale, warning_scale)

    queue_redraw()

func _draw() -> void:
    if countdown <= 1.2:
        var warning_color := Color(1.0, 0.2, 0.2, 0.35)
        draw_arc(Vector2.ZERO, explosion_radius, 0.0, TAU, 80, warning_color, 3.0)

func _circle_points(radius: float, steps: int) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(steps):
        var angle := TAU * float(i) / float(steps)
        points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
    return points
