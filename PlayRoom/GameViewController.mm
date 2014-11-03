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
@end


@implementation GameViewController
{
	CGPoint _prevPoint;
	BOOL _wasMoved;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		[EAGLContext setCurrentContext:_glContext];
		
		_gameController = std::make_shared<GameController>(new GameViewControllerHelper(self));
		self.dataSender = [[GameDataSender alloc] init];
		self.dataReceiver = [[GameDataReceiver alloc] initWithDelegate:self];
		
		self.pyramidID = [[CKRecordID alloc] initWithRecordName:@"pyramid"];
		
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
	
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


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
	
	[self requestCloudRecord];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
	[self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


- (void)render:(CADisplayLink *)link
{
	_gameController->render();
}


- (void)rotateWithPoint:(CGPoint)pt
{
	auto r = _gameController->objectAtPoint({250, 200});
	
	if (pt.x > 0 && _prevPoint.x > 0) {
		const float deltaX = 0.02 * (pt.x - _prevPoint.x);
		const float deltaY = 0.02 * (pt.y - _prevPoint.y);
		_pyramidShape->rotateGlobal(glm::vec3(deltaY, deltaX, 0));
	}
	
	_prevPoint = pt;
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
				
				NSData *data = record[@"matrix"];
				float *objm = &strongSelf.pyramidShape->m()[0][0];
				memcpy(objm, data.bytes, 16 * sizeof(float));
			}
		}
	}];
}


- (void)updateCloudRecord
{
	if (self.pyramidRecord == nil) {
		self.pyramidRecord = [[CKRecord alloc] initWithRecordType:@"config" recordID:self.pyramidID];
	}
	
	const float *objm = &_pyramidShape->m()[0][0];
	self.pyramidRecord[@"matrix"] = [NSData dataWithBytes:objm length:16 * sizeof(float)];
}


- (void)updateCloudDatabase
{
	if (self.pyramidRecord) {
		CKDatabase *db = [[CKContainer defaultContainer] privateCloudDatabase];
		[db saveRecord:self.pyramidRecord completionHandler:nil];
	}
}


- (void)doRotate:(UIGestureRecognizer *)rec
{
	_wasMoved = YES;
	
	CGPoint pt = CGPointZero;
	if (rec.state == UIGestureRecognizerStateChanged) {
		pt = [rec locationInView:self.view];
	}
	
	[self rotateWithPoint:pt];
	
	const float *objm = &_pyramidShape->m()[0][0];
	[self.dataSender sendMatrix:objm];
	
	if (rec.state == UIGestureRecognizerStateEnded) {
		[self updateCloudRecord];
	}
}


//- (void)dataReceiverDidConnect:(GameDataReceiver *)dataReceiver
//{
//}


- (void)dataReceiver:(id)dataReceiver syncMatrix:(CGFloat *)mat
{
	_wasMoved = YES;
	
	float *objm = &_pyramidShape->m()[0][0];
	memcpy(objm, mat, 16 * sizeof(float));
	
	[self updateCloudRecord];
}


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
