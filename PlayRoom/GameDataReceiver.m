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
@property(nonatomic, strong) dispatch_queue_t queue;
@property(nonatomic, strong) NSMutableSet *peripherals;

- (void)stopScanning;
- (void)startScanning;
@end


@implementation GameDataReceiver
#pragma mark - Memory
- (instancetype)initWithDelegate:(id<GameDataReceiverDelegate>)delegate
{
	if ((self = [super init])) {
		self.queue = dispatch_queue_create("GameDataReceiver", 0);
		
		NSDictionary *options = @{ CBCentralManagerOptionShowPowerAlertKey : @(0) };
		self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:self.queue options:options];
		
		self.delegate = delegate;
		
		self.peripherals = [NSMutableSet new];
	}
	
	return self;
}


#pragma mark - Internal
- (void)stopScanning
{
	[self.manager stopScan];
}


- (void)startScanning
{
	NSArray *services = @[ [CBUUID UUIDWithString:GameDataSenderServiceUUID] ];
	[self.manager scanForPeripheralsWithServices:services options:nil];
}


#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	if (central.state == CBCentralManagerStatePoweredOn) {
		[self startScanning];
	}
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	[self.peripherals addObject:peripheral];
	
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
	[self.peripherals removeObject:peripheral];
	
	[self stopScanning];
	[self startScanning];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	[central cancelPeripheralConnection:peripheral];
	[self.peripherals removeObject:peripheral];
	
	[self stopScanning];
	[self startScanning];
}


#pragma mark - CBPeripheralDelegate
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
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate dataReceiverDidConnect:self];
		});
	}
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if ([[characteristic.UUID UUIDString] isEqualToString:GameDataSenderMatrixUUID]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate dataReceiver:self syncMatrix:characteristic.value];
		});
	}
}
@end
