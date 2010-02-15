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

#import "TileMapAtlas.h"
#import "ccMacros.h"
#import "Support/FileUtils.h"

@interface TileMapAtlas (Private)
-(void) loadTGAfile:(NSString*)file;
-(void) calculateItemsToRender;
-(void) updateAtlasValueAt:(ccGridSize)pos withValue:(ccColor3B)value withIndex:(int)idx;
@end


@implementation TileMapAtlas

@synthesize tgaInfo;

#pragma mark TileMapAtlas - Creation & Init
+(id) tileMapAtlasWithTileFile:(NSString*)tile mapFile:(NSString*)map tileWidth:(int)w tileHeight:(int)h
{
	return [[[self alloc] initWithTileFile:tile mapFile:map tileWidth:w tileHeight:h] autorelease];
}


-(id) initWithTileFile:(NSString*)tile mapFile:(NSString*)map tileWidth:(int)w tileHeight:(int)h
{
	[self loadTGAfile: map];
	[self calculateItemsToRender];

	if( (self=[super initWithTileFile:tile tileWidth:w tileHeight:h itemsToRender: itemsToRender]) ) {

		posToAtlasIndex = [[NSMutableDictionary dictionaryWithCapacity:itemsToRender] retain];

		[self updateAtlasValues];
		
		[self setContentSize: CGSizeMake(tgaInfo->width*itemWidth, tgaInfo->height*itemHeight)];
	}

	return self;
}

-(void) dealloc
{
	if( tgaInfo )
		tgaDestroy(tgaInfo);

	[posToAtlasIndex release];

	[super dealloc];
}

-(void) releaseMap
{
	if( tgaInfo )
		tgaDestroy(tgaInfo);
	tgaInfo = nil;

	[posToAtlasIndex release];
	posToAtlasIndex = nil;
}

-(void) calculateItemsToRender
{
	NSAssert( tgaInfo != nil, @"tgaInfo must be non-nil");

	itemsToRender = 0;
	for(int x=0;x < tgaInfo->width; x++ ) {
		for( int y=0; y < tgaInfo->height; y++ ) {
			ccColor3B *ptr = (ccColor3B*) tgaInfo->imageData;
			ccColor3B value = ptr[x + y * tgaInfo->width];
			if( value.r )
				itemsToRender++;
		}
	}
}

-(void) loadTGAfile:(NSString*)file
{
	NSAssert( file != nil, @"file must be non-nil");

	NSString *path = [FileUtils fullPathFromRelativePath:file ];

//	//Find the path of the file
//	NSBundle *mainBndl = [NSBundle mainBundle];
//	NSString *resourcePath = [mainBndl resourcePath];
//	NSString * path = [resourcePath stringByAppendingPathComponent:file];
	
	tgaInfo = tgaLoad( [path UTF8String] );
#if 1
	if( tgaInfo->status != TGA_OK ) {
		[NSException raise:@"TileMapAtlasLoadTGA" format:@"TileMapAtas cannot load TGA file"];
	}
#endif
}

#pragma mark TileMapAtlas - Atlas generation / updates

-(void) setTile:(ccColor3B) tile at:(ccGridSize) pos
{
	NSAssert( tgaInfo != nil, @"tgaInfo must not be nil");
	NSAssert( posToAtlasIndex != nil, @"posToAtlasIndex must not be nil");
	NSAssert( pos.x < tgaInfo->width, @"Invalid position.x");
	NSAssert( pos.y < tgaInfo->height, @"Invalid position.x");
	NSAssert( tile.r != 0, @"R component must be non 0");
	
	ccColor3B *ptr = (ccColor3B*) tgaInfo->imageData;
	ccColor3B value = ptr[pos.x + pos.y * tgaInfo->width];
	if( value.r == 0 ) {
		CCLOG(@"cocos2d: Value.r must be non 0.");
	} else {
		ptr[pos.x + pos.y * tgaInfo->width] = tile;
		
		// XXX: this method consumes a lot of memory
		// XXX: a tree of something like that shall be impolemented
		NSNumber *num = [posToAtlasIndex objectForKey: [NSString stringWithFormat:@"%d,%d", pos.x, pos.y]];
		[self updateAtlasValueAt:pos withValue:tile withIndex: [num integerValue]];
	}	
}

-(ccColor3B) tileAt:(ccGridSize) pos
{
	NSAssert( tgaInfo != nil, @"tgaInfo must not be nil");
	NSAssert( pos.x < tgaInfo->width, @"Invalid position.x");
	NSAssert( pos.y < tgaInfo->height, @"Invalid position.y");
	
	ccColor3B *ptr = (ccColor3B*) tgaInfo->imageData;
	ccColor3B value = ptr[pos.x + pos.y * tgaInfo->width];
	
	return value;	
}

-(void) updateAtlasValueAt:(ccGridSize)pos withValue:(ccColor3B)value withIndex:(int)idx
{
	ccV3F_C4B_T2F_Quad quad;

	int x = pos.x;
	int y = pos.y;
	float row = (value.r % itemsPerRow) * texStepX;
	float col = (value.r / itemsPerRow) * texStepY;

	quad.tl.texCoords.u = row;
	quad.tl.texCoords.v = col;
	quad.tr.texCoords.u = row + texStepX;
	quad.tr.texCoords.v = col;
	quad.bl.texCoords.u = row;
	quad.bl.texCoords.v = col + texStepY;
	quad.br.texCoords.u = row + texStepX;
	quad.br.texCoords.v = col + texStepY;

	quad.bl.vertices.x = (int) (x * itemWidth);
	quad.bl.vertices.y = (int) (y * itemHeight);
	quad.bl.vertices.z = 0.0f;
	quad.br.vertices.x = (int)(x * itemWidth + itemWidth);
	quad.br.vertices.y = (int)(y * itemHeight);
	quad.br.vertices.z = 0.0f;
	quad.tl.vertices.x = (int)(x * itemWidth);
	quad.tl.vertices.y = (int)(y * itemHeight + itemHeight);
	quad.tl.vertices.z = 0.0f;
	quad.tr.vertices.x = (int)(x * itemWidth + itemWidth);
	quad.tr.vertices.y = (int)(y * itemHeight + itemHeight);
	quad.tr.vertices.z = 0.0f;
	
	[textureAtlas_ updateQuad:&quad atIndex:idx];
}

-(void) updateAtlasValues
{
	NSAssert( tgaInfo != nil, @"tgaInfo must be non-nil");

	
	int total = 0;

	for(int x=0;x < tgaInfo->width; x++ ) {
		for( int y=0; y < tgaInfo->height; y++ ) {
			if( total < itemsToRender ) {
				ccColor3B *ptr = (ccColor3B*) tgaInfo->imageData;
				ccColor3B value = ptr[x + y * tgaInfo->width];
				
				if( value.r != 0 ) {
					[self updateAtlasValueAt:ccg(x,y) withValue:value withIndex:total];
					
					NSString *key = [NSString stringWithFormat:@"%d,%d", x,y];
					NSNumber *num = [NSNumber numberWithInt:total];
					[posToAtlasIndex setObject:num forKey:key];

					total++;
				}
			}
		}
	}
}
@end
