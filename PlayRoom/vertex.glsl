uniform mat4 u_vp;
uniform mat4 u_m;
uniform vec3 u_position;
uniform vec4 u_color;
uniform int u_maskMode;

attribute vec4 a_vertex;

varying vec4 v_color;


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
	
	gl_Position = (u_vp * u_m * a_vertex) + vec4(u_position, 1.0);
}
