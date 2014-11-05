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
#include <sys/time.h>
#include "GameObject.h"


class GameSceneDelegate {
public:
	virtual GLuint uniformLocation(const char *name) const = 0;
	virtual GLuint attributeLocation(const char *name) const = 0;
};


class GameScene : public GameObject {
public:
	GameScene(GameSceneDelegate *delegate);
	
	void setRenderSize(const std::pair<GLfloat, GLfloat> renderSize);
	void look(const glm::vec3 &eye, const glm::vec3 &subject);
	void light(const glm::vec3 &light);
	
	bool needsUpdateMask();
	void setNeedsUpdateMask(const bool &a) const;
	
	glm::vec4 generateMaskColor() const;
	void renderMask();
	
	GLuint modelSlot() const { return _modelSlot; }
	GLuint vertexSlot() const { return _vertexSlot; }
	GLuint normalSlot() const { return _normalSlot; }
	GLuint colorSlot() const { return _colorSlot; }
	GLuint lightSlot() const { return _lightSlot; }
	GLuint maskModeSlot() const { return _maskModeSlot; }
	GLuint maskColorSlot() const { return _maskColorSlot; }
	
private:
	void drawPyramid();
	
private:
	GameSceneDelegate *_delegate = NULL;
	mutable timeval _needsUpdateMaskTime { 0, 0 };
	
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
