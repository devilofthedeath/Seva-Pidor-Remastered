extends CPUParticles2D
class_name PixelBurst
## Универсальный пиксельный взрыв: одна сцена на все эффекты.
## Пресеты: hit / death / dust / muzzle / blood / poop. Цвет и направление задаёт вызвавший.

const PRESET_HIT: String = "hit"
const PRESET_DEATH: String = "death"
const PRESET_DUST: String = "dust"
const PRESET_MUZZLE: String = "muzzle"
const PRESET_BLOOD: String = "blood"
const PRESET_POOP: String = "poop"

static var _pixel_texture: ImageTexture = null

@export var preset: String = PRESET_HIT
@export var tint: Color = Color.WHITE
@export var emit_direction: Vector2 = Vector2.ZERO
@export var auto_free: bool = true


func _ready() -> void:
	texture = _get_pixel_texture()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	local_coords = false
	one_shot = true
	# НЕ включаем эмиссию сразу. FX добавляет ноду в дерево, и только ПОСЛЕ
	# этого задаёт global_position. С local_coords = false частицы живут в
	# мировых координатах: если испустить их в (0,0), они останутся в углу,
	# даже когда ноду потом переместят.
	emitting = false
	z_index = 100
	z_as_relative = false
	_apply_preset(preset, tint, emit_direction)
	if auto_free:
		finished.connect(queue_free)


## Вызывается FX.gd сразу после выставления global_position.
## Синхронно (без call_deferred), чтобы не было гонок со сменой сцены.
func emit_burst() -> void:
	if not is_instance_valid(self):
		return
	emitting = true
	restart()


static func _get_pixel_texture() -> ImageTexture:
	if _pixel_texture == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_pixel_texture = ImageTexture.create_from_image(img)
	return _pixel_texture


func _apply_preset(which: String, tint_color: Color, emit_dir: Vector2) -> void:
	# ВАЖНО: параметр НЕ должен называться `direction` — он затенял бы свойство
	# CPUParticles2D.direction, и все пресеты молча получили бы Vector2.RIGHT.
	var dir := emit_dir
	if dir.length_squared() < 0.000001:
		dir = Vector2.RIGHT
	dir = dir.normalized()

	match which:
		PRESET_DEATH:
			amount = 26
			lifetime = 0.55
			initial_velocity_min = 90.0
			initial_velocity_max = 240.0
			direction = dir
			spread = 180.0
			gravity = Vector2(0.0, 120.0)
			scale_amount_min = 1.0
			scale_amount_max = 2.6
			emission_sphere_radius = 3.0
			angular_velocity_min = -220.0
			angular_velocity_max = 220.0
		PRESET_DUST:
			amount = 10
			lifetime = 0.35
			initial_velocity_min = 20.0
			initial_velocity_max = 70.0
			direction = dir
			spread = 150.0
			gravity = Vector2(0.0, -30.0)
			scale_amount_min = 0.7
			scale_amount_max = 1.6
			emission_sphere_radius = 4.0
			angular_velocity_min = 0.0
			angular_velocity_max = 0.0
		PRESET_MUZZLE:
			amount = 7
			lifetime = 0.18
			initial_velocity_min = 110.0
			initial_velocity_max = 200.0
			direction = dir
			spread = 28.0
			gravity = Vector2.ZERO
			scale_amount_min = 0.8
			scale_amount_max = 1.4
			emission_sphere_radius = 1.5
			angular_velocity_min = 0.0
			angular_velocity_max = 0.0
		PRESET_BLOOD:
			amount = 14
			lifetime = 0.4
			initial_velocity_min = 70.0
			initial_velocity_max = 190.0
			direction = dir
			spread = 150.0
			gravity = Vector2(0.0, 150.0)
			scale_amount_min = 0.8
			scale_amount_max = 2.2
			emission_sphere_radius = 2.0
			angular_velocity_min = -200.0
			angular_velocity_max = 200.0
		PRESET_POOP:
			amount = 16
			lifetime = 0.45
			initial_velocity_min = 60.0
			initial_velocity_max = 170.0
			direction = dir
			spread = 160.0
			gravity = Vector2(0.0, 220.0)
			scale_amount_min = 1.0
			scale_amount_max = 2.4
			emission_sphere_radius = 3.0
			angular_velocity_min = -160.0
			angular_velocity_max = 160.0
		_:  # PRESET_HIT
			amount = 12
			lifetime = 0.28
			initial_velocity_min = 60.0
			initial_velocity_max = 160.0
			direction = dir
			spread = 120.0
			gravity = Vector2(0.0, 80.0)
			scale_amount_min = 0.9
			scale_amount_max = 2.0
			emission_sphere_radius = 2.0
			angular_velocity_min = -140.0
			angular_velocity_max = 140.0

	explosiveness = 1.0
	color_ramp = null
	color = tint_color
