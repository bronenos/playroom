//
//  GameObject.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include "GameObject.h"
#include "GameScene.h"


GameObject::GameObject(const GameScene *scene)
: _scene(scene)
{
	this->setMaskMode(false);
}


void GameObject::setMaskMode(const bool &a)
{
	const GLint mode = a ? 1 : 0;
	
	if (a) {
		_maskColor = _scene->generateMaskColor();
	}
	else {
		_maskColor[3] = 0;
	}
	
	glUniform1iv(_scene->maskModeSlot(), 1, &mode);
	glUniform4fv(_scene->maskColorSlot(), 1, &_maskColor[0]);
}


void GameObject::moveBy(const glm::vec3 &move)
{
	_m = glm::translate(_m, move);
}


void GameObject::rotate(const glm::vec3 &angles)
{
	if (angles.x != 0) {
		_m = glm::rotate(_m, angles.x, glm::vec3(1, 0, 0));
	}
	
	if (angles.y != 0) {
		_m = glm::rotate(_m, angles.y, glm::vec3(0, 1, 0));
	}
	
	if (angles.z != 0) {
		_m = glm::rotate(_m, angles.z, glm::vec3(0, 0, 1));
	}
}


void GameObject::rotateGlobal(const glm::vec3 &angles)
{
	if (angles.x != 0) {
		const glm::vec4 axis = glm::inverse(_m) * glm::vec4(1, 0, 0, 0);
		_m = glm::rotate(_m, angles.x, glm::vec3(axis));
	}
	
	if (angles.y != 0) {
		const glm::vec4 axis = glm::inverse(_m) * glm::vec4(0, 1, 0, 0);
		_m = glm::rotate(_m, angles.y, glm::vec3(axis));
	}
	
	if (angles.z != 0) {
		const glm::vec4 axis = glm::inverse(_m) * glm::vec4(0, 0, 1, 0);
		_m = glm::rotate(_m, angles.z, glm::vec3(axis));
	}
}


glm::vec3 GameObject::calculateNormalVector(const GLfloat *v)
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


void GameObject::render()
{
	_rm = _m * _pm;
	glUniformMatrix4fv(_scene->modelSlot(), 1, GL_FALSE, &_rm[0][0]);
	glUniform4fv(_scene->colorSlot(), 1, &_color[0]);
}


void GameObject::renderChildren()
{
	for (auto it : _children) {
		it->_pm = _rm;
		it->render();
		it->renderChildren();
	}
}


void GameObject::renderMask()
{
	this->setMaskMode(true);
	
	this->render();
	this->renderChildrenMask();
	
	this->setMaskMode(false);
}


void GameObject::renderChildrenMask()
{
	for (auto it : _children) {
		it->_pm = _rm;
		it->renderMask();
		it->renderChildrenMask();
	}
}


std::shared_ptr<GameObject> GameObject::objectWithMaskColor(const glm::vec4 &mc)
{
	for (auto child : this->_children) {
		if (child->maskColor() == mc) {
			return child;
		}
		
		const auto sub = child->objectWithMaskColor(mc);
		if (sub) {
			return sub;
		}
	}
	
	return nullptr;
}
