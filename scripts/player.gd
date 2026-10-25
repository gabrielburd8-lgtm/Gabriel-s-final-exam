extends Node2D

const ARENA_POS := Vector2(160, 90)
const ARENA_SIZE := Vector2(960, 540)
const BOMB_LIMIT := 20
const STARTING_BOMBS := 8
const BOMB_SPAWN_INTERVAL := 0.6
const PICKUP_SPAWN_INTERVAL := 4.0

const COLOR_OPTIONS := {
    "Red": Color(1.0, 0.2, 0.2),
    "Orange": Color(1.0, 0.55, 0.2),
    "Yellow": Color(1.0, 0.9, 0.2),
    "Green": Color(0.3, 0.9, 0.35),
    "Blue": Color(0.25, 0.5, 1.0),
    "Indigo": Color(0.35, 0.3, 0.9),
    "Violet": Color(0.75, 0.35, 1.0),
}

var player_scene = preload("res://scenes/player.tscn")
var bomb_scene = preload("res://scenes/bomb.tscn")
var pickup_scene = preload("res://scenes/pickup.tscn")

var current_mode := ""
var solo_color := "Red"
var player1_color := "Red"
var player2_color := "Blue"
var game_started := false
var match_time := 0.0
var bomb_spawn_timer := 0.0
var pickup_spawn_timer := 0.0
var menu_root: Control
var selection_root: Control
var results_root: Control
var hud_canvas: CanvasLayer
var timer_label: Label
var players: Array = []
var bombs: Array = []
var pickups: Array = []
var player_hud: Dictionary = {}
var game_over := false

func _ready() -> void:
    _build_hud()
    _build_main_menu()
    _build_selection_screen()
    _build_results_screen()
    show_main_menu()

func _build_hud() -> void:
    var arena_bg := ColorRect.new()
    arena_bg.position = ARENA_POS
    arena_bg.size = ARENA_SIZE
    arena_bg.color = Color(0.04, 0.1, 0.26)
    add_child(arena_bg)

    var border := ColorRect.new()
    border.position = ARENA_POS - Vector2(6, 6)
    border.size = ARENA_SIZE + Vector2(12, 12)
    border.color = Color(0.1, 0.2, 0.4, 0.7)
    border.z_index = -1
    add_child(border)

    hud_canvas = CanvasLayer.new()
    add_child(hud_canvas)

    timer_label = Label.new()
    timer_label.anchor_left = 0.5
    timer_label.anchor_right = 0.5
    timer_label.anchor_top = 0.0
    timer_label.anchor_bottom = 0.0
    timer_label.offset_left = -120
    timer_label.offset_top = 10
    timer_label.offset_right = 120
    timer_label.offset_bottom = 48
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    timer_label.add_theme_font_size_override("font_size", 28)
    timer_label.text = "00:00.0"
    timer_label.visible = false
    hud_canvas.add_child(timer_label)

func _build_main_menu() -> void:
    menu_root = Control.new()
    menu_root.name = "MenuRoot"
    add_child(menu_root)

    var title_label := Label.new()
    title_label.text = "BOMB DODGE"
    title_label.add_theme_font_size_override("font_size", 54)
    title_label.position = Vector2(440, 90)
    title_label.size = Vector2(400, 80)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_root.add_child(title_label)

    var solo_button := Button.new()
    solo_button.text = "Solo"
    solo_button.position = Vector2(530, 250)
    solo_button.size = Vector2(220, 60)
    solo_button.pressed.connect(_on_solo_pressed)
    menu_root.add_child(solo_button)

    var multiplayer_button := Button.new()
    multiplayer_button.text = "Local Multiplayer"
    multiplayer_button.position = Vector2(470, 330)
    multiplayer_button.size = Vector2(340, 60)
    multiplayer_button.pressed.connect(_on_multiplayer_pressed)
    menu_root.add_child(multiplayer_button)

    var exit_button := Button.new()
    exit_button.text = "Exit"
    exit_button.position = Vector2(530, 410)
    exit_button.size = Vector2(220, 60)
    exit_button.pressed.connect(_on_exit_pressed)
    menu_root.add_child(exit_button)

