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
: GameObject(this)
, _delegate(delegate)
{
	_vpSlot = _delegate->uniformLocation("u_vp");
	_modelSlot = _delegate->uniformLocation("u_m");
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
	GLint w, h;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
	
	const glm::mat4 pMatrix = glm::perspective<float>(45, (float(w) / float(h)), 0.1, 1000);
	const glm::mat4 vMatrix = glm::lookAt(eye, subject, glm::vec3(0, 1, 0));
	
	const glm::mat4 vpMatrix = pMatrix * vMatrix;
	glUniformMatrix4fv(_vpSlot, 1, GL_FALSE, &vpMatrix[0][0]);
	
	this->setNeedsUpdateMask(true);
}


void GameScene::light(glm::vec3 light)
{
	glUniform3fv(this->lightSlot(), 1, &light[0]);
}


glm::vec4 GameScene::generateMaskColor()
{
	const float step = 1.0 / 255.0;
	
	_maskColor.b += step;
	
	if (_maskColor.b > 1.0) {
		_maskColor.b = 0;
		_maskColor.g += step;
	}
	
	if (_maskColor.g > 1.0) {
		_maskColor.g = 0;
		_maskColor.r += step;
	}
	
	return _maskColor;
}


void GameScene::renderMask()
{
	_maskColor = glm::vec4(0, 0, 0, 1);
	
	for (auto it : _children) {
		it->renderMask();
	}
}
