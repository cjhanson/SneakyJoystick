/* CocosDenshion Sound Engine
 *
 * Copyright (C) 2009 Steve Oldmeadow
 *
 * For independent entities this program is free software; you can redistribute
 * it and/or modify it under the terms of the 'cocos2d for iPhone' license with
 * the additional proviso that 'cocos2D for iPhone' must be credited in a manner
 * that can be be observed by end users, for example, in the credits or during
 * start up. Failure to include such notice is deemed to be acceptance of a 
 * non independent license (see below).
 *
 * For the purpose of this software non independent entities are defined as 
 * those where the annual revenue of the entity employing, partnering, or 
 * affiliated in any way with the Licensee is greater than $250,000 USD annually.
 *
 * Non independent entities may license this software or a derivation of it
 * by a donation of $500 USD per application to the cocos2d for iPhone project. 
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 */

#import "CocosDenshion.h"
#import "CDOpenALSupport.h"
#import "ccMacros.h"

//Audio session interruption callback - used if sound engine is 
//handling audio session interruption automatically
extern void interruptionListenerCallback (void *inUserData, UInt32 interruptionState ) { 
	CDSoundEngine *controller = (CDSoundEngine *) inUserData; 
    if (interruptionState == kAudioSessionBeginInterruption) { 
        [controller audioSessionInterrupted]; 
    } else if (interruptionState == kAudioSessionEndInterruption) { 
        [controller audioSessionResumed]; 
    } 
} 

@implementation CDSoundEngine

@synthesize lastErrorCode, functioning, asynchLoadProgress;

/**
 * Internal method called during init
 */
- (BOOL) _initOpenAL
{
	//ALenum			error;
	context = NULL;
	ALCdevice		*newDevice = NULL;
	
	//_buffers = new ALuint[CD_MAX_BUFFERS];
	_buffers = (ALuint *)malloc( sizeof(_buffers[0]) * CD_MAX_BUFFERS );
	if(!_buffers) {
		CCLOG(@"Denshion: buffer memory allocation failed");
		return FALSE;
	}
	
	//_sources = new ALuint[CD_MAX_SOURCES];
	_sources = (ALuint *)malloc( sizeof(_sources[0]) * CD_MAX_SOURCES );
	if(!_sources) {
		CCLOG(@"Denshion: source memory allocation failed");
		return FALSE;
	}
	
	// Create a new OpenAL Device
	// Pass NULL to specify the system's default output device
	newDevice = alcOpenDevice(NULL);
	if (newDevice != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		context = alcCreateContext(newDevice, 0);
		if (context != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(context);
			
			//Don't want a distance model
			alDistanceModel(AL_NONE);
			
			// Create some OpenAL Buffer Objects
			alGenBuffers(CD_MAX_BUFFERS, _buffers);
			if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
				CCLOG(@"Denshion: Error Generating Buffers: %x", lastErrorCode);
				return FALSE;//No buffers
			}
			
			// Create some OpenAL Source Objects
			alGenSources(CD_MAX_SOURCES, _sources);
			if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
				CCLOG(@"Denshion: Error generating sources! %x\n", lastErrorCode);
				return FALSE;//No sources
			} 
			
		}
	} else {
		return FALSE;//No device
	}	
	alGetError();//Clear error
	return TRUE;
}

- (void) dealloc {
	ALCcontext	*currentContext = NULL;
    ALCdevice	*device = NULL;
	

	CCLOG(@"Denshion: Deallocing sound engine.");
	free(_bufferStates);
	free(_channelGroups);
	free(_sourceBufferAttachments);
	
	// Delete the Sources
    alDeleteSources(CD_MAX_SOURCES, _sources);
	if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: Error deleting sources! %x\n", lastErrorCode);
	} 
	// Delete the Buffers
    alDeleteBuffers(CD_MAX_BUFFERS, _buffers);
	if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: Error deleting buffers! %x\n", lastErrorCode);
	} 
	
	//Get active context
    currentContext = alcGetCurrentContext();
    //Get device for active context
    device = alcGetContextsDevice(currentContext);
    //Release context
    alcDestroyContext(currentContext);
    //Close device
    alcCloseDevice(device);
	
	free(_buffers);
	free(_sources);
	[super dealloc];
}	

