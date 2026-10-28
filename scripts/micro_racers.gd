extends Node3D

const TRACK_HALF := 18.0
const WAYPOINTS: Array[Vector3] = [
    Vector3(0, 0, -12),
    Vector3(12, 0, 0),
    Vector3(0, 0, 12),
    Vector3(-12, 0, 0)
]
const CAR_COLORS: Array[Color] = [
    Color("#39c5ff"),
    Color("#ff5858"),
    Color("#ffd34d"),
    Color("#9b7bff")
]
const PLAYER_KEYS := [
    {"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D},
    {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT},
    {"up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L},
    {"up": KEY_T, "down": KEY_G, "left": KEY_F, "right": KEY_H}
]

var racers: Array[Dictionary] = []
var player_count := 1
var race_time := 0.0
var finished := false
var hud: Label
var help_label: Label

func _ready() -> void:
    var config := ConfigFile.new()
    if config.load("user://session.cfg") == OK:
        player_count = clampi(int(config.get_value("race", "players", 1)), 1, 4)

    _build_track()
    _build_camera()
    _build_hud()

    for i in range(4 if player_count == 1 else player_count):
        _create_racer(i)

    _refresh_hud()

func _build_track() -> void:
    var ground := StaticBody3D.new()
    ground.name = "TrackFloor"
    add_child(ground)

    var floor_mesh := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(40, 0.4, 40)
    floor_mesh.mesh = plane
    floor_mesh.position.y = -0.25
    var floor_material := StandardMaterial3D.new()
    floor_material.albedo_color = Color("#263445")
    floor_mesh.material_override = floor_material
    ground.add_child(floor_mesh)

    var floor_collision := CollisionShape3D.new()
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(40, 0.4, 40)
    floor_collision.shape = floor_shape
    floor_collision.position.y = -0.25
    ground.add_child(floor_collision)

    _add_wall(Vector3(0, 0.7, -TRACK_HALF), Vector3(36, 1.4, 0.6))
    _add_wall(Vector3(0, 0.7, TRACK_HALF), Vector3(36, 1.4, 0.6))
    _add_wall(Vector3(-TRACK_HALF, 0.7, 0), Vector3(0.6, 1.4, 36))
    _add_wall(Vector3(TRACK_HALF, 0.7, 0), Vector3(0.6, 1.4, 36))

    # Dashed centre markers make the racing direction easier to see.
    for z in range(-15, 16, 3):
        _add_marker(Vector3(0, 0.005, z), Vector3(0.18, 0.02, 1.0))

    # Start line.
    for x in range(-3, 4):
        var color := Color("#f5f7ff") if x % 2 == 0 else Color("#18202b")
        _add_marker(Vector3(float(x) * 0.8, 0.02, 9.0),
            Vector3(0.78, 0.04, 0.65), color)

func _add_wall(pos: Vector3, dimensions: Vector3) -> void:
    var wall := StaticBody3D.new()
    wall.position = pos
    add_child(wall)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#718096")
    mesh_instance.material_override = material
    wall.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    wall.add_child(collision)

func _add_marker(pos: Vector3, dimensions: Vector3,
        color: Color = Color("#43d9b0")) -> void:
    var marker := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    marker.mesh = mesh
    marker.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    marker.material_override = material
    add_child(marker)

func _build_camera() -> void:
    var camera := Camera3D.new()
    camera.position = Vector3(0, 30, 23)
    camera.rotation_degrees = Vector3(-48, 0, 0)
    camera.current = true
    camera.fov = 58
    add_child(camera)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_energy = 1.2
    add_child(light)

    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#a5bfdc")
    environment.ambient_light_energy = 0.65
    environment_node.environment = environment
    add_child(environment_node)

func _create_racer(index: int) -> void:
    var car := CharacterBody3D.new()
    car.name = "Racer" + str(index + 1)
    car.position = Vector3((float(index) - 1.5) * 1.8, 0.35, 8.0)
    add_child(car)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.05, 0.55, 1.7)
    collision.shape = shape
    car.add_child(collision)

    var body_mesh := MeshInstance3D.new()
    var body_box := BoxMesh.new()
    body_box.size = Vector3(1.0, 0.45, 1.55)
    body_mesh.mesh = body_box
    var material := StandardMaterial3D.new()
    material.albedo_color = CAR_COLORS[index]
    material.metallic = 0.15
    material.roughness = 0.42
    body_mesh.material_override = material
    car.add_child(body_mesh)

    var cabin := MeshInstance3D.new()
    var cabin_box := BoxMesh.new()
    cabin_box.size = Vector3(0.62, 0.3, 0.7)
    cabin.mesh = cabin_box
    cabin.position = Vector3(0, 0.32, 0.05)
    var cabin_material := StandardMaterial3D.new()
    cabin_material.albedo_color = Color("#172333")
    cabin.material_override = cabin_material
    car.add_child(cabin)

    var label := Label3D.new()
    label.text = "P" + str(index + 1) if index < player_count else "BOT"
    label.position = Vector3(0, 1.0, 0)
    label.font_size = 32
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    car.add_child(label)

    racers.append({
        "body": car,
        "speed": 0.0,
        "checkpoint": 0,
        "lap": 0,
        "done": false,
        "bot": player_count == 1 and index > 0,
        "index": index
    })

func _physics_process(delta: float) -> void:
    if finished:
        return

    race_time += delta

    for racer in racers:
        if racer["done"]:
            continue

        var car: CharacterBody3D = racer["body"]
        var index: int = racer["index"]
        var throttle := 0.0
        var steering := 0.0

        if racer["bot"]:
            var target: Vector3 = WAYPOINTS[int(racer["checkpoint"])]
            var to_target := target - car.global_position
            var desired_angle := atan2(to_target.x, to_target.z)
            var angle_difference := wrapf(
                desired_angle - car.rotation.y, -PI, PI)
            steering = clampf(angle_difference * 2.0, -1.0, 1.0)
            throttle = 1.0 if absf(angle_difference) < 1.5 else 0.55
        else:
            var keys: Dictionary = PLAYER_KEYS[index]
            throttle = float(Input.is_key_pressed(keys["up"])) \
                - float(Input.is_key_pressed(keys["down"]))
            steering = float(Input.is_key_pressed(keys["right"])) \
                - float(Input.is_key_pressed(keys["left"]))

        var speed: float = racer["speed"]
        speed += throttle * 13.0 * delta
        if throttle == 0.0:
            speed = move_toward(speed, 0.0, 4.0 * delta)
        speed = clampf(speed, -5.0, 12.0)

        var turn_factor := clampf(absf(speed) / 3.0, 0.0, 1.0)
        car.rotation.y += steering * 1.8 * turn_factor * delta \
            * (1.0 if speed >= 0.0 else -1.0)

        var forward := Vector3(sin(car.rotation.y), 0, cos(car.rotation.y))
        car.velocity.x = forward.x * speed
        car.velocity.z = -forward.z * speed
        car.velocity.y = 0.0
        car.move_and_slide()

        racer["speed"] = speed
        _update_checkpoint(racer)

    _refresh_hud()

func _update_checkpoint(racer: Dictionary) -> void:
    var car: CharacterBody3D = racer["body"]
    var checkpoint: int = racer["checkpoint"]
    if car.global_position.distance_to(WAYPOINTS[checkpoint]) > 3.0:
        return

    racer["checkpoint"] = (checkpoint + 1) % WAYPOINTS.size()
    if checkpoint == WAYPOINTS.size() - 1:
        racer["lap"] += 1
        if int(racer["lap"]) >= 3:
            racer["done"] = true

    if racer["done"]:
        var all_done := true
        for entry in racers:
            if not entry["done"]:
                all_done = false
                break
        if all_done:
            finished = true
            help_label.text = "RACE FINISHED  •  Press R to race again"

func _process(_delta: float) -> void:
    if finished and Input.is_key_pressed(KEY_R):
        get_tree().reload_current_scene()
    if Input.is_key_pressed(KEY_ESCAPE):
        get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(14, 14)
    layer.add_child(panel)

    var column := VBoxContainer.new()
    panel.add_child(column)

    hud = Label.new()
    hud.add_theme_font_size_override("font_size", 18)
    column.add_child(hud)

    help_label = Label.new()
    help_label.text = "WASD: P1  |  Arrows: P2  |  IJKL: P3  |  TFGH: P4"
    help_label.add_theme_font_size_override("font_size", 13)
    column.add_child(help_label)

    var back := Button.new()
    back.text = "BACK TO MENU (Esc)"
    back.pressed.connect(
        func() -> void:
            get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
    )
    column.add_child(back)

func _refresh_hud() -> void:
    if hud == null:
        return
    var lines := ["MICRO RACERS  •  3 LAPS"]
    for racer in racers:
        var number := int(racer["index"]) + 1
        var name := "P" + str(number) if number <= player_count else "BOT " + str(number)
        lines.append("%s: Lap %d/3%s" % [
            name, mini(int(racer["lap"]) + 1, 3),
            "  FINISHED" if racer["done"] else ""
        ])
    hud.text = "\n".join(lines)
