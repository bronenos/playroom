//
//  GameDataSender.m
//  PlayRoom
//
//  Created by Stan Potemkin on 11/1/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "GameDataSender.h"


NSString * const GameDataSenderServiceUUID = @"41223F6C-4F58-4C59-9CE5-19737D742E53";
NSString * const GameDataSenderMatrixUUID = @"180F";


@interface GameDataSender() <CBPeripheralManagerDelegate>
@property(nonatomic, strong) CBPeripheralManager *manager;
@property(nonatomic, strong) CBMutableCharacteristic *matrixItem;
@end


@implementation GameDataSender
- (instancetype)init
{
	if ((self = [super init])) {
		self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
	}
	
	return self;
}


- (void)sendMatrix:(const float[16])mat
{
	if (self.matrixItem) {
		[self.manager updateValue:[NSData dataWithBytes:mat length:16 * sizeof(CGFloat)]
				forCharacteristic:self.matrixItem
			 onSubscribedCentrals:nil];
	}
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
	if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
		CBCharacteristicProperties props = 0;
		props |= CBCharacteristicPropertyRead;
		props |= CBCharacteristicPropertyNotify;
		
		self.matrixItem = [[CBMutableCharacteristic alloc] initWithType:CBUUID(GameDataSenderMatrixUUID)
															 properties:props
																  value:nil
															permissions:CBAttributePermissionsReadable];
		
		CBMutableService *service = [[CBMutableService alloc] initWithType:CBUUID(GameDataSenderServiceUUID)
																   primary:YES];
		service.characteristics = @[ self.matrixItem ];
		
		[peripheral removeAllServices];
		[peripheral addService:service];
	}
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
	if (error == nil) {
		NSMutableDictionary *adv = [NSMutableDictionary new];
		adv[CBAdvertisementDataServiceUUIDsKey] = @[ service.UUID ];
		adv[CBAdvertisementDataLocalNameKey] = [UIDevice currentDevice].name;
		
		[peripheral startAdvertising:adv];
	}
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
	NSMutableDictionary *items;
	items[self.matrixItem.UUID] = self.matrixItem;
	
	CBCharacteristic *item = items[request.characteristic.UUID];
	if (item) {
		const NSUInteger valueLength = item.value.length;
		if (request.offset > valueLength) {
			[peripheral respondToRequest:request withResult:CBATTErrorInvalidOffset];
		}
		else {
			const NSRange subrange = NSMakeRange(request.offset, item.value.length - request.offset);
			request.value = [item.value subdataWithRange:subrange];
			
			[peripheral respondToRequest:request withResult:CBATTErrorSuccess];
		}
	}
}
@end