func _build_selection_screen() -> void:
    selection_root = Control.new()
    selection_root.name = "SelectionRoot"
    selection_root.visible = false
    add_child(selection_root)

    var title_label := Label.new()
    title_label.text = "Choose Colors"
    title_label.add_theme_font_size_override("font_size", 34)
    title_label.position = Vector2(420, 40)
    title_label.size = Vector2(440, 60)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    selection_root.add_child(title_label)

    var back_button := Button.new()
    back_button.text = "Back"
    back_button.position = Vector2(30, 25)
    back_button.size = Vector2(110, 40)
    back_button.pressed.connect(show_main_menu)
    selection_root.add_child(back_button)

    var start_button := Button.new()
    start_button.name = "StartButton"
    start_button.text = "Start Game"
    start_button.position = Vector2(540, 632)
    start_button.size = Vector2(200, 50)
    start_button.disabled = true
    start_button.pressed.connect(_on_start_game_pressed)
    selection_root.add_child(start_button)

    var solo_panel := VBoxContainer.new()
    solo_panel.name = "SoloPanel"
    solo_panel.position = Vector2(240, 120)
    solo_panel.size = Vector2(800, 460)
    solo_panel.visible = true
    selection_root.add_child(solo_panel)

    var multi_panel := VBoxContainer.new()
    multi_panel.name = "MultiPanel"
    multi_panel.position = Vector2(140, 120)
    multi_panel.size = Vector2(1000, 500)
    multi_panel.visible = false
    selection_root.add_child(multi_panel)

    var solo_preview := ColorRect.new()
    solo_preview.name = "SoloPreview"
    solo_preview.size = Vector2(180, 60)
    solo_preview.color = COLOR_OPTIONS[solo_color]
    solo_panel.add_child(solo_preview)

    var p1_preview := ColorRect.new()
    p1_preview.name = "P1Preview"
    p1_preview.size = Vector2(180, 60)
    p1_preview.color = COLOR_OPTIONS[player1_color]
    multi_panel.add_child(p1_preview)

    var p2_preview := ColorRect.new()
    p2_preview.name = "P2Preview"
    p2_preview.size = Vector2(180, 60)
    p2_preview.color = COLOR_OPTIONS[player2_color]
    multi_panel.add_child(p2_preview)

    var color_names := ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet"]
    for color_name in color_names:
        var solo_btn := Button.new()
        solo_btn.text = color_name
        solo_btn.custom_minimum_size = Vector2(120, 38)
        solo_btn.modulate = COLOR_OPTIONS[color_name]
        solo_btn.pressed.connect(_make_color_handler(color_name, "solo"))
        solo_panel.add_child(solo_btn)

        var p1_btn := Button.new()
        p1_btn.text = "P1: " + color_name
        p1_btn.custom_minimum_size = Vector2(160, 38)
        p1_btn.modulate = COLOR_OPTIONS[color_name]
        p1_btn.pressed.connect(_make_color_handler(color_name, "p1"))
        multi_panel.add_child(p1_btn)

        var p2_btn := Button.new()
        p2_btn.text = "P2: " + color_name
        p2_btn.custom_minimum_size = Vector2(160, 38)
        p2_btn.modulate = COLOR_OPTIONS[color_name]
        p2_btn.pressed.connect(_make_color_handler(color_name, "p2"))
        multi_panel.add_child(p2_btn)

    selection_root.set_meta("solo_preview", solo_preview)
    selection_root.set_meta("p1_preview", p1_preview)
    selection_root.set_meta("p2_preview", p2_preview)
    selection_root.set_meta("solo_panel", solo_panel)
    selection_root.set_meta("multi_panel", multi_panel)
    selection_root.set_meta("start_button", start_button)

    _update_color_selection_ui()

