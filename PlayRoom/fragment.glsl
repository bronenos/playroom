precision mediump float;
precision highp int;

uniform int u_maskMode;
uniform vec4 u_maskColor;

varying vec4 v_color;


void main()
{
	if (u_maskMode == 0) {
		gl_FragColor = v_color;
	}
	else {
		gl_FragColor = u_maskColor;
	}
}
