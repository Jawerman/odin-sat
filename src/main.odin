package sat

import "core:log"
import "core:math/linalg"
import rl "vendor:raylib"

SCREEN_WIDTH :: [2]i32{800, 600}

MOVE_SPEED :: 100
SCALE_SPEED :: 1
ROTATE_SPEED :: 50


main :: proc() {
	context.logger = log.create_console_logger()

	rl.SetTargetFPS(60)
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})

	rl.InitWindow(SCREEN_WIDTH.x, SCREEN_WIDTH.y, "SAT test")
	defer rl.CloseWindow()

	pentagon_points := create_ngon(5, 100)
	defer delete(pentagon_points)
	pentangon: PolygonEntity = {
		position = {100, 100},
		scale    = {1, 1},
		points   = pentagon_points,
		rotation = 0,
	}

	triangle_points := create_ngon(3, 80)
	defer delete(triangle_points)
	triangle: PolygonEntity = {
		position = {400, 400},
		scale    = {1, 1},
		points   = triangle_points,
		rotation = 0,
	}

	square_points := create_ngon(4, 90)
	defer delete(square_points)
	square: PolygonEntity = {
		position = {600, 100},
		scale    = {1, 1},
		points   = square_points,
		rotation = 0,
	}

	shapes: []PolygonEntity = {pentangon, triangle, square}


	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		first_shape := &shapes[0]
		first_shape.position += linalg.normalize0(get_input_movement()) * dt * MOVE_SPEED
		first_shape.scale += get_input_scale() * dt * SCALE_SPEED
		first_shape.rotation += get_input_rotate() * dt * ROTATE_SPEED

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.BLACK)

			for &shape in shapes {
				draw_polygon_instance(shape, rl.WHITE)
			}
		}
	}

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
