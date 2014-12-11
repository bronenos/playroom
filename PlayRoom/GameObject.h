//
//  GameObject.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <vector>


@class GameScene;


@interface GameObject : NSObject
@property(nonatomic, weak) GameScene *scene;
@property(nonatomic, assign) glm::mat4 *matrix;
@property(nonatomic, assign) glm::vec3 size;
@property(nonatomic, assign) glm::vec4 color;
@property(nonatomic, assign) glm::vec4 maskColor;
@property(nonatomic, strong) NSMutableArray *children;

- (void)moveBy:(glm::vec3)move;
- (void)rotate:(glm::vec3)angles;
- (void)rotateGlobal:(glm::vec3)angles;

+ (glm::vec3)calculateNormalVector:(const float *)triangle;

- (void)render;
- (void)renderChildren;

- (void)renderMask;
- (void)renderChildrenMask;

- (void)setMaskMode:(BOOL)maskMode;
- (GameObject *)objectWithMaskColor:(const glm::vec4)mc;

- (void)addChild:(GameObject *)child;
- (void)removeChild:(GameObject *)child;
@end
