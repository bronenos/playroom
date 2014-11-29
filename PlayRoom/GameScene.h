//
//  GameScene.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/22/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <glm/glm.hpp>
#import <string>
#import <vector>
#import <utility>
#import <sys/time.h>
#import "GameObject.h"


@protocol GameSceneDelegate
- (GLuint)uniformLocation:(const char *)name;
- (GLuint)attributeLocation:(const char *)name;
@end


@interface GameScene : GameObject
@property(nonatomic, readonly) GLuint modelSlot;
@property(nonatomic, readonly) GLuint vertexSlot;
@property(nonatomic, readonly) GLuint normalSlot;
@property(nonatomic, readonly) GLuint colorSlot;
@property(nonatomic, readonly) GLuint lightSlot;
@property(nonatomic, readonly) GLuint maskModeSlot;
@property(nonatomic, readonly) GLuint maskColorSlot;

- (instancetype)initWithDelegate:(id<GameSceneDelegate>)delegate;

- (void)setEye:(glm::vec3)eye subject:(glm::vec3)subject;
- (void)setLight:(glm::vec3)light;

- (BOOL)needsUpdateMask;
- (void)setNeedsUpdateMask:(BOOL)needsUpdateMask;

- (glm::vec4)generateMaskColor;
- (void)renderMask;
@end