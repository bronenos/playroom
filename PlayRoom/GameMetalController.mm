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
#import "GameObject.h"


static simd::float3 convert_vec3(glm::vec3 m)
{
	return (simd::float3) { m[0], m[1], m[2] };
}


static simd::float3x3 convert_mat3(glm::mat3 m)
{
	return simd::float3x3(
						  (simd::float3) { m[0][0], m[0][1], m[0][2] },
						  (simd::float3) { m[1][0], m[1][1], m[1][2] },
						  (simd::float3) { m[2][0], m[2][1], m[2][2] }
	);
}


static simd::float4 convert_vec4(glm::vec4 m)
{
	return (simd::float4) { m[0], m[1], m[2], m[3] };
}


static simd::float4x4 convert_mat4(glm::mat4 m)
{
	return simd::float4x4(
						  (simd::float4) { m[0][0], m[0][1], m[0][2], m[0][3] },
						  (simd::float4) { m[1][0], m[1][1], m[1][2], m[1][3] },
						  (simd::float4) { m[2][0], m[2][1], m[2][2], m[2][3] },
						  (simd::float4) { m[3][0], m[3][1], m[3][2], m[3][3] }
						  );
}


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
@property(nonatomic, strong) id<MTLCommandBuffer> commandBuffer;
@property(nonatomic, strong) id<MTLRenderCommandEncoder> commandEncoder;
@property(nonatomic, assign) glm::mat4 projMatrix;
@property(nonatomic, assign) glm::mat4 viewMatrix;
@property(nonatomic, assign) NSUInteger objectIndex;
@property(nonatomic, assign) std::vector<GLubyte> maskData;
@property(nonatomic, strong) dispatch_semaphore_t rendererLock;

- (attributes_t *)currentAttributes;
@end


@implementation GameMetalController
- (instancetype)init
{
	if ((self = [super init])) {
		self.rendererLock = dispatch_semaphore_create(1);
	}
	
	return self;
}


+ (BOOL)isSupported
{
	return MTLCreateSystemDefaultDevice() ? YES : NO;
}


+ (NSString *)shaderFilename
{
	return @"common.metalsrc";
}


- (void)configureWithView:(UIView *)view
{
	UIView *renderView = [[GameMetalView alloc] initWithFrame:view.bounds];
	renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[view addSubview:renderView];
	self.layer = renderView.layer;
	
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
	dispatch_semaphore_wait(self.rendererLock, DISPATCH_TIME_FOREVER);
	
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
	
	self.commandBuffer = [self.commandQueue commandBuffer];
	if (self.commandBuffer) {
		self.commandEncoder = [self.commandBuffer renderCommandEncoderWithDescriptor:self.renderPass];
		if (self.commandEncoder) {
			[self.commandEncoder setDepthStencilState:self.depthState];
			[self.commandEncoder setRenderPipelineState:self.pipelineState];
			[self.commandEncoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:0];
			[self.commandEncoder setFragmentBuffer:self.uniformBuffer offset:0 atIndex:0];
			[self.commandEncoder setCullMode:MTLCullModeFront];
			
			self.objectIndex = 0;
			[self.scene renderChildren];
			
			[self.commandEncoder endEncoding];
			self.commandEncoder = nil;
		}
		
		__block dispatch_semaphore_t semaphore = self.rendererLock;
		[self.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
			dispatch_semaphore_signal(semaphore);
		}];
		
		[self.commandBuffer presentDrawable:drawable];
		[self.commandBuffer commit];
		self.commandBuffer = nil;
	}
}


- (attributes_t *)currentAttributes
{
	const char *basePointer = (char *) [self.modelBuffer contents];
	return (attributes_t *) (basePointer + self.objectIndex * sizeof(attributes_t));
}


- (void)setEye:(glm::vec3)eye lookAt:(glm::vec3)lookAt
{
	const CGSize layerSize = self.layer.bounds.size;
	self.projMatrix = glm::perspective<float>(45, (layerSize.width / layerSize.height), 0.1, 1000);
	self.viewMatrix = glm::lookAt(eye, lookAt, glm::vec3(0, 1, 0));
	
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	uniforms->proj_matrix = convert_mat4(_projMatrix);
	uniforms->view_matrix = convert_mat4(_viewMatrix);
}


- (void)setLight:(glm::vec3)light
{
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	uniforms->light_position = convert_vec3(light);
}


- (void)setModelMatrix:(glm::mat4x4)matrix
{
	attributes_t *attribs = [self currentAttributes];
	attribs->matrix = convert_mat4(matrix);
	
	const glm::mat3 normalMatrix = glm::transpose(glm::inverse(glm::mat3(self.viewMatrix * matrix)));
	attribs->normal_matrix = convert_mat3(normalMatrix);
}


- (void)setColor:(glm::vec4)color
{
	attributes_t *attribs = [self currentAttributes];
	attribs->color = convert_vec4(color);
}


- (void)setVertexData:(const float *)data size:(size_t)size
{
	attributes_t *attribs = [self currentAttributes];
	for (size_t i=0, offset=0; offset<size; i++) {
		simd::float4 v;
		v.x = data[offset++];
		v.y = data[offset++];
		v.z = data[offset++];
		v.w = 1.0;
		
		attribs->vertices[i] = v;
	}
}


- (void)setNormal:(glm::vec3)normal forVertexIndex:(NSUInteger)index
{
	attributes_t *attribs = [self currentAttributes];
	attribs->normals[index] = convert_vec3(normal);
}


- (void)setMaskMode:(BOOL)maskMode
{
	uniforms_t *uniforms = (uniforms_t *) [self.uniformBuffer contents];
	uniforms->mask_mode = maskMode;
}


- (void)setMaskColor:(glm::vec4)maskColor
{
	attributes_t *attribs = [self currentAttributes];
	attribs->mask_color = convert_vec4(maskColor);
}


- (void)beginDrawing
{
	static const size_t attrib_size = sizeof(attributes_t);
	[self.commandEncoder setVertexBuffer:self.modelBuffer offset:(attrib_size * self.objectIndex) atIndex:1];
	[self.commandEncoder setFragmentBuffer:self.modelBuffer offset:(attrib_size * self.objectIndex) atIndex:1];
}


- (void)drawTriangles:(size_t)number withOffset:(size_t)offset
{
	[self.commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
							vertexStart:offset
							vertexCount:number];
}


- (void)endDrawing
{
	self.objectIndex++;
}


- (GameObject *)objectAtPoint:(CGPoint)point
{
	return nil;
}
@end
