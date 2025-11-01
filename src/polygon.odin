package sat

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"


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
			if !test_axis_polygons_overlap(p1, p2, {-edge.y, edge.x}) do return false
		}
	}
	return true
}

test_axis_polygons_overlap :: proc(p1: []Point, p2: []Point, axis: [2]f32) -> bool {
	min_p1, max_p1 := get_polygon_projection_min_max(p1, axis)
	min_p2, max_p2 := get_polygon_projection_min_max(p2, axis)

	return min_p1 < max_p2 && max_p1 > min_p2
}

test_polygon_circle_overlap_sat :: proc(p: []Point, c: Circle) -> bool {
	for &point_a, index in p {
		point_b := p[(index + 1) % len(p)]
		edge := point_b - point_a
		axis: [2]f32 = linalg.normalize0([2]f32{-edge.y, edge.x})

		min_p, max_p := get_polygon_projection_min_max(p, axis)
		min_c, max_c := get_circle_projection_min_max(c, axis)

		// circle_center_projection := linalg.vector_dot(c.center, axis)
		// min_c, max_c := circle_center_projection - c.radius, circle_center_projection + c.radius

		if min_p >= max_c || max_p <= min_c do return false
	}

	// Testing center to closes point axis https://www.reddit.com/r/gamedev/comments/xtry1/circlepolygon_collison_using_sat/
	{
		center_to_closest := get_polygon_closest_point_to(p, c.center)
		axis: [2]f32 = linalg.normalize0(center_to_closest - c.center)

		min_p, max_p := get_polygon_projection_min_max(p, axis)
		min_c, max_c := get_circle_projection_min_max(c, axis)

		// circle_center_projection := linalg.vector_dot(c.center, axis)
		// min_c, max_c := circle_center_projection - c.radius, circle_center_projection + c.radius

		if min_p >= max_c || max_p <= min_c do return false
	}

	return true
}

get_circle_projection_min_max :: proc(c: Circle, axis: [2]f32) -> (min_p, max_p: f32) {
	scaled_axis := axis * c.radius
	min := c.center - scaled_axis
	max := c.center + scaled_axis

	// circle_center_projection := linalg.vector_dot(c.center, axis)
	// return circle_center_projection - c.radius, circle_center_projection + c.radius
	return linalg.vector_dot(min, axis), linalg.vector_dot(max, axis)
}

resolve_polygon_circle_overlap_sat :: proc(
	p: []Point,
	c: Circle,
) -> (
	normal: [2]f32,
	depth: f32,
	overlap: bool,
) {
	overlap = false
	depth = max(f32)

	for &point_a, index in p {
		point_b := p[(index + 1) % len(p)]
		edge := point_b - point_a
		axis: [2]f32 = linalg.normalize0([2]f32{-edge.y, edge.x})

		min_depth, overlap := get_polygon_circle_proyection_separation(p, c, axis)
		if !overlap do return

		min_depth_abs := abs(min_depth)

		if min_depth_abs < depth {
			depth = min_depth_abs
			normal = min_depth < 0 ? -axis : axis
		}
	}
	// Testing center to closes point axis https://www.reddit.com/r/gamedev/comments/xtry1/circlepolygon_collison_using_sat/
	{
		center_to_closest := get_polygon_closest_point_to(p, c.center)
		axis: [2]f32 = linalg.normalize0(center_to_closest - c.center)

		min_depth, overlap := get_polygon_circle_proyection_separation(p, c, axis)
		if !overlap do return

		min_depth_abs := abs(min_depth)

		if min_depth_abs < depth {
			depth = min_depth_abs
			normal = min_depth < 0 ? -axis : axis
		}
	}
	return normal, depth, true
}


get_polygon_closest_point_to :: proc(points: []Point, ref_point: Point) -> (closest: [2]f32) {
	min_distance := max(f32)
	for &point, index in points {
		diff := ref_point - point
		length_diff := linalg.length2(diff)

		if (length_diff < min_distance) {
			min_distance = length_diff
			closest = point
		}
	}
	return closest
}


resolve_polygons_overlap_sat :: proc(
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

resolve_axis_polygons_overlap :: proc(
	p1: []Point,
	p2: []Point,
	axis: [2]f32,
) -> (
	normal: [2]f32,
	depth: f32,
	overlap: bool,
) {
	axis_min_depth: f32
	axis_min_depth, overlap = get_polygons_proyection_separation(p1, p2, axis)
	if !overlap do return

	depth = abs(axis_min_depth)
	normal = axis_min_depth < 0 ? -axis : axis
	return normal, depth, overlap
}

get_polygons_proyection_separation :: proc(
	p1, p2: []Point,
	axis: [2]f32,
) -> (
	depth: f32,
	overlap: bool,
) {
	min_p1, max_p1 := get_polygon_projection_min_max(p1, axis)
	min_p2, max_p2 := get_polygon_projection_min_max(p2, axis)

	return get_min_projection_separation(min_p1, max_p1, min_p2, max_p2)
}

get_polygon_circle_proyection_separation :: proc(
	p: []Point,
	c: Circle,
	axis: [2]f32,
) -> (
	depth: f32,
	overlap: bool,
) {
	min_p, max_p := get_polygon_projection_min_max(p, axis)
	min_c, max_c := get_circle_projection_min_max(c, axis)

	return get_min_projection_separation(min_p, max_p, min_c, max_c)
}

get_min_projection_separation :: proc(min1, max1, min2, max2: f32) -> (depth: f32, overlap: bool) {
	depth_side1 := max1 - min2
	depth_side2 := min1 - max2

	if depth_side1 * depth_side2 >= 0 do return

	return abs(depth_side1) < abs(depth_side2) ? depth_side1 : depth_side2, true
}

get_polygon_projection_min_max :: proc(polygon: []Point, axis: [2]f32) -> (min_p, max_p: f32) {
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
