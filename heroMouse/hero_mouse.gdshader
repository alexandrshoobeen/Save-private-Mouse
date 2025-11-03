shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0,0.0,0.0,1.0);
uniform float alpha : hint_range(0.0,1.0) = 1.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float t = smoothstep(0.2,0.5,dist);
    vec4 col = mix(vec4(0.0), vignette_color, t);
    COLOR = vec4(col.rgb, col.a * alpha);
}

void vertex() {
	// Called for every vertex the material is visible on.
}


//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