func _build_results_screen() -> void:
    results_root = Control.new()
    results_root.visible = false
    add_child(results_root)

    var result_title := Label.new()
    result_title.name = "ResultTitle"
    result_title.position = Vector2(430, 160)
    result_title.size = Vector2(420, 80)
    result_title.add_theme_font_size_override("font_size", 42)
    result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    results_root.add_child(result_title)

    var result_time := Label.new()
    result_time.name = "ResultTime"
    result_time.position = Vector2(430, 250)
    result_time.size = Vector2(420, 60)
    result_time.add_theme_font_size_override("font_size", 24)
    result_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    results_root.add_child(result_time)

    var restart_button := Button.new()
    restart_button.text = "Restart"
    restart_button.position = Vector2(515, 340)
    restart_button.size = Vector2(170, 60)
    restart_button.pressed.connect(_on_restart_pressed)
    results_root.add_child(restart_button)

    var menu_button := Button.new()
    menu_button.text = "Main Menu"
    menu_button.position = Vector2(515, 420)
    menu_button.size = Vector2(170, 60)
    menu_button.pressed.connect(show_main_menu)
    results_root.add_child(menu_button)

    results_root.set_meta("title", result_title)
    results_root.set_meta("time", result_time)

func _make_color_handler(color_name: String, target: String) -> Callable:
    return Callable(self, "_on_color_selected").bind(color_name, target)

func _on_color_selected(color_name: String, target: String) -> void:
    if target == "solo":
        solo_color = color_name
    elif target == "p1":
        player1_color = color_name
    elif target == "p2":
        player2_color = color_name
    _update_color_selection_ui()

func _update_color_selection_ui() -> void:
    if selection_root == null:
        return

    var solo_preview: ColorRect = selection_root.get_meta("solo_preview")
    var p1_preview: ColorRect = selection_root.get_meta("p1_preview")
    var p2_preview: ColorRect = selection_root.get_meta("p2_preview")
    var start_button: Button = selection_root.get_meta("start_button")
    var solo_panel: VBoxContainer = selection_root.get_meta("solo_panel")
    var multi_panel: VBoxContainer = selection_root.get_meta("multi_panel")

    solo_preview.color = COLOR_OPTIONS[solo_color]
    p1_preview.color = COLOR_OPTIONS[player1_color]
    p2_preview.color = COLOR_OPTIONS[player2_color]

    if current_mode == "solo":
        solo_panel.visible = true
        multi_panel.visible = false
        start_button.disabled = false
    elif current_mode == "multiplayer":
        solo_panel.visible = false
        multi_panel.visible = true
        start_button.disabled = player1_color == player2_color
    else:
        start_button.disabled = true

func _on_solo_pressed() -> void:
    current_mode = "solo"
    _update_color_selection_ui()
    show_selection_screen()

func _on_multiplayer_pressed() -> void:
    current_mode = "multiplayer"
    _update_color_selection_ui()
    show_selection_screen()

func _on_start_game_pressed() -> void:
    if current_mode == "solo":
        begin_match(solo_color)
    elif current_mode == "multiplayer":
        if player1_color == player2_color:
            return
        begin_match(player1_color, player2_color)

func show_main_menu() -> void:
    menu_root.visible = true
    selection_root.visible = false
    results_root.visible = false
    timer_label.visible = false
    game_over = false
    current_mode = ""
    _clear_match_objects()

func show_selection_screen() -> void:
    menu_root.visible = false
    selection_root.visible = true
    results_root.visible = false
    _update_color_selection_ui()

func begin_match(color_one: String, color_two: String = "") -> void:
    _clear_match_objects()

    game_over = false
    game_started = true
    match_time = 0.0
    bomb_spawn_timer = 0.0
    pickup_spawn_timer = 3.0
    timer_label.visible = true
    timer_label.text = "00:00.0"
    selection_root.visible = false
    results_root.visible = false

    var arena := Node2D.new()
    arena.name = "Arena"
    add_child(arena)

    var p1 := player_scene.instantiate()
    p1.position = Vector2(ARENA_POS.x + 220, ARENA_POS.y + 240)
    p1.input_prefix = "p1"
    p1.player_name = "PLAYER 1"
    p1.set_color_choice(color_one, COLOR_OPTIONS[color_one])
    arena.add_child(p1)
    players.append(p1)

    if color_two != "":
        var p2 := player_scene.instantiate()
        p2.position = Vector2(ARENA_POS.x + 700, ARENA_POS.y + 240)
        p2.input_prefix = "p2"
        p2.player_name = "PLAYER 2"
        p2.set_color_choice(color_two, COLOR_OPTIONS[color_two])
        arena.add_child(p2)
        players.append(p2)

    _setup_player_hud()
    _spawn_starting_bombs()

