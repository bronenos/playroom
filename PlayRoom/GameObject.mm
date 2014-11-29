//
//  GameObject.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameObject.h"
#import "GameScene.h"


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
		
		self.position = glm::vec3(0, 0, 0);
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


+ (glm::vec3)calculateNormalVector:(const GLfloat *)v
{
#	define x 0
#	define y 1
#	define z 2
	
	static GLfloat t1[3];
	t1[x] = v[3 + x] - v[0 + x];
	t1[y] = v[3 + y] - v[0 + y];
	t1[z] = v[3 + z] - v[0 + z];
	
	static GLfloat t2[3];
	t2[x] = v[6 + x] - v[0 + x];
	t2[y] = v[6 + y] - v[0 + y];
	t2[z] = v[6 + z] - v[0 + z];
	
	static GLfloat c[3];
	c[x] = t1[y] * t2[z] - t1[z] * t2[y];
	c[y] = t1[z] * t2[x] - t1[x] * t2[z];
	c[z] = t1[x] * t2[y] - t1[y] * t2[x];
	
	return glm::vec3(c[x], c[y], c[z]);
}


- (void)render
{
	_rm = _m * _pm;
	glUniformMatrix4fv([self.scene modelSlot], 1, GL_FALSE, &_rm[0][0]);
	glUniform4fv([self.scene colorSlot], 1, &_color[0]);
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
	const GLint mode = maskMode ? 1 : 0;
	
	if (maskMode) {
		_maskColor = [self.scene generateMaskColor];
	}
	else {
		_maskColor[3] = 0;
	}
	
	glUniform1iv([self.scene maskModeSlot], 1, &mode);
	glUniform4fv([self.scene maskColorSlot], 1, &_maskColor[0]);
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
