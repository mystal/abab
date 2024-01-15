class_name Player
extends CharacterBody2D

# TODO: Move to global vars.
const TILE_HEIGHT: float = 128.0
const TILE_WIDTH: float = 128.0

## What to do when releasing the jump button after jumping.
enum JumpReleaseBehavior {
	## Do nothing.
	None,

	## Zero out vertical velocity.
	ZeroOut,

	## Set vertical velocity such that the player moves up half a tile.
	HalfTile,
}

enum Facing {
	Left,
	Right,
}

@export var PLAYER_ID: int = 1

@export var DEFAULT_LIVES: int = 3

@export var PEW_PEW_SCENE: PackedScene
@export var MAX_PEWS: int = 3

## Horizontal speed in pixel units.
@export_range(0.0, 2_000.0, 10.0, "or_greater") var MOVE_SPEED: float = 800.0
## Jump height in tiles.
@export var JUMP_HEIGHT_TILES: float = 3.5
## Jump horizontal distance in tiles.
@export var JUMP_DISTANCE_TILES: float = 5
## What to do when releasing the jump button after jumping.
@export var JUMP_RELEASE_BEHAVIOR: JumpReleaseBehavior = JumpReleaseBehavior.None

# Derived jump constants.
var JUMP_HEIGHT: float = JUMP_HEIGHT_TILES * TILE_HEIGHT
## Horizontal pixel unit distance from start of jump to peak.
var JUMP_DISTANCE: float = JUMP_DISTANCE_TILES * TILE_WIDTH / 2.0
var JUMP_PEAK_TIME: float = JUMP_DISTANCE / MOVE_SPEED
var JUMP_VELOCITY: float = -(2.0 * JUMP_HEIGHT) / JUMP_PEAK_TIME
var GRAVITY: float = (2.0 * JUMP_HEIGHT) / pow(JUMP_PEAK_TIME, 2.0)
var HALF_TILE_JUMP_PEAK_TIME: float = sqrt(TILE_HEIGHT / GRAVITY)
var HALF_TILE_JUMP_SPEED: float = -(GRAVITY * HALF_TILE_JUMP_PEAK_TIME)
var JUMP_RELEASE_SPEED: float = 0.0

@onready var _respawn_position: Vector2 = position
@onready var _sprite = $AnimatedSprite2D

var _lives: int = DEFAULT_LIVES
var _num_pew_pews: int = 0
var _facing: Facing = Facing.Right
var _dead: bool = false

# Input action vars
var _jump_input: String = "jump"
var _move_left_input: String = "move_left"
var _move_right_input: String = "move_right"
var _shoot_input: String = "shoot"
var _slide_input: String = "slide"

func _ready():
	# Append PLAYER_ID to input action strings
	_jump_input += str(PLAYER_ID)
	_move_left_input += str(PLAYER_ID)
	_move_right_input += str(PLAYER_ID)
	_shoot_input += str(PLAYER_ID)
	_slide_input += str(PLAYER_ID)

	if JUMP_RELEASE_BEHAVIOR == JumpReleaseBehavior.HalfTile:
		JUMP_RELEASE_SPEED = HALF_TILE_JUMP_SPEED

func _physics_process(delta):
	if _dead:
		return

	# In-air logic.
	if not is_on_floor():
		# TODO: Add a minimum jump release time.
		if _can_release_jump() and Input.is_action_just_released(_jump_input) and velocity.y < JUMP_RELEASE_SPEED:
			# Clamp velocity if greater than JUMP_RELEASE_SPEED.
			velocity.y = JUMP_RELEASE_SPEED
		else:
			# Apply gravity.
			velocity.y += GRAVITY * delta

	# Handle Jump and Slide.
	if Input.is_action_just_pressed(_jump_input) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# TODO: Add acceleration/deceleration.
	var direction = Input.get_axis(_move_left_input, _move_right_input)
	if direction:
		velocity.x = direction * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)

	# Modifies velocity
	move_and_slide()

	# Update animation
	if !is_on_floor():
		_sprite.play("jump")
	elif is_zero_approx(velocity.x):
		_sprite.play("idle")
	else:
		_sprite.play("walk")

	# Update facing
	if !is_zero_approx(velocity.x):
		var facing_right = velocity.x > 0.0
		if facing_right:
			_facing = Facing.Right
			$ShootRoot.position.x = abs($ShootRoot.position.x)
		else:
			_facing = Facing.Left
			$ShootRoot.position.x = -abs($ShootRoot.position.x)
		_sprite.flip_h = !facing_right

	# Try to shoot
	if Input.is_action_just_pressed(_shoot_input) and _num_pew_pews < MAX_PEWS:
		var pew_pew = PEW_PEW_SCENE.instantiate()
		pew_pew._owning_player = self
		pew_pew.position = $ShootRoot.global_position
		if _facing == Facing.Left:
			pew_pew.SPEED *= -1
		get_tree().current_scene.add_child(pew_pew)
		_num_pew_pews += 1

func _can_release_jump() -> bool:
	return JUMP_RELEASE_BEHAVIOR != JumpReleaseBehavior.None

func decrement_pew_pews():
	_num_pew_pews -= 1
	if _num_pew_pews < 0:
		_num_pew_pews = 0

func _die():
	_lives -= 1
	if _lives <= 0:
		_lives = 0

	position = _respawn_position
	velocity = Vector2.ZERO
	$AnimatedSprite2D.visible = false
	$WorldCollision2D.set_deferred("disabled", true)
	$Area2D/AreaCollision2D.set_deferred("disabled", true)
	$DeathTimer.start()
	_dead = true
	# TODO: Give temporary invulnerability
	# TODO: Play a death sound!
	
func _respawn():
	position = _respawn_position
	velocity = Vector2.ZERO
	$AnimatedSprite2D.visible = true
	$WorldCollision2D.set_deferred("disabled", false)
	$Area2D/AreaCollision2D.set_deferred("disabled", false)
	_dead = false

func _on_area_2d_body_entered(body: Node2D):
	if body is TileMap:
		_die()

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("teleporters"):
		get_tree().change_scene_to_file(area.NEXT_SCENE)
	elif area is PewPew and area._owning_player != self:
		area.queue_free()
		_die()

func _on_death_timer_timeout():
	_respawn()
