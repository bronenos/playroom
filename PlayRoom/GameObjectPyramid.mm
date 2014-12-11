//
//  GameObjectPyramid.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameObjectPyramid.h"
#import "GameScene.h"
#import "GameController.h"


@implementation GameObjectPyramid
- (void)render
{
	[[GameController sharedInstance] beginDrawing];
	
	[super render];
	
	const glm::vec3 size = self.size;
	const float halfX = size.x * 0.5;
	const float halfY = size.y * 0.5;
	const float halfZ = size.z * 0.5;
	
	const float v[] {
		// top front
		0,			halfY,		0,
		-halfX,		-halfY,		halfZ,
		halfX,		-halfY,		halfZ,
		
		// top right
		0,			halfY,		0,
		halfX,		-halfY,		halfZ,
		halfX,		-halfY,		-halfZ,
		
		// top rare
		0,			halfY,		0,
		halfX,		-halfY,		-halfZ,
		-halfX,		-halfY,		-halfZ,
		
		// top left
		0,			halfY,		0,
		-halfX,		-halfY,		-halfZ,
		-halfX,		-halfY,		halfZ,
		
		// bottom first half
		halfX,		-halfY,		halfZ,
		-halfX,		-halfY,		halfZ,
		-halfX,		-halfY,		-halfZ,
		
		// bottom second half
		-halfX,		-halfY,		-halfZ,
		halfX,		-halfY,		-halfZ,
		halfX,		-halfY,		halfZ,
	};
	
	const size_t v_size = sizeof(v);
	const size_t v_count = v_size / sizeof(*v);
	[[GameController sharedInstance] setVertexData:v size:v_size];
	
	const size_t v_vcount = v_count / 3;
	const size_t v_tcount = v_vcount / 3;
	for (size_t i=0; i<v_tcount; i++) {
		const glm::vec3 normal = [GameObject calculateNormalVector:&v[i * (v_count / v_tcount)]];
		const size_t baseIndex = i * 3;
		
		[[GameController sharedInstance] setNormal:normal forVertexIndex:(baseIndex + 0)];
		[[GameController sharedInstance] setNormal:normal forVertexIndex:(baseIndex + 1)];
		[[GameController sharedInstance] setNormal:normal forVertexIndex:(baseIndex + 2)];
		[[GameController sharedInstance] drawTriangles:3 withOffset:baseIndex];
	}
	
	[[GameController sharedInstance] endDrawing];
}
@end
