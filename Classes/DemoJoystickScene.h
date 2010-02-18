
// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
@class SneakyJoystick;

@interface DemoJoystickLayer : CCLayer
{
	SneakyJoystick *leftJoystick;
	SneakyJoystick *rightJoystick;
	CCNode *leftPlayer;
	CCNode *rightPlayer;
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

@end
