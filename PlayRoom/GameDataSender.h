//
//  GameDataSender.h
//  PlayRoom
//
//  Created by Stan Potemkin on 11/1/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSString * const GameDataSenderServiceUUID;
extern NSString * const GameDataSenderMatrixUUID;


#define CBUUID(s) [CBUUID UUIDWithString:(s)]


@interface GameDataSender : NSObject
- (void)sendMatrix:(const CGFloat[16])mat;
@end