/**
 * Call this initialiser if you want the sound engine to automatically handle audio session interruption.
 * If you are using the sound engine in conjunction with another audio api such as AVAudioPlayer or
 * AudioQueue then you probably do not want the sound engine to handle audio session interruption
 * for you.
 *
 * The audioSessionCategory should be one of the audio session category enumeration values such as
 * kAudioSessionCategory_AmbientSound. Your choice is dependent on how you want your audio to interact
 * with other audio on the device.
 *
 * Please note that audio session interruption is different to application interruption.  Known triggers are
 * alarm notification from clock, incoming phone call that is rejected and video playback ending.
 */
- (id)init:(int[]) channelGroupDefinitions channelGroupTotal:(int) channelGroupTotal audioSessionCategory:(UInt32) audioSessionCategory 
{	
	if ((self = [super init])) {
		
		_mute = FALSE;
		asynchLoadProgress = 0.0f;
		_audioSessionCategory = audioSessionCategory;
		_handleAudioSession = (_audioSessionCategory != CD_IGNORE_AUDIO_SESSION);
		if (_handleAudioSession) {
			CCLOG(@"Denshion: Sound engine will handle audio session interruption");
			//Set up audio session
			OSStatus result = AudioSessionInitialize(NULL, NULL,interruptionListenerCallback, self); 
			result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(_audioSessionCategory), &_audioSessionCategory); 
			#pragma unused(result)
		}	
		
		//Set up channel groups
		//_channelGroups = new channelGroup[channelGroupTotal];
		_channelGroups = (channelGroup *)malloc( sizeof(_channelGroups[0]) * channelGroupTotal);
		if(!_channelGroups) {
			CCLOG(@"Denshion: channel groups memory allocation failed");
		}
		
		_channelGroupTotal = channelGroupTotal;
		int channelCount = 0;
		for (int i=0; i < channelGroupTotal; i++) {
			
			_channelGroups[i].startIndex = channelCount;
			_channelGroups[i].endIndex = _channelGroups[i].startIndex + channelGroupDefinitions[i] - 1;
			_channelGroups[i].currentIndex = _channelGroups[i].startIndex;
			_channelGroups[i].mute = false;
			channelCount += channelGroupDefinitions[i];
			CCLOG(@"Denshion: channel def %i %i %i %i",i,_channelGroups[i].startIndex, _channelGroups[i].endIndex, _channelGroups[i].currentIndex);
		}
		
		NSAssert(channelCount <= CD_MAX_SOURCES,@"requested total channels exceeds CD_MAX_SOURCES");
		_channelTotal = channelCount;
		
		//Set up buffer states
		//_bufferStates = new int[CD_MAX_BUFFERS];
		_bufferStates = (int *)malloc( sizeof(_bufferStates[0]) * CD_MAX_BUFFERS);
		if(!_bufferStates) {
			CCLOG(@"Denshion: buffer states memory allocation failed");
		}
		
		for (int i=0; i < CD_MAX_BUFFERS; i++) {
			_bufferStates[i] = CD_BS_EMPTY;
		}	
		
		//_sourceBufferAttachments = new ALuint[CD_MAX_SOURCES];
		_sourceBufferAttachments = (ALuint *)malloc( sizeof(_sourceBufferAttachments[0]) * CD_MAX_SOURCES);
		if(!_sourceBufferAttachments) {
			CCLOG(@"Denshion: source buffer attachments memory allocation failed");
		}
		
		// Initialize our OpenAL environment
		if ([self _initOpenAL]) {
			functioning = TRUE;
		} else {
			//Something went wrong with OpenAL
			functioning = FALSE;
		}
		
		
	}
	
	return self;
}

