//
//  GameObject.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#ifndef __PlayRoom__GameObject__
#define __PlayRoom__GameObject__

#include <stdio.h>
#include <OpenGLES/ES2/gl.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>


class GameScene;


class GameObject {
public:
	GameObject(GameScene *scene);
	
	void rotate(glm::vec3 angles);
	virtual void render();
	
	bool maskMode() { return _maskMode; }
	void setMaskMode(const bool &a);
	
	glm::mat4& m() { return _m; }
	glm::vec3 position() { return _position; }
	glm::vec3 size() { return _size; }
	glm::vec4 color() { return _color; }
	glm::vec4 maskColor() { return _maskColor; }
	
	void setPosition(const glm::vec3 &a) { _position = a; }
	void setSize(const glm::vec3 &a) { _size = a; }
	void setColor(const glm::vec4 &a) { _color = a; }
	void setMaskColor(const glm::vec4 &a) { _maskColor = a; }
	
	static glm::vec3 calculateNormalVector(GLfloat *v);
	
protected:
	GameScene *_scene;
	
	int _maskMode = 0;
	glm::vec4 _maskColor = glm::vec4(1.0, 0, 0, 1.0);
	
	glm::mat4 _m = glm::mat4(1.0);
	glm::vec3 _position = glm::vec3(0, 0, 0);
	glm::vec3 _size = glm::vec3(1, 1, 1);
	glm::vec4 _color = glm::vec4(0, 0, 0, 1.0);
};

#endif /* defined(__PlayRoom__GameObject__) */
