extends CharacterBody2D

# Signals
signal took_damage

# Character configuration
var character_config: CharacterConfig = null
var character_id: String = "warrior"  # Store which character is selected

# Equipment system
var equipment_manager: EquipmentManager = null
var equipped_weapon_sprite: Sprite2D = null  # Visual sprite for equipped weapon

# Movement settings
var move_speed: float = 200.0  # pixels per second

# Detection settings
var detection_radius: float = 500.0  # Only shoot enemies within this radius

# Weapon settings
var projectile_scene = preload("res://scenes/projectile.tscn")
var laser_scene = preload("res://scenes/laser_projectile.tscn")
var orbiting_bullet_scene = preload("res://scenes/orbiting_bullet.tscn")
var homing_missile_scene = preload("res://scenes/homing_missile.tscn")
var chain_lightning_scene = preload("res://scenes/chain_lightning.tscn")
var boomerang_scene = preload("res://scenes/boomerang.tscn")
var flamethrower_scene = preload("res://scenes/flamethrower.tscn")
var toxic_pool_scene = preload("res://scenes/toxic_pool.tscn")
var sniper_scene = preload("res://scenes/sniper_projectile.tscn")
var ice_beam_scene = preload("res://scenes/ice_beam.tscn")

var shoot_interval: float = 0.5  # Shoot every 0.5 seconds
var shoot_timer: float = 0.0
var shooting_enabled: bool = true  # Toggle for testing
var p_key_was_pressed: bool = false

# Active weapons
var has_laser: bool = false
var laser_timer: float = 0.0
var laser_interval: float = 1.0  # Slower than normal shots
var laser_level: int = 0

var has_shotgun: bool = false
var shotgun_level: int = 0

var has_orbiting_bullets: bool = false
var orbiting_bullets: Array = []  # Track active orbiting bullets
var orbiting_level: int = 0

var has_homing_missiles: bool = false
var homing_timer: float = 0.0
var homing_interval: float = 1.5
var homing_level: int = 0

var has_chain_lightning: bool = false
var lightning_timer: float = 0.0
var lightning_interval: float = 0.8
var lightning_level: int = 0

var has_boomerang: bool = false
var boomerang_timer: float = 0.0
var boomerang_interval: float = 1.2
var boomerang_level: int = 0

var has_flamethrower: bool = false
var flamethrower_instance: Node2D = null
var flamethrower_level: int = 0

var has_toxic_pools: bool = false
var toxic_pools_level: int = 0
var toxic_pool_radius: float = 60.0
var toxic_pool_lifetime: float = 5.0

var has_sniper: bool = false
var sniper_timer: float = 0.0
var sniper_interval: float = 2.0  # Slow fire rate - every 2 seconds
var sniper_level: int = 0

var has_ice_beam: bool = false
var ice_beam_timer: float = 0.0
var ice_beam_interval: float = 0.6  # Moderate fire rate
var ice_beam_level: int = 0

# Particle effects
var levelup_particles = preload("res://scenes/levelup_particles.tscn")

# XP and Level system
var current_level: int = 1
var current_xp: int = 0
var xp_threshold: int = 100  # XP needed for next level
var total_xp_collected: int = 0

# Health system
var max_health: float = 100.0
var current_health: float = 100.0
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var invincibility_duration: float = 0.5  # 0.5 seconds

# Upgrade system
var active_upgrades: Dictionary = {}
var upgrade_ui: CanvasLayer = null  # Reference to UI panel

# Regeneration
var regen_timer: float = 0.0

# Damage reduction
var damage_reduction: float = 0.0

# Passive item bonuses
var passive_damage_boost: float = 0.0
var passive_speed_boost: float = 0.0
var passive_xp_boost: float = 0.0
var passive_pickup_boost: int = 0

# Critical hit system
var crit_chance: float = 0.10  # 10% base crit chance
var crit_multiplier: float = 2.0  # Crits do 2x damage

# New passive upgrades
var shield_charges: int = 0  # Extra hits before taking damage
var has_lifesteal: bool = false
var lifesteal_amount: float = 5.0
var has_thorns: bool = false
var thorns_damage: float = 20.0
var has_knockback: bool = false
var knockback_force: float = 100.0
var has_explosion_kill: bool = false
var explosion_kill_radius: float = 80.0
var explosion_kill_damage: float = 30.0
var luck_multiplier: float = 0.0  # Extra XP/coin percentage
var projectile_size_mult: float = 1.0  # Projectile scale multiplier
var area_damage_mult: float = 0.0  # AoE damage bonus

# Stats tracking
var total_kills: int = 0
var total_boss_kills: int = 0
var total_damage_dealt: float = 0.0
var game_start_time: float = 0.0

# Dash ability
var dash_speed: float = 600.0
var dash_duration: float = 0.2  # 0.2 seconds
var dash_cooldown: float = 2.0  # 2 seconds cooldown
var dash_timer: float = 0.0  # Time since last dash
var is_dashing: bool = false
var dash_time_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Ultimate ability
var ultimate_damage: float = 100.0
var ultimate_radius: float = 400.0  # Screen-wide explosion
var ultimate_cooldown: float = 10.0  # 10 seconds cooldown
var ultimate_timer: float = 0.0  # Starts at 0, counts up to cooldown

# Walk animation
var walk_anim_time: float = 0.0
var walk_bob_amount: float = 2.0  # How many pixels to bob up/down
var walk_bob_speed: float = 10.0  # Speed of bobbing
var sprite_base_y: float = 0.0  # Store original Y position

# Walking animation (procedural)
var walk_cycle_time: float = 0.0
var walk_cycle_speed: float = 8.0  # Speed of animation cycle
var walk_bob_intensity: float = 3.0  # Vertical bobbing
var walk_tilt_intensity: float = 0.08  # Rotation tilt (radians)
var walk_squash_intensity: float = 0.05  # Squash & stretch effect

func load_character_config():
	# Load the selected character (always Wizard for now)
	var selected_character_id = "mage"  # Default to Wizard
	if SaveSystem.has("selected_character"):
		selected_character_id = SaveSystem.get_value("selected_character")

	# Store character ID for later use
	character_id = selected_character_id

	# Load character config
	var character_path = "res://resources/character_%s.tres" % selected_character_id
	if ResourceLoader.exists(character_path):
		character_config = load(character_path)
	else:
		# Fallback to warrior if character not found
		character_config = load("res://resources/character_warrior.tres")

	# Apply character stats
	if character_config:
		max_health = character_config.base_health
		current_health = max_health
		move_speed = character_config.base_speed
		passive_damage_boost = character_config.base_damage_mult - 1.0  # Convert to bonus
		crit_chance += character_config.crit_chance_bonus
		crit_multiplier = character_config.crit_damage_mult
		dash_cooldown *= character_config.dash_cooldown_mult
		passive_pickup_boost += int(character_config.pickup_radius_bonus)
		passive_xp_boost = character_config.xp_gain_mult - 1.0  # Convert to bonus percentage

		# Special abilities
		if character_config.start_with_extra_weapon:
			# Hunter starts with Laser as second weapon
			has_laser = true
			laser_level = 1
			print("Hunter bonus: Starting with Laser weapon!")

		print("Loaded character: %s" % character_config.character_name)
		print("Stats - HP: %.0f, Speed: %.0f, Damage: %.2f" % [max_health, move_speed, passive_damage_boost + 1.0])

	# Load character sprite
	load_character_sprite(selected_character_id)

func load_character_sprite(character_id: String):
	if not has_node("Sprite2D"):
		print("Warning: No Sprite2D node found in player!")
		return

	var sprite = $Sprite2D

	# Load sprite based on character
	match character_id:
		"hunter":
			# Load the Hunter sprite (static image, animated with code)
			var hunter_texture = load("res://Hunter/Hunter2Godot.png")
			if hunter_texture:
				sprite.texture = hunter_texture
				# Scale to game size (larger and more visible)
				sprite.scale = Vector2(0.07, 0.07)  # 1024 * 0.07 ≈ 72 pixels
				print("Loaded Hunter2 sprite!")
			else:
				print("Error: Could not load Hunter2Godot.png")
		"warrior":
			# Load the Warrior sprite
			var warrior_texture = load("res://Warrior/WarriorGodot.png")
			if warrior_texture:
				sprite.texture = warrior_texture
				# Scale to game size (same as other characters)
				sprite.scale = Vector2(0.07, 0.07)  # 1024 * 0.07 ≈ 72 pixels
				print("Loaded WarriorGodot sprite!")
			else:
				print("Error: Could not load WarriorGodot.png")
		"assassin":
			# Load the Assassin sprite
			var assassin_texture = load("res://Assassin/AssassinGodot.png")
			if assassin_texture:
				sprite.texture = assassin_texture
				# Scale to game size (same as Hunter)
				sprite.scale = Vector2(0.07, 0.07)  # 1024 * 0.07 ≈ 72 pixels
				print("Loaded AssassinGodot sprite!")
			else:
				print("Error: Could not load AssassinGodot.png")
		"tank":
			# Load the Tank sprite
			var tank_texture = load("res://Tank/TankGodot.png")
			if tank_texture:
				sprite.texture = tank_texture
				# Scale to game size (same as other characters)
				sprite.scale = Vector2(0.07, 0.07)  # 1024 * 0.07 ≈ 72 pixels
				print("Loaded TankGodot sprite!")
			else:
				print("Error: Could not load TankGodot.png")
		"mage":
			# Load the Wizard sprite WITHOUT staff (staff will be shown separately when equipped)
			var wizard_texture = load("res://Wizard/WizardNoStaffGodot.png")
			if wizard_texture:
				sprite.texture = wizard_texture
				# Scale to game size (same as Hunter)
				sprite.scale = Vector2(0.07, 0.07)  # 1024 * 0.07 ≈ 72 pixels
				print("Loaded WizardNoStaffGodot sprite!")
			else:
				print("Error: Could not load WizardNoStaffGodot.png")
		_:
			sprite.texture = create_placeholder_texture(Color(1, 0, 0, 1))
			sprite.scale = Vector2(1, 1)

