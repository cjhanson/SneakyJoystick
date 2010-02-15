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

#import "ccMacros.h"
#import "Grid.h"
#import "Texture2D.h"
#import "Director.h"
#import "Grabber.h"

#import "Support/glu.h"
#import "Support/CGPointExtension.h"

@implementation GridBase

@synthesize reuseGrid=reuseGrid_;
@synthesize texture=texture_;
@synthesize grabber=grabber_;
@synthesize gridSize=gridSize_;
@synthesize step=step_;

#define kTextureSize 512
-(id)initWithSize:(ccGridSize)gSize
{
	if ( (self = [super init] ) )
	{
		active_ = NO;
		reuseGrid_ = 0;
		gridSize_ = gSize;
		
		CGSize	win = [[Director sharedDirector] winSize];
	
		if ( texture_ == nil )
		{
			Texture2DPixelFormat format = [Director sharedDirector].pixelFormat == kPixelFormatRGB565 ? kTexture2DPixelFormat_RGB565 : kTexture2DPixelFormat_RGBA8888;
			
			void *data = malloc((int)(kTextureSize * kTextureSize * 4));
			memset(data, 0, (int)(kTextureSize * kTextureSize * 4));
			
			texture_ = [[Texture2D alloc] initWithData:data pixelFormat:format pixelsWide:kTextureSize pixelsHigh:kTextureSize contentSize:win];
			free( data );
		}
		
		grabber_ = [[Grabber alloc] init];
		[grabber_ grab:self.texture];

		step_.x = win.width / gridSize_.x;
		step_.y = win.height / gridSize_.y;
	}
	
	return self;
}
- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %08X | Dimensions = %ix%i>", [self class], self, gridSize_.x, gridSize_.y];
}

- (void) dealloc
{
	CCLOG(@"cocos2d: deallocing %@", self);

	[self setActive: NO];

	[texture_ release];
	[grabber_ release];
	[super dealloc];
}

// properties
-(BOOL) active
{
	return active_;
}

-(void) setActive:(BOOL)active
{
	active_ = active;
	if( ! active ) {
		Director *director = [Director sharedDirector];
		ccDirectorProjection proj = [director projection];
		[director setProjection:proj];
	}
}

// This routine can be merged with Director
-(void)applyLandscape
{
	ccDeviceOrientation orientation  = [[Director sharedDirector] deviceOrientation];

	switch (orientation) {
		case CCDeviceOrientationLandscapeLeft:
			glTranslatef(160,240,0);
			glRotatef(-90,0,0,1);
			glTranslatef(-240,-160,0);
			break;
		case CCDeviceOrientationLandscapeRight:
			glTranslatef(160,240,0);
			glRotatef(90,0,0,1);
			glTranslatef(-240,-160,0);
			break;
		case CCDeviceOrientationPortraitUpsideDown:
			glTranslatef(160,240,0);
			glRotatef(180,0,0,1);
			glTranslatef(-160,-240,0);
			break;
		default:
			break;
	}
}

-(void)set2DProjection
{
	CGSize	winSize = [[Director sharedDirector] winSize];
	
	glLoadIdentity();
	glViewport(0, 0, winSize.width, winSize.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, winSize.width, 0, winSize.height, -100, 100);
	glMatrixMode(GL_MODELVIEW);
}

// This routine can be merged with Director
-(void)set3DProjection
{
	CGSize	winSize = [[Director sharedDirector] displaySize];
	
	glViewport(0, 0, winSize.width, winSize.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(60, (GLfloat)winSize.width/winSize.height, 0.5f, 1500.0f);
	
	glMatrixMode(GL_MODELVIEW);	
	glLoadIdentity();
	gluLookAt( winSize.width/2, winSize.height/2, [Camera getZEye],
			  winSize.width/2, winSize.height/2, 0,
			  0.0f, 1.0f, 0.0f
			  );
}

-(void)beforeDraw
{
	[self set2DProjection];
	[grabber_ beforeRender:self.texture];
}

-(void)afterDraw:(Camera *)camera
{
	[grabber_ afterRender:self.texture];
	
	[self set3DProjection];
	[self applyLandscape];

	BOOL cDirty = camera.dirty;
	camera.dirty = YES;
	[camera locate];
	camera.dirty = cDirty;
		
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, self.texture.name);
	
	[self blit];
	
	glDisable(GL_TEXTURE_2D);
}

-(void)blit
{
	[NSException raise:@"GridBase" format:@"Abstract class needs implementation"];
}

-(void)reuse
{
	[NSException raise:@"GridBase" format:@"Abstract class needs implementation"];
}

@end

////////////////////////////////////////////////////////////

@implementation Grid3D

+(id)gridWithSize:(ccGridSize)gridSize
{
	return [[[Grid3D alloc] initWithSize:gridSize] autorelease];
}

