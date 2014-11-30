//
//  GameGLController.m
//  PlayRoom
//
//  Created by Stan Potemkin on 11/30/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import "GameGLController.h"
#import "GameGLView.h"


enum class GLShader {
	Vertex, Fragment
};


@interface GameGLController()
@property(nonatomic, strong) EAGLContext *context;
@property(nonatomic, assign) CGSize renderSize;
@property(nonatomic, assign) GLuint mainFrameBuffer;
@property(nonatomic, assign) GLuint colorRenderBuffer;
@property(nonatomic, assign) GLuint depthRenderBuffer;
@property(nonatomic, assign) std::vector<GLubyte> maskData;
@property(nonatomic, assign) GLuint shaderProgram;
@property(nonatomic, assign) GLuint vertexBuffer;

@property(nonatomic, assign) GLuint vpSlot;
@property(nonatomic, assign) GLuint modelSlot;
@property(nonatomic, assign) GLuint vertexSlot;
@property(nonatomic, assign) GLuint normalSlot;
@property(nonatomic, assign) GLuint colorSlot;
@property(nonatomic, assign) GLuint lightSlot;
@property(nonatomic, assign) GLuint maskModeSlot;
@property(nonatomic, assign) GLuint maskColorSlot;

- (void)setupBuffers;
- (void)loadShaders;
- (GLuint)loadShaderWithType:(GLShader)shaderType;
@end


@implementation GameGLController
+ (BOOL)isSupported
{
	return YES;
}


- (instancetype)init
{
	if ((self = [super init])) {
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


- (Class)viewClass
{
	return [GameGLView class];
}


- (void)setupWithLayer:(CALayer *)layer
{
	self.layer = layer;
}


- (void)initialize
{
	[self setupBuffers];
	[self loadShaders];
	[self reconfigure];
	
	self.scene = [GameScene new];
	
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
	
	self.vpSlot = glGetUniformLocation(_shaderProgram, "u_vp");
	self.modelSlot = glGetUniformLocation(_shaderProgram, "u_m");
	self.vertexSlot = glGetAttribLocation(_shaderProgram, "a_vertex");
	self.normalSlot = glGetUniformLocation(_shaderProgram, "u_normal");
	self.colorSlot = glGetUniformLocation(_shaderProgram, "u_color");
	self.lightSlot = glGetUniformLocation(_shaderProgram, "u_light");
	self.maskModeSlot = glGetUniformLocation(_shaderProgram, "u_maskMode");
	self.maskColorSlot = glGetUniformLocation(_shaderProgram, "u_maskColor");
	
	glEnableVertexAttribArray(self.vertexSlot);
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
	
	const glm::vec4 color = self.scene.color;
	glClearColor(color.r, color.g, color.b, color.a);
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


- (void)setEye:(glm::vec3)eye lookAt:(glm::vec3)lookAt
{
	GLint w, h;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
	
	const glm::mat4 pMatrix = glm::perspective<float>(45, (float(w) / float(h)), 0.1, 1000);
	const glm::mat4 vMatrix = glm::lookAt(eye, lookAt, glm::vec3(0, 1, 0));
	const glm::mat4 vpMatrix = pMatrix * vMatrix;
	
	glUniformMatrix4fv(self.vpSlot, 1, GL_FALSE, &vpMatrix[0][0]);
}


- (void)setLight:(glm::vec3)light
{
	glUniform3fv(self.lightSlot, 1, &light[0]);
}


- (void)setModelMatrix:(glm::mat4x4)matrix
{
	glUniformMatrix4fv(self.modelSlot, 1, GL_FALSE, &matrix[0][0]);
}


- (void)setColor:(glm::vec4)color
{
	glUniform4fv(self.colorSlot, 1, &color[0]);
}


- (void)setVertexData:(float *)data size:(size_t)size
{
	glBufferData(GL_ARRAY_BUFFER, size, data, GL_STATIC_DRAW);
	glVertexAttribPointer(self.vertexSlot, 3, GL_FLOAT, GL_FALSE, 0, NULL);
}


- (void)setNormal:(glm::vec3)normal
{
	glUniform3fv(self.normalSlot, 1, &normal[0]);
}


- (void)setMaskMode:(BOOL)maskMode
{
	const GLint a = maskMode ? 1 : 0;
	glUniform1iv(self.maskModeSlot, 1, &a);
}


- (void)setMaskColor:(glm::vec4)maskColor
{
	glUniform4fv(self.maskColorSlot, 1, &maskColor[0]);
}


- (void)drawTriangles:(size_t)number withOffset:(size_t)offset
{
	glDrawArrays(GL_TRIANGLES, (GLint)offset, (GLint)number);
}


- (GameObject *)objectAtPoint:(CGPoint)point
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
@end