func create_placeholder_texture(color: Color) -> ImageTexture:
	# Create a simple colored square as placeholder
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _ready():
	# Initialize position in center of screen
	position = Vector2(640, 360)  # 1280/2, 720/2

	# Create equipped weapon sprite (shown when weapon is equipped)
	equipped_weapon_sprite = Sprite2D.new()
	equipped_weapon_sprite.name = "EquippedWeaponSprite"
	equipped_weapon_sprite.visible = false  # Hidden until weapon is equipped
	equipped_weapon_sprite.z_index = 1  # IN FRONT of player so we can see it!
	add_child(equipped_weapon_sprite)
	print("Created equipped weapon sprite for player")

	# Initialize equipment system
	equipment_manager = EquipmentManager.new()
	add_child(equipment_manager)
	equipment_manager.equipment_changed.connect(_on_equipment_changed)

	# Check for pending gear items from shop
	check_pending_gear_items()

	# Add to player group
	add_to_group("player")

	# Set collision layer (which layer this body is on)
	collision_layer = 1

	# Set collision mask (which layers this body can collide with)
	collision_mask = 1

	# Start with abilities ready
	dash_timer = dash_cooldown
	ultimate_timer = ultimate_cooldown

	# Track game start time for stats
	game_start_time = Time.get_ticks_msec() / 1000.0

	# Load and apply character configuration
	load_character_config()

	# Apply permanent bonuses from SaveSystem
	apply_permanent_bonuses()

	# Create Epic Gloves Godot as starting gear (AFTER character config is loaded)
	var epic_gloves = Item.new()
	epic_gloves.item_name = "Epic Gloves Godot"
	epic_gloves.description = "Legendary gloves forged in the fires of Godot."
	epic_gloves.icon_path = "res://Items/Gloves/EpicGlovesGodot.png"
	epic_gloves.item_type = Item.ItemType.GLOVES
	epic_gloves.rarity = Item.Rarity.EPIC
	# Gloves = Attack Speed and Damage (hand-based attacks)
	epic_gloves.damage_bonus = 0.12  # 12% damage
	epic_gloves.fire_rate_bonus = 0.15  # 15% attack speed
	epic_gloves.crit_chance_bonus = 0.05  # 5% crit
	epic_gloves.sell_value = 200

	equipment_manager.equipped_gloves = epic_gloves
	equipment_manager.equipment_changed.emit()
	print("✅ Epic Gloves Godot equipped!")

	# Create and add all 7 staffs to inventory
	# Staff 1 - Staff of Embers (Common)
	var staff1 = Item.new()
	staff1.item_name = "Staff of Embers"
	staff1.description = "A simple wooden staff with a faint glow."
	staff1.icon_path = "res://Staffs/Staff1Godot.png"
	staff1.item_type = Item.ItemType.WEAPON
	staff1.rarity = Item.Rarity.COMMON
	# Common Staff = Basic damage and fire rate
	staff1.damage_bonus = 0.05  # 5% damage
	staff1.fire_rate_bonus = 0.03  # 3% fire rate
	staff1.sell_value = 10
	equipment_manager.add_to_inventory(staff1)

	# Staff 2 - Staff of Nature (Common)
	var staff2 = Item.new()
	staff2.item_name = "Staff of Nature"
	staff2.description = "A staff carved from ancient oak."
	staff2.icon_path = "res://Staffs/Staff2Godot.png"
	staff2.item_type = Item.ItemType.WEAPON
	staff2.rarity = Item.Rarity.COMMON
	staff2.damage_bonus = 0.08  # 8% damage
	staff2.fire_rate_bonus = 0.05  # 5% fire rate
	staff2.sell_value = 12
	equipment_manager.add_to_inventory(staff2)

	# Staff 3 - Staff of Frost (Uncommon)
	var staff3 = Item.new()
	staff3.item_name = "Staff of Frost"
	staff3.description = "An icy staff that chills enemies."
	staff3.icon_path = "res://Staffs/Staff3Godot.png"
	staff3.item_type = Item.ItemType.WEAPON
	staff3.rarity = Item.Rarity.UNCOMMON
	staff3.damage_bonus = 0.10  # 10% damage
	staff3.fire_rate_bonus = 0.08  # 8% fire rate
	staff3.crit_chance_bonus = 0.03  # 3% crit
	staff3.sell_value = 25
	equipment_manager.add_to_inventory(staff3)

	# Staff 4 - Staff of Lightning (Uncommon)
	var staff4 = Item.new()
	staff4.item_name = "Staff of Lightning"
	staff4.description = "Crackling with electrical energy."
	staff4.icon_path = "res://Staffs/Staff4Godot.png"
	staff4.item_type = Item.ItemType.WEAPON
	staff4.rarity = Item.Rarity.UNCOMMON
	staff4.damage_bonus = 0.12  # 12% damage
	staff4.fire_rate_bonus = 0.10  # 10% fire rate
	staff4.crit_chance_bonus = 0.05  # 5% crit
	staff4.sell_value = 30
	equipment_manager.add_to_inventory(staff4)

	# Staff 5 - Staff of Shadows (Rare)
	var staff5 = Item.new()
	staff5.item_name = "Staff of Shadows"
	staff5.description = "A dark staff imbued with shadow magic."
	staff5.icon_path = "res://Staffs/Staff5Godot.png"
	staff5.item_type = Item.ItemType.WEAPON
	staff5.rarity = Item.Rarity.RARE
	staff5.damage_bonus = 0.15  # 15% damage
	staff5.fire_rate_bonus = 0.12  # 12% fire rate
	staff5.crit_chance_bonus = 0.08  # 8% crit
	staff5.sell_value = 60
	equipment_manager.add_to_inventory(staff5)

	# Staff 6 - Staff of the Archmage (Rare)
	var staff6 = Item.new()
	staff6.item_name = "Staff of the Archmage"
	staff6.description = "Once wielded by a legendary wizard."
	staff6.icon_path = "res://Staffs/Staff6Godot.png"
	staff6.item_type = Item.ItemType.WEAPON
	staff6.rarity = Item.Rarity.RARE
	staff6.damage_bonus = 0.18  # 18% damage
	staff6.fire_rate_bonus = 0.15  # 15% fire rate
	staff6.crit_chance_bonus = 0.10  # 10% crit
	staff6.sell_value = 80
	equipment_manager.add_to_inventory(staff6)

	# Staff 7 - Staff of Cosmic Power (Epic)
	var staff7 = Item.new()
	staff7.item_name = "Staff of Cosmic Power"
	staff7.description = "Forged from stardust and chaos energy."
	staff7.icon_path = "res://Staffs/Staff7Godot.png"
	staff7.item_type = Item.ItemType.WEAPON
	staff7.rarity = Item.Rarity.EPIC
	staff7.damage_bonus = 0.25  # 25% damage
	staff7.fire_rate_bonus = 0.18  # 18% fire rate
	staff7.crit_chance_bonus = 0.12  # 12% crit
	staff7.sell_value = 150
	equipment_manager.add_to_inventory(staff7)

	# Rare Helmet
	var rare_helmet = Item.new()
	rare_helmet.item_name = "Rare Helmet"
	rare_helmet.description = "A sturdy helmet forged from rare metals."
	rare_helmet.icon_path = "res://Items/Helmet/RareHelmetGodot.png"
	rare_helmet.item_type = Item.ItemType.HELMET
	rare_helmet.rarity = Item.Rarity.RARE
	# Helmet = Protection (HP and Armor)
	rare_helmet.health_bonus = 25.0  # 25 HP
	rare_helmet.armor_bonus = 0.10  # 10% armor
	rare_helmet.sell_value = 50
	equipment_manager.add_to_inventory(rare_helmet)

	# Legendary Ring 1 - Ring of Fortune
	var legendary_ring = Item.new()
	legendary_ring.item_name = "Ring of Fortune"
	legendary_ring.description = "A mystical ring that brings power and luck."
	legendary_ring.icon_path = "res://Items/Rings/LegendaryRingGodot.png"
	legendary_ring.item_type = Item.ItemType.RING
	legendary_ring.rarity = Item.Rarity.LEGENDARY
	# Ring = Magical bonuses (Damage, Crit, Luck)
	legendary_ring.damage_bonus = 0.15  # 15% damage
	legendary_ring.crit_chance_bonus = 0.12  # 12% crit chance
	legendary_ring.luck_bonus = 0.15  # 15% luck
	legendary_ring.sell_value = 150
	equipment_manager.add_to_inventory(legendary_ring)

	# Legendary Ring 2 - Ring of Swiftness
	var legendary_ring2 = Item.new()
	legendary_ring2.item_name = "Ring of Swiftness"
	legendary_ring2.description = "An ancient ring that enhances speed and precision."
	legendary_ring2.icon_path = "res://Items/Rings/LegendaryRing2Godot.png"
	legendary_ring2.item_type = Item.ItemType.RING
	legendary_ring2.rarity = Item.Rarity.LEGENDARY
	# Ring 2 = Speed-focused (Crit Damage, Fire Rate, Cooldown)
	legendary_ring2.crit_damage_bonus = 0.30  # 30% crit damage
	legendary_ring2.fire_rate_bonus = 0.15  # 15% fire rate
	legendary_ring2.cooldown_reduction_bonus = 0.20  # 20% cooldown reduction
	legendary_ring2.sell_value = 150
	equipment_manager.add_to_inventory(legendary_ring2)

	print("✅ Added 7 staffs, Rare Helmet, and 2 Legendary Rings to inventory!")

	# Reset run coins counter
	SaveSystem.reset_run_coins()

	# Update health UI with character's stats
	# Need to wait one frame for UILayer to be created and populated
	await get_tree().process_frame
	update_health_ui()

	# Update weapon visual (in case weapon is already equipped from start)
	update_equipped_weapon_visual()

	# Not using signals for damage detection anymore - enemies use distance

