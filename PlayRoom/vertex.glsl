precision mediump float;
precision highp int;

uniform mat4 u_projMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform mat3 u_normalMatrix;
uniform vec3 u_normal;
uniform vec4 u_color;
uniform vec3 u_light;
uniform int u_maskMode;

attribute vec4 a_vertex;

varying vec4 v_color;
varying vec3 v_normal;
varying vec3 v_light;

vec4 sub_corner_color(vec4 pos)
{
	vec4 color;
	color.r = pos.x > 0.0 ? 1.0 : 0.0;
	color.g = pos.y > 0.0 ? 1.0 : 0.0;
	color.b = pos.z > 0.0 ? 1.0 : 0.0;
	color.a = 1.0;
	return color;
}

void main()
{
	gl_Position = u_projMatrix * u_viewMatrix * u_modelMatrix * a_vertex;
	
	if (u_maskMode == 0) {
		if (u_color.a > 0.0) {
			v_color = u_color;
		}
		else {
			v_color = sub_corner_color(a_vertex);
		}
		
		v_normal = vec3(normalize(u_modelMatrix * vec4(u_normal, 0.0)));
		v_light = normalize(u_light);
	}
}
