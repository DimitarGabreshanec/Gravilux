//
//  main.m
//  Gravilux
//
//  Created by SolYsky on 2020/10/3.
//  Copyright © 2020 SolYsky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraviluxAppDelegate.h"
#include "Gravilux.h"
#include "GraviluxView.h"

Gravilux       *gGravilux = NULL;
GraviluxView   *gGraviluxView = NULL;
NSString       *strFileName = @"Night Sea - Still - 06 Grand Bleu.m4a"; 
NSURL          *assetURL;
bool           loadingFlag = true;
bool           firstRun = true;
int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([GraviluxAppDelegate class]));
    }
 
}
/*
int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([GraviluxAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
*/
