shader_type canvas_item;
// World-fixed reference grid. `world_offset` maps screen pixels to world space
// (camera position minus half the viewport), so the grid scrolls with the camera.

uniform vec2 world_offset = vec2(0.0);
uniform float grid_spacing = 128.0;
uniform vec4 grid_color : source_color = vec4(1.0, 1.0, 1.0, 0.06);
uniform float line_width = 1.0;

void fragment() {
	vec2 world = FRAGCOORD.xy + world_offset;
	vec2 m = mod(world, grid_spacing);
	vec2 d = min(m, grid_spacing - m);
	float line = min(d.x, d.y);
	float a = 1.0 - smoothstep(0.0, line_width, line);
	COLOR = vec4(grid_color.rgb, grid_color.a * a);
}
