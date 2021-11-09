//
//  SettingViewController.m
//  Gravilux
//
//  Created by SolYsky on 2020/9/25.
//  Copyright © 2020 Scott Snibbe Studio. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController(Public)
- (void)syncControls;
//- (void)syncControlsColor;
//- (void)syncControlsRandColor;
 
@end

@implementation SettingViewController 
 
- (void)viewDidLoad {
    [super viewDidLoad];
    [self syncControls];
//    [self syncControlsColor];
//    [self syncControlsRandColor];
    
    if (@available(iOS 14.0, *))
    {
        colorRan1.hidden = YES;
        colorRan2.hidden = YES;
        colorRan3.hidden = YES;
        colorRandom1.hidden = NO;
        colorRandom2.hidden = NO;
        colorRandom3.hidden = NO;
        
        colorRandom3.layer.cornerRadius = colorRandom3.bounds.size.width / 2;
        
        colorRandom2.layer.cornerRadius = colorRandom2.bounds.size.width / 2;
        colorRandom2.layer.masksToBounds = true;
        
        colorRandom1.layer.cornerRadius = colorRandom1.bounds.size.width / 2;
        colorRandom1.layer.masksToBounds = true;
    }
    else
    {
        colorRan1.hidden = NO;
        colorRan2.hidden = NO;
        colorRan3.hidden = NO;
        colorRandom1.hidden = YES;
        colorRandom2.hidden = YES;
        colorRandom3.hidden = YES;
    }
    // register for when the color picker is dismissed, to send analytic event
}
- (void)dealloc {
    [colorRandom1 release];
    [colorRandom2 release];
    [colorRandom3 release];
    [super dealloc];
} 
- (IBAction)resetAll:(id)sender
{
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                            kFIRParameterItemCategory:@"Settings View",
                            kFIRParameterItemName:@"Reset All"
                        }];
    
    gGravilux->resetGrains();
    gGravilux->params()->setDefaults(true);
    
    [self syncControls];
}

- (IBAction)greyColor:(UIButton *)sender
{
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                            kFIRParameterItemCategory:@"Settings View",
                            kFIRParameterItemName:@"Set Grey Colors"
                        }];
    
    Color greyColors[3];
    
    greyColors[0].r = greyColors[0].g = greyColors[0].b = 0.0;
    greyColors[1].r = greyColors[1].g = greyColors[1].b = 0.5;
    greyColors[2].r = greyColors[2].g = greyColors[2].b = 1.0;
    
    gGravilux->params()->setColors(greyColors);
    gGravilux->params()->setHeatColor(YES);
    

    
    //[self updatePickerFromColors];
    [self syncControls];
}


- (IBAction)updateSetting:(id)sender {
   if ([sender isEqual:sizeSlider]) {
       gGravilux->params()->setStarSize(sizeSlider.value);
       
   } else if ([sender isEqual:densitySlider]) {
       
       int rowscols = (int)sqrtf(densitySlider.value);
       gGravilux->params()->setSize(rowscols, rowscols);
       
   } else if ([sender isEqual:gravitySlider]) {
       float fval = 1.0;
       
       // sender.value ranges from 1 - 100
       float normVal = gravitySlider.value / 100.0;
       // shift scale to allow more range at low end
       fval = powf(normVal, G_SLIDER_EXPONENT);
       fval *= MAX_GRAVITY;
       
       if (fval > 5) fval = roundf(fval);
       gGravilux->params()->setGravity(fval);
       gGravilux->forceState()->setGravity(fval);
   }
    
    [self syncControls];
}

- (IBAction)finishUpdatingSetting:(id)sender {
   if ([sender isEqual:sizeSlider]) {
       
       [FIRAnalytics logEventWithName:kFIREventSelectContent
                           parameters:@{
                               kFIRParameterItemCategory:@"Settings View",
                               kFIRParameterItemName:@"Set Star Size",
                               kFIRParameterValue: [NSNumber numberWithFloat:gGravilux->params()->starSize()]
                           }];
       
   } else if ([sender isEqual:densitySlider]) {
       
       [FIRAnalytics logEventWithName:kFIREventSelectContent
                           parameters:@{
                               kFIRParameterItemCategory:@"Settings View",
                               kFIRParameterItemName:@"Set Star Amount",
                               kFIRParameterValue: [NSNumber numberWithInt:gGravilux->params()->rows()*gGravilux->params()->cols()]
                           }];
       
   } else if ([sender isEqual:gravitySlider] ) {
       
       [FIRAnalytics logEventWithName:kFIREventSelectContent
                           parameters:@{
                               kFIRParameterItemCategory:@"Settings View",
                               kFIRParameterItemName:@"Set Gravity",
                               kFIRParameterValue: [NSNumber numberWithFloat:gGravilux->params()->gravity()]
                           }];
   }
}

