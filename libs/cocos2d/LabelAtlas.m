/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 * Copyright (C) 2008 Ricardo Quesada
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the 'cocos2d for iPhone' license.
 *
 * You will find a copy of this license within the cocos2d for iPhone
 * distribution inside the "LICENSE" file.
 *
 */

#import "ccConfig.h"
#import "ccMacros.h"
#import "DrawingPrimitives.h"
#import "LabelAtlas.h"
#import "Support/CGPointExtension.h"



@implementation LabelAtlas

#pragma mark LabelAtlas - Creation & Init
+(id) labelAtlasWithString:(NSString*)string charMapFile:(NSString*)charmapfile itemWidth:(int)w itemHeight:(int)h startCharMap:(char)c
{
	return [[[self alloc] initWithString:string charMapFile:charmapfile itemWidth:w itemHeight:h startCharMap:c] autorelease];
}


-(id) initWithString:(NSString*) theString charMapFile: (NSString*) charmapfile itemWidth:(int)w itemHeight:(int)h startCharMap:(char)c
{

	if ((self=[super initWithTileFile:charmapfile tileWidth:w tileHeight:h itemsToRender:[theString length] ]) ) {

		mapStartChar = c;		
		[self setString: theString];
	}

	return self;
}

-(void) dealloc
{
	[string_ release];

	[super dealloc];
}

#pragma mark LabelAtlas - Atlas generation

-(void) updateAtlasValues
{
	int n = [string_ length];
	
	ccV3F_C4B_T2F_Quad quad;

	const char *s = [string_ UTF8String];

	for( int i=0; i<n; i++) {
		unsigned char a = s[i] - mapStartChar;
		float row = (a % itemsPerRow) * texStepX;
		float col = (a / itemsPerRow) * texStepY;
		
		quad.tl.texCoords.u = row;
		quad.tl.texCoords.v = col;
		quad.tr.texCoords.u = row + texStepX;
		quad.tr.texCoords.v = col;
		quad.bl.texCoords.u = row;
		quad.bl.texCoords.v = col + texStepY;
		quad.br.texCoords.u = row + texStepX;
		quad.br.texCoords.v = col + texStepY;
		
		quad.bl.vertices.x = (int) (i * itemWidth);
		quad.bl.vertices.y = 0;
		quad.bl.vertices.z = 0.0f;
		quad.br.vertices.x = (int)(i * itemWidth + itemWidth);
		quad.br.vertices.y = 0;
		quad.br.vertices.z = 0.0f;
		quad.tl.vertices.x = (int)(i * itemWidth);
		quad.tl.vertices.y = (int)(itemHeight);
		quad.tl.vertices.z = 0.0f;
		quad.tr.vertices.x = (int)(i * itemWidth + itemWidth);
		quad.tr.vertices.y = (int)(itemHeight);
		quad.tr.vertices.z = 0.0f;
		
		[textureAtlas_ updateQuad:&quad atIndex:i];
	}
}

#pragma mark LabelAtlas - CocosNodeLabel

- (void) setString:(NSString*) newString
{
	if( newString.length > textureAtlas_.totalQuads )
		[textureAtlas_ resizeCapacity: newString.length];

	[string_ release];
	string_ = [newString retain];
	[self updateAtlasValues];

	CGSize s;
	s.width = [string_ length] * itemWidth;
	s.height = itemHeight;
	[self setContentSize:s];
}

#pragma mark LabelAtlas - draw

// XXX: overriding draw from AtlasNode
- (void) draw
{
	glEnableClientState( GL_VERTEX_ARRAY);
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	
	glEnable( GL_TEXTURE_2D);
	
	glColor4ub( color_.r, color_.g, color_.b, opacity_);
	
	BOOL newBlend = NO;
	if( blendFunc_.src != CC_BLEND_SRC || blendFunc_.dst != CC_BLEND_DST ) {
		newBlend = YES;
		glBlendFunc( blendFunc_.src, blendFunc_.dst );
	}
	
	[textureAtlas_ drawNumberOfQuads: string_.length];
	
	if( newBlend )
		glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
	
	// is this chepear than saving/restoring color state ?
	glColor4ub( 255, 255, 255, 255);
	
	glDisable( GL_TEXTURE_2D);
	
	glDisableClientState(GL_VERTEX_ARRAY );
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );
	
#if CC_LABELATLAS_DEBUG_DRAW
	CGSize s = [self contentSize];
	CGPoint vertices[4]={
		ccp(0,0),ccp(s.width,0),
		ccp(s.width,s.height),ccp(0,s.height),
	};
	drawPoly(vertices, 4, YES);
#endif // CC_LABELATLAS_DEBUG_DRAW

}
@end
