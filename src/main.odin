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
	pentagon: Polygon_Instance = {
		position = {100, 100},
		scale    = {1, 1},
		points   = pentagon_points,
		rotation = 0,
	}

	triangle_points := create_regular_ngon(3, 80)
	defer delete(triangle_points)
	triangle: Polygon_Instance = {
		position = {400, 400},
		scale    = {1, 1},
		points   = triangle_points,
		rotation = 0,
	}

	square_points := create_regular_ngon(4, 90)
	defer delete(square_points)
	square: Polygon_Instance = {
		position = {600, 100},
		scale    = {1, 1},
		points   = square_points,
		rotation = 0,
	}

	circle1: Circle_Instance = {
		center = {200, 100},
		radius = 100,
		scale  = 1.0,
	}

	circle2: Circle_Instance = {
		center = {500, 100},
		radius = 50,
		scale  = 1.0,
	}

	shapes: []Shape_Instance = {pentagon, triangle, square, circle1, circle2}
	transformed_shapes: []Shape = {
		make([]Point, len(pentagon.points)),
		make([]Point, len(triangle.points)),
		make([]Point, len(square.points)),
		circle1.circle,
		circle2.circle,
	}
	defer {
		for &shape in transformed_shapes {
			if type_of(shape) == []Point {
				delete(shape.([]Point))
			}
		}
	}

	shape_selected_index: int = 0

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		dt := rl.GetFrameTime()

		shape_selected_index =
			(shape_selected_index + get_selected_shape_index_inc() + len(shapes)) % len(shapes)

		selected_shape := &shapes[shape_selected_index]
		position_inc := get_input_movement() * MOVE_SPEED * dt
		scale_inc := get_input_scale() * SCALE_SPEED * dt
		rotation_inc := get_input_rotate() * ROTATE_SPEED * dt

		switch &s in selected_shape {
		case Polygon_Instance:
			{
				s.position += position_inc
				s.scale += scale_inc
				s.rotation += rotation_inc
			}
		case Circle_Instance:
			s.position += position_inc
			s.scale += scale_inc.x
		}

		for &shape, index in shapes {
			switch &s in shape {
			case Polygon_Instance:
				{
					apply_transform_to_polygon(
						s.points,
						transformed_shapes[index].([]Point),
						get_transform_matrix(s.transform_description),
					)
				}
			case Circle_Instance:
				circle := &transformed_shapes[index].(Circle)
				circle.center = s.center + s.position
				circle.radius = s.radius * s.scale
			}
		}

		for &shape, index in transformed_shapes {
			for &other_shape, other_index in transformed_shapes {
				if index == other_index do continue

				normal, depth, collide := resolve_collision(shape, other_shape)

				if collide {
					displacement_half := normal * (depth / 2)

					switch &s in other_shape {
					case []Point:
						{
							other_shape_ref := &shapes[other_index].(Polygon_Instance)
							other_shape_ref.position += displacement_half
							for &point in s {
								point += displacement_half
							}

						}
					case Circle:
						{
							other_shape_ref := &shapes[other_index].(Circle_Instance)
							other_shape_ref.center += displacement_half
							s.center += displacement_half
						}
					}

					switch &s in shape {
					case []Point:
						{
							shape_ref := &shapes[index].(Polygon_Instance)
							shape_ref.position -= displacement_half
							for &point in s {
								point -= displacement_half
							}

						}
					case Circle:
						{
							shape_ref := &shapes[index].(Circle_Instance)
							shape_ref.center -= displacement_half
							s.center -= displacement_half
						}
					}
				}
			}
		}

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.BLACK)

			for &shape, index in transformed_shapes {
				color := index == shape_selected_index ? rl.BLUE : rl.WHITE

				switch &s in shape {
				case []Point:
					draw_polygon_points(s, color)
				case Circle:
					rl.DrawCircleLinesV(s.center, s.radius, color)
				}
			}
		}
	}

}

resolve_collision :: proc(s1, s2: Shape) -> (normal: [2]f32, depth: f32, overlap: bool) {
	overlap = false
	_, s1_poly := s1.([]Point)
	_, s2_poly := s2.([]Point)

	if s1_poly && s2_poly {
		return resolve_polygons_overlap_sat(s1.([]Point), s2.([]Point))
	}
	if s1_poly && !s2_poly {
		return resolve_polygon_circle_overlap_sat(s1.([]Point), s2.(Circle))
	}
	if !s1_poly && s2_poly {
		return resolve_polygon_circle_overlap_sat(s2.([]Point), s1.(Circle))
	}
	return
}


get_selected_shape_index_inc :: proc() -> int {
	if rl.IsKeyPressed(.ONE) {
		return -1
	}
	if rl.IsKeyPressed(.TWO) {
		return 1
	}
	return 0

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
