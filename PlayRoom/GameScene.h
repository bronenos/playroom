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
	virtual std::pair<GLfloat, GLfloat> renderSize() = 0;
	virtual GLuint uniformLocation(const char *name) = 0;
	virtual GLuint attributeLocation(const char *name) = 0;
};


class GameScene {
public:
	GameScene(GameSceneDelegate *delegate);
	
	void setRenderSize(std::pair<GLfloat, GLfloat> renderSize);
	void look(glm::vec3 eye, glm::vec3 subject);
	
	bool needsUpdateMask() { return _needsUpdateMask; }
	void setNeedsUpdateMask(const bool &a) { _needsUpdateMask = a; }
	
	void render();
	void renderMask();
	
	std::vector< std::shared_ptr<GameObject> >& objects() { return _objects; }
	GLuint modelSlot() { return _modelSlot; }
	GLuint positionSlot() { return _positionSlot; }
	GLuint vertexSlot() { return _vertexSlot; }
	GLuint colorSlot() { return _colorSlot; }
	GLuint maskModeSlot() { return _maskModeSlot; }
	GLuint maskColorSlot() { return _maskColorSlot; }
	
private:
	void drawPyramid();
	
private:
	GameSceneDelegate *_delegate = NULL;
	std::vector< std::shared_ptr<GameObject> > _objects;
	
	GLuint _vpSlot;
	GLuint _modelSlot;
	GLuint _positionSlot;
	GLuint _vertexSlot;
	GLuint _colorSlot;
	GLuint _maskModeSlot;
	GLuint _maskColorSlot;
	
	glm::vec3 _eyePosition;
	glm::vec3 _subjectPosition;
	bool _needsUpdateMask = false;
};

#endif /* defined(__PlayRoom__GameScene__) */
