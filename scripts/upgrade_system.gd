extends Node

# All available upgrades
var all_upgrades: Dictionary = {}

func _ready():
	create_upgrades()

func create_upgrades():
	# Upgrade 1: Power Shot - Increase damage
	var power_shot = UpgradeMeta.new()
	power_shot.upgrade_id = "damage_boost"
	power_shot.upgrade_name = "Power Shot"
	power_shot.upgrade_description = "Increase projectile damage by 10%"
	power_shot.callback_name = "apply_damage_boost"
	all_upgrades["damage_boost"] = power_shot

	# Upgrade 2: Rapid Fire - Increase fire rate
	var rapid_fire = UpgradeMeta.new()
	rapid_fire.upgrade_id = "fire_rate_boost"
	rapid_fire.upgrade_name = "Rapid Fire"
	rapid_fire.upgrade_description = "Shoot 10% faster"
	rapid_fire.callback_name = "apply_fire_rate_boost"
	all_upgrades["fire_rate_boost"] = rapid_fire

	# Upgrade 3: Swift Feet - Increase movement speed
	var swift_feet = UpgradeMeta.new()
	swift_feet.upgrade_id = "speed_boost"
	swift_feet.upgrade_name = "Swift Feet"
	swift_feet.upgrade_description = "Move 10% faster"
	swift_feet.callback_name = "apply_speed_boost"
	all_upgrades["speed_boost"] = swift_feet

	# Upgrade 4: Vitality - Increase max health
	var vitality = UpgradeMeta.new()
	vitality.upgrade_id = "health_boost"
	vitality.upgrade_name = "Vitality"
	vitality.upgrade_description = "Gain 20 max HP (healed to full)"
	vitality.callback_name = "apply_health_boost"
	all_upgrades["health_boost"] = vitality

	# Upgrade 5: Multi-Shot - Fire multiple projectiles
	var multi_shot = UpgradeMeta.new()
	multi_shot.upgrade_id = "multi_shot"
	multi_shot.upgrade_name = "Multi-Shot"
	multi_shot.upgrade_description = "Shoot 1 additional projectile"
	multi_shot.callback_name = "apply_multi_shot"
	all_upgrades["multi_shot"] = multi_shot

	# Upgrade 6: Regeneration - Heal over time
	var regeneration = UpgradeMeta.new()
	regeneration.upgrade_id = "regeneration"
	regeneration.upgrade_name = "Regeneration"
	regeneration.upgrade_description = "Heal 5 HP per second"
	regeneration.callback_name = "apply_regeneration"
	all_upgrades["regeneration"] = regeneration

	# Upgrade 7: Piercing Shots - Projectiles pierce enemies
	var piercing = UpgradeMeta.new()
	piercing.upgrade_id = "piercing"
	piercing.upgrade_name = "Piercing Shots"
	piercing.upgrade_description = "Projectiles hit 1 additional enemy"
	piercing.callback_name = "apply_piercing"
	all_upgrades["piercing"] = piercing

	# Upgrade 8: Projectile Range - Faster projectiles
	var range_boost = UpgradeMeta.new()
	range_boost.upgrade_id = "range_boost"
	range_boost.upgrade_name = "Long Range"
	range_boost.upgrade_description = "Projectiles fly 20% faster"
	range_boost.callback_name = "apply_range_boost"
	all_upgrades["range_boost"] = range_boost

	# Upgrade 9: Magnetic Field - Bigger XP pickup radius
	var magnet = UpgradeMeta.new()
	magnet.upgrade_id = "magnet"
	magnet.upgrade_name = "Magnetic Field"
	magnet.upgrade_description = "XP orbs attracted from farther away"
	magnet.callback_name = "apply_magnet"
	all_upgrades["magnet"] = magnet

	# Upgrade 10: Fortify - Reduce damage taken
	var fortify = UpgradeMeta.new()
	fortify.upgrade_id = "fortify"
	fortify.upgrade_name = "Fortify"
	fortify.upgrade_description = "Reduce damage taken by 10%"
	fortify.callback_name = "apply_fortify"
	all_upgrades["fortify"] = fortify

	# NEW PASSIVE UPGRADES
	# Upgrade 11: Shield - Extra hit protection
	var shield = UpgradeMeta.new()
	shield.upgrade_id = "shield"
	shield.upgrade_name = "Shield"
	shield.upgrade_description = "Gain 1 extra hit before taking damage"
	shield.callback_name = "apply_shield"
	all_upgrades["shield"] = shield

	# Upgrade 12: Lifesteal
	var lifesteal = UpgradeMeta.new()
	lifesteal.upgrade_id = "lifesteal"
	lifesteal.upgrade_name = "Lifesteal"
	lifesteal.upgrade_description = "Heal 5 HP when killing enemies"
	lifesteal.callback_name = "apply_lifesteal"
	all_upgrades["lifesteal"] = lifesteal

	# Upgrade 13: Thorns - Reflect damage
	var thorns = UpgradeMeta.new()
	thorns.upgrade_id = "thorns"
	thorns.upgrade_name = "Thorns"
	thorns.upgrade_description = "Enemies take 20 damage when hitting you"
	thorns.callback_name = "apply_thorns"
	all_upgrades["thorns"] = thorns

	# Upgrade 14: Knockback
	var knockback = UpgradeMeta.new()
	knockback.upgrade_id = "knockback"
	knockback.upgrade_name = "Knockback"
	knockback.upgrade_description = "Projectiles push enemies back"
	knockback.callback_name = "apply_knockback"
	all_upgrades["knockback"] = knockback

	# Upgrade 15: Explosion on Kill
	var explosion_kill = UpgradeMeta.new()
	explosion_kill.upgrade_id = "explosion_kill"
	explosion_kill.upgrade_name = "Chain Reaction"
	explosion_kill.upgrade_description = "Enemies explode on death, damaging nearby foes"
	explosion_kill.callback_name = "apply_explosion_kill"
	all_upgrades["explosion_kill"] = explosion_kill

	# Upgrade 16: Dash Cooldown Reduction
	var dash_cdr = UpgradeMeta.new()
	dash_cdr.upgrade_id = "dash_cdr"
	dash_cdr.upgrade_name = "Swift Dash"
	dash_cdr.upgrade_description = "Dash cooldown reduced by 20%"
	dash_cdr.callback_name = "apply_dash_cdr"
	all_upgrades["dash_cdr"] = dash_cdr

	# Upgrade 17: Ultimate Cooldown Reduction
	var ultimate_cdr = UpgradeMeta.new()
	ultimate_cdr.upgrade_id = "ultimate_cdr"
	ultimate_cdr.upgrade_name = "Quick Charge"
	ultimate_cdr.upgrade_description = "Ultimate cooldown reduced by 20%"
	ultimate_cdr.callback_name = "apply_ultimate_cdr"
	all_upgrades["ultimate_cdr"] = ultimate_cdr

	# Upgrade 18: Luck
	var luck = UpgradeMeta.new()
	luck.upgrade_id = "luck"
	luck.upgrade_name = "Lucky Charm"
	luck.upgrade_description = "15% more XP and coins from drops"
	luck.callback_name = "apply_luck"
	all_upgrades["luck"] = luck

	# Upgrade 19: Projectile Size
	var proj_size = UpgradeMeta.new()
	proj_size.upgrade_id = "projectile_size"
	proj_size.upgrade_name = "Giant Bullets"
	proj_size.upgrade_description = "Projectiles 25% bigger (easier to hit)"
	proj_size.callback_name = "apply_projectile_size"
	all_upgrades["projectile_size"] = proj_size

	# Upgrade 20: Critical Damage
	var crit_damage = UpgradeMeta.new()
	crit_damage.upgrade_id = "crit_damage"
	crit_damage.upgrade_name = "Deadly Crits"
	crit_damage.upgrade_description = "Critical hits deal 50% more damage"
	crit_damage.callback_name = "apply_crit_damage"
	all_upgrades["crit_damage"] = crit_damage

	# Upgrade 21: Area Damage
	var area_damage = UpgradeMeta.new()
	area_damage.upgrade_id = "area_damage"
	area_damage.upgrade_name = "Area Master"
	area_damage.upgrade_description = "All AoE effects deal 15% more damage"
	area_damage.callback_name = "apply_area_damage"
	all_upgrades["area_damage"] = area_damage

	# NEW WEAPONS
	# Upgrade 11: Laser Weapon
	var laser = UpgradeMeta.new()
	laser.upgrade_id = "laser_weapon"
	laser.upgrade_name = "Laser Beam"
	laser.upgrade_description = "Unlock laser that penetrates many enemies!"
	laser.callback_name = "apply_laser_weapon"
	all_upgrades["laser_weapon"] = laser

	# Upgrade 12: Shotgun
	var shotgun = UpgradeMeta.new()
	shotgun.upgrade_id = "shotgun"
	shotgun.upgrade_name = "Shotgun"
	shotgun.upgrade_description = "Shoot 3 pellets in a spread pattern!"
	shotgun.callback_name = "apply_shotgun"
	all_upgrades["shotgun"] = shotgun

	# Upgrade 13: Orbiting Bullets
	var orbiting = UpgradeMeta.new()
	orbiting.upgrade_id = "orbiting_bullets"
	orbiting.upgrade_name = "Orbiting Shield"
	orbiting.upgrade_description = "Bullets orbit around you, damaging enemies!"
	orbiting.callback_name = "apply_orbiting_bullets"
	all_upgrades["orbiting_bullets"] = orbiting

	# Upgrade 14: Homing Missiles
	var homing = UpgradeMeta.new()
	homing.upgrade_id = "homing_missiles"
	homing.upgrade_name = "Homing Missiles"
	homing.upgrade_description = "Fire missiles that seek out enemies!"
	homing.callback_name = "apply_homing_missiles"
	all_upgrades["homing_missiles"] = homing

	# NEW WEAPONS BATCH 2
	# Upgrade 15: Chain Lightning
	var chain_lightning = UpgradeMeta.new()
	chain_lightning.upgrade_id = "chain_lightning"
	chain_lightning.upgrade_name = "Chain Lightning"
	chain_lightning.upgrade_description = "Lightning bounces between 4 enemies!"
	chain_lightning.callback_name = "apply_chain_lightning"
	all_upgrades["chain_lightning"] = chain_lightning

	# Upgrade 16: Boomerang
	var boomerang = UpgradeMeta.new()
	boomerang.upgrade_id = "boomerang"
	boomerang.upgrade_name = "Boomerang"
	boomerang.upgrade_description = "Hits enemies twice - out and back!"
	boomerang.callback_name = "apply_boomerang"
	all_upgrades["boomerang"] = boomerang

	# Upgrade 17: Flamethrower
	var flamethrower = UpgradeMeta.new()
	flamethrower.upgrade_id = "flamethrower"
	flamethrower.upgrade_name = "Flamethrower"
	flamethrower.upgrade_description = "Continuous flame cone in front of you!"
	flamethrower.callback_name = "apply_flamethrower"
	all_upgrades["flamethrower"] = flamethrower

	# Upgrade 18: Toxic Pools
	var toxic_pools = UpgradeMeta.new()
	toxic_pools.upgrade_id = "toxic_pools"
	toxic_pools.upgrade_name = "Toxic Pools"
	toxic_pools.upgrade_description = "Enemies leave toxic pools on death!"
	toxic_pools.callback_name = "apply_toxic_pools"
	all_upgrades["toxic_pools"] = toxic_pools

	# Upgrade 19: Sniper Rifle
	var sniper = UpgradeMeta.new()
	sniper.upgrade_id = "sniper"
	sniper.upgrade_name = "Sniper Rifle"
	sniper.upgrade_description = "High damage, slow fire, pierces enemies!"
	sniper.callback_name = "apply_sniper"
	all_upgrades["sniper"] = sniper

	# Upgrade 20: Ice Beam
	var ice_beam = UpgradeMeta.new()
	ice_beam.upgrade_id = "ice_beam"
	ice_beam.upgrade_name = "Ice Beam"
	ice_beam.upgrade_description = "Slows enemies by 50% for 2 seconds!"
	ice_beam.callback_name = "apply_ice_beam"
	all_upgrades["ice_beam"] = ice_beam

