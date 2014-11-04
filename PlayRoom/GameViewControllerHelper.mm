//
//  GameViewControllerHelper.cpp
//  PlayRoom
//
//  Created by Stan Potemkin on 11/1/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#include <Foundation/Foundation.h>
#include "GameViewControllerHelper.h"


GameViewControllerHelper::GameViewControllerHelper(GameViewController * const __strong &viewController)
: _viewController(viewController)
{
}
	

std::pair<float, float> GameViewControllerHelper::renderSize()
{
	const CGSize ss = _viewController.view.bounds.size;
	return std::make_pair(ss.width, ss.height);
}


std::string GameViewControllerHelper::shaderSource(GLShader shaderType)
{
	NSString *fileName = (shaderType == GLShader::Vertex ? @"vertex" : @"fragment");
	NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"glsl"];
	
	NSString *fileContents = [[NSString alloc] initWithContentsOfFile:filePath
															 encoding:NSUTF8StringEncoding
																error:nil];
	return [fileContents UTF8String];
}


void GameViewControllerHelper::assignBuffer(long bufferID)
{
	[_viewController.glContext renderbufferStorage:bufferID
									  fromDrawable:(id)_viewController.view.layer];
}


void GameViewControllerHelper::presentBuffer(long bufferID)
{
	[_viewController.glContext presentRenderbuffer:bufferID];
}