/**
 * If you call this initialiser the sound engine won't handle audio session interruption and resumption.
 */
- (id)init:(int[]) channelGroupDefinitions channelGroupTotal:(int) channelGroupTotal {
	return [self init:channelGroupDefinitions channelGroupTotal:channelGroupTotal audioSessionCategory:CD_IGNORE_AUDIO_SESSION];
}	

/**
 * Delete the buffer identified by soundId
 * @return true if buffer deleted successfully, otherwise false
 */
- (BOOL) unloadBuffer:(int) soundId 
{
	//Before a buffer can be deleted any sources that are attached to it must be stopped
	for (int i=0; i < _channelTotal; i++) {
		//Note: tried getting the AL_BUFFER attribute of the source instead but doesn't
		//appear to work on a device - just returned zero.
		if (_buffers[soundId] == _sourceBufferAttachments[i]) {
			
			CCLOG(@"Denshion: Found attached source %i %i %i",i,_buffers[soundId],_sourceBufferAttachments[i]);
			
			//Stop source and detach
			alSourceStop(_sources[i]);	
			if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
				CCLOG(@"Denshion: error stopping source: %x\n", lastErrorCode);
			}	
			
			alSourcei(_sources[i], AL_BUFFER, 0);//Attach to "NULL" buffer to detach
			if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
				CCLOG(@"Denshion: error detaching buffer: %x\n", lastErrorCode);
			} else {
				//Record that source is now attached to nothing
				_sourceBufferAttachments[i] = 0;
			}	
		}	
	}	
	
	alDeleteBuffers(1, &_buffers[soundId]);
	if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: error deleting buffer: %x\n", lastErrorCode);
		_bufferStates[soundId] = CD_BS_FAILED;
		return FALSE;
	} 
	
	alGenBuffers(1, &_buffers[soundId]);
	if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: error regenerating buffer: %x\n", lastErrorCode);
		_bufferStates[soundId] = CD_BS_FAILED;
		return FALSE;
	} else {
		//We now have an empty buffer
		_bufferStates[soundId] = CD_BS_EMPTY;
		CCLOG(@"Denshion: buffer %i successfully unloaded\n",soundId);
		return TRUE;
	}	
}	

/**
 * Load buffers asynchronously 
 * Check asynchLoadProgress for progress. asynchLoadProgress represents fraction of completion. When it equals 1.0 loading
 * is complete. NB: asynchLoadProgress is simply based on the number of load requests, it does not take into account
 * file sizes.
 * @param An array of CDBufferLoadRequest objects
 */
- (void) loadBuffersAsynchronously:(NSArray *) loadRequests {
	@synchronized(self) {
		asynchLoadProgress = 0.0f;
		CDAsynchBufferLoader *loaderOp = [[[CDAsynchBufferLoader alloc] init:loadRequests soundEngine:self] autorelease];
		NSOperationQueue *opQ = [[[NSOperationQueue alloc] init] autorelease]; //This is going to leak?
		[opQ addOperation:loaderOp];
	}
}	


/**
 * Load sound data for later play back.
 * @return TRUE if buffer loaded okay for play back otherwise false
 */
