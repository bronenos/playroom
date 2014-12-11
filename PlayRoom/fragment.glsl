precision mediump float;
precision highp int;

uniform mat4 u_projMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform mat3 u_normalMatrix;
uniform vec3 u_lightPosition;
uniform int u_maskMode;
uniform vec4 u_maskColor;

varying vec4 v_color;
varying vec3 v_normal;
varying vec3 v_light;

void main()
{
	if (u_maskMode == 0) {
		highp vec4 color = v_color;
		color *= clamp(max(0.0, dot(v_normal, v_light)), 0.2, 1.0);
		color.a = v_color.a;
		gl_FragColor = color;
	}
	else {
		gl_FragColor = u_maskColor;
	}
}
