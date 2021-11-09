//
//  Visualizer.mm
//  Gravilux
//
//  Created by Colin Roache on 10/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "Visualizer.h"
#include "Gravilux.h"
#include "Parameters.h"
#include "FEperlin.h"
#include "FEspinning.h"
#include "FEline.h"
#include "FEupwards.h"
#include "FEquad.h"
#include "FEspine.h"
#include "FEpushPull.h"

#include "inc/fmod_errors.h"
#include "inc/fmod_ios.h"

#define AUTOMATIC_LEVEL .25f
void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
//        raise(SIGINT);  // break into debugger
    }
}


Visualizer::Visualizer()
{
    fmodchn = 0;
    fmodsnd = 0;
    FMOD::System_Create(&fmodsys);

//    FMOD_IPHONE_EXTRADRIVERDATA extradriverdata;
//    memset(&extradriverdata, 0, sizeof(FMOD_IPHONE_EXTRADRIVERDATA));
//    extradriverdata.sessionCategory = FMOD_IPHONE_SESSIONCATEGORY_MEDIAPLAYBACK;
//    extradriverdata.forceMixWithOthers = true;
    ERRCHECK(fmodsys->init(32, FMOD_INIT_NORMAL, nil));
//    //ERRCHECK(FMOD_IPhone_MixWithOtherAudio(TRUE));
    
//    BOOL success = false;
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//
//    success = [session setCategory:AVAudioSessionCategoryAmbient error:nil];
//    assert(success);
//
//    success = [session setActive:TRUE error:nil];
//    assert(success);
    
    ERRCHECK(fmodsys->getMasterChannelGroup(&masterGroup));
    ERRCHECK(fmodsys->createDSPByType(FMOD_DSP_TYPE_FFT, &mydsp));
    ERRCHECK(mydsp->setParameterInt(FMOD_DSP_FFT_WINDOWTYPE, FMOD_DSP_FFT_WINDOW_HANNING));
    ERRCHECK(mydsp->setParameterInt(FMOD_DSP_FFT_WINDOWSIZE, SPECLEN));
    ERRCHECK(masterGroup->addDSP(FMOD_CHANNELCONTROL_DSP_HEAD, mydsp));
    
    
    //ERRCHECK(mydsp->setBypass(true));
    //ERRCHECK(mydsp->setActive(true));
    
    
    specL = (float*)malloc(SPECLEN*sizeof(float));
    specR = (float*)malloc(SPECLEN*sizeof(float));

    forceState_ = new ForceState();
    forceState_->setOffset((ForceEmitter*)new FEperlin(NULL));
    emitters_.push_back((ForceEmitter*)new FEspinning(forceState_));
    emitters_.push_back((ForceEmitter*)new FEupwards(forceState_));
    /*emitters_.push_back((ForceEmitter*)new FEline(forceState_)); // not to be used*/
    emitters_.push_back((ForceEmitter*)new FEquad(forceState_));
    emitters_.push_back((ForceEmitter*)new FEspine(forceState_));
    emitters_.push_back((ForceEmitter*)new FEpushPull(forceState_));
    
    for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
        (*it)->state()->setStrength(AUTOMATIC_LEVEL);
        (*it)->stop();
    }
    vector<ForceEmitter*>::iterator iter = emitters_.begin();
    for (int i = 0; i < AUTO_SIMULTANEOUS_INPUTS; i++) {
        automatingEmitters.push_back(iter);
        iter++;
    }
    lastTransition = CFAbsoluteTimeGetCurrent();
    
    automatic_ = true;
    repeat_ = false;
    colorWalk_ = false;
    
    loaded_ = false;
    running_ = false;
    
    colorWalker_ = new ColorWalk();
}

Visualizer::~Visualizer()
{
    stop();
    ERRCHECK(fmodsys->release());
    free(specL);
    free(specR);
    for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
        delete (ForceEmitter*)(*it);
    }
    delete forceState_;
    automatingEmitters.clear();
    
    delete colorWalker_;
}

