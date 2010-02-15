/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 * Copyright (C) 2008,2009 Ricardo Quesada
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the 'cocos2d for iPhone' license.
 *
 * You will find a copy of this license within the cocos2d for iPhone
 * distribution inside the "LICENSE" file.
 *
 */


#import "CameraAction.h"
#import "CocosNode.h"
#import "Camera.h"
#import "ccMacros.h"

//
// CameraAction
//
@implementation CameraAction
-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[[target camera] centerX:&centerXOrig centerY:&centerYOrig centerZ: &centerZOrig];
	[[target camera] eyeX:&eyeXOrig eyeY:&eyeYOrig eyeZ: &eyeZOrig];
	[[target camera] upX:&upXOrig upY:&upYOrig upZ: &upZOrig];
}

-(id) reverse
{
	return [ReverseTime actionWithAction:self];
}
@end

@implementation OrbitCamera
+(id) actionWithDuration:(float)t radius:(float)r deltaRadius:(float) dr angleZ:(float)z deltaAngleZ:(float)dz angleX:(float)x deltaAngleX:(float)dx
{
	return [[[self alloc] initWithDuration:t radius:r deltaRadius:dr angleZ:z deltaAngleZ:dz angleX:x deltaAngleX:dx] autorelease];
}

-(id) copyWithZone: (NSZone*) zone
{
	return [[[self class] allocWithZone: zone] initWithDuration:duration radius:radius deltaRadius:deltaRadius angleZ:angleZ deltaAngleZ:deltaAngleZ angleX:angleX deltaAngleX:deltaAngleX];
}


-(id) initWithDuration:(float)t radius:(float)r deltaRadius:(float) dr angleZ:(float)z deltaAngleZ:(float)dz angleX:(float)x deltaAngleX:(float)dx
{
	if(!(self=[super initWithDuration:t]) )
		return nil;
	
	radius = r;
	deltaRadius = dr;
	angleZ = z;
	deltaAngleZ = dz;
	angleX = x;
	deltaAngleX = dx;

	radDeltaZ = (CGFloat)CC_DEGREES_TO_RADIANS(dz);
	radDeltaX = (CGFloat)CC_DEGREES_TO_RADIANS(dx);
	
	return self;
}

-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	float r, zenith, azimuth;
	
	[self sphericalRadius: &r zenith:&zenith azimuth:&azimuth];
	if( isnan(radius) )
		radius = r;
	if( isnan(angleZ) )
		angleZ = (CGFloat)CC_RADIANS_TO_DEGREES(zenith);
	if( isnan(angleX) )
		angleX = (CGFloat)CC_RADIANS_TO_DEGREES(azimuth);

	radZ = (CGFloat)CC_DEGREES_TO_RADIANS(angleZ);
	radX = (CGFloat)CC_DEGREES_TO_RADIANS(angleX);
}

-(void) update: (ccTime) t
{
	float r = (radius + deltaRadius * t) *[Camera getZEye];
	float za = radZ + radDeltaZ * t;
	float xa = radX + radDeltaX * t;

	float i = sinf(za) * cosf(xa) * r + centerXOrig;
	float j = sinf(za) * sinf(xa) * r + centerYOrig;
	float k = cosf(za) * r + centerZOrig;

	[[target camera] setEyeX:i eyeY:j eyeZ:k];
}

-(void) sphericalRadius:(float*) newRadius zenith:(float*) zenith azimuth:(float*) azimuth
{
	float ex, ey, ez, cx, cy, cz, x, y, z;
	float r; // radius
	float s;
	
	[[target camera] eyeX:&ex eyeY:&ey eyeZ:&ez];
	[[target camera] centerX:&cx centerY:&cy centerZ:&cz];
	
	x = ex-cx;
	y = ey-cy;
	z = ez-cz;
	
	r = sqrtf( powf(x,2) + powf(y,2) + powf(z,2));
	s = sqrtf( powf(x,2) + powf(y,2));
	if(s==0.0f)
		s=0.00000001f;
	if(r==0.0f)
		r=0.00000001f;

	*zenith = acosf( z/r);
	if( x < 0 )
		*azimuth= (CGFloat)M_PI - asinf(y/s);
	else
		*azimuth = asinf(y/s);
					
	*newRadius = r / [Camera getZEye];					
}
@end
