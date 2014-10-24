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
