//
//  GameScene.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/22/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <glm/gtc/matrix_transform.hpp>
#import "GameScene.h"
#import "GameController.h"


@interface GameScene()
@property(nonatomic, assign) timeval needsUpdateMaskTime;
@end


@implementation GameScene
- (instancetype)init
{
	if ((self = [super init])) {
		self.scene = self;
	}
	
	return self;
}


- (void)setEye:(glm::vec3)eye lookAt:(glm::vec3)lookAt
{
	[[GameController sharedInstance] setEye:eye lookAt:lookAt];
	[self setNeedsUpdateMask:YES];
}


- (void)setLight:(glm::vec3)light
{
	[[GameController sharedInstance] setLight:light];
}


- (void)render
{
	// nothing should be applied
}


- (void)setMaskMode:(BOOL)maskMode
{
	[[GameController sharedInstance] setMaskMode:maskMode];
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