func _clear_match_objects() -> void:
    for item in bombs:
        if is_instance_valid(item):
            item.queue_free()
    bombs.clear()

    for item in pickups:
        if is_instance_valid(item):
            item.queue_free()
    pickups.clear()

    for player in players:
        if is_instance_valid(player):
            player.queue_free()
    players.clear()

    for hud_item in player_hud.values():
        if is_instance_valid(hud_item):
            hud_item.queue_free()
    player_hud.clear()

    if has_node("Arena"):
        get_node("Arena").queue_free()

func _setup_player_hud() -> void:
    for old in player_hud.values():
        if is_instance_valid(old):
            old.queue_free()
    player_hud.clear()

    for i in range(players.size()):
        var box := VBoxContainer.new()
        box.position = Vector2(30 + i * 260, 20)
        box.size = Vector2(200, 100)
        hud_canvas.add_child(box)

        var label := Label.new()
        label.text = players[i].player_name
        label.add_theme_font_size_override("font_size", 18)
        box.add_child(label)

        var ability_button := Button.new()
        ability_button.text = ""
        ability_button.size = Vector2(120, 40)
        ability_button.disabled = true
        ability_button.gui_input.connect(_on_ability_button_input.bind(players[i]))
        box.add_child(ability_button)

        player_hud[players[i]] = ability_button
        _refresh_player_hud(players[i])

func _on_ability_button_input(event: InputEvent, player: Node) -> void:
    if not game_started or game_over:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
        if player.has_method("activate_ability"):
            player.activate_ability()
        _refresh_player_hud(player)

func _refresh_player_hud(player: Node) -> void:
    if not player_hud.has(player):
        return

    var button: Button = player_hud[player]
    if player.ability_name == "dash":
        button.text = "DASH"
        button.modulate = Color(1.0, 0.2, 0.2)
        button.disabled = false
    elif player.ability_name == "shield":
        button.text = "SHIELD"
        button.modulate = Color(0.25, 0.5, 1.0)
        button.disabled = false
    else:
        button.text = ""
        button.disabled = true

func _spawn_starting_bombs() -> void:
    for i in range(STARTING_BOMBS):
        _spawn_bomb()

func _spawn_bomb() -> void:
    if bombs.size() >= BOMB_LIMIT or not game_started or game_over:
        return

    for attempt in range(60):
        var spawn_position := Vector2(
            randf_range(ARENA_POS.x + 30, ARENA_POS.x + ARENA_SIZE.x - 30),
            randf_range(ARENA_POS.y + 30, ARENA_POS.y + ARENA_SIZE.y - 30)
        )

        var blocked := false
        for player in players:
            if player.global_position.distance_to(spawn_position) < 80:
                blocked = true
                break

        if blocked:
            continue

        var bomb := bomb_scene.instantiate()
        bomb.position = spawn_position
        get_node("Arena").add_child(bomb)
        bomb.bomb_exploded.connect(_on_bomb_exploded)
        bombs.append(bomb)
        return

func _spawn_pickup() -> void:
    if not game_started or game_over or pickups.size() >= 3:
        return

    var picked_kind := "dash" if randf() < 0.5 else "shield"
    var spawn_position := _find_valid_pickup_position()
    if spawn_position == Vector2.ZERO:
        return

    var pickup := pickup_scene.instantiate()
    pickup.setup(picked_kind, picked_kind == "dash" if true else Color(0.25, 0.5, 1.0))
    if picked_kind == "dash":
        pickup.setup("dash", Color(1.0, 0.2, 0.2))
    else:
        pickup.setup("shield", Color(0.25, 0.5, 1.0))
    pickup.position = spawn_position
    get_node("Arena").add_child(pickup)
    pickups.append(pickup)

