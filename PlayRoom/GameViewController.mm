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
#import "GameViewControllerHelper.h"
#import "GameView.h"
#import "GameDataSender.h"
#import "GameDataReceiver.h"
#import "GameController.h"
#import "GameObjectBox.h"
#import "GameObjectPyramid.h"


static NSString * const kCloudRecordType		= @"config";
static NSString * const kCloudRecordName		= @"pyramid";
static NSString * const kCloudRecordMatrixKey	= @"matrix";


@interface GameViewController() <GameDataReceiverDelegate>
@property(nonatomic, strong) EAGLContext *glContext;
@property(nonatomic, strong) CADisplayLink *displayLink;

@property(nonatomic, assign) std::shared_ptr<GameController> gameController;
@property(nonatomic, assign) std::shared_ptr<GameScene> scene;
@property(nonatomic, assign) std::shared_ptr<GameObjectBox> boxShape;
@property(nonatomic, assign) std::shared_ptr<GameObjectPyramid> pyramidShape;

@property(nonatomic, strong) CKRecordID *pyramidID;
@property(nonatomic, strong) CKRecord *pyramidRecord;

@property(nonatomic, strong) GameDataSender *dataSender;
@property(nonatomic, strong) GameDataReceiver *dataReceiver;

- (void)configure;
- (void)setupScene;
- (void)render:(CADisplayLink *)link;
- (void)rotateWithPoint:(CGPoint)pt;

- (NSMutableData *)pyramidMatrix;

- (void)requestCloudRecord;
- (void)updateCloudRecord;
- (void)updateCloudDatabase;

- (void)doRotate:(UIGestureRecognizer *)rec;

- (void)onAppWillResignActive;
- (void)onAppDidBecomeActive;
- (void)onAppWillTerminate;
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
	_glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	[EAGLContext setCurrentContext:_glContext];
	
	_gameController = std::make_shared<GameController>(new GameViewControllerHelper(self));
	self.dataSender = [[GameDataSender alloc] init];
	self.dataReceiver = [[GameDataReceiver alloc] initWithDelegate:self];
	
	self.pyramidID = [[CKRecordID alloc] initWithRecordName:kCloudRecordName];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onAppWillResignActive)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onAppDidBecomeActive)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onAppWillTerminate)
												 name:UIApplicationWillTerminateNotification
											   object:nil];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.dataSender = nil;
	self.dataReceiver.delegate = nil;
	self.dataReceiver = nil;
	
	_scene.reset();
	_boxShape.reset();
	_pyramidShape.reset();
	_gameController.reset();
	
	[EAGLContext setCurrentContext:nil];
	self.glContext = nil;
}


#pragma mark - View
- (void)loadView
{
	self.view = [GameView new];
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
	
	_gameController->initialize();
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
	_scene = _gameController->scene();
	_scene->look(glm::vec3(0, 25, 100), glm::vec3(0, -10, 0));
	_scene->light(glm::vec3(85, 50, 0));
	
	_pyramidShape = std::make_shared<GameObjectPyramid>(_scene.get());
	_pyramidShape->setSize(glm::vec3(40, 55, 40));
	_pyramidShape->setColor(glm::vec4(0, 0, 0, 0));
	
	_boxShape = std::make_shared<GameObjectBox>(_scene.get());
	_boxShape->moveBy(glm::vec3(0, 0, 0));
	_boxShape->addChild(_pyramidShape);
	_scene->addChild(_boxShape);
}


- (void)render:(CADisplayLink *)link
{
	_gameController->render();
}


- (void)rotateWithPoint:(CGPoint)pt
{
	if (pt.x > 0 && _prevPoint.x > 0) {
		const float deltaX = 0.02 * (pt.x - _prevPoint.x);
		const float deltaY = 0.02 * (pt.y - _prevPoint.y);
		_pyramidShape->rotateGlobal(glm::vec3(deltaY, deltaX, 0));
	}
	
	_prevPoint = pt;
}


- (NSMutableData *)pyramidMatrix
{
	float *objm = &_pyramidShape->m()[0][0];
	return [NSMutableData dataWithBytesNoCopy:objm length:16 * sizeof(float) freeWhenDone:NO];
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
				[[strongSelf pyramidMatrix] setData:record[kCloudRecordMatrixKey]];;
			}
		}
	}];
}


- (void)updateCloudRecord
{
	if (self.pyramidRecord == nil) {
		self.pyramidRecord = [[CKRecord alloc] initWithRecordType:kCloudRecordType recordID:self.pyramidID];
	}
	
	self.pyramidRecord[kCloudRecordMatrixKey] = [self pyramidMatrix];
}


- (void)updateCloudDatabase
{
	if (self.pyramidRecord) {
		CKDatabase *db = [[CKContainer defaultContainer] privateCloudDatabase];
		[db saveRecord:self.pyramidRecord completionHandler:nil];
	}
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
	[self.dataSender sendMatrix:[self pyramidMatrix]];
	
	if (rec.state == UIGestureRecognizerStateEnded) {
		[self updateCloudRecord];
	}
}


#pragma mark - GameDataReceiverDelegate
- (void)dataReceiver:(id)dataReceiver syncMatrix:(NSData *)data
{
	_wasMoved = YES;
	
	[[self pyramidMatrix] setData:data];
	[self updateCloudRecord];
}


#pragma mark - Events
- (void)onAppWillResignActive
{
	self.displayLink.paused = YES;
	[self updateCloudDatabase];
}


- (void)onAppDidBecomeActive
{
	self.displayLink.paused = NO;
}


- (void)onAppWillTerminate
{
	[self updateCloudDatabase];
}
@end