- (IBAction)randomColor:(UIButton *)sender
{
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                            kFIRParameterItemCategory:@"Settings View",
                            kFIRParameterItemName:@"Randomize"
                        }];
    
    Color randomColors[3];
    
    for (int i=0; i < 3; i++) {
        randomColors[i].r = (float) arc4random() / (float) UINT32_MAX;
        randomColors[i].g = (float) arc4random() / (float) UINT32_MAX;
        randomColors[i].b = (float) arc4random() / (float) UINT32_MAX;
    }
    
    gGravilux->params()->setColors(randomColors);
    gGravilux->params()->setHeatColor(YES);
    
    // also randomize other settings
    float normVal = FRAND(0.1,0.35); // more limited range than slider
    
    // shift scale to allow more range at low end
    float newGravity = powf(normVal, G_SLIDER_EXPONENT);
    newGravity *= MAX_GRAVITY;
    
    gGravilux->params()->setGravity(newGravity);
    
    bool newAntigravity = FRAND(0,1) > 0.5;
    gGravilux->params()->setAntigravity(newAntigravity);
 
    float newStarSize = FRAND(sizeSlider.minimumValue, sizeSlider.maximumValue);
    gGravilux->params()->setStarSize(newStarSize);
    
    int newRowsCols = round(sqrtf(FRAND(densitySlider.minimumValue, densitySlider.maximumValue)));
    gGravilux->params()->setSize(newRowsCols, newRowsCols);
    
    //[self updatePickerFromColors];
    [self syncControls];
}


- (NSString *) colorToString:(UIColor *) color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"%02x%02x%02x", (int)(red * 255), (int)(green * 255) , (int)(blue * 255)];
}

- (IBAction)selectWellColor:(id)sender {
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
  Color colors[3];
  
#ifdef IS_IOS14_AND_UP
    if (@available(iOS 14.0, *))
    {
        
//        colorPickerController.delegate = self;
        
//        [colorRandom1 setTintColor:colorPickerController.selectedColor];
        [colorRandom1.selectedColor getRed:&red green:&green blue:&blue alpha:&alpha];
        colors[0].r = red;
        colors[0].g = green;
        colors[0].b = blue;
        
//        [colorRandom2 setTintColor:colorPickerController.selectedColor];
        [colorRandom2.selectedColor getRed:&red green:&green blue:&blue alpha:&alpha];
        colors[1].r = red;
        colors[1].g = green;
        colors[1].b = blue;
        
//        [colorRandom3 setTintColor:colorPickerController.selectedColor];
        [colorRandom3.selectedColor getRed:&red green:&green blue:&blue alpha:&alpha];
        colors[2].r = red;
        colors[2].g = green;
        colors[2].b = blue;
        gGravilux->params()->setColors(colors);
        gGravilux->params()->setHeatColor(YES);
        
        NSString *colorsStr = [NSString stringWithFormat:@"#%@ #%@ #%@",
                               [self colorToString:colorRandom1.selectedColor],
                               [self colorToString:colorRandom2.selectedColor],
                               [self colorToString:colorRandom3.selectedColor]];
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                kFIRParameterItemCategory:@"Settings View",
                                kFIRParameterItemName:@"Set Colors",
                                kFIRParameterItemID:colorsStr
                            }];
    }
    
#endif
    
  //[self updatePickerFromColors];
  [self syncControls];
}

//- (IBAction)finishedEditingColor:(id)sender {
//
//    [FIRAnalytics logEventWithName:kFIREventSelectContent
//                           parameters:@{
//                               kFIRParameterItemCategory:@"Settings View",
//                               kFIRParameterItemName:@"Set Colors"
//                           }];
//}

// would only work if we instantiated our own colorPickerViewController
//- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
//API_AVAILABLE(ios(14.0)) {
//    [FIRAnalytics logEventWithName:kFIREventSelectContent
//                           parameters:@{
//                               kFIRParameterItemCategory:@"Settings View",
//                               kFIRParameterItemName:@"Set Colors"
//                           }];
//}

- (void)onVisibleMenu: (NSString*) name
{
    [self syncControls];
}

