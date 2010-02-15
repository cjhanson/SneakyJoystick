//
// cocos2d Hello World example
// http://www.cocos2d-iphone.org
//

// Import the interfaces
#import "HelloWorldScene.h"

// HelloWorld implementation
@implementation HelloWorld

+(id) scene
{
	// 'scene' is an autorelease object.
	Scene *scene = [Scene node];
	
	// 'layer' is an autorelease object.
	HelloWorld *layer = [HelloWorld node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		
			// enable touch interaction
		self.isTouchEnabled = YES;
		
			// create and initialize a Label
		helloWorldLabel = [Label labelWithString:@"Hello World" fontName:@"Marker Felt" fontSize:64];
		
			// make a rect with the x/y position and width/height of the joystick
			// then create and initalize the joystick
		CGRect leftjoy = CGRectMake(0.0f, 0.0f, 128.0f, 128.0f);
		leftJoystick = [[[joystick alloc] initWithRect:leftjoy] retain];

			// ask director the the window size
		CGSize size = [[Director sharedDirector] winSize];
	
			// position the label on the center of the screen
		helloWorldLabel.position =  ccp( size.width /2 , size.height/2 );
		
			// add the label and joystick as children to this Layer
		[self addChild:helloWorldLabel];
		[self addChild:leftJoystick];
		
			// set animation interval to 60FPS, schedule a polling function at 120FPS
		[[Director sharedDirector] setAnimationInterval:1.0f/60.0f];
		[self schedule:@selector(tick:) interval:1.0f/120.0f];
	}
	return self;
}

	//function to scale the velocity
-(CGPoint)scaleVelocity:(CGPoint)velocity withScale:(float)scale{
	return CGPointMake(scale * velocity.x,scale * velocity.y);
}

	//function to apply a velocity to a position with delta
-(CGPoint)applyVelocity:(CGPoint)velocity toPosition:(CGPoint)position withDelta:(float)delta{
	return CGPointMake(position.x + velocity.x * delta, position.y + velocity.y * delta);
}

-(void)tick:(float)delta {
		// grab the velocity from leftJoystick
	CGPoint velocity = leftJoystick.velocity;
	
		// create a velocity specific to the label
		// you can make many of these using the same initial velocity to do a parallax scrolling of sorts
	CGPoint labelVelocity = [self scaleVelocity:velocity withScale:480.0f];
	
		// apply the scaled velocity to the position over delta
	labelVelocity = [self applyVelocity:labelVelocity toPosition:helloWorldLabel.position withDelta:delta];
	
		// set the position
	helloWorldLabel.position = labelVelocity;
}

	//you have to set up the events for each joystick you make
-(BOOL)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[leftJoystick touchesBegan:touches withEvent:event];
	return kEventHandled;
}

-(BOOL)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[leftJoystick touchesMoved:touches withEvent:event];
	return kEventHandled;
}

-(BOOL)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[leftJoystick touchesEnded:touches withEvent:event];
	return kEventHandled;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
