# hera.gd
extends Node2D

var touching_heracle: bool = false
var collision_platform: CollisionShape2D
var collision_hummingbird: CollisionShape2D
var area_hummingbird: Area2D
var ability: DataManager.HeraAbility
var static_body: StaticBody2D
var hera_bow: bool = false

func _ready():
	# Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	ability = DataManager.progress.selected_abilities[DataManager.Characters.HERA]
	static_body = $StaticBody2D
	static_body.collision_layer = 8
	collision_platform = $StaticBody2D/collision_platform
	collision_hummingbird = $Area2D/collision_hummingbird
	area_hummingbird = $Area2D
	area_hummingbird.monitoring = true
	area_hummingbird.collision_layer = 8

func _input(event):
	if event.is_action_pressed("hera-activate"):
		match ability:
			DataManager.HeraAbility.STATE_PLATFORM:
				hera_platform()
			DataManager.HeraAbility.STATE_SHIELD:
				hera_sheild()
			DataManager.HeraAbility.STATE_WEAPON:
				hera_weapon()
	if event.is_action_pressed("hera-toggle"):
		DataManager.ram["hera_active"] = true
		DataManager.switch_ability(DataManager.Characters.HERA)
		ability = DataManager.progress.selected_abilities[DataManager.Characters.HERA]

# Platform
func hera_platform():
	DataManager.ram["hera_active"] = false
	static_body.collision_layer = 1
	await get_tree().create_timer(1).timeout
	static_body.collision_layer = 8
	DataManager.ram["hera_active"] = true

# Shield
func hera_sheild():
	pass

# Weapon
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

# Other
func collision_manager():
	collision_platform.disabled = true
	collision_hummingbird.disabled = true
	if DataManager.ram["hera_active"]:
		collision_hummingbird.disabled = false
	else:
		match ability:
			DataManager.HeraAbility.STATE_PLATFORM:
				collision_platform.disabled = false
			DataManager.HeraAbility.STATE_WEAPON:
				pass
			DataManager.HeraAbility.STATE_SHIELD:
				pass
			DataManager.HeraAbility.STATE_LEVELIO:
				pass

func movement():
	if DataManager.ram["hera_active"]:
		position += (get_global_mouse_position() - position) / 5

func _physics_process(_delta: float) -> void:
	collision_manager()
	movement()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Heracle":
		touching_heracle = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Heracle":
		touching_heracle = false