-(id)initWithSize:(ccGridSize)gSize
{
	if ( (self = [super initWithSize:gSize] ) )
	{
		[self calculateVertexPoints];
	}
	
	return self;
}

-(void)dealloc
{
	free(texCoordinates);
	free(vertices);
	free(indices);
	free(originalVertices);
	[super dealloc];
}

-(void)blit
{
	int n = gridSize_.x * gridSize_.y;
	
	glEnableClientState( GL_VERTEX_ARRAY);
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoordinates);
	glDrawElements(GL_TRIANGLES, n*6, GL_UNSIGNED_SHORT, indices);
	
	glDisableClientState(GL_VERTEX_ARRAY );
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );
}

-(void)calculateVertexPoints
{
	float width = (float)self.texture.pixelsWide;
	float height = (float)self.texture.pixelsHigh;
	
	int x, y, i;
	
	vertices = malloc((gridSize_.x+1)*(gridSize_.y+1)*sizeof(ccVertex3F));
	originalVertices = malloc((gridSize_.x+1)*(gridSize_.y+1)*sizeof(ccVertex3F));
	texCoordinates = malloc((gridSize_.x+1)*(gridSize_.y+1)*sizeof(CGPoint));
	indices = malloc(gridSize_.x*gridSize_.y*sizeof(GLushort)*6);
	
	float *vertArray = (float*)vertices;
	float *texArray = (float*)texCoordinates;
	GLushort *idxArray = (GLushort *)indices;
	
	for( y = 0; y < (gridSize_.y+1); y++ )
	{
		for( x = 0; x < (gridSize_.x+1); x++ )
		{
			int idx = (y * (gridSize_.x+1)) + x;
			
			vertArray[idx*3] = -1;
			vertArray[idx*3+1] = -1;
			vertArray[idx*3+2] = -1;
			texArray[idx*2] = -1;
			texArray[idx*2+1] = -1;
		}
	}
	
	for( x = 0; x < gridSize_.x; x++ )
	{
		for( y = 0; y < gridSize_.y; y++ )
		{
			int idx = (y * gridSize_.x) + x;
			
			float x1 = x * step_.x;
			float x2 = x1 + step_.x;
			float y1 = y * step_.y;
			float y2 = y1 + step_.y;
			
			GLushort a = x * (gridSize_.y+1) + y;
			GLushort b = (x+1) * (gridSize_.y+1) + y;
			GLushort c = (x+1) * (gridSize_.y+1) + (y+1);
			GLushort d = x * (gridSize_.y+1) + (y+1);
			
			GLushort	tempidx[6] = { a, b, d, b, c, d };
			
			memcpy(&idxArray[6*idx], tempidx, 6*sizeof(GLushort));
			
			int l1[4] = { a*3, b*3, c*3, d*3 };
			ccVertex3F	e = {x1,y1,0};
			ccVertex3F	f = {x2,y1,0};
			ccVertex3F	g = {x2,y2,0};
			ccVertex3F	h = {x1,y2,0};
			
			ccVertex3F l2[4] = { e, f, g, h };
			
			int tex1[4] = { a*2, b*2, c*2, d*2 };
			CGPoint tex2[4] = { ccp(x1,y1), ccp(x2,y1), ccp(x2,y2), ccp(x1,y2) };
			
			for( i = 0; i < 4; i++ )
			{
				vertArray[ l1[i] ] = l2[i].x;
				vertArray[ l1[i] + 1 ] = l2[i].y;
				vertArray[ l1[i] + 2 ] = l2[i].z;
				
				texArray[ tex1[i] ] = tex2[i].x / width;
				texArray[ tex1[i] + 1 ] = tex2[i].y / height;
			}
		}
	}
	
	memcpy(originalVertices, vertices, (gridSize_.x+1)*(gridSize_.y+1)*sizeof(ccVertex3F));
}

-(ccVertex3F)vertex:(ccGridSize)pos
{
	int	index = (pos.x * (gridSize_.y+1) + pos.y) * 3;
	float *vertArray = (float *)vertices;
	
	ccVertex3F	vert = { vertArray[index], vertArray[index+1], vertArray[index+2] };
	
	return vert;
}

-(ccVertex3F)originalVertex:(ccGridSize)pos
{
	int	index = (pos.x * (gridSize_.y+1) + pos.y) * 3;
	float *vertArray = (float *)originalVertices;
	
	ccVertex3F	vert = { vertArray[index], vertArray[index+1], vertArray[index+2] };
	
	return vert;
}

-(void)setVertex:(ccGridSize)pos vertex:(ccVertex3F)vertex
{
	int	index = (pos.x * (gridSize_.y+1) + pos.y) * 3;
	float *vertArray = (float *)vertices;
	vertArray[index] = vertex.x;
	vertArray[index+1] = vertex.y;
	vertArray[index+2] = vertex.z;
}

