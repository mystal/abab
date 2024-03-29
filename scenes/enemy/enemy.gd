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

var JUMP_TIME: float = 2.0

@onready var _respawn_position: Vector2 = position
@onready var _sprite = $AnimatedSprite2D
@onready var _jump_timer = 0.0

func _ready():
	if JUMP_RELEASE_BEHAVIOR == JumpReleaseBehavior.HalfTile:
		JUMP_RELEASE_SPEED = HALF_TILE_JUMP_SPEED

func _physics_process(delta):
	_jump_timer += delta
	var wants_to_jump = false
	if _jump_timer > JUMP_TIME:
		_jump_timer = 0.0
		wants_to_jump = true

	if not is_on_floor():
		# TODO: Add a minimum jump release time.
		# if _can_release_jump() and Input.is_action_just_released("jump") and velocity.y < JUMP_RELEASE_SPEED:
		# 	# Clamp velocity if greater than JUMP_RELEASE_SPEED.
		# 	velocity.y = JUMP_RELEASE_SPEED
		# else:
		# Apply gravity.
		velocity.y += GRAVITY * delta

	# Handle Jump.
	if wants_to_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# TODO: Add acceleration/deceleration.
	var direction = false
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

	var player = get_tree().get_first_node_in_group("players")
	if player:
		_sprite.flip_h = player.position.x < position.x
	if !is_zero_approx(velocity.x):
		_sprite.flip_h = velocity.x < 0.0

func _can_release_jump() -> bool:
	return JUMP_RELEASE_BEHAVIOR != JumpReleaseBehavior.None

func _on_area_2d_body_entered(body: Node2D):
	if body is TileMap:
		position = _respawn_position
		velocity = Vector2.ZERO
		# TODO: Play a death sound!

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("teleporters"):
		get_tree().change_scene_to_file(area.NEXT_SCENE)