func _physics_process(delta):
	# Toggle shooting with P key (press once to toggle)
	var p_key_pressed = Input.is_physical_key_pressed(KEY_P)
	if p_key_pressed and not p_key_was_pressed:
		shooting_enabled = !shooting_enabled
	p_key_was_pressed = p_key_pressed

	# Update cooldown timers
	if dash_timer < dash_cooldown:
		dash_timer += delta
	if ultimate_timer < ultimate_cooldown:
		ultimate_timer += delta

	# Handle dash
	if Input.is_action_just_pressed("dash") and dash_timer >= dash_cooldown and not is_dashing:
		start_dash()

	# Handle ultimate
	if Input.is_action_just_pressed("ultimate") and ultimate_timer >= ultimate_cooldown:
		use_ultimate()

	# Get input direction
	var input_direction = Vector2.ZERO

	# Add input from the input map
	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	# Normalize the direction to prevent faster diagonal movement
	# Without normalization, diagonal movement would be ~1.41x faster
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()

	# Dash logic
	if is_dashing:
		dash_time_remaining -= delta
		if dash_time_remaining <= 0:
			is_dashing = false
			is_invincible = false
			modulate = Color(1, 1, 1, 1)  # Reset color
		else:
			# Move in dash direction at high speed
			velocity = dash_direction * dash_speed
			# Visual: Make semi-transparent during dash
			modulate = Color(1, 1, 1, 0.5)
	else:
		# Normal movement
		velocity = input_direction * move_speed

	# Move the character, handling collisions automatically
	move_and_slide()

	# Flip sprite based on movement direction
	if has_node("Sprite2D"):
		if input_direction.x != 0:
			$Sprite2D.flip_h = input_direction.x < 0  # Flip when moving left

			# Also flip/move the equipped weapon sprite
			if equipped_weapon_sprite and equipped_weapon_sprite.visible:
				if $Sprite2D.flip_h:
					# Player facing left - move staff to left side
					equipped_weapon_sprite.position.x = -30
					equipped_weapon_sprite.flip_h = true
					equipped_weapon_sprite.rotation_degrees = -45  # Angle left
				else:
					# Player facing right - move staff to right side
					equipped_weapon_sprite.position.x = 30
					equipped_weapon_sprite.flip_h = false
					equipped_weapon_sprite.rotation_degrees = 45  # Angle right

		# Advanced walking animation (procedural)
		if input_direction.length() > 0:
			# Player is moving - animate!
			walk_cycle_time += delta * walk_cycle_speed

			# Bobbing (up and down) - creates footstep rhythm
			var bob_offset = abs(sin(walk_cycle_time)) * walk_bob_intensity
			$Sprite2D.position.y = sprite_base_y - bob_offset  # Negative to bob upward

			# Tilt/Rotation - lean forward and back as walking
			var tilt_angle = sin(walk_cycle_time) * walk_tilt_intensity
			$Sprite2D.rotation = tilt_angle

			# Squash & Stretch - compress when foot hits ground (twice per cycle)
			var squash_phase = sin(walk_cycle_time * 2.0)  # 2x faster for each step
			var scale_x = 1.0 + (squash_phase * walk_squash_intensity)
			var scale_y = 1.0 - (squash_phase * walk_squash_intensity)

			# Apply squash/stretch to base scale (preserve Hunter's size)
			var base_scale = 0.07
			$Sprite2D.scale = Vector2(base_scale * scale_x, base_scale * scale_y)
		else:
			# Player is idle - reset to neutral pose
			walk_cycle_time = 0.0
			$Sprite2D.position.y = sprite_base_y
			$Sprite2D.rotation = 0.0
			$Sprite2D.scale = Vector2(0.07, 0.07)  # Reset to base scale

	# Weapon system - shoot at intervals (only if enabled)
	if shooting_enabled:
		shoot_timer += delta

		# Calculate fire rate multiplier from upgrades
		var fire_rate_multiplier = pow(0.9, active_upgrades.get("fire_rate_boost", 0))
		var adjusted_interval = shoot_interval * fire_rate_multiplier

		if shoot_timer >= adjusted_interval:
			shoot_projectile()
			shoot_timer = 0.0

		# Laser weapon
		if has_laser:
			laser_timer += delta
			if laser_timer >= laser_interval * fire_rate_multiplier:
				shoot_laser()
				laser_timer = 0.0

		# Homing missiles
		if has_homing_missiles:
			homing_timer += delta
			if homing_timer >= homing_interval * fire_rate_multiplier:
				shoot_homing_missile()
				homing_timer = 0.0

		# Chain Lightning
		if has_chain_lightning:
			lightning_timer += delta
			if lightning_timer >= lightning_interval * fire_rate_multiplier:
				shoot_chain_lightning()
				lightning_timer = 0.0

		# Boomerang
		if has_boomerang:
			boomerang_timer += delta
			if boomerang_timer >= boomerang_interval * fire_rate_multiplier:
				shoot_boomerang()
				boomerang_timer = 0.0

		# Sniper Rifle
		if has_sniper:
			sniper_timer += delta
			if sniper_timer >= sniper_interval * fire_rate_multiplier:
				shoot_sniper()
				sniper_timer = 0.0

		# Ice Beam
		if has_ice_beam:
			ice_beam_timer += delta
			if ice_beam_timer >= ice_beam_interval * fire_rate_multiplier:
				shoot_ice_beam()
				ice_beam_timer = 0.0

	# Update invincibility timer
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			modulate = Color(1, 1, 1, 1)  # Reset color

	# Regeneration
	if active_upgrades.has("regeneration"):
		regen_timer += delta
		if regen_timer >= 1.0:  # Every second
			var regen_amount = active_upgrades.get("regeneration", 0) * 5.0
			current_health = min(current_health + regen_amount, max_health)
			regen_timer = 0.0

			# Update health bar
			var main = get_parent()
			if main.has_node("UILayer/HealthProgressBar"):
				main.get_node("UILayer/HealthProgressBar").value = current_health
			if main.has_node("UILayer/HealthLabel"):
				main.get_node("UILayer/HealthLabel").text = "%.0f / %.0f HP" % [current_health, max_health]

	# Update ability cooldown UI
	update_ability_ui()

func get_nearest_enemy() -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var nearest = null
	var nearest_distance = detection_radius + 1  # Start beyond detection range

	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		# Only consider enemies within detection radius
		if distance <= detection_radius and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance

	return nearest  # Will be null if no enemies in range