- (BOOL) loadBuffer:(int) soundId filePath:(NSString*) filePath
{
	
	ALenum  format;
	ALvoid* data;
	ALsizei size;
	ALsizei freq;
	
	CCLOG(@"Denshion: Loading openAL buffer %i %@", soundId, filePath);
	
#ifdef DEBUG
	//Sanity check parameters - only in DEBUG
	NSAssert(soundId >= 0, @"soundId can not be negative");
	NSAssert(soundId < CD_MAX_BUFFERS, @"soundId exceeds limit set by CD_MAX_BUFFERS");	
#endif

	if (!functioning) {
		//OpenAL initialisation has previously failed
		CCLOG(@"Denshion: Loading buffer failed because sound engine state != functioning");
		return FALSE;
	}

	CFURLRef fileURL = nil;
	NSString *path = [FileUtils fullPathFromRelativePath:filePath];
	if (path) {
		fileURL = (CFURLRef)[[NSURL fileURLWithPath:path] retain];
	}

	if (fileURL)
	{
		if (_bufferStates[soundId] != CD_BS_EMPTY) {
			CCLOG(@"Denshion: non empty buffer, regenerating");
			if (![self unloadBuffer:soundId]) {
				//Deletion of buffer failed, delete buffer routine has set buffer state and lastErrorCode
				CFRelease(fileURL);//Thanks clang ;)
				return FALSE;
			}	
		}	
		
		data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		CCLOG(@"Denshion: size %i frequency %i format %i %i", size, freq, format, data);
		CFRelease(fileURL);
		
		if(data == NULL || (lastErrorCode = alGetError()) != AL_NO_ERROR) {
			CCLOG(@"Denshion: error loading sound: %x\n", lastErrorCode);
			_bufferStates[soundId] = CD_BS_FAILED;
			if (data != NULL) {
				free(data);//Free memory, it was an OpenAL error so there is data to free
			}	
			return FALSE;
		}
		
		alBufferData(_buffers[soundId], format, data, size, freq);
		free(data);		
		if((lastErrorCode = alGetError()) != AL_NO_ERROR) {
			CCLOG(@"Denshion: error attaching audio to buffer: %x\n", lastErrorCode);
			_bufferStates[soundId] = CD_BS_FAILED;
			return FALSE;
		} 
	} else {
		CCLOG(@"Denshion: Could not find file!\n");
		//Don't change buffer state here as it will be the same as before method was called	
		return FALSE;
	}	
	
	_bufferStates[soundId] = CD_BS_LOADED;
	return TRUE;
}

- (ALfloat) masterGain {
	ALfloat gain;
	alGetListenerf(AL_GAIN, &gain);
	return gain;
}	

/**
 * Overall gain setting multiplier. e.g 0.5 is half the gain.
 */
- (void) setMasterGain:(ALfloat) newGainValue {
	alListenerf(AL_GAIN, newGainValue);
}

- (BOOL) mute {
	return _mute;
}	

/**
 * Setting mute to true stops all sounds and prevent further sounds being played.  If you do not want sounds to be stopped but just silenced
 * then set masterGain to 0 instead.
 */
- (void) setMute:(BOOL) newMuteValue {
	_mute = newMuteValue;
	if (_mute) {
		//Turn off all sounds
		for (int i=0; i < _channelGroupTotal; i++) {
			[self stopChannelGroup:i];
		}	
	}	
}

/**
 * Play a sound.
 * @param soundId the id of the sound to play (buffer id).
 * @param channelGroupId the channel group that will be used to play the sound.
 * @param pitch pitch multiplier. e.g 1.0 is unaltered, 0.5 is 1 octave lower. 
 * @param pan stereo position. -1 is fully left, 0 is centre and 1 is fully right.
 * @param gain gain multiplier. e.g. 1.0 is unaltered, 0.5 is half the gain
 * @param loop should the sound be looped or one shot.
 * @return the id of the source being used to play the sound or CD_MUTE if the sound engine is muted or non functioning 
 * or CD_NO_SOURCE if a problem occurs setting up the source
 * 
 */
