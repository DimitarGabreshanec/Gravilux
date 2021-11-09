//
//  GraviluxAppDelegate.mm
//  Gravilux
//
//  Created by Colin Roache on 9/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "GraviluxAppDelegate.h"
#import <FirebaseCore/FirebaseCore.h>
#import "GraviluxAppDelegate.h" 
 
//static void uncaughtExceptionHandler(NSException *exception) {
//    //[Flurry logError:@"Uncaught" message:@"Crash!" exception:exception];
//    
//    [FIRAnalytics logEventWithName:kFIREventSelectContent
//    parameters:@{
//                 kFIRParameterItemID:@"Crash!",
//                 kFIRParameterItemName:@"Uncaught",
//                 kFIRParameterContentType:@"image"
//                 }];
//     
//}

@implementation GraviluxAppDelegate

@synthesize window, graviluxController;

- (void)dealloc
{
    [super dealloc];
	[graviluxController release];
}
 

- (void)applicationWillResignActive:(UIApplication *)application
{
	[graviluxController stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[graviluxController stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[graviluxController startAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[graviluxController startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[graviluxController stopAnimation];
}

- (UIInterfaceOrientationMask) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    return  UIInterfaceOrientationMaskAll;

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIView appearance] setTintColor:[UIColor whiteColor]]; 
    // Override point for customization after application launch.
    gGravilux = new Gravilux();
    /*UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MainViewController* mainVC = (MainViewController *)[sb instantiateViewControllerWithIdentifier:@"MainViewController"];
    GraviluxViewController *grviluxVC = [[GraviluxViewController alloc] init];
    grviluxVC.view.multipleTouchEnabled = true;
    [window addSubview:mainVC.view];
    [window insertSubview:grviluxVC.view belowSubview:mainVC.view];
    [self.window makeKeyAndVisible];*/
    [FIRApp configure];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}
 
 

@end
