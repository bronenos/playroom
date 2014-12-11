//
//  GameViewController.m
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CloudKit/CloudKit.h>
#import <glm/glm.hpp>
#import "GameViewController.h"
#import "GameGLView.h"
#import "GameObjectData.h"
#import "GameDataSender.h"
#import "GameDataReceiver.h"
#import "GameController.h"
#import "GameObjectBox.h"
#import "GameObjectPyramid.h"
using namespace glm;


static NSString * const kCloudRecordType		= @"Config";
static NSString * const kCloudRecordMatrixKey	= @"Matrix";


@interface GameViewController() <GameDataReceiverDelegate>
@property(nonatomic, strong) GameController<GameControllerAPI> *gameController;
@property(nonatomic, weak) GameScene *scene;
@property(nonatomic, weak) GameObject *boxShape;
@property(nonatomic, weak) GameObject *pyramidShape;
@property(nonatomic, strong) CADisplayLink *displayLink;

@property(nonatomic, strong) CKRecordID *pyramidID;
@property(nonatomic, strong) CKRecord *pyramidRecord;

@property(nonatomic, strong) GameDataSender *dataSender;
@property(nonatomic, strong) GameDataReceiver *dataReceiver;

@property(nonatomic, weak) IBOutlet UIView *engineRenderView;
@property(nonatomic, weak) IBOutlet UISegmentedControl *engineChoose;

- (BOOL)shouldUseMetal;
- (void)configure;
- (void)setupEngine;
- (void)setupScene;
- (void)render:(CADisplayLink *)link;
- (void)rotateWithPoint:(CGPoint)pt;

- (GameObjectData *)pyramidMatrix;
- (void)updateSceneMask;

- (void)requestCloudRecord;
- (void)updateCloudRecord;
- (void)updateCloudDatabase;

- (void)doRotate:(UIGestureRecognizer *)rec;

- (void)onAppWillResignActive;
- (void)onAppDidBecomeActive;

- (IBAction)doChooseEngine:(UISegmentedControl *)control;
@end


@implementation GameViewController
{
	CGPoint _prevPoint;
	BOOL _wasMoved;
}

#pragma mark - Memory
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self configure];
	}
	
	return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self configure];
	}
	
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.dataSender = nil;
	self.dataReceiver.delegate = nil;
	self.dataReceiver = nil;
}


#pragma mark - View
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	self.engineChoose.selectedSegmentIndex = [defs integerForKey:kGameEngineChoice];
	[self.engineChoose setEnabled:(!![GameController controllerClassWithOpenGL]) forSegmentAtIndex:0];
	[self.engineChoose setEnabled:(!![GameController controllerClassWithMetal]) forSegmentAtIndex:1];
	
	UIPanGestureRecognizer *panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self
																			 action:@selector(doRotate:)];
	[self.view addGestureRecognizer:panRec];
}


- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	if (self.gameController == nil) {
		[self setupEngine];
		[self requestCloudRecord];
	}
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
	[self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	self.displayLink.paused = YES;
	self.displayLink = nil;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Internal
- (BOOL)shouldUseMetal
{
	if (self.engineChoose.selectedSegmentIndex == 0) {
		return NO;
	}
	
	return YES;
}


- (void)configure
{
	self.dataSender = [[GameDataSender alloc] init];
	self.dataReceiver = [[GameDataReceiver alloc] initWithDelegate:self];
	self.pyramidID = [[CKRecordID alloc] initWithRecordName:kCloudRecordType];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onAppWillResignActive)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onAppDidBecomeActive)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
}


- (void)setupEngine
{
	self.displayLink.paused = YES;
	
	NSData *mat = [[[self pyramidMatrix] data] copy];
	
	if ([self shouldUseMetal]) {
		self.gameController = [[GameController controllerClassWithMetal] new];
	}
	else {
		self.gameController = [[GameController controllerClassWithOpenGL] new];
	}
	
	[self.engineRenderView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.gameController configureWithView:self.engineRenderView];
	
	[self setupScene];
	
	[[self pyramidMatrix] setData:mat];
	
	self.displayLink.paused = NO;
}


