// Variante de plumaje para pollos NPC (mismo patrón que vehicle_paint.gdshader).
// Solo recolorea la pluma blanca/gris clara, deja intactos pico, patas,
// cresta, contornos, daño y muerte (amarillos/naranjas/rojos saturados).
// Preserva el sombreado pixel-art transfiriendo S/V relativos al color nuevo.
shader_type canvas_item;

uniform vec4 plume_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float plume_amount : hint_range(0.0, 1.0) = 1.0;

// Pluma blanca original: luminancia alta, saturación baja (medido del arte).
// Sirven de referencia para que el sombreado del pixel-art se conserve.
const float REF_S = 0.12;
const float REF_V = 0.95;

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
	if (tex.a > 0.01 && plume_amount > 0.001) {
		vec3 hsv_orig = rgb_to_hsv(tex.rgb);
		float lum = min(min(tex.r, tex.g), tex.b);
		// Máscara pluma: píxel claro (blanco/gris) y poco saturado.
		float mask = smoothstep(0.70, 0.80, lum) * (1.0 - smoothstep(0.20, 0.30, hsv_orig.y));
		// Exclusión pico/patas (naranja): r domina, g medio, b bajo -> mask=0.
		if (tex.r > 0.8 && tex.g > 0.4 && tex.g < 0.75 && tex.b < 0.4) {
			mask = 0.0;
		}
		// Exclusión cresta/barba (rojo saturado): por si acaso, fuera de la máscara
		// de baja saturación ya queda fuera, pero se refuerza aquí.
		if (tex.r > 0.7 && tex.g < 0.35 && tex.b < 0.35) {
			mask = 0.0;
		}
		if (mask > 0.001) {
			// Mismo truco HSV que vehicle_paint: escala S/V del nuevo color
			// según el píxel original para conservar el sombreado.
			vec3 hsv_plume = rgb_to_hsv(plume_color.rgb);
			float s_scale = hsv_orig.y / max(REF_S, 0.01);
			float v_scale = hsv_orig.z / max(REF_V, 0.01);
			vec3 repaint_hsv = vec3(
				hsv_plume.x,
				clamp(hsv_plume.y * s_scale, 0.0, 1.0),
				clamp(hsv_plume.z * v_scale, 0.0, 1.0)
			);
			vec3 repaint = hsv_to_rgb(repaint_hsv);
			out_rgb = mix(tex.rgb, repaint, clamp(mask * plume_amount, 0.0, 1.0));
		}
	}
	COLOR = vec4(out_rgb, tex.a);
}
