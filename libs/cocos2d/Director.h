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


//
#import "ccConfig.h"
#import "ccTypes.h"

// OpenGL related
#import "Support/EAGLView.h"

/** Possible Pixel Formats for the EAGLView */
typedef enum {
	/** RGB565 pixel format. No alpha. 16-bit. (Default) */
	kPixelFormatRGB565,
	/** RGBA format. 32-bit. Needed for some 3D effects. It is not as fast as the RGB565 format. */
	kPixelFormatRGBA8888,
	/** default pixel format */
	kPixelFormatDefault = kPixelFormatRGB565,

	kRGB565 = kPixelFormatRGB565,
	kRGBA8 = kPixelFormatRGBA8888,
} tPixelFormat;

/** Possible DepthBuffer Formats for the EAGLView.
 Use 16 or 24 bit depth buffers if you are going to use real 3D objects.
 */
typedef enum {
	/// A Depth Buffer of 0 bits will be used (default)
	kDepthBufferNone,
	/// A depth buffer of 16 bits will be used
	kDepthBuffer16,
	/// A depth buffer of 24 bits will be used
	kDepthBuffer24,
} tDepthBufferFormat;

/** Possible OpenGL projections used by director */
typedef enum {
	/// sets a 2D projection (orthogonal projection)
	CCDirectorProjection2D,
	
	/// sets a 3D projection with a fovy=60, znear=0.5f and zfar=1500.
	CCDirectorProjection3D,
	
	/// it does nothing. But if you are using a custom projection set it this value.
	CCDirectorProjectionCustom,
	
	/// Detault projection is 3D projection
	CCDirectorProjectionDefault = CCDirectorProjection3D,

} ccDirectorProjection;

/** Possible Director Types.
 @since v0.8.2
 */
typedef enum {
	/** Will use a Director that triggers the main loop from an NSTimer object
	 *
	 * Features and Limitations:
	 * - Integrates OK with UIKit objects
	 * - It the slowest director
	 * - The invertal update is customizable from 1 to 60
	 */
	CCDirectorTypeNSTimer,
	
	/** will use a Director that triggers the main loop from a custom main loop.
	 *
	 * Features and Limitations:
	 * - Faster than NSTimer Director
	 * - It doesn't integrate well with UIKit objecgts
	 * - The interval update can't be customizable
	 */
	CCDirectorTypeMainLoop,
	
	/** Will use a Director that triggers the main loop from a thread, but the main loop will be executed on the main thread.
	 *
	 * Features and Limitations:
	 * - Faster than NSTimer Director
	 * - It doesn't integrate well with UIKit objecgts
	 * - The interval update can't be customizable
	 */
	CCDirectorTypeThreadMainLoop,
	
	/** Will use a Director that synchronizes timers with the refresh rate of the display.
	 *
	 * Features and Limitations:
	 * - Faster than NSTimer Director
	 * - Only available on 3.1+
	 * - Scheduled timers & drawing are synchronizes with the refresh rate of the display
	 * - Integrates OK with UIKit objects
	 * - The interval update can be 1/60, 1/30, 1/15
	 */	
	CCDirectorTypeDisplayLink,
	
	/** Default director is the NSTimer directory */
	CCDirectorTypeDefault = CCDirectorTypeNSTimer,

} ccDirectorType;

/** Possible device orientations */
typedef enum {
	/// Device oriented vertically, home button on the bottom
	CCDeviceOrientationPortrait = UIDeviceOrientationPortrait,	
	/// Device oriented vertically, home button on the top
    CCDeviceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
	/// Device oriented horizontally, home button on the right
    CCDeviceOrientationLandscapeLeft = UIDeviceOrientationLandscapeLeft,
	/// Device oriented horizontally, home button on the left
    CCDeviceOrientationLandscapeRight = UIDeviceOrientationLandscapeRight,
} ccDeviceOrientation;

@class LabelAtlas;
@class Scene;

/**Class that creates and handle the main Window and manages how
and when to execute the Scenes.
*/
@interface Director : NSObject
{
	EAGLView	*openGLView_;

	// internal timer
	NSTimeInterval animationInterval;
	NSTimeInterval oldAnimationInterval;

	tPixelFormat pixelFormat_;
	tDepthBufferFormat depthBufferFormat_;

	/* landscape mode ? */
	BOOL landscape;
	
	/* orientation */
	ccDeviceOrientation	deviceOrientation_;
	
	/* display FPS ? */
	BOOL displayFPS;
	int frames;
	ccTime accumDt;
	ccTime frameRate;
#if	CC_DIRECTOR_FAST_FPS
	LabelAtlas *FPSLabel;
#endif
	
	/* is the running scene paused */
	BOOL isPaused_;
	
