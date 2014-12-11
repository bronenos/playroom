//
//  common.metal
//  PlayRoom
//
//  Created by Stan Potemkin on 11/30/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "GameMetalTypes.h"
using namespace metal;


struct ShaderValue {
	float4 position [[ position ]];
	float4 color;
	float3 normal;
	float3 light;
};


static float4 sub_corner_color(float4 pos)
{
	float4 color;
	color.r = pos.x > 0.0 ? 1.0 : 0.0;
	color.g = pos.y > 0.0 ? 1.0 : 0.0;
	color.b = pos.z > 0.0 ? 1.0 : 0.0;
	color.a = 1.0;
	return color;
}


vertex ShaderValue main_vertex(unsigned int vid [[ vertex_id ]],
							   device uniforms_t *uniforms [[ buffer(0) ]],
							   device attributes_t *attribs [[ buffer(1) ]])
{
	ShaderValue out;
	out.position = uniforms->proj_matrix * uniforms->view_matrix * attribs->matrix * attribs->vertices[vid];
	
	if (uniforms->mask_mode == false) {
		if (attribs->color.a > 0.0) {
			out.color = attribs->color;
		}
		else {
			out.color = sub_corner_color(attribs->vertices[vid]);
		}
		
		out.normal = float3(normalize(attribs->matrix * float4(attribs->normals[vid], 0.0)));
		out.light = normalize(uniforms->light_position);
	}
	
	return out;
}


fragment float4 main_fragment(ShaderValue in [[ stage_in ]],
							  device const uniforms_t *uniforms [[ buffer(0) ]],
							  device const attributes_t *attribs [[ buffer(1) ]])
{
	if (uniforms->mask_mode == false) {
		float4 color = in.color;
		color *= clamp(max(0.0, dot(in.normal, in.light)), 0.2, 1.0);
		color.a = in.color.a;
		return color;
	}
	else {
		return attribs->mask_color;
	}
};
