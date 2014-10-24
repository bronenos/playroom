//
//  GameScene.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/22/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include <glm/gtc/matrix_transform.hpp>
#include "GameScene.h"


GameScene::GameScene(GameSceneDelegate *delegate)
: _delegate(delegate)
{
	_vpSlot = _delegate->uniformLocation("u_vp");
	_modelSlot = _delegate->uniformLocation("u_m");
	_positionSlot = _delegate->uniformLocation("u_position");
	_vertexSlot = _delegate->attributeLocation("a_vertex");
	_colorSlot = _delegate->uniformLocation("u_color");
	_maskModeSlot = _delegate->uniformLocation("u_maskMode");
	_maskColorSlot = _delegate->uniformLocation("u_maskColor");
	
	glEnableVertexAttribArray(_vertexSlot);
	glEnableVertexAttribArray(_colorSlot);
}


void GameScene::look(glm::vec3 eye, glm::vec3 subject)
{
	_eyePosition = eye;
	_subjectPosition = subject;
	
	auto rs = _delegate->renderSize();
	glm::mat4 pMatrix = glm::perspective<float>(45, rs.second / rs.first, 0.1, 1000);
	glm::mat4 vMatrix = glm::lookAt(_eyePosition, _subjectPosition, glm::vec3(0, 1, 0));
	
	glm::mat4 m = pMatrix * vMatrix;
	glUniformMatrix4fv(_vpSlot, 1, GL_FALSE, &m[0][0]);
	
	this->setNeedsUpdateMask(true);
}


void GameScene::render()
{
	std::for_each(_objects.begin(), _objects.end(), [](std::shared_ptr<GameObject> object){
		object->render();
	});
}


void GameScene::renderMask()
{
	float r{0}, g{0}, b{0};
	std::for_each(_objects.begin(), _objects.end(), [&](std::shared_ptr<GameObject> object){
		b += (1.0 / 255.0);
		if (b > 1.0) { b = 0; g += (1.0 / 255.0); }
		if (g > 1.0) { g = 0; r += (1.0 / 255.0); }
		object->setMaskColor(glm::vec4(r, g, b, 1));
		
		object->setMaskMode(true);
		object->render();
		object->setMaskMode(false);
	});
}
