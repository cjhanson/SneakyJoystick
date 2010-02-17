//
// cocos2d Hello World example
// http://www.cocos2d-iphone.org
//

// Import the interfaces
#import "HelloWorldScene.h"
#import "ColoredCircleSprite.h"

@interface HelloWorld (privateMethods)
-(void)applyJoystick:(SneakyJoystick *)aJoystick toNode:(CCNode *)aNode forTimeDelta:(float)dt;
@end


// HelloWorld implementation
@implementation HelloWorld

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorld *layer = [HelloWorld node];
	
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
		leftJoystick = [[SneakyJoystick alloc] initWithRect:CGRectMake(100.0f+10, 100.0f+10, 200.0f, 200.0f)];
		[self addChild:leftJoystick];
		
		rightJoystick = [[SneakyJoystick alloc] initWithRect:CGRectMake(size.width - 75.0f-10, 75.0f+10, 150.0f, 150.0f)];
		rightJoystick.isDPad = YES;
		[self addChild:rightJoystick];
		
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
