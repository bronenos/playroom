//
//  GameController.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include <assert.h>
#include "GameController.h"


GameController::GameController(GameControllerDelegate *delegate)
: _delegate(delegate)
{
}


GameController::~GameController()
{
	if (_mainFrameBuffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, 0);
		
		glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
		
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glDeleteFramebuffers(1, &_mainFrameBuffer);
	}
	
	if (_colorRenderBuffer) {
		glDeleteRenderbuffers(1, &_colorRenderBuffer);
	}
	
	if (_depthRenderBuffer) {
		glDeleteRenderbuffers(1, &_depthRenderBuffer);
	}
	
	if (_vertexBuffer) {
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glDeleteBuffers(1, &_vertexBuffer);
	}
	
	if (_shaderProgram) {
		glUseProgram(0);
		glDeleteProgram(_shaderProgram);
	}
}


void GameController::initialize()
{
	this->setupBuffers();
	this->loadShaders();
	this->reconfigure();
	
	_scene = std::make_shared<GameScene>(this);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
}


void GameController::setupBuffers()
{
	GLint w = 0, h = 0;
	
	glGenFramebuffers(1, &_mainFrameBuffer);
	if (_mainFrameBuffer) {
		glBindFramebuffer(GL_FRAMEBUFFER, _mainFrameBuffer);
	}
	
	glGenRenderbuffers(1, &_colorRenderBuffer);
	if (_colorRenderBuffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		_delegate->assignBuffer(GL_RENDERBUFFER);
		
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
	}
	
	glGenRenderbuffers(1, &_depthRenderBuffer);
	if (_depthRenderBuffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, w, h);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
		glEnable(GL_DEPTH_TEST);
	}
	
	glGenBuffers(1, &_vertexBuffer);
	if (_vertexBuffer) {
		glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	}
}


void GameController::loadShaders()
{
	GLuint vertexShader = this->loadShaderWithType(GLShader::Vertex);
	GLuint fragmentShader = this->loadShaderWithType(GLShader::Fragment);
	
	_shaderProgram = glCreateProgram();
	glAttachShader(_shaderProgram, vertexShader);
	glAttachShader(_shaderProgram, fragmentShader);
	glLinkProgram(_shaderProgram);
	
	GLint ok;
	glGetProgramiv(_shaderProgram, GL_LINK_STATUS, &ok);
	if (ok == GL_FALSE) {
		GLchar log[256];
		glGetProgramInfoLog(_shaderProgram, sizeof(log), 0, log);
		
		std::cout << log;
		glDeleteProgram(_shaderProgram);
		
		return;
	}
	
	glUseProgram(_shaderProgram);
}


GLuint GameController::loadShaderWithType(GLShader shaderType)
{
	std::string shaderSource;
	GLuint shader;
	
	shaderSource = _delegate->shaderSource(shaderType);
	if (shaderSource.size() > 0) {
		if (shaderType == GLShader::Vertex) {
			shader = glCreateShader(GL_VERTEX_SHADER);
		}
		else {
			shader = glCreateShader(GL_FRAGMENT_SHADER);
		}
		
		const GLchar *src = shaderSource.c_str();
		const GLint srclen = (GLint) shaderSource.size();
		glShaderSource(shader, 1, &src, &srclen);
		
		glCompileShader(shader);
		
		GLint ok;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
		if (ok == GL_FALSE) {
			GLchar log[256];
			glGetShaderInfoLog(shader, sizeof(log), 0, log);
			
			std::cout << log;
			glDeleteShader(shader);
			
			return 0;
		}
	}
	
	return shader;
}


void GameController::reconfigure()
{
	_renderSize = _delegate->renderSize();
	glViewport(0, 0, _renderSize.first, _renderSize.second);
	
	const int w = _renderSize.first;
	const int h = _renderSize.second;
	_maskData.resize(w * h * 4);
}


void GameController::render()
{
	glBindFramebuffer(GL_FRAMEBUFFER, _mainFrameBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
	
	glClearColor(0.5, 0.5, 0.5, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	_scene->renderChildren();
	_delegate->presentBuffer(GL_RENDERBUFFER);
	
	if (_scene->needsUpdateMask()) {
		_scene->setNeedsUpdateMask(false);
		
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
		
		glClearColor(0, 0, 0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		_scene->renderMask();
		
		GLint w, h;
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
		glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, &_maskData[0]);
	}
}


std::shared_ptr<GameObject> GameController::objectAtPoint(GamePoint pt)
{
	GLint w, h;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
	
	const GLint offset = (pt.y * w + pt.x) * 4;
	GLubyte *touchMask = &_maskData[offset];
	
	static GLubyte noneMask[] { 0, 0, 0, 0xFF };
	static const size_t maskSize = sizeof(noneMask);
	
	if (memcmp(touchMask, noneMask, maskSize) == 0) {
		return nullptr;
	}
	else {
		glm::vec4 mc;
		mc.r = (float) touchMask[0] / 255.0;
		mc.g = (float) touchMask[1] / 255.0;
		mc.b = (float) touchMask[2] / 255.0;
		
		return _scene->objectWithMaskColor(mc);
	}
}


GLuint GameController::uniformLocation(const char *name) const
{
	return glGetUniformLocation(_shaderProgram, name);
}


GLuint GameController::attributeLocation(const char *name) const
{
	return glGetAttribLocation(_shaderProgram, name);
}
