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
var arena_background: ColorRect
var menu_root: Control
var selection_root: Control
var results_root: Control
var hud_canvas: CanvasLayer
var timer_label: Label
var status_label: Label
var players: Array = []
var bombs: Array = []
var pickups: Array = []
var player_hud: Dictionary = {}
var game_over := false
var last_mode := "solo"

func _ready() -> void:
    _build_arena_background()
    _build_hud()
    _build_main_menu()
    _build_selection_ui()
    _build_results_ui()
    show_main_menu()

func _build_arena_background() -> void:
    arena_background = ColorRect.new()
    arena_background.position = ARENA_POS
    arena_background.size = ARENA_SIZE
    arena_background.color = Color(0.04, 0.1, 0.26)
    add_child(arena_background)

    var border = ColorRect.new()
    border.position = ARENA_POS - Vector2(6, 6)
    border.size = ARENA_SIZE + Vector2(12, 12)
    border.color = Color(0.1, 0.2, 0.4, 0.7)
    border.z_index = -1
    add_child(border)

func _build_hud() -> void:
    hud_canvas = CanvasLayer.new()
    add_child(hud_canvas)

    timer_label = Label.new()
    timer_label.anchor_left = 0.5
    timer_label.anchor_top = 0.0
    timer_label.anchor_right = 0.5
    timer_label.anchor_bottom = 0.0
    timer_label.offset_left = -120
    timer_label.offset_top = 12
    timer_label.offset_right = 120
    timer_label.offset_bottom = 52
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    timer_label.add_theme_font_size_override("font_size", 28)
    timer_label.modulate = Color(1, 1, 1, 1)
    hud_canvas.add_child(timer_label)

    status_label = Label.new()
    status_label.anchor_left = 0.5
    status_label.anchor_right = 0.5
    status_label.anchor_top = 0.0
    status_label.anchor_bottom = 0.0
    status_label.offset_left = -180
    status_label.offset_top = 55
    status_label.offset_right = 180
    status_label.offset_bottom = 90
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.visible = false
    hud_canvas.add_child(status_label)

    timer_label.text = "00:00.0"

func _build_main_menu() -> void:
    menu_root = Control.new()
    menu_root.name = "MenuRoot"
    menu_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    menu_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(menu_root)

    var title_label = Label.new()
    title_label.text = "BOMB DODGE"
    title_label.add_theme_font_size_override("font_size", 54)
    title_label.position = Vector2(480, 100)
    title_label.size = Vector2(320, 80)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    menu_root.add_child(title_label)

    var solo_button = Button.new()
    solo_button.text = "Solo"
    solo_button.position = Vector2(530, 260)
    solo_button.size = Vector2(220, 60)
    solo_button.pressed.connect(_on_solo_pressed)
    menu_root.add_child(solo_button)

    var multi_button = Button.new()
    multi_button.text = "Local Multiplayer"
    multi_button.position = Vector2(470, 340)
    multi_button.size = Vector2(340, 60)
    multi_button.pressed.connect(_on_multiplayer_pressed)
    menu_root.add_child(multi_button)

    var exit_button = Button.new()
    exit_button.text = "Exit"
    exit_button.position = Vector2(530, 420)
    exit_button.size = Vector2(220, 60)
    exit_button.pressed.connect(_on_exit_pressed)
    menu_root.add_child(exit_button)

