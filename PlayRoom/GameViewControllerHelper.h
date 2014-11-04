//
//  GameViewControllerHelper.h
//  PlayRoom
//
//  Created by Stan Potemkin on 11/1/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#ifndef __PlayRoom__GameViewControllerHelper__
#define __PlayRoom__GameViewControllerHelper__

#include "GameViewController.h"
#include "GameController.h"


class GameViewControllerHelper : public GameControllerDelegate {
public:
	GameViewControllerHelper(GameViewController * const __strong &viewController);
	
protected:
	virtual std::pair<float, float> renderSize();
	virtual std::string shaderSource(GLShader shaderType);
	virtual void assignBuffer(long bufferID);
	virtual void presentBuffer(long bufferID);
	
private:
	__weak GameViewController *_viewController;
};

#endif /* defined(__PlayRoom__GameViewControllerHelper__) */
