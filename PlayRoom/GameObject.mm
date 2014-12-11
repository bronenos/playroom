//
//  GameObject.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameObject.h"
#import "GameScene.h"
#import "GameController.h"


@interface GameObject()
@property(nonatomic, assign) glm::mat4 m;
@property(nonatomic, assign) glm::mat4 pm;
@property(nonatomic, assign) glm::mat4 rm;
@end


@implementation GameObject
- (instancetype)init
{
	if ((self = [super init])) {
		self.children = [NSMutableArray new];
		
		self.m = glm::mat4(1.0);
		self.pm = self.m;
		
		self.size = glm::vec3(1, 1, 1);
		self.color = glm::vec4(0, 0, 0, 1.0);
		self.maskColor = glm::vec4(1.0, 0, 0, 1.0);
		
		[self setMaskMode:NO];
	}
	
	return self;
}


- (glm::mat4 *)matrix
{
	return &_m;
}


- (void)moveBy:(glm::vec3)move
{
	_m = glm::translate(_m, move);
}


- (void)rotate:(glm::vec3)angles
{
	if (angles.x != 0) {
		_m = glm::rotate(_m, angles.x, glm::vec3(1, 0, 0));
	}
	
	if (angles.y != 0) {
		_m = glm::rotate(_m, angles.y, glm::vec3(0, 1, 0));
	}
	
	if (angles.z != 0) {
		_m = glm::rotate(_m, angles.z, glm::vec3(0, 0, 1));
	}
	
	[self.scene setNeedsUpdateMask:YES];
}


- (void)rotateGlobal:(glm::vec3)angles
{
	if (angles.x != 0) {
		const glm::vec4 axis = glm::inverse(_m) * glm::vec4(1, 0, 0, 0);
		_m = glm::rotate(_m, angles.x, glm::vec3(axis));
	}
	
	if (angles.y != 0) {
		const glm::vec4 axis = glm::inverse(_m) * glm::vec4(0, 1, 0, 0);
		_m = glm::rotate(_m, angles.y, glm::vec3(axis));
	}
	
	if (angles.z != 0) {
		const glm::vec4 axis = glm::inverse(_m) * glm::vec4(0, 0, 1, 0);
		_m = glm::rotate(_m, angles.z, glm::vec3(axis));
	}
	
	[self.scene setNeedsUpdateMask:YES];
}


+ (glm::vec3)calculateNormalVector:(const float *)triangle
{
	const int x = 0;
	const int y = 1;
	const int z = 2;
	
	static float u[3];
	u[x] = triangle[3 + x] - triangle[0 + x];
	u[y] = triangle[3 + y] - triangle[0 + y];
	u[z] = triangle[3 + z] - triangle[0 + z];
	
	static float v[3];
	v[x] = triangle[6 + x] - triangle[0 + x];
	v[y] = triangle[6 + y] - triangle[0 + y];
	v[z] = triangle[6 + z] - triangle[0 + z];
	
	static float n[3];
	n[x] = u[y] * v[z] - u[z] * v[y];
	n[y] = u[z] * v[x] - u[x] * v[z];
	n[z] = u[x] * v[y] - u[y] * v[x];
	
	glm::vec3 normal(n[x], n[y], n[z]);
	glm::vec3 nor = glm::normalize(normal);
	return nor;
}


- (void)render
{
	_rm = _pm * _m;
	[[GameController sharedInstance] setModelMatrix:_rm];
	[[GameController sharedInstance] setColor:_color];
	[[GameController sharedInstance] setMaskColor:_maskColor];
}


- (void)renderChildren
{
	for (GameObject *child in self.children) {
		child.pm = _rm;
		[child render];
		[child renderChildren];
	}
}


- (void)renderMask
{
	[self setMaskMode:YES];
	
	[self render];
	[self renderChildrenMask];
	
	[self setMaskMode:NO];
}


- (void)renderChildrenMask
{
	for (GameObject *child in self.children) {
		child.pm = _rm;
		[child renderMask];
		[child renderChildrenMask];
	}
}


- (void)setMaskMode:(BOOL)maskMode
{
	if (maskMode) {
		_maskColor = [self.scene generateMaskColor];
	}
	else {
		_maskColor[3] = 0;
	}
}


- (GameObject *)objectWithMaskColor:(const glm::vec4)mc
{
	for (GameObject *child in _children) {
		if (child.maskColor == mc) {
			return child;
		}
		
		GameObject *subChild = [child objectWithMaskColor:mc];
		if (subChild) {
			return subChild;
		}
	}
	
	return nil;
}


- (void)addChild:(GameObject *)child
{
	[_children addObject:child];
	child.scene = self.scene;
}


- (void)removeChild:(GameObject *)child
{
	[_children removeObject:child];
	child.scene = self.scene;
}
@end
