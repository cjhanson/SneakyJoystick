//
//  joystick.m
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

#import "SneakyJoystick.h"
#import "cocos2d.h"
#import "ColoredCircleSprite.h"

@interface SneakyJoystick(hidden)
- (void)updateVelocity:(CGPoint)point;
@end

@implementation SneakyJoystick

@synthesize joystickRadius, thumbRadius, autoCenter, velocity, degrees, isDPad, numberOfDirections;

- (void) dealloc
{
	[thumb release];
	[background release];
	[super dealloc];
}

-(id)initWithRect:(CGRect)rect
{
	self = [super init];
	if(self){
		position_ = rect.origin;
		velocity = CGPointZero;
		autoCenter = YES;
		joystickRadius = rect.size.width/2;
		thumbRadius = 32.0f;
		curPosition = CGPointZero;
		active = NO;
		isDPad = NO;
		numberOfDirections = 4;
		
		background = [[ColoredCircleSprite circleWithColor:ccc4(255, 0, 0, 128) radius:rect.size.width/2] retain];
		[self addChild:background z:0];
		
		thumb = [[ColoredCircleSprite circleWithColor:ccc4(255, 255, 255, 128) radius:thumbRadius] retain];
		[self addChild:thumb z:1];
	}
	return self;
}

- (void) onEnterTransitionDidFinish
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:YES];
}

- (void) onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
}

-(void)updateVelocity:(CGPoint)point {
	// Calculate distance and angle from the center.
	float dx = point.x;
	float dy = point.y;
	
	float joyRadSq = joystickRadius * joystickRadius;
	float thumbRadSq = thumbRadius * thumbRadius;
	float dSq = dx * dx + dy * dy;
	float angle = atan2f(dy, dx); // in radians
	
	// NOTE: Velocity goes from -1.0 to 1.0.
	// BE CAREFUL: don't just cap each direction at 1.0 since that
	// doesn't preserve the proportions.
	if (dSq > joyRadSq) {
		dx = cosf(angle) * joystickRadius;
		dy = sinf(angle) *  joystickRadius;
	}
	
	velocity = CGPointMake(dx/joystickRadius, dy/joystickRadius);
	degrees = angle * (180.0f/3.14159265359f);
	
	// Constrain the thumb so that it stays within the joystick
	// boundaries.  This is smaller than the joystick radius in
	// order to account for the size of the thumb.
	if (dSq > thumbRadSq) {
		point.x = cosf(angle) * thumbRadius;
		point.y = sinf(angle) * thumbRadius;
	}
	
	// Update the thumb's position
	[thumb setPosition:point];
}

- (void) setJoystickRadius:(float)r
{
	joystickRadius = r;
	background.radius = r;
}

- (void) setThumbRadius:(float)r
{
	thumbRadius = r;
	thumb.radius = r;
}

#pragma mark Touch Delegate

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(active)
		return NO;
	
	CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
	if([background containsPoint:[background convertToNodeSpace:location]]){
		active = YES;
		curPosition = [self convertToNodeSpace:location];
		[self updateVelocity:curPosition];
		[background setColor:ccc3(0, 255, 0)];
		return YES;
	}
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(!active)
		return;
	CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
	curPosition = [self convertToNodeSpace:location];
	[self updateVelocity:curPosition];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(!active)
		return;
	
	active = NO;
	if(autoCenter){
		curPosition = CGPointZero;
	}else{
		CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		curPosition = [self convertToNodeSpace:location];
	}
	[self updateVelocity:curPosition];
	[background setColor:ccc3(255, 0, 0)];
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self ccTouchEnded:touch withEvent:event];
}

@end
