extends StaticBody3D

# ArcherTower.gd - Torre de Vigia de Madeira
# Arqueiros sobem automaticamente para a plataforma elevada, ganhando alcance e dano

@export var max_garrison: int = 3
@export var platform_height: float = 3.2

const CHECK_INTERVAL: float = 0.2

var garrisoned_archers: Array[Node3D] = []
var _check_timer: float = 0.0

@onready var garrison_area: Area3D = $GarrisonArea
@onready var platform_marker: Marker3D = $PlatformMarker

func _ready() -> void:
	add_to_group("towers")
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if garrison_area:
		garrison_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if garrisoned_archers.size() >= max_garrison:
		set_process(false)
		return
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	# Verifica se há arqueiros livres perto do pé da torre
	for troop in get_tree().get_nodes_in_group("troops"):
		if is_instance_valid(troop) and troop.troop_id == "archer" and not troop.is_mounted_on_tower:
			var dist = global_position.distance_to(troop.global_position)
			if dist <= 3.8:
				_mount_archer(troop)
				if garrisoned_archers.size() >= max_garrison:
					set_process(false)
					break

func _mount_archer(archer: Node3D) -> void:
	if garrisoned_archers.has(archer):
		return
		
	garrisoned_archers.append(archer)
	var idx = garrisoned_archers.size() - 1
	var offset = Vector3((idx - 1) * 0.6, platform_height, 0)
	archer.mount_on_tower(self, global_position + offset)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("troops") and body.get("troop_id") == "archer" and not body.is_mounted_on_tower:
		if garrisoned_archers.size() < max_garrison:
			_mount_archer(body)

