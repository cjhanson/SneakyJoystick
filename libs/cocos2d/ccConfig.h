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

/**
 @file
 cocos2d (cc) configuration file
*/

/**
 If enabled, FontLabel will be used to render .ttf files.
 If the .ttf file is not found, then it will use the standard UIFont class
 If disabled, the standard UIFont class will be used.
 */
#define CC_FONT_LABEL_SUPPORT	1

/**
 If enabled, the the FPS will be drawn using LabelAtlas (fast rendering).
 You will need to add the fps_images.png to your project.
 If disabled, the FPS will be rendered using Label (slow rendering)
 */
#define CC_DIRECTOR_FAST_FPS	1

/**
 If enabled, and only when it is used with FastDirector, the main loop will wait 0.04 seconds to
 dispatch all the events, even if there are not events to dispatch.
 If your game uses lot's of events (eg: touches) it might be a good idea to enable this feature.
 Otherwise, it is safe to leave it disabled.
 @warning This feature is experimental
 */
// #define CC_DIRECTOR_DISPATCH_FAST_EVENTS 1

/**
 If enabled, the CocosNode objects (Sprite,Label,etc) will be able to render in subpixels.
 If disabled, integer pixels will be used.
 */
#define CC_COCOSNODE_RENDER_SUBPIXEL 1

/**
 If enabled, the AtlasSprites will be able to render in subpixels.
 If disabled, integer pixels will be used.
 */
#define CC_ATLAS_SPRITE_RENDER_SUBPIXEL	1


/**
 If enabled, all subclasses of TextureNode will draw a bounding box
 Useful for debugging purposes only.
 It is recommened to leave it disabled.
 */
//#define CC_TEXTURENODE_DEBUG_DRAW 1

/**
 If enabled, all subclasses of BitmapFontAtlas will draw a bounding box
 Useful for debugging purposes only.
 It is recommened to leave it disabled.
 */
//#define CC_BITMAPFONTATLAS_DEBUG_DRAW 1

/**
 If enabled, all subclasses of LabeltAtlas will draw a bounding box
 Useful for debugging purposes only.
 It is recommened to leave it disabled.
 */
//#define CC_LABELATLAS_DEBUG_DRAW 1

/**
 If enabled, all subclasses of AtlasSprite will draw a bounding box
 Useful for debugging purposes only.
 It is recommened to leave it disabled.
 */
//#define CC_ATLASSPRITE_DEBUG_DRAW 1
