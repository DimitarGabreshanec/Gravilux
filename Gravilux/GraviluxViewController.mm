//
//  GraviluxViewController.m
//  Gravilux
//
//  Created by Colin Roache on 9/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "GraviluxViewController.h"
#import <CoreFoundation/CoreFoundation.h>
#ifndef OPENGL_ENABLED
    #import "AAPLRenderer.h"
#endif
#import "Visualizer.h"

@implementation GraviluxViewController

#ifdef OPENGL_ENABLED
@synthesize animating, animationFrameInterval, context, displayLink;
#endif

- (void)viewDidLoad
{
    self.view.multipleTouchEnabled = YES;   //added by @solysky20201002
    graviluxView.multipleTouchEnabled = YES;    //added by @solysky20201002
    [super viewDidLoad];
    [self startAnimation];
     
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(orientationChanged:)
       name:UIDeviceOrientationDidChangeNotification
       object:[UIDevice currentDevice]];
}

- (void) orientationChanged:(NSNotification *)note
{ 
    graviluxView.frame = [UIScreen mainScreen].bounds;
    self.view.frame = [UIScreen mainScreen].bounds; 
    gGravilux->resetGrains();
}

- (id)init
{
	self = [super init];
	if(self) { 
	}
	return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
#ifdef OPENGL_ENABLED
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	[context release];
#endif
	[graviluxView release];
//	delete gGravilux;
// $$$ should work! ^
	
	
	[super dealloc];
}

#pragma mark UIResponder Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    gGravilux->params()->setInteractionTime();
    ForceState * forceState = gGravilux->forceState();
    float gravity = gGravilux->params()->gravity();
    
    //  pass touches on to the experience if not touching the UI
    for (UITouch *touch in touches) {
            Force * f = new Force(touch);
            f->setStrength(gravity);
            // This is for tossing points:
            f->setBoundaryMode(ForceBoundaryModeBounce);
            f->enableVelocity(false);   // don't add simulation to natural touches
            f->setAcceleration(.9, .6);
            forceState->addForce(f); 
    }
//    NSLog(@"toucheBegan\n");
    self.view.userInteractionEnabled = true;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    gGravilux->params()->setInteractionTime();
    self.view.userInteractionEnabled = true;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    gGravilux->params()->setInteractionTime();
    self.view.userInteractionEnabled = true;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.view.userInteractionEnabled = true;
    gGravilux->params()->setInteractionTime();
}
 
#pragma mark - View lifecycle
 
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	graviluxView = [[GraviluxView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    gGraviluxView = graviluxView; 
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view.multipleTouchEnabled = YES;
    [self.view addSubview:graviluxView];
	
    
#ifdef OPENGL_ENABLED
	// force to 1.1 OpenGL
	EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if (!aContext)
		NSLog(@"Failed to create ES context");
	else if (![EAGLContext setCurrentContext:aContext])
		NSLog(@"Failed to set ES context current");
	
	self.context = aContext;
	[aContext release];
#endif
	self.displayLink = nil;
#ifdef OPENGL_ENABLED
	[graviluxView setContext:self.context];
#endif
	
    _animating = FALSE;
    _animationFrameInterval = 1;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

// deprecated
//- (void)viewDidUnload
//{
//    [super viewDidUnload];
//}

- (void)drawFrame
{
    if(!_animating) {
		return;
	}
	
	if(gGravilux->params()->getTimeSinceLastInteraction() > TIME_TO_RESET && gGravilux->visualizer()->running()) {
		gGravilux->params()->setInteractionTime();
		
		gGravilux->resetGrains();
		
		gGravilux->params()->setAntigravity(!gGravilux->params()->antigravity());
        gGravilux->params()->setGravity(RANDOM(1.0, 50.0));
		NSLog(@"resetting: antigravity: %@ gravity: %f", gGravilux->params()->antigravity()?@"YES":@"NO", gGravilux->params()->gravity());
	}
#ifdef OPENGL_ENABLED
	[graviluxView setFramebuffer];
	
	glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
#endif
//#warning Move to GraviluxView
	gGravilux->update();
	gGravilux->draw();
#ifdef OPENGL_ENABLED
	[graviluxView presentFramebuffer];
#endif
     
}

- (void)startAnimation
{
    if (!_animating)
    {
		SEL drawCall = @selector(drawFrame);
		
		// Use a display link to stay synced with screen refreshes
		CADisplayLink *aDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:drawCall];
//        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink setPreferredFramesPerSecond:0.01];   // = - highest refresh rate of display, usually 60
               
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
		
		// Use a 60fps NSTimer when UIKit is blocking the displaylink
		uiTimer = [NSTimer timerWithTimeInterval:1./60. target:self selector:drawCall userInfo:nil repeats:YES]; 
		[[NSRunLoop currentRunLoop] addTimer:uiTimer forMode:UITrackingRunLoopMode];
        
        _animating = TRUE;
        
#ifndef OPENGL_ENABLED
        // Set the view to use the default device
        graviluxView.device = MTLCreateSystemDefaultDevice();
        NSAssert(graviluxView.device, @"Metal is not supported on this device");
        _renderer = [[AAPLRenderer alloc] initWithMetalKitView:graviluxView];
        NSAssert(_renderer, @"Renderer failed initialization");

        // Initialize our renderer with the view size
        [_renderer mtkView:graviluxView drawableSizeWillChange:graviluxView.drawableSize];
        graviluxView.delegate = _renderer;
         
#endif
    }
}

- (void)stopAnimation
{
    if (_animating)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
		if(uiTimer) {
			[uiTimer invalidate];
			uiTimer = nil;
		}
        _animating = FALSE;
	}
}
 
- (BOOL)shouldAutorotate
{
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}
 
//-(UIInterfaceOrientation) interfaceOrientation
//{
//    return UIInterfaceOrientationPortrait;
//}
 
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    [UIView setAnimationsEnabled:NO];

    // Stackoverflow #26357162 to force orientation
//    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
//    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

@end
