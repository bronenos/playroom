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
		// top front
		0,			_size.y,	0,
		-halfX,		0,			halfZ,
		halfX,		0,			halfZ,
		
		// top right
		0,			_size.y,	0,
		halfX,		0,			halfZ,
		halfX,		0,			-halfZ,
		
		// top rare
		0,			_size.y,	0,
		halfX,		0,			-halfZ,
		-halfX,		0,			-halfZ,
		
		// top left
		0,			_size.y,	0,
		-halfX,		0,			-halfZ,
		-halfX,		0,			halfZ,
		
		// bottom front
		halfX,		0,			halfZ,
		-halfX,		0,			halfZ,
		-halfX,		0,			-halfZ,
		
		// top front
		-halfX,		0,			-halfZ,
		halfX,		0,			-halfZ,
		halfX,		0,			halfZ,
	};
	
	const size_t v_size = sizeof(v);
	const size_t v_top_count = 4;
	const size_t v_bottom_count = 2;
	
	glBufferData(GL_ARRAY_BUFFER, v_size, v, GL_STATIC_DRAW);
	glVertexAttribPointer(_scene->vertexSlot(), 3, GL_FLOAT, GL_FALSE, 0, NULL);
	
	size_t i = 0;
	size_t cnt = v_top_count;
	for (; i<cnt; i++) {
		const glm::vec3 n = GameObject::calculateNormalVector(v + i * 9);
		glUniform3fv(_scene->normalSlot(), 1, &n[0]);
		
		glDrawArrays(GL_TRIANGLES, i * 3, 3);
	}
	
	cnt += v_bottom_count;
	for (; i<cnt; i++) {
		const glm::vec3 n = GameObject::calculateNormalVector(v + i * 9);
		glUniform3fv(_scene->normalSlot(), 1, &n[0]);
		
		glDrawArrays(GL_TRIANGLES, i * 3, 3);
	}
}
