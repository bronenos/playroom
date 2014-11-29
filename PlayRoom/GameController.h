//
//  GameController.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>
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


@protocol GameControllerDelegate
- (std::pair<float, float>)renderSize;
- (std::string)shaderSource:(GLShader)shaderType;
- (void)assignBuffer:(long)bufferID;
- (void)presentBuffer:(long)bufferID;
@end


@interface GameController : NSObject <GameSceneDelegate>
@property(nonatomic, readonly) GameScene *scene;

- (instancetype)initWithLayer:(CALayer *)layer;

- (void)initialize;
- (void)reconfigure;
- (void)render;

- (GameObject *)objectAtPoint:(GamePoint)point;
@end