	/* The running scene */
	Scene *runningScene_;
	
	/* will be the next 'runningScene' in the next frame
	 nextScene is a weak reference. */
	Scene *nextScene;

	/* scheduled scenes */
	NSMutableArray *scenesStack_;
	
	/* last time the main loop was updated */
	struct timeval lastUpdate;
	/* delta time since last tick to main loop */
	ccTime dt;
	/* whether or not the next delta time will be zero */
	BOOL nextDeltaTimeZero_;
	
	/* projection used */
	ccDirectorProjection projection_;
}

/** The current running Scene. Director can only run one Scene at the time */
@property (nonatomic,readonly) Scene* runningScene;
/** The FPS value */
@property (nonatomic,readwrite, assign) NSTimeInterval animationInterval;
/** Whether or not to display the FPS on the bottom-left corner */
@property (nonatomic,readwrite, assign) BOOL displayFPS;
/** The OpenGL view */
@property (nonatomic,readonly) EAGLView *openGLView;
/** Pixel format used to create the context */
@property (nonatomic,readonly) tPixelFormat pixelFormat;
/** whether or not the next delta time will be zero */
@property (nonatomic,readwrite,assign) BOOL nextDeltaTimeZero;
/** The device orientattion */
@property (nonatomic,readwrite) ccDeviceOrientation deviceOrientation;
/** Whether or not the Director is paused */
@property (nonatomic,readonly) BOOL isPaused;
/** Sets an OpenGL projection
 @since v0.8.2
 */
@property (nonatomic,readwrite) ccDirectorProjection projection;

/** returns a shared instance of the director */
+(Director *)sharedDirector;

/** Uses a Director that triggers the main loop as fast as it can.
 * To use it, it must be called before calling any director function
 * Features and Limitations:
 *  - Faster than "normal" director
 *  - Consumes more battery than the "normal" director
 *  - It has some issues while using UIKit objects
 *
 * @deprecated Use [Director setDirectorType:CCDirectorTypeMainLoop] instead. Will be removed in v0.9
 */
+(void) useFastDirector __attribute__ ((deprecated));

/** There are 4 types of Director.
 - CCDirectorTypeNSTimer (default)
 - CCDirectorTypeMainLoop
 - CCDirectorTypeThreadMainLoop
 - CCDirectorTypeDisplayLink
 
 Each Director has it's own benefits, limitations.
 If you are using SDK 3.1 or newer it is recommed to use the DisplayLink director
 
 This method should be called before any other call to the director.

 It will return NO if the director type is CCDirectorTypeDisplayLink and the running SDK is < 3.1. Otherwise it will return YES.
 
 @since v0.8.2
 */
+(BOOL) setDirectorType:(ccDirectorType) directorType;


// iPhone Specific

/** change default pixel format.
 Call this class method before attaching it to a UIWindow/UIView
 Default pixel format: kRGB565. Supported pixel formats: kRGBA8 and kRGB565
 */
-(void) setPixelFormat: (tPixelFormat) p;

/** change depth buffer format.
 Call this class method before attaching it to a UIWindow/UIView
 Default depth buffer: 0 (none).  Supported: kDepthBufferNone, kDepthBuffer16, and kDepthBuffer24
 */
-(void) setDepthBufferFormat: (tDepthBufferFormat) db;

// Integration with UIKit
/** detach the cocos2d view from the view/window */
-(BOOL)detach;

/** attach in UIWindow using the full frame */
-(BOOL)attachInWindow:(UIWindow *)window;

/** attach in UIView using the full frame */
-(BOOL)attachInView:(UIView *)view;

/** attach in UIView using the given frame */
-(BOOL)attachInView:(UIView *)view withFrame:(CGRect)frame;

// Landscape

/** returns the size of the OpenGL view according to the landspace */
- (CGSize) winSize;
/** returns the display size of the OpenGL view */
-(CGSize) displaySize;

/** returns whether or not the screen is in landscape mode
 @deprecated Use deviceOrientation instead. This method will be removed in v0.9
 */
- (BOOL) landscape __attribute__((deprecated));
/** sets lanscape mode
 @deprecated Use setDeviceOrientation: instead. This method will be removedin v0.9
 */
- (void) setLandscape: (BOOL) on __attribute__((deprecated));

/** converts a UIKit coordinate to an OpenGL coordinate
 Useful to convert (multi) touchs coordinates to the current layout (portrait or landscape).
 @deprecated Use convertToGL: instead. This method will be removed in v0.9
 */
-(CGPoint) convertCoordinate: (CGPoint) p __attribute__((deprecated));

/** converts a UIKit coordinate to an OpenGL coordinate
 Useful to convert (multi) touchs coordinates to the current layout (portrait or landscape)
 */
