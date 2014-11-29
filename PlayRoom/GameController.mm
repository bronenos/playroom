//
//  GameController.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 10/20/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "GameController.h"


@interface GameController()
@property(nonatomic, weak) CALayer *layer;
@property(nonatomic, strong) EAGLContext *context;
@property(nonatomic, readwrite, strong) GameScene *scene;
@property(nonatomic, assign) CGSize renderSize;
@property(nonatomic, assign) GLuint mainFrameBuffer;
@property(nonatomic, assign) GLuint colorRenderBuffer;
@property(nonatomic, assign) GLuint depthRenderBuffer;
@property(nonatomic, assign) std::vector<GLubyte> maskData;
@property(nonatomic, assign) GLuint shaderProgram;
@property(nonatomic, assign) GLuint vertexBuffer;

- (void)setupBuffers;
- (void)loadShaders;
- (GLuint)loadShaderWithType:(GLShader)shaderType;
@end


@implementation GameController
- (instancetype)initWithLayer:(CALayer *)layer
{
	if ((self = [super init])) {
		self.layer = layer;
		
		self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		[EAGLContext setCurrentContext:self.context];
	}
	
	return self;
}


- (void)dealloc
{
	if (_mainFrameBuffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, 0);
		
		glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
		
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glDeleteFramebuffers(1, &_mainFrameBuffer);
	}
	
	if (_colorRenderBuffer) {
		glDeleteRenderbuffers(1, &_colorRenderBuffer);
	}
	
	if (_depthRenderBuffer) {
		glDeleteRenderbuffers(1, &_depthRenderBuffer);
	}
	
	if (_vertexBuffer) {
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glDeleteBuffers(1, &_vertexBuffer);
	}
	
	if (_shaderProgram) {
		glUseProgram(0);
		glDeleteProgram(_shaderProgram);
	}
	
	[EAGLContext setCurrentContext:nil];
}


- (void)initialize
{
	[self setupBuffers];
	[self loadShaders];
	[self reconfigure];
	
	self.scene = [[GameScene alloc] initWithDelegate:self];
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
}


- (void)setupBuffers
{
	GLint w = 0, h = 0;
	
	glGenFramebuffers(1, &_mainFrameBuffer);
	if (_mainFrameBuffer) {
		glBindFramebuffer(GL_FRAMEBUFFER, _mainFrameBuffer);
	}
	
	glGenRenderbuffers(1, &_colorRenderBuffer);
	if (_colorRenderBuffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		[self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id)self.layer];
		
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
	}
	
	glGenRenderbuffers(1, &_depthRenderBuffer);
	if (_depthRenderBuffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, w, h);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
		glEnable(GL_DEPTH_TEST);
	}
	
	glGenBuffers(1, &_vertexBuffer);
	if (_vertexBuffer) {
		glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	}
}


- (void)loadShaders
{
	GLuint vertexShader = [self loadShaderWithType:GLShader::Vertex];
	GLuint fragmentShader = [self loadShaderWithType:GLShader::Fragment];
	
	_shaderProgram = glCreateProgram();
	glAttachShader(_shaderProgram, vertexShader);
	glAttachShader(_shaderProgram, fragmentShader);
	glLinkProgram(_shaderProgram);
	
	GLint ok;
	glGetProgramiv(_shaderProgram, GL_LINK_STATUS, &ok);
	if (ok == GL_FALSE) {
		GLchar log[256];
		glGetProgramInfoLog(_shaderProgram, sizeof(log), 0, log);
		
		glDeleteProgram(_shaderProgram);
		
		return;
	}
	
	glUseProgram(_shaderProgram);
}


- (GLuint)loadShaderWithType:(GLShader)shaderType
{
	std::string shaderSource;
	GLuint shader;
	
	NSString *fileName = (shaderType == GLShader::Vertex ? @"vertex" : @"fragment");
	NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"glsl"];
	
	NSString *fileContents = [[NSString alloc] initWithContentsOfFile:filePath
															 encoding:NSUTF8StringEncoding
																error:nil];
	shaderSource = [fileContents UTF8String];
	
	if (shaderSource.size() > 0) {
		if (shaderType == GLShader::Vertex) {
			shader = glCreateShader(GL_VERTEX_SHADER);
		}
		else {
			shader = glCreateShader(GL_FRAGMENT_SHADER);
		}
		
		const GLchar *src = shaderSource.c_str();
		const GLint srclen = (GLint) shaderSource.size();
		glShaderSource(shader, 1, &src, &srclen);
		
		glCompileShader(shader);
		
		GLint ok;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
		if (ok == GL_FALSE) {
			GLchar log[256];
			glGetShaderInfoLog(shader, sizeof(log), 0, log);
			
			glDeleteShader(shader);
			
			return 0;
		}
	}
	
	return shader;
}


- (void)reconfigure
{
	self.renderSize = self.layer.bounds.size;
	const int w = self.renderSize.width;
	const int h = self.renderSize.height;
	
	glViewport(0, 0, w, h);
	_maskData.resize(w * h * 4);
}


- (void)render
{
	glBindFramebuffer(GL_FRAMEBUFFER, _mainFrameBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
	
	glClearColor(0.5, 0.5, 0.5, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	[self.scene renderChildren];
	[self.context presentRenderbuffer:GL_RENDERBUFFER];
	
	if ([self.scene needsUpdateMask]) {
		[self.scene setNeedsUpdateMask:NO];
		
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
		
		glClearColor(0, 0, 0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		[self.scene renderMask];
		
		GLint w, h;
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
		glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, &_maskData[0]);
	}
}


- (GameObject *)objectAtPoint:(GamePoint)point
{
	GLint w, h;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
	
	const GLint offset = (point.y * w + point.x) * 4;
	GLubyte *touchMask = &_maskData[offset];
	
	static GLubyte noneMask[] { 0, 0, 0, 0xFF };
	static const size_t maskSize = sizeof(noneMask);
	
	if (memcmp(touchMask, noneMask, maskSize) == 0) {
		return nullptr;
	}
	else {
		glm::vec4 mc;
		mc.r = (float) touchMask[0] / 255.0;
		mc.g = (float) touchMask[1] / 255.0;
		mc.b = (float) touchMask[2] / 255.0;
		
		return [self.scene objectWithMaskColor:mc];
	}
}


- (GLuint)uniformLocation:(const char *)name
{
	return glGetUniformLocation(_shaderProgram, name);
}


- (GLuint)attributeLocation:(const char *)name
{
	return glGetAttribLocation(_shaderProgram, name);
}
@end
