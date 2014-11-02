//
//  GameObject.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include "GameObject.h"
#include "GameScene.h"


GameObject::GameObject(GameScene *scene)
: _scene(scene)
{
	this->setMaskMode(false);
}


void GameObject::setMaskMode(const bool &a)
{
	_maskMode = a;
	
	glUniform1iv(_scene->maskModeSlot(), 1, &_maskMode);
	glUniform4fv(_scene->maskColorSlot(), 1, &_maskColor[0]);
}


void GameObject::rotate(glm::vec3 angles)
{
	if (angles[0] != 0) {
		_m = glm::rotate(_m, angles[0], glm::vec3(1, 0, 0));
	}
	
	if (angles[1] != 0) {
		_m = glm::rotate(_m, angles[1], glm::vec3(0, 1, 0));
	}
	
	if (angles[2] != 0) {
		_m = glm::rotate(_m, angles[2], glm::vec3(0, 0, 1));
	}
	
	_scene->setNeedsUpdateMask(true);
}


void GameObject::render()
{
	glUniformMatrix4fv(_scene->modelSlot(), 1, GL_FALSE, &_m[0][0]);
	glUniform3fv(_scene->positionSlot(), 1, &_position[0]);
	glUniform4fv(_scene->colorSlot(), 1, &_color[0]);
}


glm::vec3 GameObject::calculateNormalVector(GLfloat *v)
{
#	define x 0
#	define y 1
#	define z 2
	
	static GLfloat t1[3];
	t1[x] = v[3 + x] - v[0 + x];
	t1[y] = v[3 + y] - v[0 + y];
	t1[z] = v[3 + z] - v[0 + z];
	
	static GLfloat t2[3];
	t2[x] = v[6 + x] - v[0 + x];
	t2[y] = v[6 + y] - v[0 + y];
	t2[z] = v[6 + z] - v[0 + z];
	
	static GLfloat c[3];
	c[x] = t1[y] * t2[z] - t1[z] * t2[y];
	c[y] = t1[z] * t2[x] - t1[x] * t2[z];
	c[z] = t1[x] * t2[y] - t1[y] * t2[x];
	
	return glm::vec3(c[x], c[y], c[z]);
}
