//
//  GameScene.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/22/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include <glm/gtc/matrix_transform.hpp>
#include "GameScene.h"


@interface GameScene()
@property(nonatomic, weak) id<GameSceneDelegate> delegate;
@property(nonatomic, assign) timeval needsUpdateMaskTime;

@property(nonatomic, assign) GLuint vpSlot;
@property(nonatomic, readwrite, assign) GLuint modelSlot;
@property(nonatomic, readwrite, assign) GLuint vertexSlot;
@property(nonatomic, readwrite, assign) GLuint normalSlot;
@property(nonatomic, readwrite, assign) GLuint colorSlot;
@property(nonatomic, readwrite, assign) GLuint lightSlot;
@property(nonatomic, readwrite, assign) GLuint maskModeSlot;
@property(nonatomic, readwrite, assign) GLuint maskColorSlot;
@end


@implementation GameScene
- (instancetype)initWithDelegate:(id<GameSceneDelegate>)delegate
{
	if ((self = [super init])) {
		self.delegate = delegate;
		self.scene = self;
		
		self.vpSlot = [self.delegate uniformLocation:"u_vp"];
		self.modelSlot = [self.delegate uniformLocation:"u_m"];
		self.vertexSlot = [self.delegate attributeLocation:"a_vertex"];
		self.normalSlot = [self.delegate uniformLocation:"u_normal"];
		self.colorSlot = [self.delegate uniformLocation:"u_color"];
		self.lightSlot = [self.delegate uniformLocation:"u_light"];
		self.maskModeSlot = [self.delegate uniformLocation:"u_maskMode"];
		self.maskColorSlot = [self.delegate uniformLocation:"u_maskColor"];
		
		glEnableVertexAttribArray(self.vertexSlot);
	}
	
	return self;
}


- (void)setEye:(glm::vec3)eye subject:(glm::vec3)subject
{
	GLint w, h;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
	
	const glm::mat4 pMatrix = glm::perspective<float>(45, (float(w) / float(h)), 0.1, 1000);
	const glm::mat4 vMatrix = glm::lookAt(eye, subject, glm::vec3(0, 1, 0));
	
	const glm::mat4 vpMatrix = pMatrix * vMatrix;
	glUniformMatrix4fv(_vpSlot, 1, GL_FALSE, &vpMatrix[0][0]);
	
	[self setNeedsUpdateMask:YES];
}


- (void)setLight:(glm::vec3)light
{
	glUniform3fv(self.lightSlot, 1, &light[0]);
}


- (void)setNeedsUpdateMask:(BOOL)needsUpdateMask
{
	if (needsUpdateMask) {
		gettimeofday(&_needsUpdateMaskTime, NULL);
	}
	else {
		_needsUpdateMaskTime.tv_sec = 0;
	}
}


- (BOOL)needsUpdateMask
{
	if (_needsUpdateMaskTime.tv_sec > 0) {
		timeval currentTime;
		gettimeofday(&currentTime, NULL);
		
		const long sec = currentTime.tv_sec - _needsUpdateMaskTime.tv_sec;
		const long usec = currentTime.tv_usec - _needsUpdateMaskTime.tv_usec;
		const long diff = (sec * 1000 + usec / 1000.0) + 0.5;
		
		return (diff > 50);
	}
	
	return NO;
}


- (glm::vec4)generateMaskColor
{
	glm::vec4 mc = self.maskColor;
	const float step = 1.0 / 255.0;
	
	mc.b += step;
	
	if (mc.b > 1.0) {
		mc.b = 0;
		mc.g += step;
	}
	
	if (mc.g > 1.0) {
		mc.g = 0;
		mc.r += step;
	}
	
	self.maskColor = mc;
	return mc;
}


- (void)renderMask
{
	self.maskColor = glm::vec4(0, 0, 0, 1);
	
	for (GameObject *child in self.children) {
		[child renderMask];
	}
}
@end
