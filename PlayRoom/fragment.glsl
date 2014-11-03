precision mediump float;
precision highp int;

uniform vec3 u_light;
uniform int u_maskMode;
uniform vec4 u_maskColor;

varying vec3 v_vertex;
varying vec4 v_color;
varying vec3 v_normal;


void main()
{
	if (u_maskMode == 0) {
		float dist = length(u_light - v_vertex);
		vec3 light_vector = normalize(u_light - v_vertex);
		
		float diffuse = max(dot(v_normal, light_vector), 0.1);
		diffuse = diffuse * (1.0 / (1.0 + (0.2 * dist * dist))) + 0.2;
		
		gl_FragColor = v_color * diffuse;
	}
	else {
		gl_FragColor = u_maskColor;
	}
}
