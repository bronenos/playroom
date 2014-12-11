//
//  GameController.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <glm/glm.hpp>
#import "GameScene.h"


extern NSString * const kGameEngineChoice;


@class GameObject;


@protocol GameControllerAPI
+ (BOOL)isSupported;
+ (NSString *)shaderFilename;

- (void)configureWithView:(UIView *)view;
- (void)reconfigure;

- (void)render;

- (void)setEye:(glm::vec3)eye lookAt:(glm::vec3)lookAt;
- (void)setLight:(glm::vec3)light;

- (void)setModelMatrix:(glm::mat4x4)matrix;
- (void)setColor:(glm::vec4)color;

- (void)setVertexData:(const float *)data size:(size_t)size;
- (void)setNormal:(glm::vec3)normal forVertexIndex:(NSUInteger)index;

- (void)setMaskMode:(BOOL)maskMode;
- (void)setMaskColor:(glm::vec4)maskColor;

- (void)beginDrawing;
- (void)drawTriangles:(size_t)number withOffset:(size_t)offset;
- (void)endDrawing;

- (GameObject *)objectAtPoint:(CGPoint)point;
@end


@interface GameController : NSObject
@property(nonatomic, weak) CALayer *layer;
@property(nonatomic, strong) GameScene *scene;

+ (GameController<GameControllerAPI> *)sharedInstance;

+ (Class)controllerClassWithOpenGL;
+ (Class)controllerClassWithMetal;
@end
