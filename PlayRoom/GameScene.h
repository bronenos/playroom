//
//  GameScene.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/22/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#ifndef __PlayRoom__GameScene__
#define __PlayRoom__GameScene__

#include <OpenGLES/ES2/gl.h>
#include <glm/glm.hpp>
#include <string>
#include <vector>
#include <utility>
#include "GameObject.h"


class GameSceneDelegate {
public:
	virtual GLuint uniformLocation(const char *name) = 0;
	virtual GLuint attributeLocation(const char *name) = 0;
};


class GameScene : public GameObject {
public:
	GameScene(GameSceneDelegate *delegate);
	
	void setRenderSize(std::pair<GLfloat, GLfloat> renderSize);
	void look(glm::vec3 eye, glm::vec3 subject);
	void light(glm::vec3 light);
	
	bool needsUpdateMask() { return _needsUpdateMask; }
	void setNeedsUpdateMask(const bool &a) { _needsUpdateMask = a; }
	
	glm::vec4 generateMaskColor();
	void renderMask();
	
	GLuint modelSlot() { return _modelSlot; }
	GLuint vertexSlot() { return _vertexSlot; }
	GLuint normalSlot() { return _normalSlot; }
	GLuint colorSlot() { return _colorSlot; }
	GLuint lightSlot() { return _lightSlot; }
	GLuint maskModeSlot() { return _maskModeSlot; }
	GLuint maskColorSlot() { return _maskColorSlot; }
	
private:
	void drawPyramid();
	
private:
	GameSceneDelegate *_delegate = NULL;
	bool _needsUpdateMask = false;
	
	GLuint _vpSlot;
	GLuint _modelSlot;
	GLuint _vertexSlot;
	GLuint _normalSlot;
	GLuint _colorSlot;
	GLuint _lightSlot;
	GLuint _maskModeSlot;
	GLuint _maskColorSlot;
};

#endif /* defined(__PlayRoom__GameScene__) */