void
Visualizer::simulate(float dt)
{
    float lows = 0.;
    float mids = 0.;
    float highs = 0.;
	bool syncUI = false; // Set if we need a UI refresh, send notification once at end
	if (running_) {
		if (automatic_) {
			CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
			CFAbsoluteTime timeDelta = currentTime - lastTransition;
			if (timeDelta > AUTO_TRANSITION_TIME_S) {
				lastTransition = currentTime;
				
				// Randomly choose an active emitter, turn it off,
				// find a new inactive emitter and turn it on
				bool haveMoved = false;
				while (!haveMoved) {
					int newPosition = rand() % emitters_.size();
					bool newPositionIsInactive = true;
					for (vector<vector<ForceEmitter*>::iterator>::iterator scanner = automatingEmitters.begin(); scanner < automatingEmitters.end(); ++scanner) {
						if(*scanner == emitters_.begin() + newPosition) {
							newPositionIsInactive = false;
						}
					}
					if(newPositionIsInactive) {
						int automatingEmitterToMove = rand() % automatingEmitters.size();
						(**automatingEmitters[automatingEmitterToMove]).state()->setStrength(0.);
						(**automatingEmitters[automatingEmitterToMove]).stop();
						automatingEmitters[automatingEmitterToMove] = emitters_.begin() + newPosition;
						(**automatingEmitters[automatingEmitterToMove]).start();
						(**automatingEmitters[automatingEmitterToMove]).state()->setStrength(AUTOMATIC_LEVEL);
						haveMoved = true;
					}
				}		
			}
			syncUI = true;
		}
		
		bool paused = true;
		if (fmodchn)
			ERRCHECK(fmodchn->getPaused( &paused ));
		if ( !paused )
		{
            ERRCHECK(fmodsys->update());
            ERRCHECK(mydsp->getParameterData(FMOD_DSP_FFT_SPECTRUMDATA, (void **)&fftparameter, 0, 0, 0));
            if(fftparameter->spectrum[0] == nil)
                return;
            memcpy(specL, &fftparameter->spectrum[0][0], SPECLEN*sizeof(float));
            memcpy(specR, &fftparameter->spectrum[1][0], SPECLEN*sizeof(float));
            // sum channel data into low, middle and high frequencies
            int lengthSum = fftparameter->length * 0.5; // leave out highest frequencies, just use first half
            int iterations = floor(lengthSum/3);
            for (int i = 0; i < iterations; i++) {
                lows += fftparameter->spectrum[0][i] + fftparameter->spectrum[1][i];
                mids += fftparameter->spectrum[0][iterations+i] + fftparameter->spectrum[1][iterations+i];
                highs += fftparameter->spectrum[0][(iterations*2)+i] + fftparameter->spectrum[1][(iterations*2)+i];
            }
            lows /= iterations;
            mids /= iterations;
            highs /= iterations;
            
            // 50,200,200 pretty good or 50, 100, 100 / 25,75,100
            lows =  MIN(lows*25, 1.0);
            mids =  MIN(mids*100, 1.0);
            highs = MIN(highs*50, 1.0);
             
		}
        /*else {
            memset( specL, 0, SPECLEN*sizeof(float) );
            memset( specR, 0, SPECLEN*sizeof(float) );
        };*/
        
        if (fmodsnd != nullptr) {
            FMOD_TIMEUNIT timeUnit = FMOD_TIMEUNIT_PCM;
            unsigned int length,position;
            ERRCHECK(fmodsnd->getLength(&length, timeUnit));
            ERRCHECK(fmodchn->getPosition(&position, timeUnit));
            if (length <= position) {
                stop();
            }
        }
		
//		NSLog(@"lows:%f mids:%f highs:%f", lows, mids, highs);
		for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
			if ((*it)->state()->active() && (*it)->state()->strength() > 0.05) {
				(*it)->simulate(dt, lows, mids, highs);
			}
		}
		
		if(colorWalk_) {
			ColorSet colors = colorWalker_->simulate(lows+mids+highs);
			gGravilux->params()->setColorsWalk(colors);
		}
		
		if(running_ && automatic_) {
			this->syncUILevels();
		}
	}
}

