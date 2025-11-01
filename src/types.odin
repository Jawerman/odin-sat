package sat

import "core:math"
import "core:math/linalg"

Point :: [2]f32

Circle :: struct {
	center: Point,
	radius: f32,
}

IDENTITY_MATRIX: matrix[2, 2]f32 = {0, 0, 0, 0}

Transform_Description :: struct {
	position: [2]f32,
	rotation: f32,
	scale:    [2]f32,
}

Shape_Instance :: struct {
	points:                      []Point,
	using transform_description: Transform_Description,
}

get_transform_matrix :: proc(transform_description: Transform_Description) -> linalg.Matrix3f32 {
	rotate := matrix3_rotate_f32(linalg.to_radians(f32(transform_description.rotation)))
	translate := matrix3_translate_f32(transform_description.position)
	scale := matrix3_scale_f32(transform_description.scale)

	return translate * rotate * scale
}

apply_transform_to_polygon :: proc(
	polygon: []Point,
	transformed_polygon: []Point,
	transform: linalg.Matrix3f32,
) {
	for &point, index in polygon {
		transformed_polygon[index] =
			linalg.matrix_mul_vector(transform, [3]f32{point.x, point.y, 1}).xy
	}
}
create_regular_ngon :: proc(num_vertices: int, radius: f32) -> []Point {
	ngon := make([]Point, num_vertices)
	f_theta := math.PI * 2.0 / f32(num_vertices)

	for i in 0 ..< num_vertices {
		fi := f32(i)
		ngon[i] = {math.cos(f_theta * fi), math.sin(f_theta * fi)} * radius
	}

	return ngon
}