func shoot_projectile():
	var target = get_nearest_enemy()
	if not target:
		return  # No enemies, don't shoot

	# Calculate damage multiplier from upgrades AND passive items
	var damage_multiplier = pow(1.1, active_upgrades.get("damage_boost", 0)) * (1.0 + passive_damage_boost)

	# Calculate number of shots (multi-shot upgrade)
	var shot_count = 1 + active_upgrades.get("multi_shot", 0)

	# Shotgun mode shoots in a spread pattern
	if has_shotgun:
		# Level determines pellet count: Level 1 = 3, Level 2 = 5, Level 5 = 7
		var num_pellets = 3
		if shotgun_level >= 5:
			num_pellets = 7
		elif shotgun_level >= 2:
			num_pellets = 5

		var spread_angle = 30.0  # degrees
		if shotgun_level >= 4:
			spread_angle = 20.0  # Tighter spread at level 4

		var direction_to_target = (target.position - position).normalized()
		var base_angle = direction_to_target.angle()

		for i in range(num_pellets):
			var angle_offset = deg_to_rad((i - (num_pellets - 1) / 2.0) * spread_angle)
			var spread_direction = Vector2(cos(base_angle + angle_offset), sin(base_angle + angle_offset))
			var spread_target = position + spread_direction * 1000

			var projectile = projectile_scene.instantiate()
			projectile.position = position
			projectile.target_position = spread_target
			var pellet_damage_mult = 0.7
			if shotgun_level >= 3:
				pellet_damage_mult = 0.98  # Level 3: +40% damage (0.7 * 1.4 = 0.98)
			projectile.damage *= damage_multiplier * pellet_damage_mult
			projectile.max_hits = 1  # Shotgun doesn't pierce
			projectile.hits_remaining = 1

			var range_multiplier = pow(1.2, active_upgrades.get("range_boost", 0))
			projectile.speed *= range_multiplier

			# Apply projectile size multiplier
			projectile.scale = Vector2(projectile_size_mult, projectile_size_mult)

			# Hunter gets custom arrow sprite
			if character_id == "hunter":
				projectile.custom_sprite_path = "res://HunterArrowGodot.png"
			# Wizard/Mage gets custom magic projectile sprite
			elif character_id == "mage":
				projectile.custom_sprite_path = "res://Weapons/WizardProjectileGodot.png"
			# Warrior gets custom axe/weapon projectile sprite
			elif character_id == "warrior":
				projectile.custom_sprite_path = "res://WarriorProjectileGodot.png"
			# Assassin gets custom dagger/shuriken projectile sprite
			elif character_id == "assassin":
				projectile.custom_sprite_path = "res://AssassinProjectileGodot.png"
			# Tank gets custom cannon/hammer projectile sprite
			elif character_id == "tank":
				projectile.custom_sprite_path = "res://TankProjectileGodot.png"

			get_parent().add_child(projectile)
	else:
		# Normal shooting
		for i in range(shot_count):
			var projectile = projectile_scene.instantiate()
			projectile.position = position
			projectile.target_position = target.position

			# Check for critical hit
			var is_crit = randf() < crit_chance
			var final_damage_mult = damage_multiplier
			if is_crit:
				final_damage_mult *= crit_multiplier

			projectile.damage *= final_damage_mult  # Apply damage boost
			projectile.is_critical = is_crit  # Mark projectile as critical

			# Apply piercing upgrade
			var pierce_count = active_upgrades.get("piercing", 0)
			projectile.max_hits = 1 + pierce_count
			projectile.hits_remaining = projectile.max_hits

			# Apply range boost (faster speed)
			var range_multiplier = pow(1.2, active_upgrades.get("range_boost", 0))
			projectile.speed *= range_multiplier

			# Apply projectile size multiplier
			projectile.scale = Vector2(projectile_size_mult, projectile_size_mult)

			# Hunter gets custom arrow sprite
			if character_id == "hunter":
				projectile.custom_sprite_path = "res://HunterArrowGodot.png"
			# Wizard/Mage gets custom magic projectile sprite
			elif character_id == "mage":
				projectile.custom_sprite_path = "res://Weapons/WizardProjectileGodot.png"
			# Warrior gets custom axe/weapon projectile sprite
			elif character_id == "warrior":
				projectile.custom_sprite_path = "res://WarriorProjectileGodot.png"
			# Assassin gets custom dagger/shuriken projectile sprite
			elif character_id == "assassin":
				projectile.custom_sprite_path = "res://AssassinProjectileGodot.png"
			# Tank gets custom cannon/hammer projectile sprite
			elif character_id == "tank":
				projectile.custom_sprite_path = "res://TankProjectileGodot.png"

			# Add to main scene (parent of player)
			get_parent().add_child(projectile)

func shoot_laser():
	var target = get_nearest_enemy()
	if not target:
		return

	var laser = laser_scene.instantiate()
	laser.position = position
	laser.target_position = target.position

	# Apply damage boost (upgrades + passives)
	var damage_multiplier = pow(1.1, active_upgrades.get("damage_boost", 0)) * (1.0 + passive_damage_boost)
	if laser_level >= 2:
		damage_multiplier *= 1.3  # Level 2: +30% damage
	if laser_level >= 5:
		damage_multiplier *= 1.5  # Level 5: +50% more damage
	laser.damage *= damage_multiplier

	# Apply level upgrades
	if laser_level >= 4:
		laser.speed *= 1.5  # Level 4: +50% longer range (faster speed)

	# Set custom laser sprite
	laser.custom_sprite_path = "res://LaserProjectile.png"

	get_parent().add_child(laser)

func shoot_homing_missile():
	var target = get_nearest_enemy()
	if not target:
		return

	# Level 3: 2 missiles, Level 5: 3 missiles
	var missile_count = 1
	if homing_level >= 5:
		missile_count = 3
	elif homing_level >= 3:
		missile_count = 2

	for i in range(missile_count):
		var missile = homing_missile_scene.instantiate()
		# Slightly offset spawn position for multiple missiles
		var offset = Vector2(i * 10 - (missile_count - 1) * 5, 0)
		missile.position = position + offset
		missile.target = target

		# Apply damage boost (upgrades + passives)
		var damage_multiplier = pow(1.1, active_upgrades.get("damage_boost", 0)) * (1.0 + passive_damage_boost)
		if homing_level >= 2:
			damage_multiplier *= 1.4  # Level 2: +40% damage
		missile.damage *= damage_multiplier

		# Apply level upgrades
		if homing_level >= 4:
			missile.turn_speed *= 1.5  # Level 4: +50% tracking speed

		get_parent().add_child(missile)

func spawn_orbiting_bullets(count: int = 3):
	# Clear existing orbiting bullets
	for bullet in orbiting_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	orbiting_bullets.clear()

	# Spawn new orbiting bullets around player
	for i in range(count):
		var bullet = orbiting_bullet_scene.instantiate()
		bullet.player = self
		bullet.current_angle = (i / float(count)) * TAU  # Evenly distribute around circle
		get_parent().add_child(bullet)
		orbiting_bullets.append(bullet)

func shoot_chain_lightning():
	var target = get_nearest_enemy()
	if not target:
		return

	var lightning = chain_lightning_scene.instantiate()
	lightning.position = Vector2.ZERO  # Will be set by start_chain

	# Apply damage boost
	var damage_boost = pow(1.1, active_upgrades.get("damage_boost", 0)) - 1.0 + passive_damage_boost

	# Apply level upgrades BEFORE adding to tree
	if lightning_level >= 2:
		lightning.max_bounces = 6  # Level 2: 6 enemies
	if lightning_level >= 3:
		damage_boost += 0.3  # Level 3: +30% damage
	if lightning_level >= 4:
		lightning.max_bounces = 8  # Level 4: 8 enemies

	# Add to tree FIRST, then start chain (so get_tree() works)
	get_parent().add_child(lightning)
	lightning.start_chain(position, target, damage_boost)

func shoot_boomerang():
	# Shoot towards nearest enemy, or right if no enemy
	var target = get_nearest_enemy()
	var direction = Vector2(1, 0)  # Default right
	if target:
		direction = (target.position - position).normalized()

	# Level 2: 2 boomerangs, Level 5: 3 boomerangs
	var boomerang_count = 1
	if boomerang_level >= 5:
		boomerang_count = 3
	elif boomerang_level >= 2:
		boomerang_count = 2

	for i in range(boomerang_count):
		var angle_offset = 0.0
		if boomerang_count > 1:
			angle_offset = (i - (boomerang_count - 1) / 2.0) * 0.3  # Spread pattern

		var spread_direction = direction.rotated(angle_offset)
		var boomerang = boomerang_scene.instantiate()

		# Apply damage boost
		var damage_multiplier = pow(1.1, active_upgrades.get("damage_boost", 0)) * (1.0 + passive_damage_boost)
		boomerang.damage *= damage_multiplier

		# Apply level upgrades
		if boomerang_level >= 3:
			boomerang.max_distance *= 1.3  # +30% range
		if boomerang_level >= 4:
			boomerang.return_speed_mult = 1.5  # 50% faster return

		boomerang.setup(position, spread_direction, self, passive_damage_boost)
		get_parent().add_child(boomerang)

