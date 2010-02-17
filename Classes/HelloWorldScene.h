
// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "SneakyJoystick.h"

@class SneakyJoystick;

// HelloWorld Layer
@interface HelloWorld : CCLayer
{
	SneakyJoystick *leftJoystick;
	SneakyJoystick *rightJoystick;
	CCNode *leftPlayer;
	CCNode *rightPlayer;
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

@end