func get_random_upgrades(count: int, player: Node = null) -> Array:
	var available = []

	# Get list of weapon upgrade IDs
	var weapon_ids = ["laser_weapon", "shotgun", "orbiting_bullets", "homing_missiles",
	                  "chain_lightning", "boomerang", "flamethrower", "toxic_pools",
	                  "sniper", "ice_beam"]

	var max_weapon_level = 5  # Weapons can be upgraded 5 times

	# Count how many extra weapons player has (for first-time unlocks)
	var active_weapon_count = 0
	if player:
		if player.has_laser: active_weapon_count += 1
		if player.has_shotgun: active_weapon_count += 1
		if player.has_orbiting_bullets: active_weapon_count += 1
		if player.has_homing_missiles: active_weapon_count += 1
		if player.has_chain_lightning: active_weapon_count += 1
		if player.has_boomerang: active_weapon_count += 1
		if player.has_flamethrower: active_weapon_count += 1
		if player.has_toxic_pools: active_weapon_count += 1
		if player.has_sniper: active_weapon_count += 1
		if player.has_ice_beam: active_weapon_count += 1

	for upgrade_id in all_upgrades.keys():
		var is_weapon = upgrade_id in weapon_ids

		# If it's a weapon upgrade
		if is_weapon:
			if player:
				# Check weapon level - skip if maxed out
				var weapon_level = get_weapon_level(player, upgrade_id)

				# If player doesn't have weapon yet
				if weapon_level == 0:
					# Skip if player already has max weapons (2 extra)
					if active_weapon_count >= 2:
						continue
				else:
					# Player has weapon - check if it's maxed
					if weapon_level >= max_weapon_level:
						continue  # Skip maxed weapons

		# Add to available list
		available.append(upgrade_id)

	available.shuffle()
	return available.slice(0, min(count, available.size()))