func shoot_sniper():
	var target = get_nearest_enemy()
	if not target:
		return  # No enemies, don't shoot

	# Calculate damage multiplier
	var damage_multiplier = pow(1.1, active_upgrades.get("damage_boost", 0)) * (1.0 + passive_damage_boost)

	# Level determines shot count: Level 1 = 1, Level 3 = 2, Level 5 = 3
	var shot_count = 1
	if sniper_level >= 5:
		shot_count = 3
	elif sniper_level >= 3:
		shot_count = 2

	for i in range(shot_count):
		var sniper = sniper_scene.instantiate()
		sniper.position = position
		sniper.target_position = target.position

		# Check for critical hit
		var is_crit = randf() < crit_chance
		var final_damage_mult = damage_multiplier
		if is_crit:
			final_damage_mult *= crit_multiplier

		sniper.damage *= final_damage_mult
		sniper.is_critical = is_crit

		# Level bonuses
		if sniper_level >= 2:
			sniper.max_hits = 3  # Level 2: Pierce 2 enemies
		if sniper_level >= 4:
			sniper.damage *= 1.5  # Level 4: +50% damage

		# Apply projectile size multiplier
		sniper.scale = Vector2(projectile_size_mult, projectile_size_mult)

		get_parent().add_child(sniper)

func shoot_ice_beam():
	var target = get_nearest_enemy()
	if not target:
		return

	var damage_multiplier = pow(1.1, active_upgrades.get("damage_boost", 0)) * (1.0 + passive_damage_boost)

	# Level determines beam count
	var beam_count = 1
	if ice_beam_level >= 5:
		beam_count = 3
	elif ice_beam_level >= 3:
		beam_count = 2

	for i in range(beam_count):
		var beam = ice_beam_scene.instantiate()
		beam.position = position

		# Spread pattern for multiple beams
		var target_pos = target.position
		if beam_count > 1:
			var angle_offset = (i - (beam_count - 1) / 2.0) * 0.4
			var direction = (target.position - position).normalized().rotated(angle_offset)
			target_pos = position + direction * 1000

		beam.target_position = target_pos

		# Check for critical hit
		var is_crit = randf() < crit_chance
		var final_damage_mult = damage_multiplier
		if is_crit:
			final_damage_mult *= crit_multiplier

		beam.damage *= final_damage_mult
		beam.is_critical = is_crit

		# Level bonuses
		if ice_beam_level >= 2:
			beam.slow_amount = 0.7  # Level 2: 70% slow (stronger)
		if ice_beam_level >= 4:
			beam.slow_duration = 3.0  # Level 4: 3 seconds slow

		# Apply projectile size multiplier
		beam.scale = Vector2(projectile_size_mult, projectile_size_mult)

		get_parent().add_child(beam)

func collect_xp(amount: int):
	# Apply passive XP boost + luck multiplier
	var total_multiplier = (1.0 + passive_xp_boost + luck_multiplier)
	var bonus_xp = int(amount * total_multiplier)
	current_xp += bonus_xp
	total_xp_collected += bonus_xp
	print("XP collected: +%d (x%.1f = %d) (Total: %d)" % [amount, total_multiplier, bonus_xp, total_xp_collected])

	# Check for level up
	while current_xp >= xp_threshold:
		level_up()

	# Update player UI
	# Update UI labels if they exist (for backward compatibility)
	var main = get_parent()
	if main.has_node("UILayer/XPLabel"):
		main.get_node("UILayer/XPLabel").text = "XP: %d" % total_xp_collected
	if main.has_node("UILayer/LevelLabel"):
		main.get_node("UILayer/LevelLabel").text = "Level: %d" % current_level
	if main.has_node("UILayer/XPProgressBar"):
		main.get_node("UILayer/XPProgressBar").max_value = xp_threshold
		main.get_node("UILayer/XPProgressBar").value = current_xp
	if main.has_node("UILayer/XPBarLabel"):
		main.get_node("UILayer/XPBarLabel").text = "%d / %d XP" % [current_xp, xp_threshold]

func get_xp_requirement(level: int) -> int:
	# Linear growth: 100, 150, 200, 250, etc.
	return 100 + (level - 1) * 50

func level_up():
	current_level += 1
	current_xp -= xp_threshold  # Carry over excess XP
	xp_threshold = get_xp_requirement(current_level)
	print("LEVEL UP! Now level %d (Next level at %d XP)" % [current_level, xp_threshold])

	# Update level achievements
	AchievementSystem.update_progress("level_10", current_level)
	AchievementSystem.update_progress("level_20", current_level)

	# Camera shake for level up!
	var main = get_parent()
	if main.has_node("Camera"):
		main.get_node("Camera").shake(0.3, 8.0)  # Satisfying level up shake

	# Spawn level-up particles
	var particles = levelup_particles.instantiate()
	particles.position = position
	particles.emitting = true
	get_parent().add_child(particles)

	# Show upgrade menu and pause
	show_upgrade_menu()

func update_health_ui():
	var main = get_parent()
	if main.has_node("UILayer/HealthProgressBar"):
		main.get_node("UILayer/HealthProgressBar").max_value = max_health
		main.get_node("UILayer/HealthProgressBar").value = current_health
	if main.has_node("UILayer/HealthLabel"):
		main.get_node("UILayer/HealthLabel").text = "%.0f / %.0f HP" % [current_health, max_health]

func show_upgrade_menu():
	get_tree().paused = true

	# Get 3 random upgrades (pass player for weapon filtering)
	var upgrade_ids = UpgradeSystem.get_random_upgrades(3, self)

	# Pass to UI to display
	if upgrade_ui:
		upgrade_ui.show_upgrades(upgrade_ids)

func take_damage(damage: float, attacker: Node = null):
	if is_invincible:
		return  # Already invincible, ignore damage

	# Check shield charges first
	if shield_charges > 0:
		shield_charges -= 1
		print("Shield absorbed hit! Remaining shields: %d" % shield_charges)

		# Visual feedback - blue flash for shield
		modulate = Color(0.5, 0.8, 1, 1)
		is_invincible = true
		invincibility_timer = invincibility_duration

		# Emit signal for camera shake (smaller)
		emit_signal("took_damage")

		# Apply thorns damage to attacker
		if has_thorns and attacker and attacker.has_method("take_damage"):
			attacker.take_damage(thorns_damage)
			print("Thorns! Enemy took %.0f damage" % thorns_damage)

		return  # Shield absorbed the hit, no health damage

	# Apply damage reduction
	var final_damage = damage * (1.0 - damage_reduction)
	current_health -= final_damage
	is_invincible = true
	invincibility_timer = invincibility_duration

	# Apply thorns damage to attacker
	if has_thorns and attacker and attacker.has_method("take_damage"):
		attacker.take_damage(thorns_damage)
		print("Thorns! Enemy took %.0f damage" % thorns_damage)

	# Emit signal for camera shake
	emit_signal("took_damage")

	# Visual feedback - flash white
	modulate = Color(1, 0.5, 0.5, 1)  # Red tint

	print("Player hit! Health: %.0f/%.0f" % [current_health, max_health])

	# Update health bar if it exists
	var main = get_parent()
	if main.has_node("HealthProgressBar"):
		main.get_node("HealthProgressBar").value = current_health
	if main.has_node("HealthLabel"):
		main.get_node("HealthLabel").text = "%.0f / %.0f HP" % [current_health, max_health]

	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	print("Healed! Health: %.0f/%.0f" % [current_health, max_health])

	# Update health bar
	var main = get_parent()
	if main.has_node("HealthProgressBar"):
		main.get_node("HealthProgressBar").value = current_health
	if main.has_node("HealthLabel"):
		main.get_node("HealthLabel").text = "%.0f / %.0f HP" % [current_health, max_health]

func die():
	print("Player died at level %d!" % current_level)

	# Calculate time survived
	var time_survived = (Time.get_ticks_msec() / 1000.0) - game_start_time

	# Prepare stats dictionary
	var stats = {
		"time_survived": time_survived,
		"level": current_level,
		"total_kills": total_kills,
		"total_damage": total_damage_dealt,
		"total_xp": total_xp_collected
	}

	# Show death screen
	var main = get_parent()
	if main.has_node("UILayer/DeathScreen"):
		main.get_node("UILayer/DeathScreen").show_death_screen(stats)
	else:
		# Fallback if no death screen
		get_tree().reload_current_scene()

func register_enemy_kill(enemy_position: Vector2 = Vector2.ZERO):
	total_kills += 1

	# Update kill achievements
	AchievementSystem.update_progress("first_blood", total_kills)
	AchievementSystem.update_progress("killer", total_kills)
	AchievementSystem.update_progress("executioner", total_kills)
	AchievementSystem.update_progress("slayer", total_kills)

	# Lifesteal - heal on kill
	if has_lifesteal:
		heal(lifesteal_amount)

	# Explosion on kill - spawn explosion at enemy position
	if has_explosion_kill and enemy_position != Vector2.ZERO:
		spawn_kill_explosion(enemy_position)

	# Toxic Pools - spawn toxic pool at enemy death position
	if has_toxic_pools and enemy_position != Vector2.ZERO:
		spawn_toxic_pool(enemy_position)

