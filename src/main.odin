package sat

import "core:log"
import "core:math/linalg"
import rl "vendor:raylib"

SCREEN_WIDTH :: [2]i32{800, 600}

MOVE_SPEED :: 200
SCALE_SPEED :: 1
ROTATE_SPEED :: 50


main :: proc() {
	context.logger = log.create_console_logger()

	rl.SetTargetFPS(60)
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})

	rl.InitWindow(SCREEN_WIDTH.x, SCREEN_WIDTH.y, "SAT test")
	defer rl.CloseWindow()

	pentagon_points := create_regular_ngon(5, 100)
	defer delete(pentagon_points)
	pentagon: Shape_Instance = {
		position = {100, 100},
		scale    = {1, 1},
		points   = pentagon_points,
		rotation = 0,
	}

	triangle_points := create_regular_ngon(3, 80)
	defer delete(triangle_points)
	triangle: Shape_Instance = {
		position = {400, 400},
		scale    = {1, 1},
		points   = triangle_points,
		rotation = 0,
	}

	square_points := create_regular_ngon(4, 90)
	defer delete(square_points)
	square: Shape_Instance = {
		position = {600, 100},
		scale    = {1, 1},
		points   = square_points,
		rotation = 0,
	}

	shapes: []Shape_Instance = {pentagon, triangle, square}
	transformed_shapes: []Shape = {
		make([]Point, len(pentagon.points)),
		make([]Point, len(triangle.points)),
		make([]Point, len(square.points)),
	}
	defer {
		for &shape in transformed_shapes {
			delete(shape)
		}
	}

	shape_selected: int = 0

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		dt := rl.GetFrameTime()

		new_shape_selected := get_selected_shape()

		if new_shape_selected >= 0 {
			shape_selected = new_shape_selected
		}

		selected_shape := &shapes[shape_selected]
		selected_shape.position += linalg.normalize0(get_input_movement()) * dt * MOVE_SPEED
		selected_shape.scale += get_input_scale() * dt * SCALE_SPEED
		selected_shape.rotation += get_input_rotate() * dt * ROTATE_SPEED

		for &shape, index in shapes {
			apply_transform_to_polygon(
				shape.points,
				transformed_shapes[index],
				get_transform_matrix(shape.transform_description),
			)
		}

		for &shape, index in transformed_shapes {
			for &other_shape, other_index in transformed_shapes {
				if index == other_index do continue

				normal, depth, collide := test_polygons_overlap_sat_resolve(shape, other_shape)
				if collide {
					displacement_half := normal * (depth / 2)

					shapes[other_index].position += displacement_half
					for &point in other_shape {
						point += displacement_half
					}

					shapes[index].position -= displacement_half
					for &point in shape {
						point -= displacement_half
					}
				}
			}
		}

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.BLACK)

			for &shape, index in transformed_shapes {
				is_colliding := false

				for &other_shape, other_index in transformed_shapes {
					if index == other_index do continue
					if test_polygons_overlap_sat(shape, other_shape) {
						is_colliding = true
						break
					}
				}

				color := is_colliding ? rl.RED : rl.WHITE
				draw_shape_points(shape, color)
			}
		}
	}

}

get_selected_shape :: proc() -> int {
	if rl.IsKeyPressed(.ONE) {
		return 0
	}
	if rl.IsKeyPressed(.TWO) {
		return 1
	}
	if rl.IsKeyDown(.THREE) {
		return 2
	}
	return -1
}

get_input_movement :: proc() -> (move_inc: [2]f32) {
	if rl.IsKeyDown(.W) {
		move_inc.y -= 1
	}
	if rl.IsKeyDown(.S) {
		move_inc.y += 1
	}
	if rl.IsKeyDown(.A) {
		move_inc.x -= 1
	}
	if rl.IsKeyDown(.D) {
		move_inc.x += 1
	}

	return move_inc
}

get_input_scale :: proc() -> (scale_inc: [2]f32) {
	if rl.IsKeyDown(.UP) {
		scale_inc.y += 1
	}
	if rl.IsKeyDown(.DOWN) {
		scale_inc.y -= 1
	}
	if rl.IsKeyDown(.LEFT) {
		scale_inc.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) {
		scale_inc.x += 1
	}

	return scale_inc
}

get_input_rotate :: proc() -> (rotate_inc: f32) {
	if rl.IsKeyDown(.Q) {
		rotate_inc -= 1
	}
	if rl.IsKeyDown(.E) {
		rotate_inc += 1
	}

	return rotate_inc
}
