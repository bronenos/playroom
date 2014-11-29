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
	[super render];
	
	const glm::vec3 size = self.size;
	const float halfX = size.x * 0.5;
	const float halfY = size.y * 0.5;
	const float halfZ = size.z * 0.5;
	
	float v[] {
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
		
		// bottom
		halfX,		-halfY,		halfZ,
		-halfX,		-halfY,		halfZ,
		-halfX,		-halfY,		-halfZ,
		-halfX,		-halfY,		-halfZ,
		halfX,		-halfY,		-halfZ,
		halfX,		-halfY,		halfZ,
	};
	
	const size_t v_size = sizeof(v);
	const size_t v_top_count = 4;
	const size_t v_bottom_count = 2;
	[[GameController sharedInstance] setVertexData:v size:v_size];
	
	size_t i = 0;
	size_t cnt = v_top_count;
	for (; i<cnt; i++) {
		const glm::vec3 n = [GameObject calculateNormalVector:(v + i * 9)];
		[[GameController sharedInstance] setNormal:n];
		[[GameController sharedInstance] drawTriangles:3 withOffset:i * 3];
	}
	
	cnt += v_bottom_count;
	for (; i<cnt; i++) {
		const glm::vec3 n = [GameObject calculateNormalVector:(v + i * 9)];
		[[GameController sharedInstance] setNormal:n];
		[[GameController sharedInstance] drawTriangles:3 withOffset:i * 3];
	}
}
@end
