package sat

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"


test_polygons_overlap_sat :: proc(p1, p2: []Point) -> bool {
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

test_polygon_circle_overlap_sat :: proc(p: []Point, c: Circle) -> bool {
	for &point_a, index in p {
		point_b := p[(index + 1) % len(p)]
		edge := point_b - point_a
		axis: [2]f32 = linalg.normalize0([2]f32{-edge.y, edge.x})
		if !test_axis_polygon_circle_overlap(p, c, axis) do return false
	}

	// Testing center to closes point axis https://www.reddit.com/r/gamedev/comments/xtry1/circlepolygon_collison_using_sat/
	{
		center_to_closest := get_polygon_closest_point_to(p, c.center)
		axis: [2]f32 = linalg.normalize0(center_to_closest - c.center)

		if !test_axis_polygon_circle_overlap(p, c, axis) do return false
	}

	return true
}


test_circles_operlap :: proc(c1, c2: Circle) -> bool {
	centers_distance := c2.center - c1.center
	distance2 := linalg.vector_length2(centers_distance)
	radius_sum := c1.radius + c2.radius

	return distance2 < (radius_sum * radius_sum)
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

resolve_circles_overlap_sat :: proc(
	c1, c2: Circle,
) -> (
	normal: [2]f32,
	depth: f32,
	overlap: bool,
) {
	centers_distance := c2.center - c1.center
	axis := linalg.normalize0(centers_distance)

	min_depth: f32
	min_depth, overlap = get_circles_proyection_separation(c1, c2, axis)
	if !overlap do return

	depth = abs(min_depth)
	normal = min_depth < 0 ? -axis : axis

	return normal, depth, true
}

get_circles_proyection_separation :: proc(
	c1, c2: Circle,
	axis: [2]f32,
) -> (
	depth: f32,
	overlap: bool,
) {
	min_c1, max_c1 := get_circle_projection_min_max(c1, axis)
	min_c2, max_c2 := get_circle_projection_min_max(c2, axis)

	return get_min_projection_separation(min_c1, max_c1, min_c2, max_c2)
}

// TODO: resolve circle vs circle

test_axis_polygons_overlap :: proc(p1: []Point, p2: []Point, axis: [2]f32) -> bool {
	min_p1, max_p1 := get_polygon_projection_min_max(p1, axis)
	min_p2, max_p2 := get_polygon_projection_min_max(p2, axis)

	return min_p1 < max_p2 && max_p1 > min_p2
}

test_axis_polygon_circle_overlap :: proc(p: []Point, c: Circle, axis: [2]f32) -> bool {
	min_p, max_p := get_polygon_projection_min_max(p, axis)
	min_c, max_c := get_circle_projection_min_max(c, axis)

	return min_p < max_c && max_p > min_c
}


get_circle_projection_min_max :: proc(c: Circle, axis: [2]f32) -> (min_p, max_p: f32) {
	scaled_axis := axis * c.radius
	min := c.center - scaled_axis
	max := c.center + scaled_axis

	return linalg.vector_dot(min, axis), linalg.vector_dot(max, axis)
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
