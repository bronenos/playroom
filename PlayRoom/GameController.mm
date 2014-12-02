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


static id __sharedInstance = nil;


@implementation GameController
- (instancetype)init
{
	if ((self = [super init])) {
		__sharedInstance = self;
	}
	
	return self;
}


+ (GameController<GameControllerAPI> *)supportedController
{
#	ifdef DEBUG
	const char *gpuEngine = getenv("gpu-engine");
	if (gpuEngine) {
		if (strcmp(gpuEngine, "opengl") == 0) {
			return [GameGLController new];
		}
		else if (strcmp(gpuEngine, "metal") == 0) {
			return [GameMetalController new];
		}
	}
#	endif
	
	if ([GameMetalController isSupported]) {
		return [GameMetalController new];
	}
	
	return [GameGLController new];
}


+ (GameController<GameControllerAPI> *)sharedInstance
{
	return __sharedInstance;
}
@end
