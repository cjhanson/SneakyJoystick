//
//  joystick.h
//  SneakyJoystick
//
//  Created by Nick Pannuto.
//  2/15/09 verion 0.1
//  
//  WIKI: http://wiki.github.com/sneakyness/SneakyJoystick/
//  HTTP SRC: http://github.com/sneakyness/SneakyJoystick.git
//  GIT: git://github.com/sneakyness/SneakyJoystick.git
//  Email: SneakyJoystick@Sneakyness.com 
//  IRC: #cocos2d-iphone irc.freenode.net

#import "cocos2d.h"

@interface SneakyJoystick : CCNode <CCTargetedTouchDelegate> {
	CGPoint stickPosition;
	float degrees;
	CGPoint velocity;
	BOOL autoCenter;
	BOOL isDPad;
	NSUInteger numberOfDirections; //Used only when isDpad == YES
	
	float joystickRadius;
	float thumbRadius;
	float touchRadius; //This is just the joystickRadius - thumbRadius (updated internally when changing joy/thumb radii)
	float deadRadius; //If the stick isn't moved enough then just don't apply any velocity
	
	//Optimizations (keep Squared values of all radii for faster calculations) (updated internally when changing joy/thumb radii)
	float joystickRadiusSq;
	float thumbRadiusSq;
	float touchRadiusSq;
	float deadRadiusSq;
}

@property (nonatomic, readonly) CGPoint stickPosition;
@property (nonatomic, readonly) float degrees;
@property (nonatomic, readonly) CGPoint velocity;
@property (nonatomic, assign) BOOL autoCenter;
@property (nonatomic, assign) BOOL isDPad;
@property (nonatomic, assign) NSUInteger numberOfDirections;

@property (nonatomic, assign) float joystickRadius;
@property (nonatomic, assign) float thumbRadius;
@property (nonatomic, assign) float deadRadius;

-(id)initWithRect:(CGRect)rect;

@end
