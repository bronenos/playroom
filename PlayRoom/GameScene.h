//
//  GameScene.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/22/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <string>
#import <vector>
#import <utility>
#import <sys/time.h>
#import "GameObject.h"


@interface GameScene : GameObject
- (void)setEye:(glm::vec3)eye lookAt:(glm::vec3)lookAt;
- (void)setLight:(glm::vec3)light;

- (BOOL)needsUpdateMask;
- (void)setNeedsUpdateMask:(BOOL)needsUpdateMask;

- (glm::vec4)generateMaskColor;
- (void)renderMask;
@end