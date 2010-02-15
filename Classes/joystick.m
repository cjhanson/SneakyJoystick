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

#import "joystick.h"
#import "Director.h"

@interface joystick(hidden)
- (void)updateVelocity:(CGPoint)point;
- (void)resetJoystick;
@end

@implementation joystick

@synthesize joystickRadius, thumbRadius, autoCenter, velocity, degrees;

static bool isPointInCircle(CGPoint point, CGPoint center, float radius) {
	float dx = (point.x - center.x);
	float dy = (point.y - center.y);
	return (radius >= sqrt( (dx * dx) + (dy * dy) ));
}

-(void)updateVelocity:(CGPoint)point {
		// Calculate distance and angle from the center.
	float dx = point.x - center.x;
	float dy = point.y - center.y;
	
	float distance = sqrt(dx * dx + dy * dy);
	float angle = atan2(dy, dx); // in radians
	
		// NOTE: Velocity goes from -1.0 to 1.0.
		// BE CAREFUL: don't just cap each direction at 1.0 since that
		// doesn't preserve the proportions.
	if (distance > joystickRadius) {
		dx = cos(angle) * joystickRadius;
		dy = sin(angle) *  joystickRadius;
	}
	
	velocity = CGPointMake(dx/joystickRadius, dy/joystickRadius);
	degrees = angle * (180/3.14);
	
		// Constrain the thumb so that it stays within the joystick
		// boundaries.  This is smaller than the joystick radius in
		// order to account for the size of the thumb.
	if (distance > thumbRadius) {
		point.x = center.x + cos(angle) * thumbRadius;
		point.y = center.y + sin(angle) * thumbRadius;
	}
	
		// Update the thumb's position
	[thumb setPosition:point];
}

- (void)resetJoystick {
	[self updateVelocity:center];
}

-(id)initWithRect:(CGRect)rect{
	self = [super init];
	if(self){
		self.isTouchEnabled = YES;
		velocity = CGPointZero;
		autoCenter = YES;
		joystickRadius = 64.0f;
		thumbRadius = 32.0f;
		bounds = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
		center = CGPointMake(((rect.size.width/2)+rect.origin.x), ((rect.size.height/2)+rect.origin.y));
		curPosition = center;
		active = NO;
		
		background = [Sprite spriteWithFile:@"128_white.png"];
		[background setPosition:center];
		[self addChild:background z:0];
		
		thumb = [Sprite spriteWithFile:@"64_white.png"];
		[thumb setPosition:center];
		[self addChild:thumb z:1];
	}
	return self;
}

-(bool)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	if (active)
		return NO;
	NSArray *allTouches = [touches allObjects];
	for(UITouch* t in allTouches){
		CGPoint location = [[Director sharedDirector] convertToGL:[t locationInView:[t view]]];
		if (isPointInCircle(location, center, joystickRadius)){
			active = YES;
			touchAddress = (int)t;
			curPosition = CGPointMake(location.x, location.y);
			[self updateVelocity:curPosition];
			return YES;
		}
	}
	return NO;
}

-(bool)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	if(!active)
		return NO;
	NSArray *allTouches = [touches allObjects];
	for (UITouch* t in allTouches){
		if ((int)t == touchAddress){
			curPosition = [[Director sharedDirector] convertToGL:[t locationInView:[t view]]];
			[self updateVelocity:curPosition];
			return YES;
		}
	}
	return NO;
}

-(bool)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if(!active)
		return NO;
	NSArray *allTouches = [touches allObjects];
	for (UITouch* t in allTouches){
		if ((int)t == touchAddress){
			active = NO;
			if (autoCenter){
				curPosition = center;
			}
			[self updateVelocity:curPosition];
			return YES;
		}
	}
	return NO;
}

@end
