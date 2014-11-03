//
//  GameObjectBox.h
//  PlayRoom
//
//  Created by Stan Potemkin on 11/3/14.
//  Copyright (c) 2014 bronenos. All rights reserved.
//

#ifndef __PlayRoom__GameObjectBox__
#define __PlayRoom__GameObjectBox__

#include <stdio.h>
#include "GameObject.h"

class GameObjectBox : public GameObject {
public:
	using GameObject::GameObject;
	
	virtual void render();
};

#endif /* defined(__PlayRoom__GameObjectBox__) */