func _build_selection_ui() -> void:
    selection_root = Control.new()
    selection_root.name = "SelectionRoot"
    selection_root.visible = false
    add_child(selection_root)

    var title = Label.new()
    title.text = "Choose Colors"
    title.add_theme_font_size_override("font_size", 36)
    title.position = Vector2(480, 40)
    title.size = Vector2(320, 60)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    selection_root.add_child(title)

    var start_button = Button.new()
    start_button.name = "StartButton"
    start_button.text = "Start Game"
    start_button.position = Vector2(540, 620)
    start_button.size = Vector2(200, 60)
    start_button.disabled = true
    start_button.pressed.connect(_on_start_game_pressed)
    selection_root.add_child(start_button)

    var back_button = Button.new()
    back_button.text = "Back"
    back_button.position = Vector2(40, 30)
    back_button.size = Vector2(120, 40)
    back_button.pressed.connect(show_main_menu)
    selection_root.add_child(back_button)

    var solo_panel = VBoxContainer.new()
    solo_panel.name = "SoloPanel"
    solo_panel.position = Vector2(260, 120)
    solo_panel.size = Vector2(760, 480)
    solo_panel.visible = true
    selection_root.add_child(solo_panel)

    var multi_panel = VBoxContainer.new()
    multi_panel.name = "MultiPanel"
    multi_panel.position = Vector2(160, 120)
    multi_panel.size = Vector2(960, 480)
    multi_panel.visible = false
    selection_root.add_child(multi_panel)

    var solo_preview = ColorRect.new()
    solo_preview.name = "SoloPreview"
    solo_preview.size = Vector2(200, 60)
    solo_preview.color = COLOR_OPTIONS[solo_color]
    solo_panel.add_child(solo_preview)

    var player1_preview = ColorRect.new()
    player1_preview.name = "P1Preview"
    player1_preview.size = Vector2(200, 60)
    player1_preview.color = COLOR_OPTIONS[player1_color]
    multi_panel.add_child(player1_preview)

    var player2_preview = ColorRect.new()
    player2_preview.name = "P2Preview"
    player2_preview.size = Vector2(200, 60)
    player2_preview.color = COLOR_OPTIONS[player2_color]
    multi_panel.add_child(player2_preview)

    var color_names = ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet"]
    var solo_color_buttons = []
    var multi_p1_buttons = []
    var multi_p2_buttons = []

    for color_name in color_names:
        var solo_button = Button.new()
        solo_button.text = color_name
        solo_button.custom_minimum_size = Vector2(120, 40)
        solo_button.modulate = COLOR_OPTIONS[color_name]
        solo_button.pressed.connect(_make_color_handler(color_name, "solo"))
        solo_color_buttons.append(solo_button)

        var p1_button = Button.new()
        p1_button.text = "P1: " + color_name
        p1_button.custom_minimum_size = Vector2(160, 40)
        p1_button.modulate = COLOR_OPTIONS[color_name]
        p1_button.pressed.connect(_make_color_handler(color_name, "p1"))
        multi_p1_buttons.append(p1_button)

        var p2_button = Button.new()
        p2_button.text = "P2: " + color_name
        p2_button.custom_minimum_size = Vector2(160, 40)
        p2_button.modulate = COLOR_OPTIONS[color_name]
        p2_button.pressed.connect(_make_color_handler(color_name, "p2"))
        multi_p2_buttons.append(p2_button)

    var solo_hbox = HBoxContainer.new()
    solo_hbox.position = Vector2(0, 120)
    solo_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for btn in solo_color_buttons:
        solo_hbox.add_child(btn)
    solo_panel.add_child(solo_hbox)

    var multi_hbox1 = HBoxContainer.new()
    multi_hbox1.position = Vector2(0, 120)
    multi_hbox1.size = Vector2(420, 60)
    for btn in multi_p1_buttons:
        multi_hbox1.add_child(btn)
    multi_panel.add_child(multi_hbox1)

    var multi_hbox2 = HBoxContainer.new()
    multi_hbox2.position = Vector2(0, 230)
    multi_hbox2.size = Vector2(420, 60)
    for btn in multi_p2_buttons:
        multi_hbox2.add_child(btn)
    multi_panel.add_child(multi_hbox2)

    selection_root.set_meta("solo_preview", solo_preview)
    selection_root.set_meta("p1_preview", player1_preview)
    selection_root.set_meta("p2_preview", player2_preview)
    selection_root.set_meta("solo_panel", solo_panel)
    selection_root.set_meta("multi_panel", multi_panel)
    selection_root.set_meta("start_button", start_button)

    _update_color_selection_ui()

