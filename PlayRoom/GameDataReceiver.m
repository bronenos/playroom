//
//  GameDataReceiver.m
//  PlayRoom
//
//  Created by Stan Potemkin on 11/1/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "GameDataReceiver.h"
#import "GameDataSender.h"


@interface GameDataReceiver() <CBCentralManagerDelegate, CBPeripheralDelegate>
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) CBPeripheral *peripheral;
@property(nonatomic, weak) id<GameDataReceiverDelegate> delegate;
@end


@implementation GameDataReceiver
- (instancetype)initWithDelegate:(id<GameDataReceiverDelegate>)delegate
{
	if ((self = [super init])) {
		self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
		self.delegate = delegate;
	}
	
	return self;
}


- (void)startScanning
{
	NSArray *services = @[ [CBUUID UUIDWithString:GameDataSenderServiceUUID] ];
	[self.manager scanForPeripheralsWithServices:services options:nil];
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	if (central.state == CBCentralManagerStatePoweredOn) {
		[self startScanning];
	}
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	[central stopScan];
	
	self.peripheral = peripheral;
	
	[central cancelPeripheralConnection:peripheral];
	[central connectPeripheral:peripheral options:nil];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	peripheral.delegate = self;
	[peripheral discoverServices:nil];
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	self.peripheral = nil;
	[self startScanning];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	self.peripheral = nil;
	[self startScanning];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	for (CBService *service in peripheral.services) {
		if ([[service.UUID UUIDString] isEqualToString:GameDataSenderServiceUUID]) {
			[peripheral discoverCharacteristics:nil forService:service];
		}
	}
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	for (CBCharacteristic *characteristic in service.characteristics) {
		if ([[characteristic.UUID UUIDString] isEqualToString:GameDataSenderMatrixUUID]) {
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
	}
	
	if ([self.delegate respondsToSelector:@selector(dataReceiverDidConnect:)]) {
		[self.delegate dataReceiverDidConnect:self];
	}
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if ([[characteristic.UUID UUIDString] isEqualToString:GameDataSenderMatrixUUID]) {
		[self.delegate dataReceiver:self syncMatrix:characteristic.value];
	}
}
@end
