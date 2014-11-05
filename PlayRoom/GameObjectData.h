//
//  GameObjectData.h
//  PlayRoom
//
//  Created by Stan Potemkin on 11/5/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GameObjectData : NSObject
@property(nonatomic, assign) void *bytes;
@property(nonatomic, assign) NSUInteger length;

+ (instancetype)dataWithBytes:(const void *)bytes length:(NSUInteger)length;

- (NSData *)data;
- (void)setData:(NSData *)data;
@end