func register_damage(damage: float):
	total_damage_dealt += damage

	# Update damage achievements
	AchievementSystem.update_progress("damage_10k", int(total_damage_dealt))
	AchievementSystem.update_progress("damage_50k", int(total_damage_dealt))

func register_boss_kill():
	total_boss_kills += 1

	# Update boss achievements
	AchievementSystem.update_progress("boss_killer", total_boss_kills)
	AchievementSystem.update_progress("boss_hunter", total_boss_kills)
	print("Boss defeated! Total boss kills: %d" % total_boss_kills)

func spawn_kill_explosion(pos: Vector2):
	# Create explosion effect at enemy death position
	var explosion = Node2D.new()
	explosion.position = pos
	get_parent().add_child(explosion)

	# Visual effect - expanding circle
	var circle = Node2D.new()
	explosion.add_child(circle)

	for i in range(12):
		var segment = ColorRect.new()
		segment.custom_minimum_size = Vector2(15, 8)
		segment.color = Color(1, 0.5, 0, 0.8)

		var angle = (TAU / 12) * i
		segment.position = Vector2(cos(angle), sin(angle)) * 10
		segment.rotation = angle

		circle.add_child(segment)

	# Animate explosion
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(circle, "scale", Vector2(explosion_kill_radius / 10.0, explosion_kill_radius / 10.0), 0.3)
	tween.tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

	# Deal damage to nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = pos.distance_to(enemy.global_position)
		if distance <= explosion_kill_radius:
			if enemy.has_method("take_damage"):
				var explosion_damage = explosion_kill_damage * (1.0 + passive_damage_boost + area_damage_mult)
				enemy.take_damage(explosion_damage)
				print("Chain Reaction! Enemy took %.0f explosion damage" % explosion_damage)

func spawn_toxic_pool(pos: Vector2):
	# Create toxic pool at enemy death position
	var pool = toxic_pool_scene.instantiate()
	pool.position = pos
	pool.radius = toxic_pool_radius
	pool.lifetime = toxic_pool_lifetime
	pool.setup(passive_damage_boost, area_damage_mult)
	get_parent().add_child(pool)

# Upgrade callbacks
func apply_damage_boost():
	print("Damage increased! (x%.1f)" % pow(1.1, active_upgrades.get("damage_boost", 0)))

func apply_fire_rate_boost():
	print("Fire rate increased!")

func apply_speed_boost():
	var speed_multiplier = pow(1.1, active_upgrades.get("speed_boost", 0))
	move_speed = 200.0 * speed_multiplier
	print("Movement speed increased! New speed: %.0f" % move_speed)

func apply_health_boost():
	max_health += 20.0
	current_health = max_health  # Heal to full
	print("Max health increased! New max: %.0f HP" % max_health)

	# Update health bar
	update_health_ui()

func apply_multi_shot():
	var shot_count = 1 + active_upgrades.get("multi_shot", 0)
	print("Multi-shot! Now shooting %d projectiles" % shot_count)

func apply_regeneration():
	print("Regeneration active! Healing 5 HP per second")

func apply_piercing():
	var pierce_count = active_upgrades.get("piercing", 0)
	print("Piercing shots! Projectiles can hit %d additional enemies" % pierce_count)
	# Note: Piercing logic will be handled in projectile.gd

func apply_range_boost():
	print("Long range! Projectiles fly faster")
	# Note: Range boost will be applied in shoot_projectile

func apply_magnet():
	print("Magnetic field! XP orbs attracted from farther away")
	# Note: Magnet radius will be checked in xp_orb.gd

func apply_fortify():
	damage_reduction = 1.0 - pow(0.9, active_upgrades.get("fortify", 0))
	print("Fortify! Damage reduction: %.0f%%" % (damage_reduction * 100))

# New passive upgrades
func apply_shield():
	shield_charges += 1
	print("Shield gained! Extra hits before damage: %d" % shield_charges)

func apply_lifesteal():
	has_lifesteal = true
	print("Lifesteal active! Heal %d HP on kill" % lifesteal_amount)

func apply_thorns():
	has_thorns = true
	thorns_damage += 20.0 * active_upgrades.get("thorns", 1)
	print("Thorns active! Enemies take %.0f damage when hitting you" % thorns_damage)

func apply_knockback():
	has_knockback = true
	print("Knockback active! Projectiles push enemies back")

func apply_explosion_kill():
	has_explosion_kill = true
	print("Chain Reaction! Enemies explode on death")

func apply_dash_cdr():
	var cdr_mult = pow(0.8, active_upgrades.get("dash_cdr", 0))
	dash_cooldown = 2.0 * cdr_mult
	print("Swift Dash! Cooldown: %.1fs" % dash_cooldown)

func apply_ultimate_cdr():
	var cdr_mult = pow(0.8, active_upgrades.get("ultimate_cdr", 0))
	ultimate_cooldown = 10.0 * cdr_mult
	print("Quick Charge! Ultimate cooldown: %.1fs" % ultimate_cooldown)

func apply_luck():
	luck_multiplier += 0.15
	print("Lucky Charm! +%.0f%% XP and coins" % (luck_multiplier * 100))

func apply_projectile_size():
	projectile_size_mult += 0.25
	print("Giant Bullets! Projectiles %.0f%% bigger" % ((projectile_size_mult - 1.0) * 100))

func apply_crit_damage():
	crit_multiplier += 0.5
	print("Deadly Crits! Critical hits now deal %.1fx damage" % crit_multiplier)

func apply_area_damage():
	area_damage_mult += 0.15
	print("Area Master! AoE effects +%.0f%% damage" % (area_damage_mult * 100))

# New weapon upgrades
func apply_laser_weapon():
	if not has_laser:
		has_laser = true
		laser_level = 1
		print("Laser Weapon unlocked! Penetrates many enemies!")
		show_weapon_icon("LaserWeaponIcon")
		check_weapon_achievements()
	else:
		laser_level += 1
		match laser_level:
			2: print("Laser Level 2! +30%% damage")
			3:
				laser_interval *= 0.5  # 50% faster fire rate
				print("Laser Level 3! +50%% faster fire rate")
			4: print("Laser Level 4! +50%% longer range")
			5: print("Laser Level 5! +50%% damage (MAX)")

func apply_shotgun():
	if not has_shotgun:
		has_shotgun = true
		shotgun_level = 1
		print("Shotgun unlocked! Spread pattern!")
		show_weapon_icon("ShotgunWeaponIcon")
		check_weapon_achievements()
	else:
		shotgun_level += 1
		match shotgun_level:
			2: print("Shotgun Level 2! Fire 5 pellets")
			3: print("Shotgun Level 3! +40%% damage per pellet")
			4: print("Shotgun Level 4! Tighter spread")
			5: print("Shotgun Level 5! Fire 7 pellets! (MAX)")

func apply_orbiting_bullets():
	if not has_orbiting_bullets:
		has_orbiting_bullets = true
		orbiting_level = 1
		spawn_orbiting_bullets(3)  # Start with 3
		print("Orbiting Bullets! 3 bullets circling you!")
		show_weapon_icon("OrbitingWeaponIcon")
		check_weapon_achievements()
	else:
		orbiting_level += 1
		match orbiting_level:
			2:
				spawn_orbiting_bullets(5)  # +2 bullets
				print("Orbiting Level 2! Now 5 bullets")
			3: print("Orbiting Level 3! +30%% damage")
			4: print("Orbiting Level 4! +30%% rotation speed")
			5:
				spawn_orbiting_bullets(8)  # +3 more bullets
				print("Orbiting Level 5! Now 8 bullets! (MAX)")

func apply_homing_missiles():
	if not has_homing_missiles:
		has_homing_missiles = true
		homing_level = 1
		print("Homing Missiles unlocked! Seeks enemies!")
		show_weapon_icon("HomingWeaponIcon")
		check_weapon_achievements()
	else:
		homing_level += 1
		match homing_level:
			2: print("Homing Level 2! +40%% damage")
			3: print("Homing Level 3! Fire 2 missiles at once")
			4: print("Homing Level 4! +50%% tracking speed")
			5: print("Homing Level 5! Fire 3 missiles! (MAX)")

func apply_chain_lightning():
	if not has_chain_lightning:
		has_chain_lightning = true
		lightning_level = 1
		print("Chain Lightning unlocked! Bounces between enemies!")
		show_weapon_icon("ChainLightningIcon")
		check_weapon_achievements()
	else:
		lightning_level += 1
		match lightning_level:
			2: print("Lightning Level 2! Bounces to 6 enemies")
			3: print("Lightning Level 3! +30%% damage")
			4: print("Lightning Level 4! Bounces to 8 enemies")
			5:
				lightning_interval *= 0.7  # 30% cooldown reduction
				print("Lightning Level 5! -30%% cooldown (MAX)")

