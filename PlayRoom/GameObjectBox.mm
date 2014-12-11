//
//  GameObjectBox.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 11/3/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include "GameObjectBox.h"
#import "GameController.h"


@implementation GameObjectBox
- (void)render
{
	[[GameController sharedInstance] beginDrawing];
	
	[super render];
	
	[[GameController sharedInstance] endDrawing];
}
@end
