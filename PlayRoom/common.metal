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
};


float4 sub_corner_color(vertex_t pos);
float4 sub_corner_color(vertex_t pos)
{
	float4 color;
	color.r = pos.x > 0 ? 1 : 0;
	color.g = pos.y > 0 ? 1 : 0;
	color.b = pos.z > 0 ? 1 : 0;
	color.a = 1.0;
	return color;
}


vertex ShaderValue main_vertex(unsigned int vid [[ vertex_id ]],
							   device uniforms_t *uniforms [[ buffer(0) ]],
							   device attributes_t *attribs [[ buffer(1) ]])
{
	ShaderValue out;
	
	const float4x4 mvp_matrix = uniforms->proj_matrix * uniforms->view_matrix * attribs->matrix;
	device vertex_t *v = &attribs->vertices[vid];
	out.position = mvp_matrix * float4(v->x, v->y, v->z, 1.0);
	
	if (uniforms->mask_mode == false) {
		if (attribs->color.a > 0) {
			out.color = attribs->color;
		}
		else {
			out.color = sub_corner_color(*v);
		}
	}
	else {
		out.color = uniforms->mask_color;
	}
	
	out.normal = float3(mvp_matrix * float4(attribs->normal, 0));
	
	return out;
}


fragment float4 main_fragment(ShaderValue in [[ stage_in ]],
							  device const uniforms_t *uniforms [[ buffer(0) ]],
							  device const attributes_t *attribs [[ buffer(1) ]])
{
	if (uniforms->mask_mode == false) {
		const float4x4 vp_matrix = uniforms->proj_matrix * uniforms->view_matrix;
		const float3 in_position = float3(in.position);
		const float3 light_position = float3(vp_matrix * float4(uniforms->light_position, 0));
		
		const float dist = distance(light_position, in_position);
		const float3 light_vector = normalize(light_position - in_position);
		
		float diffuse = max(dot(attribs->normal, light_vector), 0.1);
		diffuse = diffuse * (1.0 / (1.0 + (0.2 * dist * dist))) + 0.2;
		
		return in.color * diffuse;
	}
	else {
		return in.color;
	}
};
