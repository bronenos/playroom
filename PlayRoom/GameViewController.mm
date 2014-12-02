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


static NSString * const kCloudRecordType		= @"Config";
static NSString * const kCloudRecordMatrixKey	= @"Matrix";


@interface GameViewController() <GameDataReceiverDelegate>
@property(nonatomic, strong) GameController<GameControllerAPI> *gameController;
@property(nonatomic, strong) GameScene *scene;
@property(nonatomic, strong) GameObjectBox *boxShape;
@property(nonatomic, strong) GameObjectPyramid *pyramidShape;
@property(nonatomic, strong) CADisplayLink *displayLink;

@property(nonatomic, strong) CKRecordID *pyramidID;
@property(nonatomic, strong) CKRecord *pyramidRecord;

@property(nonatomic, strong) GameDataSender *dataSender;
@property(nonatomic, strong) GameDataReceiver *dataReceiver;

- (void)configure;
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


- (void)configure
{
	self.gameController = [GameController supportedController];
	
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


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.dataSender = nil;
	self.dataReceiver.delegate = nil;
	self.dataReceiver = nil;
}


#pragma mark - View
- (void)loadView
{
	self.view = [[self.gameController viewClass] new];
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIPanGestureRecognizer *panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self
																			 action:@selector(doRotate:)];
	[self.view addGestureRecognizer:panRec];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.gameController setupWithLayer:self.view.layer];
	[self.gameController initialize];
	
	[self setupScene];
	[self requestCloudRecord];
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


#pragma mark - Internal
- (void)setupScene
{
	self.scene = self.gameController.scene;
	[self.scene setColor:glm::vec4(0.5, 0.5, 0.5, 1.0)];
	[self.scene setEye:glm::vec3(0, 25, 100) lookAt:glm::vec3(0, -10, 0)];
	[self.scene setLight:glm::vec3(65, 40, 10)];
	
	self.pyramidShape = [GameObjectPyramid new];
	self.pyramidShape.size = glm::vec3(40, 55, 40);
	self.pyramidShape.color = glm::vec4(0, 0, 0, 0);
	
	self.boxShape = [GameObjectBox new];
	[self.boxShape moveBy:glm::vec3(-20, 0, 0)];
	[self.scene addChild:self.boxShape];
	[self.boxShape addChild:self.pyramidShape];
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
		[self.pyramidShape rotateGlobal:glm::vec3(deltaY, deltaX, 0)];
	}
	
	_prevPoint = pt;
}


- (GameObjectData *)pyramidMatrix
{
	const float *objm = &(*self.pyramidShape.matrix)[0][0];
	return [GameObjectData dataWithBytes:objm length:16 * sizeof(float)];
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
				
#				warning "Enable is back"
//				[[strongSelf pyramidMatrix] setData:record[kCloudRecordMatrixKey]];
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
@end
