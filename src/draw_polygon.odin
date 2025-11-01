package sat
import rl "vendor:raylib"
import "core:math/linalg"

draw_polygon :: proc(
	points: []Point,
	color: rl.Color,
	transform: matrix[3, 3]f32 = linalg.MATRIX3F32_IDENTITY,
) {
	if len(points) == 0 do return

	for &point, index in points {
		end_point := &points[(index + 1) % len(points)]

		transformed_point := linalg.matrix_mul_vector(transform, [3]f32{point.x, point.y, 1})
		transformed_end_point := linalg.matrix_mul_vector(
			transform,
			[3]f32{end_point.x, end_point.y, 1},
		)

		rl.DrawCircleV(transformed_point.xy, 3, color)
		rl.DrawLineV(transformed_point.xy, transformed_end_point.xy, color)
	}
}

draw_polygon_points :: proc(points: []Point, color: rl.Color) {
	if len(points) == 0 do return

	for &point, index in points {
		end_point := points[(index + 1) % len(points)]

		rl.DrawCircleV(point, 3, color)
		rl.DrawLineV(point, end_point, color)
	}
}

draw_shape_instance :: proc(shape_instance: Shape_Instance, color: rl.Color = rl.WHITE) {
	draw_polygon(
		shape_instance.points,
		color,
		transform = get_transform_matrix(shape_instance.transform_description),
	)
}