- (ALuint)playSound:(int) soundId channelGroupId:(int)channelGroupId pitch:(float) pitch pan:(float) pan gain:(float) gain loop:(BOOL) loop {

#ifdef DEBUG
	//Sanity check parameters - only in DEBUG
	NSAssert(soundId >= 0, @"soundId can not be negative");
	NSAssert(soundId < CD_MAX_BUFFERS, @"soundId exceeds limit");
	NSAssert(channelGroupId >= 0, @"channelGroupId can not be negative");
	NSAssert(channelGroupId < _channelGroupTotal, @"channelGroupId exceeds limit");
	NSAssert(pitch > 0, @"pitch must be greater than zero");
	NSAssert(pan >= -1 && pan <= 1, @"pan must be between -1 and 1");
	NSAssert(gain >= 0, @"gain can not be negative");
#endif
	
	//If mute or initialisation has failed or buffer is not loaded then do nothing
	if (_mute || !functioning || _bufferStates[soundId] != CD_BS_LOADED || _channelGroups[channelGroupId].mute) {
#ifdef DEBUG
		if (!functioning) {
			CCLOG(@"Denshion: sound playback aborted because sound engine is not functioning");
		} else if (_bufferStates[soundId] != CD_BS_LOADED) {
			CCLOG(@"Denshion: sound playback aborted because buffer %i is not loaded", soundId);
		}	
#endif		
		return CD_MUTE;
	}	
	
	
	//Work out which channel we can use
	int channel = _channelGroups[channelGroupId].currentIndex;
	if (channel != CD_CHANNEL_GROUP_NON_INTERRUPTIBLE) {
		if (_channelGroups[channelGroupId].startIndex != _channelGroups[channelGroupId].endIndex) {
			_channelGroups[channelGroupId].currentIndex++;
			if(_channelGroups[channelGroupId].currentIndex > _channelGroups[channelGroupId].endIndex) {
				_channelGroups[channelGroupId].currentIndex = _channelGroups[channelGroupId].startIndex; 
			}	
		}	
		return [self _startSound:soundId channelId:channel pitchVal:pitch panVal:pan gainVal:gain looping:loop checkState:TRUE];
	} else {
		//Channel group is non interruptible therefore we must search for the first non playing channel/source if there are any
		int checkingIndex = _channelGroups[channelGroupId].startIndex;
		ALint state = 0;
		while ((checkingIndex <= _channelGroups[channelGroupId].endIndex) && (channel == CD_CHANNEL_GROUP_NON_INTERRUPTIBLE)) {
			//Check if source is playing
			alGetSourcei(_sources[checkingIndex], AL_SOURCE_STATE, &state);
			if (state != AL_PLAYING) {
				channel = checkingIndex;
			}	
			checkingIndex++;
		}
		
		if (channel != CD_CHANNEL_GROUP_NON_INTERRUPTIBLE) {
			//Found a free channel
			return [self _startSound:soundId channelId:channel pitchVal:pitch panVal:pan gainVal:gain looping:loop checkState:FALSE];
		} else {
			//Didn't find a free channel
			return CD_NO_SOURCE;
		}	
	}	
}	

/**
 * Internal method - use playSound instead.
 */
- (ALuint)_startSound:(int) soundId channelId:(int) channelId pitchVal:(float) pitchVal panVal:(float) panVal gainVal:(float) gainVal looping:(BOOL) looping checkState:(BOOL) checkState
{
	
	ALint state;
	ALuint source = _sources[channelId];
	ALuint buffer = _buffers[soundId];
	
	alGetError();//Clear the error code
	
	//If we are in interruptible mode then we check the state to see if the source 
	//is already playing and if so stop it.  Otherwise in non interruptible mode
	//we already know that the source is not playing.
	if (checkState) {
		alGetSourcei(source, AL_SOURCE_STATE, &state);
		if (state == AL_PLAYING) {
			alSourceStop(source);
		}	
	}	
	
	alSourcei(source, AL_BUFFER, buffer);//Attach to sound
	alSourcef(source, AL_PITCH, pitchVal);//Set pitch
	alSourcei(source, AL_LOOPING, looping);//Set looping
	alSourcef(source, AL_GAIN, gainVal);//Set gain/volume
	float sourcePosAL[] = {panVal, 0.0f, 0.0f};//Set position - just using left and right panning
	alSourcefv(source, AL_POSITION, sourcePosAL);

	alSourcePlay(source);
	if((lastErrorCode = alGetError()) == AL_NO_ERROR) {
		//Everything was okay
		_sourceBufferAttachments[channelId] = buffer;//Keep track of which buffer source is attached to as alGetSourcei on AL_BUFFER does not seem to work
		return source;
	} else {
		//Something went wrong - set error code and return failure code
		return CD_NO_SOURCE;
	}	
}

