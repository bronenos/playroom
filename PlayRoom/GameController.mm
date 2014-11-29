//
//  GameController.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameController.h"


static id __sharedInstance = nil;


@implementation GameController
- (instancetype)initWithLayer:(CALayer *)layer
{
	if ((self = [super init])) {
		self.layer = layer;
	}
	
	__sharedInstance = self;
	return self;
}


+ (instancetype)sharedInstance
{
	return __sharedInstance;
}
@end
