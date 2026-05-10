class_name RealmNodeData
extends Resource

@export var node_id := ""
@export_enum("start", "normal_battle", "mystery_event", "rest_site", "boss") var node_type := "normal_battle"
@export var connected_node_ids: Array[String] = []
@export var preview_reward_text := ""
@export var payload_id := ""
