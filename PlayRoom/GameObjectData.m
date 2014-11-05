//
//  GameObjectData.m
//  PlayRoom
//
//  Created by Stan Potemkin on 11/5/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameObjectData.h"


@implementation GameObjectData
+ (instancetype)dataWithBytes:(const void *)bytes length:(NSUInteger)length
{
	GameObjectData *data = [self new];
	data.bytes = (void *) bytes;
	data.length = length;
	return data;
}


- (NSData *)data
{
	return [NSData dataWithBytesNoCopy:self.bytes length:self.length freeWhenDone:NO];
}


- (void)setData:(NSData *)data
{
	memcpy(self.bytes, data.bytes, data.length);
}
@end
