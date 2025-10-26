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


	triangle: PolygonEntity = {
		points   = {{0, -100}, {-100, 100}, {100, 100}},
		scale    = {1, 1},
		position = {0, 0},
	}


	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		triangle.position += linalg.normalize0(get_input_movement()) * dt * MOVE_SPEED
		triangle.scale += get_input_scale() * dt * SCALE_SPEED
		triangle.rotation += get_input_rotate() * dt * ROTATE_SPEED

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.BLACK)

			draw_polygon_instance(triangle)
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
