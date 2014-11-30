//
//  GameMetalView.m
//  PlayRoom
//
//  Created by Stan Potemkin on 11/30/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <QuartzCore/CAMetalLayer.h>
#import "GameMetalView.h"


@implementation GameMetalView
+ (Class)layerClass
{
	return [CAMetalLayer class];
}
@end
