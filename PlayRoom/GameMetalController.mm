//
//  GameMetalController.m
//  PlayRoom
//
//  Created by Stan Potemkin on 11/30/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <simd/matrix.h>
#import "GameMetalController.h"
#import "GameMetalView.h"
#import "GameMetalTypes.h"


@interface GameMetalController()
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLLibrary> library;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property(nonatomic, strong) id<MTLDepthStencilState> depthState;
@property(nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property(nonatomic, strong) id<MTLBuffer> modelBuffer;
@property(nonatomic, strong) MTLRenderPassDescriptor *renderPass;
@property(nonatomic, strong) id<MTLTexture> depthTexture;
@property(nonatomic, strong) id<MTLRenderCommandEncoder> commandEncoder;
@property(nonatomic, assign) std::vector<GLubyte> maskData;
@end


@implementation GameMetalController
+ (BOOL)isSupported
{
	return MTLCreateSystemDefaultDevice() ? YES : NO;
}


- (Class)viewClass
{
	return [GameMetalView class];
}


- (void)setupWithLayer:(CALayer *)layer
{
	self.layer = layer;
}


- (void)initialize
{
	self.device = MTLCreateSystemDefaultDevice();
	
	self.commandQueue = [self.device newCommandQueue];
	
	self.library = [self.device newDefaultLibrary];
	id<MTLFunction> vertexFunc = [self.library newFunctionWithName:@"main_vertex"];
	id<MTLFunction> fragmentFunc = [self.library newFunctionWithName:@"main_fragment"];
	
	MTLRenderPipelineDescriptor *pdesc = [MTLRenderPipelineDescriptor new];
	pdesc.sampleCount = 1;
	pdesc.vertexFunction = vertexFunc;
	pdesc.fragmentFunction = fragmentFunc;
	pdesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pdesc.colorAttachments[0].blendingEnabled = NO;
	pdesc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pdesc error:nil];
	
	MTLDepthStencilDescriptor *ddesc = [MTLDepthStencilDescriptor new];
	ddesc.depthCompareFunction = MTLCompareFunctionLess;
	ddesc.depthWriteEnabled = YES;
	self.depthState = [self.device newDepthStencilStateWithDescriptor:ddesc];
	
	void *uniformPointer = NULL;
	vm_allocate(mach_task_self(), (vm_address_t *)&uniformPointer, vm_page_size, VM_FLAGS_ANYWHERE);
	self.uniformBuffer = [self.device newBufferWithBytesNoCopy:uniformPointer
														length:vm_page_size
													   options:MTLResourceOptionCPUCacheModeDefault
												   deallocator:^(void *pointer, NSUInteger length) {
													   vm_address_t p = (vm_address_t) pointer;
													   vm_deallocate(mach_task_self(), p, length);
												   }];
	
	void *modelPointer = NULL;
	vm_allocate(mach_task_self(), (vm_address_t *)&modelPointer, vm_page_size, VM_FLAGS_ANYWHERE);
	self.modelBuffer = [self.device newBufferWithBytesNoCopy:modelPointer
													  length:vm_page_size
													 options:MTLResourceOptionCPUCacheModeDefault
												 deallocator:^(void *pointer, NSUInteger length) {
													 vm_address_t p = (vm_address_t) pointer;
													 vm_deallocate(mach_task_self(), p, length);
												 }];
	
	self.renderPass = [MTLRenderPassDescriptor new];
	
	self.scene = [GameScene new];
}


- (void)reconfigure
{
	const CGSize size = self.layer.bounds.size;
	const int w = size.width;
	const int h = size.height;
	
	_maskData.resize(w * h * 4);
}


