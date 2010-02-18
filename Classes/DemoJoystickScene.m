#import "DemoJoystickScene.h"
#import "SneakyJoystick.h"
#import "SneakyJoystickSkinnedJoystickExample.h"
#import "SneakyJoystickSkinnedDPadExample.h"
#import "ColoredCircleSprite.h"

@interface DemoJoystickLayer (privateMethods)
-(void)applyJoystick:(SneakyJoystick *)aJoystick toNode:(CCNode *)aNode forTimeDelta:(float)dt;
@end

@implementation DemoJoystickLayer

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	DemoJoystickLayer *layer = [DemoJoystickLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (void) dealloc
{
	[leftPlayer release];
	[rightPlayer release];
	[leftJoystick release];
	[rightJoystick release];
	
	[super dealloc];
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		// create and initialize some objects to be controlled by the joysticks
		leftPlayer = [[ColoredCircleSprite circleWithColor:ccc4(128, 128, 0, 255) radius:15] retain];
		leftPlayer.position = ccp(size.width/2 - leftPlayer.contentSize.width/2 - 10, size.height/2);
		[self addChild:leftPlayer z:10];
		
		rightPlayer = [[ColoredCircleSprite circleWithColor:ccc4(128, 0, 128, 255) radius:20] retain];
		rightPlayer.position = ccp(size.width/2 + rightPlayer.contentSize.width/2 + 10, size.height/2);
		[self addChild:rightPlayer z:11];
		
		// create and initalize the joystick(s) with position and size specified by a rect
		
		//one for the left player
		SneakyJoystickSkinnedJoystickExample *leftPad = [[[SneakyJoystickSkinnedJoystickExample alloc] init] autorelease];
		leftPad.position = ccp(leftPad.contentSize.width/2 + 10, leftPad.contentSize.height/2 + 10);
		leftJoystick = [leftPad.joystick retain];
		[self addChild:leftPad];
		
		//one for the right player
		SneakyJoystickSkinnedDPadExample *rightDPad = [[[SneakyJoystickSkinnedDPadExample alloc] init] autorelease];
		rightDPad.position = ccp(size.width - rightDPad.contentSize.width/2 - 10, rightDPad.contentSize.height/2 + 10);
		rightJoystick = [rightDPad.joystick retain];
		[self addChild:rightDPad];
		
		// schedule a method to update object positions based on the joystick(s)
		[self schedule:@selector(tick:)];
	}
	return self;
}
	//function to apply a velocity to a position with delta
static CGPoint applyVelocity(CGPoint velocity, CGPoint position, float delta){
	return CGPointMake(position.x + velocity.x * delta, position.y + velocity.y * delta);
}

-(void)tick:(float)dt {
	[self applyJoystick:leftJoystick toNode:leftPlayer forTimeDelta:dt];
	[self applyJoystick:rightJoystick toNode:rightPlayer forTimeDelta:dt];
}

-(void)applyJoystick:(SneakyJoystick *)aJoystick toNode:(CCNode *)aNode forTimeDelta:(float)dt
{
	// you can create a velocity specific to the node if you wanted, just supply a different multiplier
	// which will allow you to do a parallax scrolling of sorts
	CGPoint scaledVelocity = ccpMult(aJoystick.velocity, 480.0f); 
	
	// apply the scaled velocity to the position over delta
	aNode.position = applyVelocity(scaledVelocity, aNode.position, dt);
}

@end