/*
- (void) syncControlsColor
{
    Parameters * p = gGravilux->params();
    p->savePreset(0);
    
    // Update the color picker if it has loaded
    //if (colorPicker)
    {
        //colorToggle.selected = p->heatColor();
        // Retreive current colors so we can replace the updated one and then set
        Color currentColors[3];
        p->getColors(currentColors);
        
        Color greyColors[3];
        
        greyColors[0].r = greyColors[0].g = greyColors[0].b = 0.0;
        greyColors[1].r = greyColors[1].g = greyColors[1].b = 0.5;
        greyColors[2].r = greyColors[2].g = greyColors[2].b = 1.0;
        
        // Sync the UI circles

    }
    
}
*/
/*
- (void) syncControlsRandColor
{
    Parameters * p = gGravilux->params();
    p->savePreset(0);
    
    // Update the color picker if it has loaded
    //if (colorPicker)
    {
        //colorToggle.selected = p->heatColor();
        // Retrieve current colors so we can replace the updated one and then set
        Color currentColors[3];
        p->getColors(currentColors);
        
        // Sync the UI circles
        if (@available(iOS 14.0, *))
        {
            colorRandom1.selectedColor = [UIColor colorWithRed:currentColors[0].r green:currentColors[0].g blue:currentColors[0].b alpha:1.];
            colorRandom2.selectedColor = [UIColor colorWithRed:currentColors[1].r green:currentColors[1].g blue:currentColors[1].b alpha:1.];
            colorRandom3.selectedColor = [UIColor colorWithRed:currentColors[2].r green:currentColors[2].g blue:currentColors[2].b alpha:1.];
        }
        else
        {
            colorRan1.color = [UIColor colorWithRed:currentColors[0].r green:currentColors[0].g blue:currentColors[0].b alpha:1.];
            colorRan2.color = [UIColor colorWithRed:currentColors[1].r green:currentColors[1].g blue:currentColors[1].b alpha:1.];
            colorRan3.color = [UIColor colorWithRed:currentColors[2].r green:currentColors[2].g blue:currentColors[2].b alpha:1.];
        }
    }
}
*/

- (void) syncControls
{
    // sync parameters
    
    Parameters * p = gGravilux->params();
    p->savePreset(0);
//    antigravityButton.selectedSegmentIndex = !p->antigravity();
     
    sizeSlider.value = p->starSize();
    sizeLabel.text = [NSString stringWithFormat:@"%00.2f", p->starSize()];
    
    densitySlider.value = p->rows()*p->cols();
    densityLabel.text = [NSString stringWithFormat:@"%5.d", p->rows()*p->cols()];
    
    gravitySlider.value = powf((p->gravity() / MAX_GRAVITY), .5) * 100.0;
    gravityLabel.text = [NSString stringWithFormat:@"%00.1f", (p->antigravity() ? -1 : 1) * p->gravity()];
    
    // sync colors
    
    Color currentColors[3];
    p->getColors(currentColors);
    
    //  show white color swatches if not coloring by heat
    if ( !p->heatColor() ) {
        currentColors[0].r = currentColors[1].r = currentColors[2].r = 1.0;
        currentColors[0].g = currentColors[1].g = currentColors[2].b = 1.0;
        currentColors[0].b = currentColors[1].b = currentColors[2].g = 1.0;
    }
    
    // Sync the UI circles
    if (@available(iOS 14.0, *))
    {
        colorRandom1.selectedColor = [UIColor colorWithRed:currentColors[0].r green:currentColors[0].g blue:currentColors[0].b alpha:1.];
        colorRandom2.selectedColor = [UIColor colorWithRed:currentColors[1].r green:currentColors[1].g blue:currentColors[1].b alpha:1.];
        colorRandom3.selectedColor = [UIColor colorWithRed:currentColors[2].r green:currentColors[2].g blue:currentColors[2].b alpha:1.];
    }
    else
    {
        colorRan1.color = [UIColor colorWithRed:currentColors[0].r green:currentColors[0].g blue:currentColors[0].b alpha:1.];
        colorRan2.color = [UIColor colorWithRed:currentColors[1].r green:currentColors[1].g blue:currentColors[1].b alpha:1.];
        colorRan3.color = [UIColor colorWithRed:currentColors[2].r green:currentColors[2].g blue:currentColors[2].b alpha:1.];
    }
    
}

#pragma mark - Overridden Subclass Methods
#pragma mark UIView
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) { 
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncControls) name:@"updateSettingsUI" object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncControlsRandColor) name:@"ParametersDidUpdateColorsNotification" object:nil];
    }
    return self;
}
 
- (BOOL)shouldAutorotate
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return NO;
    else
        return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

@end