func apply_boomerang():
	if not has_boomerang:
		has_boomerang = true
		boomerang_level = 1
		print("Boomerang unlocked! Comes back to you!")
		show_weapon_icon("BoomerangIcon")
		check_weapon_achievements()
	else:
		boomerang_level += 1
		match boomerang_level:
			2: print("Boomerang Level 2! Throw 2 boomerangs")
			3: print("Boomerang Level 3! +30%% range")
			4: print("Boomerang Level 4! +50%% return speed")
			5: print("Boomerang Level 5! Throw 3 boomerangs! (MAX)")

func apply_flamethrower():
	if not has_flamethrower:
		has_flamethrower = true
		flamethrower_level = 1
		print("Flamethrower unlocked! Roast your enemies!")
		show_weapon_icon("FlamethrowerIcon")
		check_weapon_achievements()
		# Spawn persistent flamethrower
		flamethrower_instance = flamethrower_scene.instantiate()
		flamethrower_instance.setup(self, passive_damage_boost)
		get_parent().add_child(flamethrower_instance)
	else:
		flamethrower_level += 1
		match flamethrower_level:
			2:
				if flamethrower_instance:
					flamethrower_instance.cone_angle = 90.0  # degrees
				print("Flamethrower Level 2! 90° cone")
			3:
				if flamethrower_instance:
					flamethrower_instance.range *= 1.5
				print("Flamethrower Level 3! +50%% range")
			4:
				if flamethrower_instance:
					flamethrower_instance.tick_rate = 0.05  # Double tick rate
				print("Flamethrower Level 4! Double tick rate")
			5:
				if flamethrower_instance:
					flamethrower_instance.cone_angle = 120.0  # degrees
				print("Flamethrower Level 5! 120° cone! (MAX)")

func apply_toxic_pools():
	if not has_toxic_pools:
		has_toxic_pools = true
		toxic_pools_level = 1
		print("Toxic Pools unlocked! Enemies leave poisonous puddles on death!")
		show_weapon_icon("ToxicPoolsIcon")
		check_weapon_achievements()
	else:
		toxic_pools_level += 1
		match toxic_pools_level:
			2:
				toxic_pool_radius = 90.0  # +50% bigger pools
				print("Toxic Pools Level 2! Bigger pools!")
			3:
				toxic_pool_lifetime = 8.0  # Lasts longer
				print("Toxic Pools Level 3! Pools last longer!")
			4:
				# Damage increase happens in toxic_pool.gd via damage_per_tick
				print("Toxic Pools Level 4! +50%% damage!")
			5:
				toxic_pool_radius = 120.0  # Even bigger!
				toxic_pool_lifetime = 10.0  # Even longer!
				print("Toxic Pools Level 5! Huge toxic zones! (MAX)")

func apply_sniper():
	if not has_sniper:
		has_sniper = true
		sniper_level = 1
		print("Sniper Rifle unlocked! High damage, piercing shots!")
		show_weapon_icon("SniperIcon")
		check_weapon_achievements()
	else:
		sniper_level += 1
		match sniper_level:
			2:
				print("Sniper Level 2! Pierce 2 enemies!")
			3:
				print("Sniper Level 3! Fire 2 shots!")
			4:
				print("Sniper Level 4! +50%% damage!")
			5:
				print("Sniper Level 5! Fire 3 shots! (MAX)")

func apply_ice_beam():
	if not has_ice_beam:
		has_ice_beam = true
		ice_beam_level = 1
		print("Ice Beam unlocked! Slows enemies!")
		show_weapon_icon("IceBeamIcon")
		check_weapon_achievements()
	else:
		ice_beam_level += 1
		match ice_beam_level:
			2:
				print("Ice Beam Level 2! 70%% slow!")
			3:
				print("Ice Beam Level 3! Fire 2 beams!")
			4:
				print("Ice Beam Level 4! 3 second slow!")
			5:
				print("Ice Beam Level 5! Fire 3 beams! (MAX)")

func show_weapon_icon(icon_name: String):
	var main = get_parent()
	if main.has_node("UILayer/" + icon_name):
		main.get_node("UILayer/" + icon_name).visible = true

func check_weapon_achievements():
	# Count unlocked weapons
	var weapon_count = 0
	if has_laser: weapon_count += 1
	if has_shotgun: weapon_count += 1
	if has_orbiting_bullets: weapon_count += 1
	if has_homing_missiles: weapon_count += 1
	if has_chain_lightning: weapon_count += 1
	if has_boomerang: weapon_count += 1
	if has_flamethrower: weapon_count += 1
	if has_toxic_pools: weapon_count += 1
	if has_sniper: weapon_count += 1
	if has_ice_beam: weapon_count += 1

	# Update weapon achievements
	AchievementSystem.update_progress("arsenal", weapon_count)
	AchievementSystem.update_progress("fully_loaded", weapon_count)

# Dash ability
func start_dash():
	# Get current movement direction
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_direction.length() > 0:
		dash_direction = input_direction.normalized()
	else:
		# If not moving, dash in facing direction (or right by default)
		dash_direction = Vector2.RIGHT

	is_dashing = true
	dash_time_remaining = dash_duration
	is_invincible = true  # Invincible during dash!
	dash_timer = 0.0  # Reset cooldown

	print("DASH! Direction: %s" % dash_direction)

	# Spawn dash particles/trail
	spawn_dash_effect()

# Ultimate ability
func use_ultimate():
	print("ULTIMATE ACTIVATED! Screen-clear explosion!")

	# Reset cooldown
	ultimate_timer = 0.0

	# Camera shake
	var main = get_parent()
	if main.has_node("Camera"):
		main.get_node("Camera").shake(0.5, 20.0)

	# Get all enemies on screen
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		if distance <= ultimate_radius:
			# Apply ultimate damage
			if enemy.has_method("take_damage"):
				enemy.take_damage(ultimate_damage)

	# Spawn ultimate explosion effect
	spawn_ultimate_effect()

func spawn_dash_effect():
	# Create dash trail particles
	var particles = levelup_particles.instantiate()  # Reuse levelup particles
	particles.position = position
	particles.emitting = true
	particles.modulate = Color(0.5, 0.8, 1, 1)  # Blue-ish trail
	get_parent().add_child(particles)

func spawn_ultimate_effect():
	# Create massive explosion effect
	var particles = levelup_particles.instantiate()
	particles.position = position
	particles.amount = 100  # Many particles!
	particles.emitting = true
	particles.modulate = Color(1, 0.5, 0, 1)  # Orange explosion
	get_parent().add_child(particles)

func update_ability_ui():
	var main = get_parent()

	# Update dash cooldown bar
	if main.has_node("DashCooldownBar"):
		main.get_node("DashCooldownBar").value = dash_timer
		main.get_node("DashCooldownBar").max_value = dash_cooldown

	# Update ultimate cooldown bar
	if main.has_node("UltimateCooldownBar"):
		main.get_node("UltimateCooldownBar").value = ultimate_timer
		main.get_node("UltimateCooldownBar").max_value = ultimate_cooldown

	# Change label color when ready
	if main.has_node("DashLabel"):
		if dash_timer >= dash_cooldown:
			main.get_node("DashLabel").modulate = Color(1, 1, 1, 1)  # White = ready
		else:
			main.get_node("DashLabel").modulate = Color(0.5, 0.5, 0.5, 1)  # Gray = not ready

	if main.has_node("UltimateLabel"):
		if ultimate_timer >= ultimate_cooldown:
			main.get_node("UltimateLabel").modulate = Color(1, 1, 1, 1)  # White = ready
		else:
			main.get_node("UltimateLabel").modulate = Color(0.5, 0.5, 0.5, 1)  # Gray = not ready

