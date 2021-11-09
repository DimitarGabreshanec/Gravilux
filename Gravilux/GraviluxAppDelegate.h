//
//  GraviluxAppDelegate.h
//  Gravilux
//
//  Created by Colin Roache on 9/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "GraviluxViewController.h"
#include "MainViewController.h"
#import <FirebaseAnalytics/FIRAnalytics.h>
 
@class GraviluxViewController;

@interface GraviluxAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) GraviluxViewController *graviluxController;

@end
