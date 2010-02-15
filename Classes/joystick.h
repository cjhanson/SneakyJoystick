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

@interface joystick : Layer {
	float joystickRadius;
	float thumbRadius;
	CGPoint center;
	CGPoint curPosition;
	float degrees;
	CGPoint velocity;
	CGRect bounds;
	bool active;
	BOOL autoCenter;
	int touchAddress;
	
	Sprite *thumb;
	Sprite *background;
}

@property (nonatomic, assign) BOOL autoCenter;
@property (nonatomic, assign) float joystickRadius;
@property (nonatomic, assign) float thumbRadius;
@property (nonatomic, readonly) CGPoint velocity;
@property (nonatomic, readonly) float degrees;

-(id)initWithRect:(CGRect)rect;
-(bool)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(bool)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(bool)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

@end