void
Visualizer::load(const char *path)
{
    fmodchn = 0;
    fmodsnd = 0;
    ERRCHECK(fmodsys->createSound(path, FMOD_3D | FMOD_CREATESTREAM | FMOD_LOOP_NORMAL, 0, &fmodsnd));
    #warning may not want to loop? or advance tracks
    ERRCHECK(fmodsnd->setMode(FMOD_LOOP_NORMAL));
    ERRCHECK(fmodsys->playSound(fmodsnd,nullptr, true,&fmodchn));
    ERRCHECK(fmodchn->setLoopCount(repeat_?-1:0));
    
    loaded_ = (fmodchn && fmodsnd);
}

void
Visualizer::start()
{
    if (fmodchn) {
        //ERRCHECK(FMOD_IPhone_MixWithOtherAudio(false));
        ERRCHECK(fmodchn->setPaused(false));
        running_ = true;
        for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
            (*it)->start();
        }
        gGravilux->params()->setColorSource(colorWalk_);
    }
    syncUI();
}

void
Visualizer::stop()
{
    running_ = false;
    for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
        (*it)->stop();
    }
    if (fmodchn) {
        ERRCHECK(fmodchn->setPaused(true));
        //ERRCHECK(FMOD_IPhone_MixWithOtherAudio(true));
    }
    gGravilux->params()->setColorSource(false);
    syncUI();
}

int
Visualizer::nEmitters()
{
    return (int) emitters_.size();
}

float
Visualizer::emitterStrength(int i)
{
    if (i < 0 || i >= nEmitters()) {
        return -1.;
    }
    return emitters_[i]->state()->strength();
}

void
Visualizer::setEmitterStrength(int i, float strength)
{
    if (i >= 0 && i < nEmitters()) {
        emitters_.at(i)->state()->setStrength(strength);
    }
}

bool
Visualizer::emitterState(int i)
{
    if (i < 0 || i >= nEmitters()) {
        return false;
    }
    return emitters_[i]->state()->active();
}

void
Visualizer::setEmitterState(int i, bool active)
{
    if (i >= 0 && i < nEmitters()) {
        if (active)
            emitters_.at(i)->start();
        else
            emitters_.at(i)->stop();
    }
}


void
Visualizer::automatic(bool a)
{
    automatic_ = a;
    for (vector<ForceEmitter*>::iterator it = emitters_.begin(); it != emitters_.end(); ++it) {
        (*it)->start();
        (*it)->state()->setStrength(0.);
    }
    
    if(automatic_) {
        for (vector<vector<ForceEmitter*>::iterator>::iterator it = automatingEmitters.begin(); it != automatingEmitters.end(); ++it) {
            (**it)->state()->setStrength(AUTOMATIC_LEVEL);
        }
    }
    syncUILevels();
    syncUI();
};

bool
Visualizer::repeat()
{
    if (fmodchn) {
        int loopcount = 0;
        ERRCHECK(fmodchn->getLoopCount(&loopcount)); // Return what is actually happening, not what we expect

        repeat_ = (loopcount == -1);
    }
    return repeat_;
}
void
Visualizer::repeat(bool b)
{
    repeat_ = b;
    if(fmodchn) {
        int loopCount = repeat_?-1:0;
        ERRCHECK(fmodchn->setLoopCount(loopCount));
    }
    syncUI();
}

void
Visualizer::colorWalk(bool c)
{
    colorWalk_ = c;
    gGravilux->params()->setColorSource(c);
    syncUI();
}

void
Visualizer::syncUI()
{
    
    if (fmodchn) {
        int loopCount = 0;
        ERRCHECK(fmodchn->getLoopCount( &loopCount ));
        repeat_ = (loopCount == -1);
        
        bool paused = true;
        ERRCHECK(fmodchn->getPaused( &paused ));
        running_ = !paused;
    }
    gGravilux->params()->setColorSource(running_ && colorWalk_);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUIVisualizer" object:nil];
}

void
Visualizer::syncUILevels()
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUIVisualizerLevels" object:[NSNotificationCenter defaultCenter]];
}