- (void)render
{
	CAMetalLayer *metalLayer = (id) self.layer;
	id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
	id<MTLTexture> texture = drawable.texture;
	
	const glm::vec4 color = self.scene.color;
	MTLRenderPassColorAttachmentDescriptor *cdesc = self.renderPass.colorAttachments[0];
	cdesc.texture = texture;
	cdesc.loadAction = MTLLoadActionClear;
	cdesc.storeAction = MTLStoreActionStore;
	cdesc.clearColor = MTLClearColorMake(color.r, color.g, color.b, color.a);
	
	if (self.depthTexture == nil) {
		MTLTextureDescriptor *tdesc = [MTLTextureDescriptor
									   texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
									   width:texture.width height:texture.height mipmapped:NO];
		tdesc.textureType = MTLTextureType2D;
		tdesc.sampleCount = 1;
		
		self.depthTexture = [self.device newTextureWithDescriptor:tdesc];
		
		MTLRenderPassDepthAttachmentDescriptor *ddesc = self.renderPass.depthAttachment;
		ddesc.texture = self.depthTexture;
		ddesc.loadAction = MTLLoadActionClear;
		ddesc.storeAction = MTLStoreActionDontCare;
		ddesc.clearDepth = 1.0;
	}
	
	id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
	
	id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPass];
	[commandEncoder setDepthStencilState:self.depthState];
	[commandEncoder setRenderPipelineState:self.pipelineState];
	[commandEncoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:0];
	[commandEncoder setVertexBuffer:self.modelBuffer offset:0 atIndex:1];
	[commandEncoder setFragmentBuffer:self.uniformBuffer offset:0 atIndex:0];
	[commandEncoder setFragmentBuffer:self.modelBuffer offset:0 atIndex:1];
	[commandEncoder setCullMode:MTLCullModeFront];
	self.commandEncoder = commandEncoder;
	[self.scene renderChildren];
	[commandEncoder endEncoding];
	
	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
	
	self.commandEncoder = nil;
}


- (void)setEye:(glm::vec3)eye lookAt:(glm::vec3)lookAt
{
	const CGSize layerSize = self.layer.bounds.size;
	
	const glm::mat4 pMatrix = glm::perspective<float>(45, (layerSize.width / layerSize.height), 0.1, 1000);
	const glm::mat4 vMatrix = glm::lookAt(eye, lookAt, glm::vec3(0, 1, 0));
	
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	memcpy(&uniforms->proj_matrix, &pMatrix[0][0], sizeof(pMatrix));
	memcpy(&uniforms->view_matrix, &vMatrix[0][0], sizeof(vMatrix));
}


- (void)setLight:(glm::vec3)light
{
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	memcpy(&uniforms->light_position, &light[0], sizeof(light));
}


- (void)setModelMatrix:(glm::mat4x4)matrix
{
	attributes_t *attributes = (attributes_t *) [self.modelBuffer contents];
	memcpy(&attributes->matrix, &matrix[0][0], sizeof(matrix));
}


- (void)setColor:(glm::vec4)color
{
	attributes_t *attributes = (attributes_t *) [self.modelBuffer contents];
	memcpy(&attributes->color, &color[0], sizeof(color));
}


- (void)setVertexData:(float *)data size:(size_t)size
{
	attributes_t *attributes = (attributes_t *) [self.modelBuffer contents];
	memcpy(&attributes->vertices, data, size);
}


- (void)setNormal:(glm::vec3)normal
{
	attributes_t *attributes = (attributes_t *) [self.modelBuffer contents];
	memcpy(&attributes->normal, &normal[0], sizeof(normal));
}


- (void)setMaskMode:(BOOL)maskMode
{
	bool b = maskMode;
	
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	memcpy(&uniforms->mask_mode, &b, sizeof(b));
}


- (void)setMaskColor:(glm::vec4)maskColor
{
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	memcpy(&uniforms->mask_color, &maskColor, sizeof(maskColor));
}


- (void)drawTriangles:(size_t)number withOffset:(size_t)offset
{
	[self.commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
							vertexStart:offset
							vertexCount:number];
}


- (GameObject *)objectAtPoint:(CGPoint)point
{
	return nil;
}
@end
