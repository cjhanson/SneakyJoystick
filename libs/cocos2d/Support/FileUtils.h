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

#import <Foundation/Foundation.h>


/** Helper class to handle file operations */
@interface FileUtils : NSObject
{
}
/** converts a relative path to a full path */
+(NSString*) fullPathFromRelativePath:(NSString*) relPath;
@end
