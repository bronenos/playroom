//
//  GameViewController.m
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "GameViewController.h"
#import "GameView.h"
#import "GameController.h"
#import "GameObjectPyramid.h"


@interface GameViewController()
@property(nonatomic, strong) EAGLContext *glContext;
@property(nonatomic, assign) std::shared_ptr<GameController> gameController;
@property(nonatomic, strong) CADisplayLink *displayLink;
@end


class GameViewControllerHelper : public GameControllerDelegate {
public:
	GameViewControllerHelper(GameViewController * __strong &viewController)
	: _viewController(viewController) {
	}
	
protected:
	virtual std::pair<float, float> renderSize() {
		const CGSize ss = _viewController.view.bounds.size;
		return std::make_pair(ss.width, ss.height);
	}
	
	
	virtual std::string shaderSource(GLShader shaderType) {
		NSString *fileName = (shaderType == GLShader::Vertex ? @"vertex" : @"fragment");
		NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"glsl"];
		
		NSString *fileContents = [[NSString alloc] initWithContentsOfFile:filePath
																 encoding:NSUTF8StringEncoding
																	error:nil];
		return [fileContents UTF8String];
	}
	
	
	virtual void assignBuffer(long bufferID) {
		[_viewController.glContext renderbufferStorage:bufferID
										  fromDrawable:(id)_viewController.view.layer];
	}
	
	
	virtual void presentBuffer(long bufferID) {
		[_viewController.glContext presentRenderbuffer:bufferID];
	}
	
private:
	GameViewController *_viewController;
};


@implementation GameViewController
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		[EAGLContext setCurrentContext:_glContext];
		
		_gameController = std::make_shared<GameController>(new GameViewControllerHelper(self));
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
	
	UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:self
																		  action:@selector(doTap:)];
	[self.view addGestureRecognizer:rec];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	_gameController->initialize();
	
	auto scene = _gameController->scene();
	scene->look(glm::vec3(0, 25, 140), glm::vec3(0, 0, 0));
	
	auto object = std::make_shared<GameObjectPyramid>(scene.get());
	object->setPosition(glm::vec3(0, -20, 0));
	object->setSize(glm::vec3(40, 40, 40));
	object->setColor(glm::vec4(0, 0, 0, 0));
	object->rotate(glm::vec3(0, 9, 0));
	scene->objects().push_back(object);
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


- (void)doTap:(UIGestureRecognizer *)rec
{
	const CGPoint pt = [rec locationInView:self.view];
	const CGFloat h = self.view.bounds.size.height;
	
	auto object = _gameController->objectAtPoint({ pt.x, h - pt.y });
	if (object.get()) {
		std::cout << "object" << std::endl;
	}
	else {
		std::cout << "no object" << std::endl;
	}
}
@end