- (void)setupScene
{
	const vec3 lightPosition = vec3(10, 20, 0);
	
	self.scene = self.gameController.scene;
	self.scene.color = vec4(0.5, 0.5, 0.5, 1.0);
	[self.scene setEye:vec3(0, 25, 100) lookAt:vec3(0, -10, 0)];
	[self.scene setLight:lightPosition];
	
	GameObject *pyramidShape = [GameObjectPyramid new];
	pyramidShape.size = vec3(40, 55, 40);
	pyramidShape.color = vec4(0, 0, 0, 0);
	self.pyramidShape = pyramidShape;
	
	GameObject *boxShape = [GameObjectBox new];
	[boxShape moveBy:vec3(-20, 0, 0)];
	self.boxShape = boxShape;
	
	[boxShape addChild:pyramidShape];
	[self.scene addChild:boxShape];
	
	GameObject *lightShape = [GameObjectPyramid new];
	lightShape.size = vec3(5, 5, 5);
	lightShape.color = vec4(1, 1, 1, 1);
	[lightShape moveBy:lightPosition];
	[self.scene addChild:lightShape];
}


- (void)render:(CADisplayLink *)link
{
	[self.gameController render];
}


- (void)rotateWithPoint:(CGPoint)pt
{
	if (pt.x > 0 && _prevPoint.x > 0) {
		const float deltaX = 0.02 * (pt.x - _prevPoint.x);
		const float deltaY = 0.02 * (pt.y - _prevPoint.y);
		[self.pyramidShape rotateGlobal:vec3(deltaY, deltaX, 0)];
	}
	
	_prevPoint = pt;
}


- (GameObjectData *)pyramidMatrix
{
	if (self.pyramidShape) {
		const float *objm = &(*self.pyramidShape.matrix)[0][0];
		return [GameObjectData dataWithBytes:objm length:16 * sizeof(float)];
	}
	
	return nil;
}


- (void)updateSceneMask
{
	[self.scene setNeedsUpdateMask:YES];
}


- (void)requestCloudRecord
{
	__weak typeof(self) weakSelf = self;
	
	CKDatabase *db = [[CKContainer defaultContainer] privateCloudDatabase];
	[db fetchRecordWithID:self.pyramidID completionHandler:^(CKRecord *record, NSError *error){
		if (weakSelf && record) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			if (strongSelf->_wasMoved == NO) {
				strongSelf.pyramidRecord = record;
				
				[[strongSelf pyramidMatrix] setData:record[kCloudRecordMatrixKey]];
				[strongSelf updateSceneMask];
			}
		}
	}];
}


- (void)updateCloudRecord
{
	if (self.pyramidRecord == nil) {
		self.pyramidRecord = [[CKRecord alloc] initWithRecordType:kCloudRecordType recordID:self.pyramidID];
	}
	
	self.pyramidRecord[kCloudRecordMatrixKey] = [[self pyramidMatrix] data];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCloudDatabase) object:nil];
	[self performSelector:@selector(updateCloudDatabase) withObject:nil afterDelay:0.5];
}


- (void)updateCloudDatabase
{
	CKDatabase *db = [[CKContainer defaultContainer] privateCloudDatabase];
	[db saveRecord:self.pyramidRecord completionHandler:nil];
}


#pragma mark - User
- (void)doRotate:(UIGestureRecognizer *)rec
{
	_wasMoved = YES;
	
	CGPoint pt = CGPointZero;
	if (rec.state == UIGestureRecognizerStateChanged) {
		pt = [rec locationInView:self.view];
	}
	
	[self rotateWithPoint:pt];
	
	[self.dataSender sendMatrix:[[self pyramidMatrix] data]];
	[self updateSceneMask];
	
	if (rec.state == UIGestureRecognizerStateEnded) {
		[self updateCloudRecord];
	}
}


#pragma mark - GameDataReceiverDelegate
- (void)dataReceiver:(id)dataReceiver syncMatrix:(NSData *)data
{
	_wasMoved = YES;
	
	[[self pyramidMatrix] setData:data];
	[self updateSceneMask];
	
	[self updateCloudRecord];
}


#pragma mark - Events
- (void)onAppWillResignActive
{
	self.displayLink.paused = YES;
}


- (void)onAppDidBecomeActive
{
	self.displayLink.paused = NO;
}


#pragma mark - User
- (IBAction)doChooseEngine:(UISegmentedControl *)control
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[defs setInteger:self.engineChoose.selectedSegmentIndex forKey:kGameEngineChoice];
	[defs synchronize];
	
	[self setupEngine];
}
@end
