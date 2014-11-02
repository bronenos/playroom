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
	_normalSlot = _delegate->uniformLocation("u_normal");
	_colorSlot = _delegate->uniformLocation("u_color");
	_lightSlot = _delegate->uniformLocation("u_light");
	_maskModeSlot = _delegate->uniformLocation("u_maskMode");
	_maskColorSlot = _delegate->uniformLocation("u_maskColor");
	
	glEnableVertexAttribArray(_vertexSlot);
}


void GameScene::look(glm::vec3 eye, glm::vec3 subject)
{
	auto rs = _delegate->renderSize();
	glm::mat4 pMatrix = glm::perspective<float>(45, rs.first / rs.second, 0.1, 1000);
	glm::mat4 vMatrix = glm::lookAt(eye, subject, glm::vec3(0, 1, 0));
	
	_matrix = pMatrix * vMatrix;
	glUniformMatrix4fv(_vpSlot, 1, GL_FALSE, &_matrix[0][0]);
	
	this->setNeedsUpdateMask(true);
}


void GameScene::rotate(glm::vec3 angle)
{
	// to be implemented
	
//	if (angle[0] != 0) {
//		_matrix = glm::rotate(_matrix, angle[0], glm::vec3(1, 0, 0));
//	}
//	
//	if (angle[1] != 0) {
//		_matrix = glm::rotate(_matrix, angle[1], glm::vec3(0, 1, 0));
//	}
//	
//	if (angle[2] != 0) {
//		_matrix = glm::rotate(_matrix, angle[2], glm::vec3(0, 0, 1));
//	}
//	
//	glUniformMatrix4fv(_vpSlot, 1, GL_FALSE, &_matrix[0][0]);
}


void GameScene::light(glm::vec3 light)
{
	glUniform3fv(this->normalSlot(), 1, &light[0]);
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