func get_weapon_level(player: Node, weapon_id: String) -> int:
	match weapon_id:
		"laser_weapon":
			return player.laser_level if player.has_laser else 0
		"shotgun":
			return player.shotgun_level if player.has_shotgun else 0
		"orbiting_bullets":
			return player.orbiting_level if player.has_orbiting_bullets else 0
		"homing_missiles":
			return player.homing_level if player.has_homing_missiles else 0
		"chain_lightning":
			return player.lightning_level if player.has_chain_lightning else 0
		"boomerang":
			return player.boomerang_level if player.has_boomerang else 0
		"flamethrower":
			return player.flamethrower_level if player.has_flamethrower else 0
		"toxic_pools":
			return player.toxic_pools_level if player.has_toxic_pools else 0
		"sniper":
			return player.sniper_level if player.has_sniper else 0
		"ice_beam":
			return player.ice_beam_level if player.has_ice_beam else 0
	return 0

func get_weapon_upgrade_description(weapon_id: String, current_level: int) -> String:
	# Returns description for NEXT level (current_level + 1)
	var next_level = current_level + 1

	match weapon_id:
		"laser_weapon":
			match next_level:
				1: return "Unlock laser that penetrates many enemies!"
				2: return "Level 2: +30% damage"
				3: return "Level 3: +50% faster fire rate"
				4: return "Level 4: +50% longer range"
				5: return "Level 5: +50% damage (MAX)"

		"shotgun":
			match next_level:
				1: return "Shoot 3 pellets in a spread pattern!"
				2: return "Level 2: Fire 5 pellets instead of 3"
				3: return "Level 3: +40% damage per pellet"
				4: return "Level 4: Tighter spread pattern"
				5: return "Level 5: Fire 7 pellets! (MAX)"

		"orbiting_bullets":
			match next_level:
				1: return "Bullets orbit around you, damaging enemies!"
				2: return "Level 2: +2 orbiting bullets"
				3: return "Level 3: +30% damage"
				4: return "Level 4: +30% rotation speed"
				5: return "Level 5: +3 more bullets! (MAX)"

		"homing_missiles":
			match next_level:
				1: return "Fire missiles that seek out enemies!"
				2: return "Level 2: +40% damage"
				3: return "Level 3: Fire 2 missiles at once"
				4: return "Level 4: +50% tracking speed"
				5: return "Level 5: Fire 3 missiles! (MAX)"

		"chain_lightning":
			match next_level:
				1: return "Lightning bounces between 4 enemies!"
				2: return "Level 2: Bounces to 6 enemies"
				3: return "Level 3: +30% damage"
				4: return "Level 4: Bounces to 8 enemies"
				5: return "Level 5: -30% cooldown (MAX)"

		"boomerang":
			match next_level:
				1: return "Hits enemies twice - out and back!"
				2: return "Level 2: Throw 2 boomerangs"
				3: return "Level 3: +30% range"
				4: return "Level 4: +50% return speed"
				5: return "Level 5: Throw 3 boomerangs! (MAX)"

		"flamethrower":
			match next_level:
				1: return "Continuous flame cone in front of you!"
				2: return "Level 2: 90° cone (from 60°)"
				3: return "Level 3: +50% range"
				4: return "Level 4: Double tick rate (60 DPS)"
				5: return "Level 5: 120° cone! (MAX)"

		"toxic_pools":
			match next_level:
				1: return "Enemies leave toxic pools on death!"
				2: return "Level 2: +50% bigger pools"
				3: return "Level 3: Pools last 60% longer"
				4: return "Level 4: +50% damage"
				5: return "Level 5: Huge toxic zones! (MAX)"
		"sniper":
			match next_level:
				1: return "High damage, slow fire, pierces enemies!"
				2: return "Level 2: Pierce 2 enemies"
				3: return "Level 3: Fire 2 shots"
				4: return "Level 4: +50% damage"
				5: return "Level 5: Fire 3 shots! (MAX)"
		"ice_beam":
			match next_level:
				1: return "Slows enemies by 50% for 2 seconds!"
				2: return "Level 2: 70% slow"
				3: return "Level 3: Fire 2 beams"
				4: return "Level 4: 3 second slow"
				5: return "Level 5: Fire 3 beams! (MAX)"

	return "Unknown upgrade"

func apply_upgrade(upgrade_id: String, player: Node):
	if all_upgrades.has(upgrade_id):
		var upgrade = all_upgrades[upgrade_id]
		# Call upgrade effect on player
		if player.has_method(upgrade.callback_name):
			player.call(upgrade.callback_name)

		# Track active upgrade
		if not player.active_upgrades.has(upgrade_id):
			player.active_upgrades[upgrade_id] = 0
		player.active_upgrades[upgrade_id] += 1