func _build_results_ui() -> void:
    results_root = Control.new()
    results_root.visible = false
    add_child(results_root)

    var result_title = Label.new()
    result_title.name = "ResultTitle"
    result_title.position = Vector2(420, 150)
    result_title.size = Vector2(440, 80)
    result_title.add_theme_font_size_override("font_size", 42)
    result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    results_root.add_child(result_title)

    var result_time = Label.new()
    result_time.name = "ResultTime"
    result_time.position = Vector2(420, 250)
    result_time.size = Vector2(440, 50)
    result_time.add_theme_font_size_override("font_size", 24)
    result_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    results_root.add_child(result_time)

    var restart_button = Button.new()
    restart_button.text = "Restart"
    restart_button.position = Vector2(510, 340)
    restart_button.size = Vector2(160, 60)
    restart_button.pressed.connect(_on_restart_pressed)
    results_root.add_child(restart_button)

    var menu_button = Button.new()
    menu_button.text = "Main Menu"
    menu_button.position = Vector2(510, 420)
    menu_button.size = Vector2(160, 60)
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

    var solo_preview = selection_root.get_meta("solo_preview")
    var p1_preview = selection_root.get_meta("p1_preview")
    var p2_preview = selection_root.get_meta("p2_preview")
    var start_button = selection_root.get_meta("start_button")
    var solo_panel = selection_root.get_meta("solo_panel")
    var multi_panel = selection_root.get_meta("multi_panel")

    solo_preview.color = COLOR_OPTIONS[solo_color]
    p1_preview.color = COLOR_OPTIONS[player1_color]
    p2_preview.color = COLOR_OPTIONS[player2_color]

    if current_mode == "solo":
        solo_panel.visible = true
        multi_panel.visible = false
    else:
        solo_panel.visible = false
        multi_panel.visible = true

    if current_mode == "multiplayer":
        start_button.disabled = player1_color == player2_color
    else:
        start_button.disabled = false

func _on_solo_pressed() -> void:
    current_mode = "solo"
    last_mode = "solo"
    _update_color_selection_ui()
    show_selection_screen()

func _on_multiplayer_pressed() -> void:
    current_mode = "multiplayer"
    last_mode = "multiplayer"
    _update_color_selection_ui()
    show_selection_screen()

func _on_start_game_pressed() -> void:
    if current_mode == "solo":
        begin_match(solo_color)
    else:
        if player1_color == player2_color:
            return
        begin_match(player1_color, player2_color)

func show_main_menu() -> void:
    menu_root.visible = true
    selection_root.visible = false
    results_root.visible = false
    timer_label.visible = false
    status_label.visible = false
    game_over = false
    current_mode = ""
    if has_node("Arena"):
        for child in get_children():
            if child.name == "Arena":
                child.queue_free()

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

func show_selection_screen() -> void:
    menu_root.visible = false
    selection_root.visible = true
    results_root.visible = false
    _update_color_selection_ui()

func begin_match(color_one: String, color_two: String = "") -> void:
    if game_over:
        return

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

    game_over = false
    game_started = true
    match_time = 0.0
    bomb_spawn_timer = 0.0
    pickup_spawn_timer = 0.0
    status_label.visible = false
    timer_label.visible = true
    timer_label.text = "00:00.0"
    selection_root.visible = false
    results_root.visible = false

    var arena = Node2D.new()
    arena.name = "Arena"
    add_child(arena)
    arena.z_index = 0

    var p1 = player_scene.instantiate()
    p1.position = Vector2(ARENA_POS.x + 220, ARENA_POS.y + 240)
    p1.input_prefix = "p1"
    p1.player_name = "PLAYER 1"
    p1.set_color_choice(color_one, COLOR_OPTIONS[color_one])
    arena.add_child(p1)
    players.append(p1)

    if color_two != "":
        var p2 = player_scene.instantiate()
        p2.position = Vector2(ARENA_POS.x + 700, ARENA_POS.y + 240)
        p2.input_prefix = "p2"
        p2.player_name = "PLAYER 2"
        p2.set_color_choice(color_two, COLOR_OPTIONS[color_two])
        arena.add_child(p2)
        players.append(p2)

    _setup_player_hud()
    _spawn_starting_bombs()

func _setup_player_hud() -> void:
    for key in player_hud.keys():
        var old = player_hud[key]
        if is_instance_valid(old):
            old.queue_free()
    player_hud.clear()

    var hud_y = 20
    for i in range(players.size()):
        var box = VBoxContainer.new()
        box.position = Vector2(25 + i * 260, hud_y)
        box.size = Vector2(200, 80)
        hud_canvas.add_child(box)

        var label = Label.new()
        label.text = players[i].player_name
        label.add_theme_font_size_override("font_size", 20)
        box.add_child(label)

        var ability_button = Button.new()
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
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.doubleclick:
        if player.has_method("activate_ability"):
            player.activate_ability()
        _refresh_player_hud(player)

