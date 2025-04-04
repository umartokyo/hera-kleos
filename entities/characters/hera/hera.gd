extends Node2D

var touching_heracle: bool = false
var collision_platform: CollisionShape2D
var collision_hummingbird: CollisionShape2D
var ability: DataManager.HeraAbility
var area2d_node: Area2D
var static_body: StaticBody2D
var hera_bow: bool = false
var animation_free: bool = true
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
var hera_mouse_pos: Vector2
var prev_mouse_pos: Vector2
@export var platform_time = 1

func _ready():
	add_to_group("hera")
	DataManager.hera_safe_pos()
	if DataManager.progress.selected_abilities[DataManager.Characters.HERA]:
		ability = DataManager.progress.selected_abilities[DataManager.Characters.HERA]
	static_body = $StaticBody2D
	area2d_node = $Area2D
	static_body.collision_layer = 8
	collision_platform = $StaticBody2D/collision_platform
	collision_hummingbird = $Area2D/collision_hummingbird
	prev_mouse_pos = get_global_mouse_position()

func _input(event):
	if event.is_action_pressed("hera-activate"):
		match ability:
			DataManager.HeraAbility.STATE_PLATFORM:
				hera_platform()
			DataManager.HeraAbility.STATE_WEAPON:
				hera_weapon()
	if event.is_action_pressed("hera-toggle"):
		DataManager.ram["hera_active"] = true
		DataManager.switch_ability(DataManager.Characters.HERA)
		ability = DataManager.progress.selected_abilities[DataManager.Characters.HERA]

func hera_platform():
	DataManager.ram["hera_active"] = false
	static_body.collision_layer = 1
	await get_tree().create_timer(platform_time).timeout
	static_body.collision_layer = 8
	DataManager.ram["hera_active"] = true

func hera_weapon():
	var heracle_ability = DataManager.progress["selected_abilities"][DataManager.Characters.HERACLE]
	match heracle_ability:
		DataManager.HeracleAbility.CLUB:
			if touching_heracle:
				DataManager.ram["hera_active"] = false
				print("Hera Enters the Club")
		DataManager.HeracleAbility.SWORD:
			if touching_heracle:
				DataManager.ram["hera_active"] = false
				print("Hera Enters the Sword")
		DataManager.HeracleAbility.BOW:
			hera_bow = true

func collision_manager():
	collision_platform.disabled = true
	if DataManager.ram["hera_active"]:
		play_animations("idle")
		animation_free = true
	else:
		match ability:
			DataManager.HeraAbility.STATE_PLATFORM:
				collision_platform.disabled = false
				play_animations("platform")
				animation_free = false

func play_animations(animation_name):
	if animation_free:
		animation.play(animation_name)

func movement():
	if animation_free:
		sprite.flip_h = hera_mouse_pos.x < position.x

	if DataManager.ram["hera_active"] and not DataManager.ram["game_paused"]:
		position += (hera_mouse_pos - position) / 10

	prev_mouse_pos = hera_mouse_pos

func collision_check():
	DataManager.ram["hera_at_level_end"] = false
	for body in area2d_node.get_overlapping_bodies():
		if body.name == "Heracle":
			touching_heracle = true

		if (body.name == "Obstacle Hera" or body.name == "Obstacle Both"):
			DataManager.game_stats["deaths_hera"] += 1
			DataManager.ram["hera_dead"] = true

		if body.name == "LevelEnd":
			DataManager.ram["hera_at_level_end"] = true

func _physics_process(_delta: float) -> void:
	if not DataManager.ram["hera_dead"]:
		hera_mouse_pos = get_global_mouse_position()
		collision_manager()
		collision_check()
		movement()
		mouse_visibility()
		speed_limit()
	else:
		hera_spawn()

func hera_spawn():
	collision_hummingbird.disabled = true
	$AnimationPlayer.play("death")
	await $AnimationPlayer.animation_finished
	DataManager.hera_safe_pos()
	DataManager.ram["hera_dead"] = false
	await get_tree().create_timer(0.3).timeout
	collision_hummingbird.disabled = false

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Heracle":
		touching_heracle = false

func mouse_visibility():
	if (not DataManager.ram["game_paused"]) and is_hera_on_screen():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func is_hera_on_screen() -> bool:
	var pos = get_viewport().get_mouse_position()
	var size = get_viewport().get_visible_rect().size
	return pos.x >= 0 and pos.y >= 0 and pos.x <= size.x and pos.y <= size.y

func speed_limit():
	if DataManager.ram["hera_too_fast"]:
		hera_spawn()
		DataManager.ram["hera_too_fast"] = false
