//
//  GameController.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameController.h"
#import "GameGLController.h"
#import "GameMetalController.h"


NSString * const kGameEngineChoice = @"kGameEngineChoice";


static id __sharedInstance = nil;


@implementation GameController
- (instancetype)init
{
	if ((self = [super init])) {
		__sharedInstance = self;
	}
	
	return self;
}


+ (Class)controllerClassWithOpenGL
{
	return [GameGLController class];
}


+ (Class)controllerClassWithMetal
{
#	ifndef METAL_DISABLED
	return [GameMetalController class];
#	else
	return nil;
#	endif
}


+ (GameController<GameControllerAPI> *)sharedInstance
{
	return __sharedInstance;
}
@end
