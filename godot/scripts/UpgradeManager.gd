extends Node
# UpgradeManager: Holds upgrade definitions and applies chosen upgrades to the player.

signal upgrade_applied(upgrade: Dictionary)

# All available upgrades
const UPGRADES := [
	{
		"id": "speed_boost",
		"name": "Swift Leap",
		"description": "+20% movement speed",
		"icon_color": Color(0.2, 0.8, 0.4)
	},
	{
		"id": "attack_speed",
		"name": "Blade Dance",
		"description": "Attack cooldown -0.2s",
		"icon_color": Color(0.9, 0.3, 0.2)
	},
	{
		"id": "damage_up",
		"name": "Iron Katana",
		"description": "+25% sword damage",
		"icon_color": Color(0.7, 0.7, 0.7)
	},
	{
		"id": "health_up",
		"name": "Lotus Shield",
		"description": "+30 max HP and heal 15",
		"icon_color": Color(0.9, 0.6, 0.1)
	},
	{
		"id": "pickup_range",
		"name": "Pond Aura",
		"description": "+50% XP pickup radius",
		"icon_color": Color(0.2, 0.5, 0.9)
	},
	{
		"id": "multishot",
		"name": "Twin Slash",
		"description": "Fire an extra projectile",
		"icon_color": Color(0.8, 0.2, 0.9)
	},
	{
		"id": "proj_speed",
		"name": "Wind Cutter",
		"description": "+30% projectile speed",
		"icon_color": Color(0.3, 0.9, 0.9)
	},
	{
		"id": "regen",
		"name": "Lily Regen",
		"description": "Regenerate 1 HP/sec",
		"icon_color": Color(0.4, 0.9, 0.3)
	},
]

func get_random_upgrades(count: int = 3) -> Array:
	var pool := UPGRADES.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))

func apply_upgrade(upgrade: Dictionary, player: Node) -> void:
	match upgrade["id"]:
		"speed_boost":
			player.move_speed *= 1.2
		"attack_speed":
			player.weapon_manager.attack_cooldown = max(0.3, player.weapon_manager.attack_cooldown - 0.2)
		"damage_up":
			player.weapon_manager.damage = int(player.weapon_manager.damage * 1.25)
		"health_up":
			player.max_health += 30
			player.health = min(player.health + 15, player.max_health)
			player.health_changed.emit(player.health, player.max_health)
		"pickup_range":
			player.pickup_radius *= 1.5
		"multishot":
			player.weapon_manager.projectile_count += 1
		"proj_speed":
			player.weapon_manager.projectile_speed *= 1.3
		"regen":
			player.regen_per_second += 1.0

	upgrade_applied.emit(upgrade)
