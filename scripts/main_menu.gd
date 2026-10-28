extends Control

var status_label: Label
var player_buttons: HBoxContainer
var selected_players := 1

func _ready() -> void:
    _build_menu()

func _build_menu() -> void:
    var background := ColorRect.new()
    background.color = Color("#090d18")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(320, 0)
    column.add_theme_constant_override("separation", 16)
    center.add_child(column)

    var title := Label.new()
    title.text = "POCKET PARTY"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", Color("#71e5ff"))
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "3D MINI-GAMES"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 17)
    subtitle.add_theme_color_override("font_color", Color("#c5d2e8"))
    column.add_child(subtitle)

    var description := Label.new()
    description.text = "Race solo against bots or share one device."
    description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(description)

    var choose_button := Button.new()
    choose_button.text = "CHOOSE PLAYERS"
    choose_button.custom_minimum_size = Vector2(280, 50)
    choose_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    choose_button.pressed.connect(_show_player_choices)
    column.add_child(choose_button)

    player_buttons = HBoxContainer.new()
    player_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
    player_buttons.add_theme_constant_override("separation", 8)
    player_buttons.visible = false
    column.add_child(player_buttons)

    for count in range(1, 5):
        var button := Button.new()
        button.text = str(count) + "P"
        button.custom_minimum_size = Vector2(62, 46)
        button.pressed.connect(_select_players.bind(count))
        player_buttons.add_child(button)

    var race_button := Button.new()
    race_button.text = "PLAY MICRO RACERS"
    race_button.custom_minimum_size = Vector2(280, 56)
    race_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    race_button.pressed.connect(_start_race)
    column.add_child(race_button)

    status_label = Label.new()
    status_label.text = "First playable prototype"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color", Color("#9eacc5"))
    column.add_child(status_label)

func _show_player_choices() -> void:
    player_buttons.visible = true
    status_label.text = "Selected: %d player(s)" % selected_players

func _select_players(count: int) -> void:
    selected_players = count
    status_label.text = "Selected: %d player(s)" % count

func _start_race() -> void:
    var config := ConfigFile.new()
    config.set_value("race", "players", selected_players)
    var result := config.save("user://session.cfg")
    if result != OK:
        status_label.text = "Could not save player selection."
        return
    get_tree().change_scene_to_file(
        "res://scenes/games/micro_racers/micro_racers.tscn")
