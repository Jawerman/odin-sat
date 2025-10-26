package sat
import "core:math"
import "core:math/linalg"


@(require_results)
matrix3_translate_f32 :: proc "contextless" (
	v: linalg.Vector2f32,
) -> linalg.Matrix3f32 #no_bounds_check {
	m := linalg.MATRIX3F32_IDENTITY
	m[0, 2] = v[0]
	m[1, 2] = v[1]
	return m
}

@(require_results)
matrix3_rotate_f32 :: proc "contextless" (angle_radians: f32) -> linalg.Matrix3f32 {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	return linalg.Matrix3f32{c, -s, 0, s, c, 0, 0, 0, 1}
}

@(require_results)
matrix3_scale_f32 :: proc "contextless" (
	s: linalg.Vector2f32,
) -> linalg.Matrix3f32 #no_bounds_check {
	m := linalg.MATRIX3F32_IDENTITY
	m[0, 0] = s[0]
	m[1, 1] = s[1]
	return m
}
