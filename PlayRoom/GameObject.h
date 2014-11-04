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
#include <vector>


class GameScene;


class GameObject {
public:
	GameObject(GameScene *scene);
	
	void moveBy(const glm::vec3 &move);
	void rotate(const glm::vec3 &angles);
	void rotateGlobal(const glm::vec3 &angles);
	
	static glm::vec3 calculateNormalVector(GLfloat *v);
	
	virtual void render();
	virtual void renderChildren();
	
	virtual void renderMask();
	virtual void renderChildrenMask();
	std::shared_ptr<GameObject> objectWithMaskColor(const glm::vec4 &mc);
	
	glm::mat4& m() { return _m; }
	glm::vec3 position() { return _position; }
	glm::vec3 size() { return _size; }
	glm::vec4 color() { return _color; }
	glm::vec4 maskColor() { return _maskColor; }
	
	void setSize(const glm::vec3 &a) { _size = a; }
	void setColor(const glm::vec4 &a) { _color = a; }
	void setMaskMode(const bool &a);
	
	void addChild(std::shared_ptr<GameObject> child) {
		_children.push_back(child);
	}
	
	void removeChild(std::shared_ptr<GameObject> child) {
		auto it = std::find(_children.begin(), _children.end(), child);
		if (it < _children.end()) {
			_children.erase(it);
		}
	}
	
protected:
	GameScene *_scene;
	std::vector<std::shared_ptr<GameObject>> _children;
	
	glm::mat4 _m = glm::mat4(1.0);
	glm::mat4 _pm = glm::mat4(1.0);
	glm::mat4 _rm;
	
	glm::vec3 _position = glm::vec3(0, 0, 0);
	glm::vec3 _size = glm::vec3(1, 1, 1);
	glm::vec4 _color = glm::vec4(0, 0, 0, 1.0);
	glm::vec4 _maskColor = glm::vec4(1.0, 0, 0, 1.0);
};

#endif /* defined(__PlayRoom__GameObject__) */
