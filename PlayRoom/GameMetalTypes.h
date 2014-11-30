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
	simd::float4 mask_color;
} uniforms_t;


typedef struct {
	float x, y, z;
} vertex_t;


typedef struct {
	simd::float4x4 matrix;
	vertex_t vertices[0x50];
	simd::float3 normal;
	simd::float4 color;
} attributes_t;

#endif
