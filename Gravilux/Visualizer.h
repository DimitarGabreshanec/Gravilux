//
//  Visualizer.h
//  Gravilux
//
//  Created by Colin Roache on 10/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include <vector>
#include "time.h"
#include "ForceEmitter.h"
#include "ColorWalk.h"

//#import "SnibbeAudioUtils.h"

#define SPECLEN 64
#define AUTO_TRANSITION_TIME_S 6.//10.
#define AUTO_TRANSITION_DUR_S 1.
#define AUTO_SIMULTANEOUS_INPUTS 3
#define FMOD_DEFINE
#ifdef FMOD_DEFINE
#include "inc/fmod.hpp" 
#include "inc/fmod_ios.h"
#include "inc/fmod_errors.h"
#include "inc/fmod.h"
 
using namespace FMOD;
extern void ERRCHECK(FMOD_RESULT result);
#endif


class Visualizer {
	/*static FMOD_RESULT F_CALLBACK FMODChannelCallback(FMOD_CHANNEL *channel, FMOD_CHANNEL_CALLBACKTYPE type, void *commanddata1, void *commanddata2) {
		FMOD::Channel *cppchannel = (FMOD::Channel *)channel;
		//		Mutex::Lock __(playLock); // Prevent any other messages from being sent from main thread to the mp3 player
		//		if (!activePlayer) { // Verify that a player has been assigned
		//			return 0; // unlock and continue
		//		}
		
		// More code goes here.
		
		switch (type) {
			case FMOD_CHANNEL_CALLBACKTYPE_END:	
				this.syncUI();
				break;
				
			case FMOD_CHANNEL_CALLBACKTYPE_VIRTUALVOICE: // Called when a voice is swapped out or swapped in. 
			case FMOD_CHANNEL_CALLBACKTYPE_SYNCPOINT: // Called when a syncpoint is encountered. Can be from wav file markers. 
			case FMOD_CHANNEL_CALLBACKTYPE_OCCLUSION: // Called when the channel has its geometry occlusion value calculated. Can be used to clamp or change the value. 
				break;
			default:
				; // Error
		}
		return FMOD_OK;
	}*/
	
	
public:
	Visualizer();
	~Visualizer();
	
	void			simulate(float dt);
	
	void			load(const char * path);
	void			start();
	void			stop();
	bool			loaded() { return loaded_; };
    void            setLoaded(bool loaded) { loaded_ = loaded; };
	bool			running() { return running_; };
	int				nEmitters();
	float			emitterStrength(int i);
	void			setEmitterStrength(int i, float strength);
	bool			emitterState(int i);
	void			setEmitterState(int i, bool active);
	bool			automatic() { return automatic_; };
	void			automatic(bool a);
	bool			repeat();
	void			repeat(bool b);
	bool			colorWalk() { return colorWalk_; };
	void			colorWalk(bool c);
	ForceState *	forceState() { return forceState_; };
	

private:
	void			syncUI();
	void			syncUILevels();
	
	ForceState *			forceState_;
	vector<ForceEmitter*>	emitters_;
	
	bool					loaded_; // true if a file has been loaded into FMOD
	bool					running_;
	
	// Automatic mode
	bool					automatic_;
	bool					repeat_;
	
	// Color Automation
	bool					colorWalk_;
	ColorWalk*				colorWalker_;
	
	CFAbsoluteTime					lastTransition;
	vector<vector<ForceEmitter*>::iterator>	automatingEmitters;
	
#ifdef FMOD_DEFINE
	// FMOD 
	float					*specL, *specR, *spec;
    void                    *extradriverdata = 0;
    FMOD::System            *fmodsys;
    FMOD::Sound             *fmodsnd;
    FMOD::Channel           *fmodchn = 0;
    FMOD_RESULT             result;
    FMOD::DSP               *mydsp;
    FMOD::ChannelGroup      *masterGroup;
    FMOD_MODE               mode = FMOD_OPENUSER | FMOD_LOOP_NORMAL;
    unsigned int            version;
    FMOD_CREATESOUNDEXINFO  exinfo;
    FMOD_DSP_PARAMETER_FFT *fftparameter;
#endif
};