-(CGPoint) convertToGL: (CGPoint) p;
/** converts an OpenGL coordinate to a UIKit coordinate
 Useful to convert node points to window points for calls such as glScissor
 */
-(CGPoint) convertToUI:(CGPoint)p;

// Scene Management

/**Enters the Director's main loop with the given Scene. 
 * Call it to run only your FIRST scene.
 * Don't call it if there is already a running scene.
 */
- (void) runWithScene:(Scene*) scene;

/**Suspends the execution of the running scene, pushing it on the stack of suspended scenes.
 * The new scene will be executed.
 * Try to avoid big stacks of pushed scenes to reduce memory allocation. 
 * ONLY call it if there is a running scene.
 */
- (void) pushScene:(Scene*) scene;

/**Pops out a scene from the queue.
 * This scene will replace the running one.
 * The running scene will be deleted. If there are no more scenes in the stack the execution is terminated.
 * ONLY call it if there is a running scene.
 */
- (void) popScene;

/** Replaces the running scene with a new one. The running scene is terminated.
 * ONLY call it if there is a running scene.
 */
-(void) replaceScene: (Scene*) scene;

/** Ends the execution, releases the running scene */
-(void) end;

/** Pauses the running scene.
 The running scene will be _drawed_ but all scheduled timers will be paused
 While paused, the draw rate will be 4 FPS to reduce CPU consuption
 */
-(void) pause;

/** Resumes the paused scene
 The scheduled timers will be activated again.
 The "delta time" will be 0 (as if the game wasn't paused)
 */
-(void) resume;

/** Stops the animation. Nothing will be drawn. The main loop won't be triggered anymore.
 If you wan't to pause your animation call [pause] instead.
 */
-(void) stopAnimation;

/** The main loop is triggered again.
 Call this function only if [stopAnimation] was called earlier
 @warning Dont' call this function to start the main loop. To run the main loop call runWithScene
 */
-(void) startAnimation;


// OpenGL Helper

/** enables/disables OpenGL alpha blending */
- (void) setAlphaBlending: (BOOL) on;
/** enables/disables OpenGL depth test */
- (void) setDepthTest: (BOOL) on;
/** enables/disables OpenGL texture 2D */
- (void) setTexture2D: (BOOL) on;
/** sets cocos2d OpenGL default projection
 @deprecated Used Director#setProjection:CCDirectorProjectionDefault instead. This method will be removed in v0.9
 */
- (void) setDefaultProjection __attribute__ ((deprecated));
/** sets a 2D projection (orthogonal projection)
 @deprecated Used Director#setProjection:CCDirectorProjection2D instead. This method will be removed in v0.9
 */
-(void) set2Dprojection __attribute__ ((deprecated));
/** sets a 3D projection with a fovy=60, znear=0.5f and zfar=1500.
 @deprecated Used Director#setProjection:CCDirectorProjection3D instead. This method will be removed in v0.9
 */
-(void) set3Dprojection __attribute__ ((deprecated));
@end

/** FastDirector is a Director that triggers the main loop as fast as possible.
 *
 * Features and Limitations:
 *  - Faster than "normal" director
 *  - Consumes more battery than the "normal" director
 *  - It has some issues while using UIKit objects
 */
@interface FastDirector : Director
{
	BOOL isRunning;
	
	NSAutoreleasePool	*autoreleasePool;
}
-(void) preMainLoop;
@end

/** ThreadedFastDirector is a Director that triggers the main loop from a thread.
 *
 * Features and Limitations:
 *  - Faster than "normal" director
 *  - Consumes more battery than the "normal" director
 *  - It can be used with UIKit objects
 *
 * @since v0.8.2
 */
@interface ThreadedFastDirector : Director
{
	BOOL isRunning;	
}
-(void) preMainLoop;
@end

/** DisplayLinkDirector is a Director that synchronizes timers with the refresh rate of the display.
 *
 * Features and Limitations:
 * - Only available on 3.1+
 * - Scheduled timers & drawing are synchronizes with the refresh rate of the display
 * - Only supports animation intervals of 1/60 1/30 & 1/15
 *
 * It is the recommended Director if the SDK is 3.1 or newer
 *
 * @since v0.8.2
 */
@interface DisplayLinkDirector : Director
{
	id displayLink;
}
@end

/** TimerDirector is a Director that calls the main loop from an NSTimer object
 *
 * Features and Limitations:
 * - Integrates OK with UIKit objects
 * - It the slowest director
 * - The invertal update is customizable from 1 to 60
 *
 * It is the default Director.
 */
@interface TimerDirector : Director
{
	NSTimer *animationTimer;
}
@end

