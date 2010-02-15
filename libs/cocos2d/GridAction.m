/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 * Copyright (C) 2009 On-Core
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the 'cocos2d for iPhone' license.
 *
 * You will find a copy of this license within the cocos2d for iPhone
 * distribution inside the "LICENSE" file.
 *
 */

#import "GridAction.h"
#import "Director.h"

#pragma mark -
#pragma mark GridAction

@implementation GridAction

@synthesize gridSize;

+(id) actionWithSize:(ccGridSize)size duration:(ccTime)d
{
	return [[[self alloc] initWithSize:size duration:d ] autorelease];
}

-(id) initWithSize:(ccGridSize)gSize duration:(ccTime)d
{
	if ( (self = [super initWithDuration:d]) )
	{
		gridSize = gSize;
	}
	
	return self;
}

-(void)startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];

	GridBase *newgrid = [self grid];
	
	CocosNode *t = (CocosNode*) target;
	
	if ( t.grid && t.grid.reuseGrid > 0 )
	{
		if ( t.grid.active && t.grid.gridSize.x == gridSize.x && t.grid.gridSize.y == gridSize.y && [t.grid isKindOfClass:[newgrid class]] )
		{
			[t.grid reuse];
		}
		else
		{
			[NSException raise:@"GridBase" format:@"Cannot reuse grid"];
		}
	}
	else
	{
		if ( t.grid && t.grid.active )
			t.grid.active = NO;
		t.grid = newgrid;
		t.grid.active = YES;
	}	
}

-(GridBase *)grid
{
	[NSException raise:@"GridBase" format:@"Abstract class needs implementation"];
	return nil;
}

- (IntervalAction*) reverse
{
	return [ReverseTime actionWithAction:self];
}

-(id) copyWithZone: (NSZone*) zone
{
	GridAction *copy = [[[self class] allocWithZone:zone] initWithSize:gridSize duration:duration];
	return copy;
}
@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Grid3DAction

@implementation Grid3DAction

-(GridBase *)grid
{
	return [Grid3D gridWithSize:gridSize];
}

-(ccVertex3F)vertex:(ccGridSize)pos
{
	Grid3D *g = (Grid3D *)[target grid];
	return [g vertex:pos];
}

-(ccVertex3F)originalVertex:(ccGridSize)pos
{
	Grid3D *g = (Grid3D *)[target grid];
	return [g originalVertex:pos];
}

-(void)setVertex:(ccGridSize)pos vertex:(ccVertex3F)vertex
{
	Grid3D *g = (Grid3D *)[target grid];
	return [g setVertex:pos vertex:vertex];
}
@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark TiledGrid3DAction

@implementation TiledGrid3DAction

-(GridBase *)grid
{
	return [TiledGrid3D gridWithSize:gridSize];
}

-(ccQuad3)tile:(ccGridSize)pos
{
	TiledGrid3D *g = (TiledGrid3D *)[target grid];
	return [g tile:pos];
}

-(ccQuad3)originalTile:(ccGridSize)pos
{
	TiledGrid3D *g = (TiledGrid3D *)[target grid];
	return [g originalTile:pos];
}

-(void)setTile:(ccGridSize)pos coords:(ccQuad3)coords
{
	TiledGrid3D *g = (TiledGrid3D *)[target grid];
	[g setTile:pos coords:coords];
}

@end

////////////////////////////////////////////////////////////

@interface IntervalAction (Amplitude)
-(void)setAmplitudeRate:(CGFloat)amp;
-(CGFloat)getAmplitudeRate;
@end

@implementation IntervalAction (Amplitude)
-(void)setAmplitudeRate:(CGFloat)amp
{
	[NSException raise:@"IntervalAction (Amplitude)" format:@"Abstract class needs implementation"];
}

-(CGFloat)getAmplitudeRate
{
	[NSException raise:@"IntervalAction (Amplitude)" format:@"Abstract class needs implementation"];
	return 0;
}
@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark AccelDeccelAmplitude

@implementation AccelDeccelAmplitude

@synthesize rate;

+(id)actionWithAction:(Action*)action duration:(ccTime)d
{
	return [[[self alloc] initWithAction:action duration:d ] autorelease];
}

-(id)initWithAction:(Action *)action duration:(ccTime)d
{
	if ( (self = [super initWithDuration:d]) )
	{
		rate = 1.0f;
		other = [action retain];
	}
	
	return self;
}

-(void)dealloc
{
	[other release];
	[super dealloc];
}

-(void)startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[other startWithTarget:target];
}

-(void) update: (ccTime) time;
{
	float f = time*2;
	
	if (f > 1)
	{
		f -= 1;
		f = 1 - f;
	}
	
	[other setAmplitudeRate:powf(f, rate)];
	[other update:time];
}

- (IntervalAction*) reverse
{
	return [AccelDeccelAmplitude actionWithAction:[other reverse] duration:self.duration];
}

@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark AccelAmplitude

@implementation AccelAmplitude

@synthesize rate;

+(id)actionWithAction:(Action*)action duration:(ccTime)d
{
	return [[[self alloc] initWithAction:action duration:d ] autorelease];
}

-(id)initWithAction:(Action *)action duration:(ccTime)d
{
	if ( (self = [super initWithDuration:d]) )
	{
		rate = 1.0f;
		other = [action retain];
	}
	
	return self;
}

-(void)dealloc
{
	[other release];
	[super dealloc];
}

-(void)startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[other startWithTarget:target];
}

-(void) update: (ccTime) time;
{
	[other setAmplitudeRate:powf(time, rate)];
	[other update:time];
}

- (IntervalAction*) reverse
{
	return [AccelAmplitude actionWithAction:[other reverse] duration:self.duration];
}

@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark DeccelAmplitude

@implementation DeccelAmplitude

@synthesize rate;

+(id)actionWithAction:(Action*)action duration:(ccTime)d
{
	return [[[self alloc] initWithAction:action duration:d ] autorelease];
}

-(id)initWithAction:(Action *)action duration:(ccTime)d
{
	if ( (self = [super initWithDuration:d]) )
	{
		rate = 1.0f;
		other = [action retain];
	}
	
	return self;
}

-(void)dealloc
{
	[other release];
	[super dealloc];
}

-(void)startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[other startWithTarget:target];
}

-(void) update: (ccTime) time;
{
	[other setAmplitudeRate:powf((1-time), rate)];
	[other update:time];
}

- (IntervalAction*) reverse
{
	return [DeccelAmplitude actionWithAction:[other reverse] duration:self.duration];
}

@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark StopGrid

@implementation StopGrid

-(void)startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];

	if ( [[self target] grid] && [[[self target] grid] active] ) {
		[[[self target] grid] setActive: NO];
		
//		[[self target] setGrid: nil];
	}
}

@end

////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark ReuseGrid

@implementation ReuseGrid

+(id)actionWithTimes:(int)times
{
	return [[[self alloc] initWithTimes:times ] autorelease];
}

-(id)initWithTimes:(int)times
{
	if ( (self = [super init]) )
	{
		t = times;
	}
	
	return self;
}

-(void)startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];

	CocosNode *myTarget = (CocosNode*) [self target];
	if ( myTarget.grid && myTarget.grid.active )
		myTarget.grid.reuseGrid += t;
}

@end