/**
 * Stop all sounds playing within a channel group
 */
- (void) stopChannelGroup:(int) channelGroupId {
	if (!functioning) {
		return;
	}	
	for (int i=_channelGroups[channelGroupId].startIndex; i <= _channelGroups[channelGroupId].endIndex; i++) {
		alSourceStop(_sources[i]);
	}	
}	

/**
 * Stop a sound playing.
 * @param sourceId an OpenGL source identifier i.e. the return value of playSound
 */
- (void)stopSound:(ALuint) sourceId {
	if (!functioning) {
		return;
	}	
	alSourceStop(sourceId);
}

/**
 * Set a channel group as non interruptible.  Default is that channel groups are interruptible.
 * Non interruptible means that if a request to play a sound is made for a channel group and there are
 * no free channels available then the play request will be ignored and CD_NO_SOURCE will be returned.
 */
- (void) setChannelGroupNonInterruptible:(int) channelGroupId isNonInterruptible:(BOOL) isNonInterruptible {
	if (isNonInterruptible) {
		_channelGroups[channelGroupId].currentIndex = CD_CHANNEL_GROUP_NON_INTERRUPTIBLE;
	} else {
		_channelGroups[channelGroupId].currentIndex = _channelGroups[channelGroupId].startIndex;
	}	
}

/**
 * Set the mute property for a channel group. If mute is turned on any sounds in that channel group
 * will be stopped and further sounds in that channel group will play. However, turning mute off
 * will not restart any sounds that were playing when mute was turned on. Also the mute setting 
 * for the sound engine must be taken into account. If the sound engine is mute no sounds will play
 * no matter what the channel group mute setting is.
 */
- (void) setChannelGroupMute:(int) channelGroupId mute:(BOOL) mute {
	if (mute) {
		_channelGroups[channelGroupId].mute = true;
		[self stopChannelGroup:channelGroupId];
	} else {
		_channelGroups[channelGroupId].mute = false;	
	}	
}

/**
 * Return the mute property for the channel group identified by channelGroupId
 */
- (BOOL) channelGroupMute:(int) channelGroupId {
	if (_channelGroups[channelGroupId].mute) {
		return YES;
	} else {
		return NO;	
	}	
}

-(ALCcontext *) openALContext {
	return context;
}	

