// Repintado de carrocería para coches (opción A).
// Solo recolorea los píxeles azules saturados (carrocería del coche_azul),
// deja intactos vidrios, llantas, contornos, humo y explosión (grises/naranjas).
// Preserva el sombreado pixel-art transfiriendo S/V relativos al color nuevo.
shader_type canvas_item;

uniform vec4 paint_color : source_color = vec4(0.3, 0.55, 0.9, 1.0);
uniform float mask_threshold : hint_range(0.0, 0.5) = 0.08;
uniform float saturation_min : hint_range(0.0, 1.0) = 0.15;
uniform float paint_amount : hint_range(0.0, 1.0) = 1.0;

// Saturación/Valor medios de la carrocería azul original (0.3,0.55,0.9).
// Sirven de referencia para que un gris pinte gris y un rojo pinte rojo.
const float REF_S = 0.65;
const float REF_V = 0.9;

vec3 rgb_to_hsv(vec3 c) {
	float mx = max(max(c.r, c.g), c.b);
	float mn = min(min(c.r, c.g), c.b);
	float d = mx - mn;
	float h = 0.0;
	if (d > 0.0001) {
		if (mx > c.r - 0.0001 && mx < c.r + 0.0001) {
			h = mod((c.g - c.b) / d, 6.0) / 6.0;
		} else if (mx > c.g - 0.0001 && mx < c.g + 0.0001) {
			h = ((c.b - c.r) / d + 2.0) / 6.0;
		} else {
			h = ((c.r - c.g) / d + 4.0) / 6.0;
		}
	}
	float s = 0.0;
	if (mx > 0.0001) {
		s = d / mx;
	}
	return vec3(h, s, mx);
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 out_rgb = tex.rgb;
	if (tex.a > 0.01 && paint_amount > 0.001) {
		vec3 hsv_orig = rgb_to_hsv(tex.rgb);
		vec3 hsv_paint = rgb_to_hsv(paint_color.rgb);
		// Máscara: azul domina sobre rojo y verde + saturación mínima.
		// Vidrios/llantas/humo (grises) y explosión (naranja) quedan fuera.
		float blueness = tex.b - max(tex.r, tex.g);
		float mask = smoothstep(mask_threshold, mask_threshold + 0.08, blueness)
				* step(saturation_min, hsv_orig.y);
		if (mask > 0.001) {
			// Transfiere sombreado: escala S/V del nuevo color según el píxel original.
			float s_scale = hsv_orig.y / max(REF_S, 0.01);
			float v_scale = hsv_orig.z / max(REF_V, 0.01);
			vec3 repaint_hsv = vec3(
				hsv_paint.x,
				clamp(hsv_paint.y * s_scale, 0.0, 1.0),
				clamp(hsv_paint.z * v_scale, 0.0, 1.0)
			);
			vec3 repaint = hsv_to_rgb(repaint_hsv);
			out_rgb = mix(tex.rgb, repaint, clamp(mask * paint_amount, 0.0, 1.0));
		}
	}
	COLOR = vec4(out_rgb, tex.a);
}
