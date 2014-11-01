//
//  GameDataReceiver.h
//  PlayRoom
//
//  Created by Stan Potemkin on 11/1/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Foundation/Foundation.h>


@class GameDataReceiver;


@protocol GameDataReceiverDelegate <NSObject>
@optional
- (void)dataReceiverDidConnect:(GameDataReceiver *)dataReceiver;
@required
- (void)dataReceiver:(GameDataReceiver *)dataReceiver syncMatrix:(CGFloat[16])mat;
@end


@interface GameDataReceiver : NSObject
- (instancetype)initWithDelegate:(id<GameDataReceiverDelegate>)delegate;
@end