func _refresh_player_hud(player: Node) -> void:
    if player not in player_hud:
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

    var attempt_count := 0
    while attempt_count < 60:
        var spawn_position = Vector2(
            randf_range(ARENA_POS.x + 30, ARENA_POS.x + ARENA_SIZE.x - 30),
            randf_range(ARENA_POS.y + 30, ARENA_POS.y + ARENA_SIZE.y - 30)
        )
        var too_close_to_player := false
        for player in players:
            if player.global_position.distance_to(spawn_position) < 80:
                too_close_to_player = true
                break
        if not too_close_to_player:
            var bomb = bomb_scene.instantiate()
            bomb.position = spawn_position
            get_node("Arena").add_child(bomb)
            bomb.bomb_exploded.connect(_on_bomb_exploded)
            bombs.append(bomb)
            return
        attempt_count += 1

func _spawn_pickup() -> void:
    if game_over or not game_started:
        return
    if pickups.size() >= 3:
        return

    var valid_types = ["dash", "shield"]
    var chosen_type = valid_types[randi() % valid_types.size()]
    var safe_position = _find_valid_pickup_position()
    if safe_position == Vector2.ZERO:
        return

    var pickup = pickup_scene.instantiate()
    pickup.setup(chosen_type, chosen_type == "dash" ? Color(1.0, 0.2, 0.2) : Color(0.25, 0.5, 1.0))
    pickup.position = safe_position
    get_node("Arena").add_child(pickup)
    pickups.append(pickup)

func _find_valid_pickup_position() -> Vector2:
    for i in range(60):
        var position = Vector2(
            randf_range(ARENA_POS.x + 40, ARENA_POS.x + ARENA_SIZE.x - 40),
            randf_range(ARENA_POS.y + 40, ARENA_POS.y + ARENA_SIZE.y - 40)
        )
        var blocked := false
        for player in players:
            if player.global_position.distance_to(position) < 70:
                blocked = true
                break
        for bomb in bombs:
            if bomb.global_position.distance_to(position) < 52:
                blocked = true
                break
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
        if not player.alive:
            continue
        var pickup_found = null
        for pickup in pickups:
            if is_instance_valid(pickup) and pickup.global_position.distance_to(player.global_position) < 34:
                pickup_found = pickup
                break
        if pickup_found != null:
            if player.color_name == "Red" and pickup_found.kind == "dash":
                player.collect_ability("dash")
            elif player.color_name == "Blue" and pickup_found.kind == "shield":
                player.collect_ability("shield")
            _refresh_player_hud(player)
            pickup_found.queue_free()
            pickups.erase(pickup_found)

    _check_round_end()

func _on_bomb_exploded(bomb: Node2D, explosion_position: Vector2, radius: float) -> void:
    if bombs.has(bomb):
        bombs.erase(bomb)
    if not game_started:
        return

    for player in players:
        if not is_instance_valid(player) or not player.alive:
            continue
        if player.global_position.distance_to(explosion_position) <= radius + 24:
            if player.shield_time > 0.0:
                continue
            player.take_damage()
            if player.alive == false:
                _refresh_player_hud(player)

    _check_round_end()

func _check_round_end() -> void:
    if game_over:
        return

    var alive_players = []
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
    if has_node("Arena"):
        var arena = get_node("Arena")
        for child in arena.get_children():
            if child is Node2D:
                child.set_process(false)
                child.set_physics_process(false)

    var title_node = results_root.get_meta("title")
    var time_node = results_root.get_meta("time")
    title_node.text = title
    time_node.text = "Final Time: " + time_text
    results_root.visible = true
    timer_label.visible = true
    status_label.visible = false

func _on_restart_pressed() -> void:
    if current_mode == "solo":
        begin_match(solo_color)
    else:
        begin_match(player1_color, player2_color)

func _on_exit_pressed() -> void:
    get_tree().quit()

func _format_time(value: float) -> String:
    var minutes := int(value) / 60
    var seconds := int(value) % 60
    var tenths := int((value - floor(value)) * 10.0)
    return "%02d:%02d.%01d" % [minutes, seconds, tenths]