func apply_permanent_bonuses():
	# Get all bonuses from SaveSystem
	var bonuses = SaveSystem.get_total_stat_bonuses()

	# Apply health bonus
	if bonuses.max_health > 0:
		max_health += bonuses.max_health
		current_health += bonuses.max_health  # Also heal player
		print("Applied health bonus: +%d HP" % bonuses.max_health)

	# Apply speed bonus (multiplicative)
	if bonuses.move_speed_mult > 0:
		move_speed *= (1.0 + bonuses.move_speed_mult)
		print("Applied speed bonus: +%.0f%% speed" % (bonuses.move_speed_mult * 100))

	# Apply damage bonus (stored for use in damage calculations)
	if bonuses.damage_mult > 0:
		passive_damage_boost += bonuses.damage_mult
		print("Applied damage bonus: +%.0f%% damage" % (bonuses.damage_mult * 100))

	# Apply XP bonus (stored for use in XP calculations)
	if bonuses.xp_mult > 0:
		passive_xp_boost += bonuses.xp_mult
		print("Applied XP bonus: +%.0f%% XP" % (bonuses.xp_mult * 100))

	# Apply pickup radius bonus
	if bonuses.pickup_radius > 0:
		passive_pickup_boost += bonuses.pickup_radius
		print("Applied pickup radius bonus: +%d radius" % bonuses.pickup_radius)

	# Apply skill tree bonuses
	var skill_bonuses = SkillTreeSystem.get_total_skill_bonuses()

	# Health from skills
	if skill_bonuses.max_health > 0:
		max_health += skill_bonuses.max_health
		current_health += skill_bonuses.max_health
		print("Applied skill tree health: +%d HP" % skill_bonuses.max_health)

	# Speed from skills (multiplicative)
	if skill_bonuses.move_speed_mult > 0:
		move_speed *= (1.0 + skill_bonuses.move_speed_mult)
		print("Applied skill tree speed: +%.0f%% speed" % (skill_bonuses.move_speed_mult * 100))

	# Damage from skills
	if skill_bonuses.damage_mult > 0:
		passive_damage_boost += skill_bonuses.damage_mult
		print("Applied skill tree damage: +%.0f%% damage" % (skill_bonuses.damage_mult * 100))

	# Fire rate from skills
	if skill_bonuses.fire_rate > 0:
		shoot_interval *= (1.0 - skill_bonuses.fire_rate)
		laser_interval *= (1.0 - skill_bonuses.fire_rate)
		homing_interval *= (1.0 - skill_bonuses.fire_rate)
		lightning_interval *= (1.0 - skill_bonuses.fire_rate)
		boomerang_interval *= (1.0 - skill_bonuses.fire_rate)
		sniper_interval *= (1.0 - skill_bonuses.fire_rate)
		ice_beam_interval *= (1.0 - skill_bonuses.fire_rate)
		print("Applied skill tree fire rate: +%.0f%% faster" % (skill_bonuses.fire_rate * 100))

	# Crit chance from skills
	if skill_bonuses.crit_chance > 0:
		crit_chance += skill_bonuses.crit_chance
		print("Applied skill tree crit chance: +%.0f%%" % (skill_bonuses.crit_chance * 100))

	# Crit multiplier from skills
	if skill_bonuses.crit_mult > 0:
		crit_multiplier += skill_bonuses.crit_mult
		print("Applied skill tree crit multiplier: +%.1fx" % skill_bonuses.crit_mult)

	# Damage reduction from skills
	if skill_bonuses.damage_reduction > 0:
		damage_reduction += skill_bonuses.damage_reduction
		print("Applied skill tree damage reduction: %.0f%%" % (skill_bonuses.damage_reduction * 100))

	# Health regen from skills
	if skill_bonuses.health_regen > 0:
		# Store for use in regen logic
		print("Applied skill tree health regen: %.1f HP/s" % skill_bonuses.health_regen)
		# Note: Will need to add actual regen logic in _physics_process

	# XP multiplier from skills
	if skill_bonuses.xp_mult > 0:
		passive_xp_boost += skill_bonuses.xp_mult
		print("Applied skill tree XP: +%.0f%% XP" % (skill_bonuses.xp_mult * 100))

	# Pickup radius from skills
	if skill_bonuses.pickup_radius > 0:
		passive_pickup_boost += skill_bonuses.pickup_radius
		print("Applied skill tree pickup radius: +%d radius" % skill_bonuses.pickup_radius)

	# Coin multiplier from skills
	if skill_bonuses.coin_mult > 0:
		luck_multiplier += skill_bonuses.coin_mult
		print("Applied skill tree coin multiplier: +%.0f%% coins" % (skill_bonuses.coin_mult * 100))

	# Dash cooldown from skills
	if skill_bonuses.dash_cooldown_mult > 0:
		dash_cooldown *= (1.0 - skill_bonuses.dash_cooldown_mult)
		print("Applied skill tree dash cooldown: -%.0f%% cooldown" % (skill_bonuses.dash_cooldown_mult * 100))

func _on_equipment_changed():
	# Called when equipment changes - update player stats
	if not equipment_manager:
		return

	var gear_stats = equipment_manager.get_total_stats()

	# Apply gear bonuses to player stats
	# Health bonus (flat addition to max health)
	if gear_stats.health_bonus > 0:
		var old_max = max_health
		max_health = character_config.base_health + gear_stats.health_bonus
		current_health += (max_health - old_max)  # Increase current health proportionally
		print("Gear health bonus: +%.0f HP (Total: %.0f)" % [gear_stats.health_bonus, max_health])

	# Damage bonus (percentage multiplier)
	if gear_stats.damage_bonus > 0:
		passive_damage_boost = (character_config.base_damage_mult - 1.0) + gear_stats.damage_bonus
		print("Gear damage bonus: +%.0f%% damage" % (gear_stats.damage_bonus * 100))

	# Speed bonus (flat addition)
	if gear_stats.speed_bonus > 0:
		move_speed = character_config.base_speed + gear_stats.speed_bonus
		print("Gear speed bonus: +%.0f speed" % gear_stats.speed_bonus)

	# Crit chance bonus
	if gear_stats.crit_chance_bonus > 0:
		crit_chance = character_config.crit_chance_bonus + gear_stats.crit_chance_bonus
		print("Gear crit chance bonus: +%.1f%% crit" % (gear_stats.crit_chance_bonus * 100))

	# Crit damage bonus
	if gear_stats.crit_damage_bonus > 0:
		crit_multiplier = character_config.crit_damage_mult + gear_stats.crit_damage_bonus
		print("Gear crit damage bonus: +%.0f%% crit damage" % (gear_stats.crit_damage_bonus * 100))

	# Fire rate bonus (affects shoot intervals)
	if gear_stats.fire_rate_bonus > 0:
		shoot_interval *= (1.0 - gear_stats.fire_rate_bonus)
		laser_interval *= (1.0 - gear_stats.fire_rate_bonus)
		homing_interval *= (1.0 - gear_stats.fire_rate_bonus)
		lightning_interval *= (1.0 - gear_stats.fire_rate_bonus)
		boomerang_interval *= (1.0 - gear_stats.fire_rate_bonus)
		sniper_interval *= (1.0 - gear_stats.fire_rate_bonus)
		ice_beam_interval *= (1.0 - gear_stats.fire_rate_bonus)
		print("Gear fire rate bonus: +%.0f%% faster" % (gear_stats.fire_rate_bonus * 100))

	# Armor bonus (damage reduction)
	if gear_stats.armor_bonus > 0:
		# This could be used to reduce incoming damage
		print("Gear armor bonus: +%.1f%% damage reduction" % (gear_stats.armor_bonus * 100))

	# Cooldown reduction bonus
	if gear_stats.cooldown_reduction_bonus > 0:
		# This could reduce ability cooldowns
		print("Gear cooldown reduction: +%.1f%% faster cooldowns" % (gear_stats.cooldown_reduction_bonus * 100))

	# Luck bonus (better loot)
	if gear_stats.luck_bonus > 0:
		# This could improve drop rates
		print("Gear luck bonus: +%.1f%% better loot" % (gear_stats.luck_bonus * 100))

	# Update equipped weapon visual
	update_equipped_weapon_visual()

func update_equipped_weapon_visual():
	"""Update the visual representation of the equipped weapon (staff)"""
	if not equipment_manager or not equipped_weapon_sprite:
		return

	var weapon = equipment_manager.equipped_weapon

	if weapon and weapon.icon_path and weapon.icon_path != "":
		# Load staff texture
		var staff_texture = load(weapon.icon_path)
		if staff_texture:
			equipped_weapon_sprite.texture = staff_texture
			equipped_weapon_sprite.visible = true

			# Scale staff to appropriate size
			# Player is at 0.07 scale, staff should be similar
			equipped_weapon_sprite.scale = Vector2(0.06, 0.06)

			# Position staff to the right of player (like holding it)
			equipped_weapon_sprite.position = Vector2(30, 5)

			# Rotate staff to look like player is holding it
			equipped_weapon_sprite.rotation_degrees = 45

			# Flip staff when player faces left
			if has_node("Sprite2D") and $Sprite2D.flip_h:
				equipped_weapon_sprite.position.x = -30
				equipped_weapon_sprite.flip_h = true
				equipped_weapon_sprite.rotation_degrees = -45  # Flip angle too
			else:
				equipped_weapon_sprite.flip_h = false
				equipped_weapon_sprite.rotation_degrees = 45

			print("✅ Staff equipped visually in game: %s" % weapon.item_name)
		else:
			print("❌ Failed to load staff texture: %s" % weapon.icon_path)
			equipped_weapon_sprite.visible = false
	else:
		# No weapon equipped, hide sprite
		equipped_weapon_sprite.visible = false
		print("No weapon equipped - hiding staff sprite")

func check_pending_gear_items():
	# Check if there are any gear items purchased from shop to add to inventory
	if not SaveSystem.has("pending_gear_items"):
		return

	var pending_items = SaveSystem.get_value("pending_gear_items")
	if pending_items == null or pending_items.size() == 0:
		return

	print("Adding %d pending gear items from shop..." % pending_items.size())

	for item_data in pending_items:
		# Convert dictionary back to Item object
		var item = Item.from_dict(item_data)
		if equipment_manager.add_to_inventory(item):
			print("Added to inventory: %s" % item.item_name)
		else:
			print("Inventory full! Could not add: %s" % item.item_name)

	# Clear pending items
	SaveSystem.set_value("pending_gear_items", [])
	SaveSystem.save_data()
