package sat

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"


Point :: [2]f32

Shape :: []Point

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

draw_shape :: proc(
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

draw_shape_points :: proc(points: []Point, color: rl.Color) {
	if len(points) == 0 do return

	for &point, index in points {
		end_point := points[(index + 1) % len(points)]

		rl.DrawCircleV(point, 3, color)
		rl.DrawLineV(point, end_point, color)
	}
}

test_polygons_overlap_sat :: proc(p1: []Point, p2: []Point) -> bool {
	tested_polygons := [2][]Point{p1, p2}

	for &tested_polygon in tested_polygons {
		for &point_a, index in tested_polygon {
			point_b := tested_polygon[(index + 1) % len(tested_polygon)]
			edge := point_b - point_a

			axis: [2]f32 = [2]f32{-edge.y, edge.x}
			min_p1, max_p1 := get_projection_min_max(p1, axis)
			min_p2, max_p2 := get_projection_min_max(p2, axis)

			if min_p1 >= max_p2 || max_p1 < min_p2 do return false
		}
	}
	return true
}

test_polygons_overlap_sat_resolve :: proc(
	p1: []Point,
	p2: []Point,
) -> (
	normal: [2]f32,
	depth: f32,
	overlap: bool,
) {
	overlap = false
	depth = max(f32)

	tested_polygons := [2][]Point{p1, p2}
	for &tested_polygon in tested_polygons {
		for &point_a, index in tested_polygon {
			point_b := tested_polygon[(index + 1) % len(tested_polygon)]
			edge := point_b - point_a

			axis: [2]f32 = linalg.normalize0([2]f32{-edge.y, edge.x})
			min_depth, overlap := get_polygons_proyection_separation(p1, p2, axis)
			if !overlap do return

			min_depth_abs := abs(min_depth)

			if min_depth_abs < depth {
				depth = min_depth_abs
				normal = min_depth < 0 ? -axis : axis
			}
		}
	}
	return normal, depth, true
}

get_polygons_proyection_separation :: proc(
	p1: []Point,
	p2: []Point,
	axis: [2]f32,
) -> (
	depth: f32,
	overlap: bool,
) {
	overlap = false

	min_p1, max_p1 := get_projection_min_max(p1, axis)
	min_p2, max_p2 := get_projection_min_max(p2, axis)

	depth_side1 := max_p1 - min_p2
	depth_side2 := min_p1 - max_p2

	if depth_side1 * depth_side2 >= 0 do return

	return abs(depth_side1) < abs(depth_side2) ? depth_side1 : depth_side2, true
}

get_projection_min_max :: proc(polygon: []Point, axis: [2]f32) -> (min_p: f32, max_p: f32) {
	min_p, max_p = max(f32), min(f32)
	for &projected_point in polygon {
		projection := linalg.vector_dot(projected_point, axis)
		min_p = min(min_p, projection)
		max_p = max(max_p, projection)
	}
	return min_p, max_p
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

draw_shape_instance :: proc(shape_instance: Shape_Instance, color: rl.Color = rl.WHITE) {
	draw_shape(
		shape_instance.points,
		color,
		transform = get_transform_matrix(shape_instance.transform_description),
	)
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
