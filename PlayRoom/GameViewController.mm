//
//  GameViewController.m
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <glm/glm.hpp>
#import "GameViewController.h"
#import "GameViewControllerHelper.h"
#import "GameView.h"
#import "GameDataSender.h"
#import "GameDataReceiver.h"
#import "GameController.h"
#import "GameObjectPyramid.h"


@interface GameViewController() <GameDataReceiverDelegate>
@property(nonatomic, strong) EAGLContext *glContext;
@property(nonatomic, strong) CADisplayLink *displayLink;

@property(nonatomic, assign) std::shared_ptr<GameController> gameController;
@property(nonatomic, assign) std::shared_ptr<GameObjectPyramid> pyramidObject;

@property(nonatomic, strong) GameDataSender *dataSender;
@property(nonatomic, strong) GameDataReceiver *dataReceiver;
@end


@implementation GameViewController
{
	CGPoint _prevPoint;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		[EAGLContext setCurrentContext:_glContext];
		
		_gameController = std::make_shared<GameController>(new GameViewControllerHelper(self));
		self.dataSender = [[GameDataSender alloc] init];
		self.dataReceiver = [[GameDataReceiver alloc] initWithDelegate:self];
	}
	
	return self;
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
	
	auto scene = _gameController->scene();
	scene->look(glm::vec3(0, 25, 130), glm::vec3(0, -10, 0));
	
	_pyramidObject = std::make_shared<GameObjectPyramid>(scene.get());
	_pyramidObject->setPosition(glm::vec3(0, -20, 0));
	_pyramidObject->setSize(glm::vec3(40, 55, 40));
	_pyramidObject->setColor(glm::vec4(0, 0, 0, 0));
	_pyramidObject->rotate(glm::vec3(0, 9, 0));
	scene->objects().push_back(_pyramidObject);
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
	if (pt.x > 0 && _prevPoint.x > 0) {
		const float deltaX = 0.02 * (pt.x - _prevPoint.x);
		const float deltaY = 0.02 * (pt.y - _prevPoint.y);
		_pyramidObject->rotate(glm::vec3(deltaY, deltaX, 0));
	}
	
	_prevPoint = pt;
}


- (void)doRotate:(UIGestureRecognizer *)rec
{
	CGPoint pt = CGPointZero;
	if (rec.state == UIGestureRecognizerStateChanged) {
		pt = [rec locationInView:self.view];
	}
	
	[self rotateWithPoint:pt];
	
	const CGFloat *objm = &_pyramidObject->m()[0][0];
	[self.dataSender sendMatrix:objm];
}


//- (void)dataReceiverDidConnect:(GameDataReceiver *)dataReceiver
//{
//}


- (void)dataReceiver:(id)dataReceiver syncMatrix:(CGFloat *)mat
{
	CGFloat *objm = &_pyramidObject->m()[0][0];
	memcpy(objm, mat, 16 * sizeof(float));
}
@end
