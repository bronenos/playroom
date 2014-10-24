//
//  GameObjectPyramid.h
//  PlayRoom
//
//  Created by Stan Potemkin on 10/23/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#ifndef __PlayRoom__GameObjectPyramid__
#define __PlayRoom__GameObjectPyramid__

#include <stdio.h>
#include "GameObject.h"

class GameObjectPyramid : public GameObject {
public:
	using GameObject::GameObject;
	
	virtual void render();
};

#endif /* defined(__PlayRoom__GameObjectPyramid__) */