-(void)reuse
{
	if ( reuseGrid_ > 0 )
	{
		memcpy(originalVertices, vertices, (gridSize_.x+1)*(gridSize_.y+1)*sizeof(ccVertex3F));
		reuseGrid_--;
	}
}

@end

////////////////////////////////////////////////////////////

@implementation TiledGrid3D

+(id)gridWithSize:(ccGridSize)gridSize
{
	return [[[TiledGrid3D alloc] initWithSize:gridSize] autorelease];
}

-(id)initWithSize:(ccGridSize)gSize
{
	if ( (self = [super initWithSize:gSize] ) )
	{
		[self calculateVertexPoints];
	}
	
	return self;
}

-(void)dealloc
{
	free(texCoordinates);
	free(vertices);
	free(indices);
	free(originalVertices);
	[super dealloc];
}

-(void)blit
{
	int n = gridSize_.x * gridSize_.y;
	
	glEnableClientState( GL_VERTEX_ARRAY);
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoordinates);
	glDrawElements(GL_TRIANGLES, n*6, GL_UNSIGNED_SHORT, indices);
	
	glDisableClientState(GL_VERTEX_ARRAY );
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );
}

-(void)calculateVertexPoints
{
	float width = (float)self.texture.pixelsWide;
	float height = (float)self.texture.pixelsHigh;
	
	int numQuads = gridSize_.x * gridSize_.y;
	
	vertices = malloc(numQuads*12*sizeof(GLfloat));
	originalVertices = malloc(numQuads*12*sizeof(GLfloat));
	texCoordinates = malloc(numQuads*8*sizeof(GLfloat));
	indices = malloc(numQuads*6*sizeof(GLushort));
	
	float *vertArray = (float*)vertices;
	float *texArray = (float*)texCoordinates;
	GLushort *idxArray = (GLushort *)indices;
	
	int x, y;
	
	for( x = 0; x < gridSize_.x; x++ )
	{
		for( y = 0; y < gridSize_.y; y++ )
		{
			float x1 = x * step_.x;
			float x2 = x1 + step_.x;
			float y1 = y * step_.y;
			float y2 = y1 + step_.y;
			
			*vertArray++ = x1;
			*vertArray++ = y1;
			*vertArray++ = 0;
			*vertArray++ = x2;
			*vertArray++ = y1;
			*vertArray++ = 0;
			*vertArray++ = x1;
			*vertArray++ = y2;
			*vertArray++ = 0;
			*vertArray++ = x2;
			*vertArray++ = y2;
			*vertArray++ = 0;
			
			*texArray++ = x1 / width;
			*texArray++ = y1 / height;
			*texArray++ = x2 / width;
			*texArray++ = y1 / height;
			*texArray++ = x1 / width;
			*texArray++ = y2 / height;
			*texArray++ = x2 / width;
			*texArray++ = y2 / height;
		}
	}
	
	for( x = 0; x < numQuads; x++)
	{
		idxArray[x*6+0] = x*4+0;
		idxArray[x*6+1] = x*4+1;
		idxArray[x*6+2] = x*4+2;
		
		idxArray[x*6+3] = x*4+1;
		idxArray[x*6+4] = x*4+2;
		idxArray[x*6+5] = x*4+3;
	}
	
	memcpy(originalVertices, vertices, numQuads*12*sizeof(GLfloat));
}

-(void)setTile:(ccGridSize)pos coords:(ccQuad3)coords
{
	int idx = (gridSize_.y * pos.x + pos.y) * 4 * 3;
	float *vertArray = (float*)vertices;
	memcpy(&vertArray[idx], &coords, sizeof(ccQuad3));
}

-(ccQuad3)originalTile:(ccGridSize)pos
{
	int idx = (gridSize_.y * pos.x + pos.y) * 4 * 3;
	float *vertArray = (float*)originalVertices;
	
	ccQuad3 ret;
	memcpy(&ret, &vertArray[idx], sizeof(ccQuad3));
	
	return ret;
}

-(ccQuad3)tile:(ccGridSize)pos
{
	int idx = (gridSize_.y * pos.x + pos.y) * 4 * 3;
	float *vertArray = (float*)vertices;
	
	ccQuad3 ret;
	memcpy(&ret, &vertArray[idx], sizeof(ccQuad3));
	
	return ret;
}

-(void)reuse
{
	if ( reuseGrid_ > 0 )
	{
		int numQuads = gridSize_.x * gridSize_.y;
		
		memcpy(originalVertices, vertices, numQuads*12*sizeof(GLfloat));
		reuseGrid_--;
	}
}

@end
