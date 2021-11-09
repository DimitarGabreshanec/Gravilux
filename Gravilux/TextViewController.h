//
//  AAPLViewController.h
//  Gravilux
//
//  Created by SolYsky on 2020/9/6.
//  Copyright © 2020 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Gravilux.h"
#include "ForceState.h"
#include "Visualizer.h"

#import <FirebaseAnalytics/FIRAnalytics.h> 
NS_ASSUME_NONNULL_BEGIN
 
 
@interface TextViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UITextFieldDelegate, UIColorPickerViewControllerDelegate>
{
    //text view
    IBOutlet    UITextField     *typeAuxText;
    IBOutlet    UISlider        *typeAuxSize;
    IBOutlet    UIView            *typeAuxView;
    IBOutlet    UIView            *typeView;
    IBOutlet UIButton *clearText;
    IBOutlet UITextField *typeText;
    
    IBOutlet UISlider *typeSize;
    IBOutlet UIBarButtonItem *shareButton;
    IBOutlet UIBarButtonItem *infoButton;
 
    
    int                            rowSkip;
    UIColor                        *activeColor;
      
     
}
  
@property(nonatomic, readwrite) UIInterfaceOrientation currentOrientation;
@property (retain, nonatomic) IBOutlet UIView *baseView;

@end

NS_ASSUME_NONNULL_END