func _find_valid_pickup_position() -> Vector2:
    for i in range(60):
        var position := Vector2(
            randf_range(ARENA_POS.x + 40, ARENA_POS.x + ARENA_SIZE.x - 40),
            randf_range(ARENA_POS.y + 40, ARENA_POS.y + ARENA_SIZE.y - 40)
        )

        var blocked := false
        for player in players:
            if player.global_position.distance_to(position) < 70:
                blocked = true
                break
        if blocked:
            continue

        for bomb in bombs:
            if bomb.global_position.distance_to(position) < 52:
                blocked = true
                break
        if blocked:
            continue

        for item in pickups:
            if item.global_position.distance_to(position) < 40:
                blocked = true
                break
        if not blocked:
            return position

    return Vector2.ZERO

func _process(delta: float) -> void:
    if not game_started or game_over:
        return

    match_time += delta
    timer_label.text = _format_time(match_time)

    bomb_spawn_timer -= delta
    if bomb_spawn_timer <= 0.0:
        if bombs.size() < BOMB_LIMIT:
            _spawn_bomb()
        bomb_spawn_timer = BOMB_SPAWN_INTERVAL

    pickup_spawn_timer -= delta
    if pickup_spawn_timer <= 0.0:
        _spawn_pickup()
        pickup_spawn_timer = PICKUP_SPAWN_INTERVAL + randf_range(0.0, 2.5)

    for player in players:
        if not is_instance_valid(player) or not player.alive:
            continue

        var found_pickup = null
        for pickup in pickups:
            if is_instance_valid(pickup) and pickup.global_position.distance_to(player.global_position) < 34:
                found_pickup = pickup
                break

        if found_pickup != null:
            if player.color_name == "Red" and found_pickup.kind == "dash":
                player.collect_ability("dash")
            elif player.color_name == "Blue" and found_pickup.kind == "shield":
                player.collect_ability("shield")
            _refresh_player_hud(player)
            found_pickup.queue_free()
            pickups.erase(found_pickup)

    _check_round_end()

func _on_bomb_exploded(bomb: Node2D, explosion_position: Vector2, radius: float) -> void:
    if bombs.has(bomb):
        bombs.erase(bomb)

    for player in players:
        if not is_instance_valid(player) or not player.alive:
            continue
        if player.global_position.distance_to(explosion_position) <= radius + 24:
            if player.shield_time > 0.0:
                continue
            player.take_damage()

    _check_round_end()

func _check_round_end() -> void:
    if game_over:
        return

    var alive_players: Array = []
    for player in players:
        if is_instance_valid(player) and player.alive:
            alive_players.append(player)

    if current_mode == "solo":
        if alive_players.size() == 0:
            game_over = true
            _show_results("GAME OVER", _format_time(match_time))
    else:
        if alive_players.size() == 0:
            game_over = true
            _show_results("DRAW", _format_time(match_time))
        elif alive_players.size() == 1:
            game_over = true
            _show_results(alive_players[0].player_name + " WINS", _format_time(match_time))

func _show_results(title: String, time_text: String) -> void:
    game_started = false
    var title_node: Label = results_root.get_meta("title")
    var time_node: Label = results_root.get_meta("time")
    title_node.text = title
    time_node.text = "Final Time: " + time_text
    results_root.visible = true
    timer_label.visible = true

func _on_restart_pressed() -> void:
    if current_mode == "solo":
        begin_match(solo_color)
    elif current_mode == "multiplayer":
        begin_match(player1_color, player2_color)

func _on_exit_pressed() -> void:
    get_tree().quit()

func _format_time(value: float) -> String:
    var minutes := int(value) / 60
    var seconds := int(value) % 60
    var tenths := int((value - floor(value)) * 10.0)
    return "%02d:%02d.%01d" % [minutes, seconds, tenths]
