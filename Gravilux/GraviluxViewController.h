//
//  GraviluxViewController.h
//  Gravilux
//
//  Created by Colin Roache on 9/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
#pragma once

#include "ofxMSAShape3D.h"
#import <UIKit/UIKit.h>
#ifdef OPENGL_ENABLED
    #import <OpenGLES/EAGL.h>
    #import <OpenGLES/ES1/gl.h>
    #import <OpenGLES/ES1/glext.h>
#else
    #import "AAPLRenderer.h"
#endif

#import <QuartzCore/QuartzCore.h>

#include "Gravilux.h"
#include "Parameters.h"
#import "GraviluxView.h"

class Gravilux;
@class InterfaceViewController, InAppPurchaseViewController;

@interface GraviluxViewController : UIViewController {
	GraviluxView				*graviluxView;
#ifdef OPENGL_ENABLED
	EAGLContext					*context;
    GLuint						program;
#else 
    AAPLRenderer                *_renderer;
#endif
//    BOOL						animating;
//    NSInteger					animationFrameInterval;
//    CADisplayLink				*displayLink;
	NSTimer						*uiTimer;
    
}
@property (readonly, nonatomic, getter=isAnimating)	BOOL			animating;
@property (nonatomic)								NSInteger		animationFrameInterval;
#ifdef OPENGL_ENABLED
@property (nonatomic, retain)						EAGLContext		*context;
#endif
@property (nonatomic, assign)						CADisplayLink	*displayLink;


- (void) startAnimation;
- (void) stopAnimation; 

@end
