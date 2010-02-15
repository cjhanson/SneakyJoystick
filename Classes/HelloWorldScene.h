
// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "joystick.h"

@class joystick;

// HelloWorld Layer
@interface HelloWorld : Layer
{
	joystick * leftJoystick;
	Label * helloWorldLabel;
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

@end
