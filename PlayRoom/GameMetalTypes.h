//
//  GameMetalTypes.h
//  PlayRoom
//
//  Created by Stan Potemkin on 11/30/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//


#ifndef PlayRoom_GameMetalTypes_h
#define PlayRoom_GameMetalTypes_h

#import <simd/simd.h>


typedef struct {
	simd::float4x4 proj_matrix;
	simd::float4x4 view_matrix;
	simd::float3 light_position;
	bool mask_mode;
} uniforms_t;


typedef struct {
	simd::float4x4 matrix;
	simd::float3x3 normal_matrix;
	simd::float4 vertices[0x50];
	simd::float3 normals[0x50];
	simd::float4 color;
	simd::float4 mask_color;
} attributes_t;

#endif
