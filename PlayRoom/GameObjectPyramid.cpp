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
	
	const GLfloat halfX = _size.x * 0.5;
	const GLfloat halfZ = _size.z * 0.5;
	
	GLfloat v[] {
		0,			_size.y,	0,
		-halfX,		0,			halfZ,
		halfX,		0,			halfZ,
		halfX,		0,			-halfZ,
		-halfX,		0,			-halfZ,
		-halfX,		0,			halfZ,	// back to the [1]
	};
	
	const size_t v_size = sizeof(v);
	const size_t v_count = v_size / sizeof(*v) / 3;
	
	glBufferData(GL_ARRAY_BUFFER, v_size, v, GL_STATIC_DRAW);
	glVertexAttribPointer(_scene->vertexSlot(), 3, GL_FLOAT, GL_FALSE, 0, NULL);
	
	glCullFace(GL_FRONT);
	glDrawArrays(GL_TRIANGLE_FAN, 0, v_count);
	glCullFace(GL_BACK);
	glDrawArrays(GL_TRIANGLE_FAN, 1, v_count - 1);
	glCullFace(GL_FRONT);
}
