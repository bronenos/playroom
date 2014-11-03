uniform mat4 u_vp;
uniform mat4 u_m;
uniform vec3 u_normal;
uniform vec4 u_color;
uniform vec4 u_light;
uniform int u_maskMode;

attribute vec4 a_vertex;

varying vec3 v_vertex;
varying vec4 v_color;
varying vec3 v_normal;


void main()
{
	if (u_maskMode == 0) {
		if (u_color.a > 0.0) {
			v_color = u_color;
		}
		else {
			v_color = vec4(a_vertex.x > 0.0 ? 1 : 0, a_vertex.y > 0.0 ? 1 : 0, a_vertex.z > 0.0 ? 1 : 0, 1.0);
		}
	}
	
	mat4 u_mvp = u_vp * u_m;
	gl_Position = u_mvp * a_vertex;
	
	v_vertex = vec3(gl_Position);
	v_normal = vec3(u_mvp * vec4(u_normal, 0.0));
}