//Code to handle audio session interruption.  Thanks to Andy Fitter and Ben Britten.
-(void)audioSessionInterrupted 
{ 
    CCLOG(@"Denshion: Audio session interrupted"); 
	ALenum  error = AL_NO_ERROR;
    // Deactivate the current audio session 
    AudioSessionSetActive(NO); 
    // set the current context to NULL will 'shutdown' openAL 
    alcMakeContextCurrent(NULL); 
	if((error = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: Error making context current %x\n", error);
	} 
    // now suspend your context to 'pause' your sound world 
    alcSuspendContext(context); 
	if((error = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: Error suspending context %x\n", error);
	} 
	#pragma unused(error)
} 

//Code to handle audio session resumption.  Thanks to Andy Fitter and Ben Britten.
-(void)audioSessionResumed 
{ 
    ALenum  error = AL_NO_ERROR;
	CCLOG(@"Denshion: Audio session resumed"); 
    // Reset audio session 
    OSStatus result = AudioSessionSetProperty ( kAudioSessionProperty_AudioCategory, sizeof(_audioSessionCategory), &_audioSessionCategory ); 
	
	// Reactivate the current audio session 
    result = AudioSessionSetActive(YES); 
	#pragma unused(result)
	
    // Restore open al context 
    alcMakeContextCurrent(context); 
	if((error = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: Error making context current%x\n", error);
	} 
    // 'unpause' my context 
    alcProcessContext(context); 
	if((error = alGetError()) != AL_NO_ERROR) {
		CCLOG(@"Denshion: Error processing context%x\n", error);
	} 
	#pragma unused(error)
} 

@end

///////////////////////////////////////////////////////////////////////////////////////

@implementation CDSourceWrapper

-(void) setSourceId:(ALuint) newSourceId {
	if ((newSourceId != CD_NO_SOURCE) && (newSourceId != CD_MUTE)) {
		sourceId = newSourceId;
	} else {
		CCLOG(@"Denshion: Attempt to assign CD_MUTE or CD_NO_SOURCE to a source wrapper");
	}	
}	

- (ALuint) sourceId {
	return sourceId;
}	

- (void) setPitch:(float) newPitchValue {
	lastPitch = newPitchValue;
	alSourcef(sourceId, AL_PITCH, newPitchValue);	
}	

- (void) setGain:(float) newGainValue {
	lastGain = newGainValue;
	alSourcef(sourceId, AL_GAIN, newGainValue);	
}

- (void) setPan:(float) newPanValue {
	lastPan = newPanValue;
	float sourcePosAL[] = {newPanValue, 0.0f, 0.0f};//Set position - just using left and right panning
	alSourcefv(sourceId, AL_POSITION, sourcePosAL);
}

- (void) setLooping:(BOOL) newLoopingValue {
	lastLooping = newLoopingValue;
	alSourcei(sourceId, AL_LOOPING, newLoopingValue);
}


- (BOOL) isPlaying {
	ALint state;
	alGetSourcei(sourceId, AL_SOURCE_STATE, &state);
	return (state == AL_PLAYING);
}	

//alGetSource does not appear to work for pitch, pan and gain values
//So we just remember the last value set
- (float) pitch {
	/*
	//This does not work on simulator or device 
	ALfloat pitchVal;
	alGetSourcef(sourceId, AL_PITCH, &pitchVal);
	return pitchVal;
	*/ 
	return lastPitch;
}

- (float) pan {
	return lastPan;
}

- (float) gain {
	return lastGain;
}	

- (BOOL) looping {
	return lastLooping;
}	

@end

////////////////////////////////////////////////////////////////////////////

@implementation CDAsynchBufferLoader

-(id) init:(NSArray *)loadRequests soundEngine:(CDSoundEngine *) theSoundEngine {
	if ([super init] ) {
		_loadRequests = loadRequests;
		[_loadRequests retain];
		_soundEngine = theSoundEngine;
		[_soundEngine retain];
		return self;
	} else {
		return nil;
	}	
}	

-(void) main {
	CCLOG(@"Denshion: CDAsynchBufferLoader loading buffers");
	[super main];
	_soundEngine.asynchLoadProgress = 0.0f;

	if ([_loadRequests count] > 0) {
		float increment = 1.0f / [_loadRequests count];
		//Iterate over load request and load
		for (CDBufferLoadRequest *loadRequest in _loadRequests) {
			[_soundEngine loadBuffer:loadRequest.soundId filePath:loadRequest.filePath];
			_soundEngine.asynchLoadProgress += increment;
			
		}	
	}	
	
	//Completed
	_soundEngine.asynchLoadProgress = 1.0f;
	
}	

-(void) dealloc {
	[_loadRequests release];
	[_soundEngine release];
	[super dealloc];
}	

@end


///////////////////////////////////////////////////////////////////////////////////////
@implementation CDBufferLoadRequest

@synthesize filePath, soundId;

-(id) init:(int) theSoundId filePath:(NSString *) theFilePath {
	if ([super init]) {
		soundId = theSoundId;
		filePath = theFilePath;
		[filePath retain];
		return self;
	} else {
		return nil;
	}
}

-(void) dealloc {
	[filePath release];
	[super dealloc];
}

@end
