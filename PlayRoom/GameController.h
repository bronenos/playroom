//
//  GameController.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#ifndef __PlayRoom__GameController__
#define __PlayRoom__GameController__

#include <iostream>
#include <OpenGLES/ES2/gl.h>
#include <glm/glm.hpp>
#include "GameScene.h"


enum class GLShader {
	Vertex, Fragment
};


struct GamePoint {
	int x, y;
	
	GamePoint(double x_, double y_)
	: x(x_)
	, y(y_) {
	}
};


class GameControllerDelegate {
public:
	virtual std::pair<float, float> renderSize() = 0;
	virtual std::string shaderSource(GLShader shaderType) = 0;
	virtual void assignBuffer(long bufferID) = 0;
	virtual void presentBuffer(long bufferID) = 0;
};


class GameController : public GameSceneDelegate {
public:
	GameController(GameControllerDelegate *delegate);
	
	void initialize();
	void reconfigure();
	void render();
	
	std::shared_ptr<GameScene> scene() {
		return _scene;
	}
	
	std::shared_ptr<GameObject> objectAtPoint(GamePoint pt);
	
private:
	void loadShaders();
	GLuint loadShaderWithType(GLShader shaderType);
	
public:
	virtual GLuint uniformLocation(const char *name);
	virtual GLuint attributeLocation(const char *name);
	
private:
	GameControllerDelegate *_delegate;
	
	std::pair<float, float> _renderSize;
	std::shared_ptr<GameScene> _scene;
	
	GLuint _mainFrameBuffer;
	GLuint _colorRenderBuffer;
	GLuint _depthRenderBuffer;
	std::vector<GLubyte> _maskData;
	
	GLuint _shaderProgram;
	GLuint _vertexBuffer;
};

#endif /* defined(__PlayRoom__GameController__) */
