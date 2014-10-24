//
//  GameObjectPyramid.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include "GameObjectPyramid.h"
#include "GameScene.h"


void GameObjectPyramid::render()
{
	GameObject::render();
	
#	define half(x) ((x) * 0.5f)
	GLfloat v[] {
		0,					_size.y,	0,
		-half(_size.x),		0,			half(_size.z),
		half(_size.x),		0,			half(_size.z),
		half(_size.x),		0,			-half(_size.z),
		-half(_size.x),		0,			-half(_size.z),
		-half(_size.x),		0,			half(_size.z),	// back to the [1] vertice
	};
#	undef half
	
	glVertexAttribPointer(_scene->vertexSlot(), 3, GL_FLOAT, GL_FALSE, 0, v);
	glDrawArrays(GL_TRIANGLE_FAN, 0, (sizeof(v) / sizeof(*v) / 3));
}
