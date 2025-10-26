package sat

import "core:fmt"
import "core:log"
import "core:math/linalg"
import rl "vendor:raylib"
// make -> delete
// new -> free

Point :: [2]f32

Polygon :: []Point

IDENTITY_MATRIX: matrix[2, 2]f32 = {0, 0, 0, 0}

PolygonEntity :: struct {
	points:   Polygon,
	position: [2]f32,
	rotation: f32,
	scale:    [2]f32,
}

draw_poligon :: proc(
	poly: Polygon,
	color: rl.Color,
	transform: matrix[3, 3]f32 = linalg.MATRIX3F32_IDENTITY,
) {
	if len(poly) == 0 do return

	for &point, index in poly {
		end_point := index > 0 ? poly[index - 1] : poly[index + len(poly) - 1]

		transformed_point := linalg.matrix_mul_vector(transform, [3]f32{point.x, point.y, 1})
		transformed_end_point := linalg.matrix_mul_vector(
			transform,
			[3]f32{end_point.x, end_point.y, 1},
		)

		rl.DrawCircleV(transformed_point.xy, 3, color)
		rl.DrawLineV(transformed_point.xy, transformed_end_point.xy, color)
	}
}

draw_polygon_instance :: proc(entity: PolygonEntity) {
	rotate := matrix3_rotate_f32(linalg.to_radians(f32(entity.rotation)))
	translate := matrix3_translate_f32(entity.position)
	scale := matrix3_scale_f32(entity.scale)

	draw_poligon(entity.points, rl.WHITE, transform = translate * rotate * scale)
}
