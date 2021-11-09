//
//  SettingViewController.h
//  Gravilux
//
//  Created by SolYsky on 2020/9/25.
//  Copyright © 2020 Scott Snibbe Studio. All rights reserved.
//

 
#import "ColorCircle.h"
#import <UIKit/UIKit.h>
#import "GraviluxViewController.h"
#include "Gravilux.h"
#include "ForceState.h"
#include "Visualizer.h"
#import <FirebaseAnalytics/FIRAnalytics.h>
#import "ColorPickerView.h"
#import "ColorCircle.h"
#import "MainViewController.h"
NS_ASSUME_NONNULL_BEGIN 

#define G_SLIDER_EXPONENT 2.0
#define IS_IOS14_AND_UP ([[UIDevice currentDevice].systemVersion floatValue] >= 14.0)
 

@interface SettingViewController : UIViewController<CustomDelegate, UIColorPickerViewControllerDelegate>
{
    IBOutlet UIButton *greyButton;
    IBOutlet UISlider *gravitySlider;
    IBOutlet UISlider *sizeSlider;
    IBOutlet UISlider *densitySlider;
    IBOutlet UILabel *sizeLabel;
    IBOutlet UILabel *densityLabel;
    IBOutlet UILabel *gravityLabel;
    IBOutlet UIButton *btnResetAll;
//color view
#ifdef IS_IOS14_AND_UP
    API_AVAILABLE(ios(14.0))
    IBOutlet UIColorWell *colorRandom1;
    API_AVAILABLE(ios(14.0))
    IBOutlet UIColorWell *colorRandom2;
    API_AVAILABLE(ios(14.0)) 
    IBOutlet UIColorWell *colorRandom3;
    API_AVAILABLE(ios(14.0))
//    UIColorPickerViewController    *colorPickerController;
    
    IBOutlet ColorCircle *colorRan1;
    IBOutlet ColorCircle *colorRan2;
    IBOutlet ColorCircle *colorRan3;

#else
    IBOutlet ColorCircle *colorRandom1;
    IBOutlet ColorCircle *colorRandom2;
    IBOutlet ColorCircle *colorRandom3;
#endif
}
- (IBAction)greyColor:(UIButton *)sender; 
- (IBAction)updateSetting:(id)sender;
- (IBAction)finishUpdatingSetting:(id)sender;
- (IBAction)randomColor:(UIButton *)sender;
//setting view
 
 


@end


NS_ASSUME_NONNULL_END
