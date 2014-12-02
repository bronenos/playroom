precision mediump float;
precision highp int;

uniform mat4 u_vp;
uniform vec3 u_light;
uniform int u_maskMode;
uniform vec4 u_maskColor;

varying vec3 v_vertex;
varying vec4 v_color;
varying vec3 v_normal;


vec4 diffused_color(vec4 color, float diffuse)
{
	vec4 ret = color * diffuse;
	ret.a = color.a;
	return ret;
}


void main()
{
	if (u_maskMode == 0) {
		vec3 light_position = u_light; // vec3(/*u_vp*/mat4(1.0) * vec4(u_light, 0.0));
		float dist = distance(light_position, v_vertex);
		vec3 light_vector = normalize(light_position - v_vertex);
		
		float diffuse = max(dot(v_normal, light_vector), 0.1);
		diffuse = diffuse * (1.0 / (1.0 + (0.2 * dist * dist))) + 0.2;
		
		gl_FragColor = diffused_color(v_color, diffuse);
	}
	else {
		gl_FragColor = u_maskColor;
	}
}
