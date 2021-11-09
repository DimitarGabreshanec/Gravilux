//
//  MainViewContorller.m
//  Gravilux
//
//  Created by SolYsky on 2020/10/4.
//  Copyright © 2020 SolYsky. All rights reserved.
//

#import "MainViewController.h"
#import "SettingViewController.h"
#import "InfoViewController.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define RGB(r, g, b) [UIColor colorWithRed:(float)r / 255.0 green:(float)g / 255.0 blue:(float)b / 255.0 alpha:1.0]
#define MUSIC1  @"Night Sea - Still - 06 Grand Bleu.m4a"

@interface MainViewController(Private)
- (void)hideAllView:(UIView*)sendor;
- (void) syncControls;
- (void)resetAll;
@end

@implementation MainViewController 

@synthesize  customDelegate, topToolBar, bottomToolBar, bottomChevro, antigravityButton, antigravityButton_pad, wideToolBar, passthroughViews,
    menuInfo,
    menuTextView,
    menuSettingView,
    menuMusicView,
    menuGravilux;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.popoverPresentationController.delegate = self;
    self.hidesBottomBarWhenPushed = true;
     
    menuType = enumMenuType::MENU_NONE;
    
    menuTextView.hidden = YES;
    menuSettingView.hidden = YES;
    menuMusicView.hidden = YES;
    bottomChevro.hidden = NO;
    bottomChevro.alpha = 1.0;
 
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        wideToolBar.hidden = YES;
        bottomToolBar.hidden = NO;
    }
    else{
        wideToolBar.hidden = NO;
        bottomToolBar.hidden = YES;
    } 
        
    [[AVAudioSession sharedInstance]
     setCategory:AVAudioSessionCategoryPlayback
     error:nil];
 
    //Music loaded
    gGravilux->visualizer()->setLoaded(true);
    
    mediaPicker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic] retain];
    [mediaPicker setDelegate: self];
    strFileName = MUSIC1;
}

#pragma mark MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    loadingFlag = true;
    bool useModal = false;
    [UIView animateWithDuration:useModal?0.:TRANSITION_LENGTH_S animations:^{
        MPMediaItem* selectedItem = [mediaItemCollection.items objectAtIndex:0];
        assetURL = [selectedItem valueForProperty:MPMediaItemPropertyAssetURL];
        strFileName = selectedItem.title;
        [[NSUserDefaults standardUserDefaults] setValue:strFileName forKey:@"title"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        firstRun = false;
         
    } completion:^(BOOL finished) {
        if (finished) {
            UIResponder *responder = self;
            while (responder && ![responder isKindOfClass:[MainViewController class]]) {
                responder = [responder nextResponder];
            }
            [((UIViewController*)responder) dismissViewControllerAnimated:NO completion:nil];
            if (assetURL) { // we have the file
                if (!useModal) {
                    [mediaPicker.view removeFromSuperview];
                    [mediaPicker release];
                }
            } else { // Cannot play file
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Could not play song" message:@"This song appears to have DRM (copy protection). Please use a MP3 or an unprotected AAC file" preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                        //button click event
                                    }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }
            menuType = enumMenuType::MENU_NONE;
            [self showMusic: nil];
        }
    }];
}
 
- (void)pickSong
{
    if (@available(iOS 13.0, *)) {
        if ([self respondsToSelector:NSSelectorFromString(@"overrideUserInterfaceStyle")]) {
            [self setValue:@(UIUserInterfaceStyleLight) forKey:@"overrideUserInterfaceStyle"];
        }
    }
//    [Flurry logEvent:@"Visualizer Pick Song"];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                            kFIRParameterItemCategory:@"Music View",
                            kFIRParameterItemName:@"Choose Song"
                        }];
    
    gGravilux->visualizer()->stop();
    
    // Bring up the media picker
    mediaPicker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic] retain];  //MPMediaTypeMusic
     
    mediaPicker.delegate = self;
    //mediaPicker.delegate = id<MPMediaPickerControllerDelegate>(self);
    mediaPicker.allowsPickingMultipleItems = false;
    mediaPicker.showsItemsWithProtectedAssets = false;
    mediaPicker.showsCloudItems = false;    // only show locally cached songs
    // Find the fullscreen
    UIResponder *responder = self;
    while (responder && ![responder isKindOfClass:[MainViewController class]]) {
        responder = [responder nextResponder];
    }
    
    //[((UIViewController *)responder).view  addSubview:mediaPicker.view];
    mediaPicker.modalPresentationStyle = UIModalPresentationFullScreen;
    [(UIViewController*)responder presentViewController:mediaPicker animated:YES completion:nil];
    

    mediaPicker.view.autoresizingMask = 0xFFFFFFFF;
    mediaPicker.view.alpha = 0.5;
    [UIView animateWithDuration:TRANSITION_LENGTH_S
            animations:^{
        mediaPicker.view.alpha = 1.; //may insert mpmediaquery
    } completion:nil];

}

- (void)dealloc {

    [super dealloc];
   [[NSNotificationCenter defaultCenter] removeObserver:self];

    [topToolBar release];
    [bottomToolBar release];
    [bottomChevro release];
    [wideToolBar release];
    if(grviluxVC != nil)
        [grviluxVC release];
 
   if(antigravityButton != nil)
       [antigravityButton release];

   if(antigravityButton_pad != nil)
       [antigravityButton_pad release]; 
   
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);

    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);

    CGPoint position = view.layer.position;

    position.x -= oldPoint.x;
    position.x += newPoint.x;

    position.y -= oldPoint.y;
    position.y += newPoint.y;

    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}


- (IBAction)infoViewShow:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    menuType = enumMenuType::MENU_NONE;
    [self hideAllView:nil];
    menuInfo.hidden = NO;

    [FIRAnalytics logEventWithName:kFIREventSelectContent
    parameters:@{
                 kFIRParameterItemCategory:@"Info View",
                 kFIRParameterItemName:@"Show"
                 }];
}

- (IBAction)resetGrid:(id)sender forEvent:(UIEvent*)event {
    
    UITouch*    firstTouch = nil;
    if (   (nil != ((firstTouch = event.allTouches.allObjects.firstObject)))
        && (2 == firstTouch.tapCount))
    {
        [self resetAll];     // reset everything on double-tap
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
        parameters:@{
                     kFIRParameterItemCategory:@"Grid Button",
                     kFIRParameterItemName:@"Reset All"
                     }];
        
    } else {
        gGravilux->resetGrains();   // only reset grid on single-tap

        [FIRAnalytics logEventWithName:kFIREventSelectContent
        parameters:@{
                     kFIRParameterItemCategory:@"Grid Button",
                     kFIRParameterItemName:@"Reset Grid"
                     }];
    }
    
    [self hideAllView:nil];
}

- (void)resetAll
{
    gGravilux->resetGrains();
    gGravilux->params()->setDefaults(true);
    
    [self syncControls];
    
}


- (void) syncControls
{
    Parameters * p = gGravilux->params();
    p->savePreset(0);
    
    if (!p->antigravity()) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            antigravityButton.selected = YES;   // antigravity
            antigravityButton.highlighted = NO;   // antigravity
            antigravityButton.enabled = YES;
        }
        else{
            antigravityButton_pad.selected = YES;   // antigravity
            antigravityButton_pad.highlighted = NO;   // antigravity
            antigravityButton_pad.enabled = YES;
        }
        
    } else {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            antigravityButton.selected = NO;   // gravity
            antigravityButton.highlighted = YES;   // gravity
            antigravityButton.enabled = YES;
        }
        else{
            antigravityButton_pad.selected = NO;   // gravity
            antigravityButton_pad.highlighted = YES;   // gravity
            antigravityButton_pad.enabled = YES;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateSettingsUI" object:nil]; // update settings if they have changed
    
}

- (IBAction)onMenuShow:(id)sender {
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationCurveEaseIn animations:^(void) { 
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            bottomToolBar.hidden = NO;
            bottomToolBar.alpha = TOOLBAR_ALPHA;
        }
        else{
            wideToolBar.hidden = NO;
            wideToolBar.alpha = TOOLBAR_ALPHA;
        }
        
        topToolBar.hidden = NO;
        topToolBar.alpha = TOOLBAR_ALPHA;
   
        bottomChevro.alpha = 0.0;
        
        menuTextView.alpha = TOOLBAR_ALPHA;
        menuMusicView.alpha = TOOLBAR_ALPHA;
        menuSettingView.alpha = TOOLBAR_ALPHA;
         
        if(menuType == enumMenuType::MENU_TEXT){
            menuType = enumMenuType::MENU_NONE;
            [self showText:self];
        }
        else if(menuType == enumMenuType::MENU_SETTING){
            menuType = enumMenuType::MENU_NONE;
            [self showSetting:self];
        }
        else if(menuType == enumMenuType::MENU_MUSIC){
            menuType = enumMenuType::MENU_NONE;
            [self showMusic:self];
        }
        else if(menuType == enumMenuType::MENU_SHARE){
            menuType = enumMenuType::MENU_NONE;
            [self onShareButton:self];
        }
         
    }
    completion:^(BOOL)
    {
        bottomChevro.hidden = YES;
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                               parameters:@{
                                   kFIRParameterItemCategory:@"Toolbar",
                                   kFIRParameterItemName:@"Show"
                               }];
    }];
}

- (IBAction)onMenuHide:(id)sender {
 
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^(void){
 
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            bottomToolBar.alpha = 0.0;
        }
        else{
            wideToolBar.alpha = 0.0;
        }
        
        topToolBar.alpha = 0.0;
        bottomChevro.hidden = NO;
        bottomChevro.alpha = 1.0;
        
        menuTextView.alpha = 0.0;
        menuMusicView.alpha = 0.0;
        menuSettingView.alpha = 0.0;
        
        [self dismissViewControllerAnimated:NO completion:nil];
         
    }
    completion:^(BOOL)
     {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            bottomToolBar.hidden = YES;
        }
        else{
            wideToolBar.hidden = YES;
        }
        
        topToolBar.hidden = YES;
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                               parameters:@{
                                   kFIRParameterItemCategory:@"Toolbar",
                                   kFIRParameterItemName:@"Hide"
                               }];
     }];
}
 
- (IBAction)showText:(id)sender {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone){
        [self hideAllView:menuTextView];
    }
    else{
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        TextViewController * contentVC = [storyboard instantiateViewControllerWithIdentifier:@"TextViewController"];
        if(menuType == enumMenuType::MENU_TEXT){
            [self dismissViewControllerAnimated:YES completion:nil];
            menuType = enumMenuType::MENU_NONE;
        }
        else{
            if(menuType != enumMenuType::MENU_TEXT){
                [self dismissViewControllerAnimated:NO completion:nil];
            }
            contentVC.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popPC = contentVC.popoverPresentationController;
            contentVC.popoverPresentationController.backgroundColor = RGB(32, 32, 32);
            contentVC.popoverPresentationController.barButtonItem = shadowTextBtn;
            contentVC.popoverPresentationController.canOverlapSourceViewRect = true; 
            contentVC.popoverPresentationController.sourceView = self.view;
            popPC.permittedArrowDirections = UIPopoverArrowDirectionDown;
            popPC.delegate = self;
            popPC.passthroughViews = [NSArray arrayWithObject:self.view];
            [self presentViewController:contentVC animated:YES completion:nil];
            
            menuType = enumMenuType::MENU_TEXT;
            
            [FIRAnalytics logEventWithName:kFIREventSelectContent
            parameters:@{
                         kFIRParameterItemCategory:@"Text View",
                         kFIRParameterItemName:@"Show"
                         }];
        }

//        gGravilux->params()->setAntigravity(!(gGravilux->params()->antigravity()));
    }
    [self syncControls];
     
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverController
{
    return NO;
}

- (IBAction)showMusic:(id)sender {
     
    //added by @Sergysky 20210307
//    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
//        return;
//    }
   
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone){
        [self hideAllView:menuMusicView];
    }
    else{
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        MusicViewController * contentVC = [storyboard instantiateViewControllerWithIdentifier:@"MusicViewController"];
        contentVC->mainVC = self;
        if(menuType == enumMenuType::MENU_MUSIC){
            [self dismissViewControllerAnimated:YES completion:nil];
            menuType = enumMenuType::MENU_NONE;
        }
        else{
            if(menuType != enumMenuType::MENU_MUSIC){
                [self dismissViewControllerAnimated:NO completion:nil];
            } 
            //[contentVC loadUI];
            contentVC.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popPC = contentVC.popoverPresentationController;
            contentVC.popoverPresentationController.backgroundColor = RGB(32, 32, 32);
            contentVC.popoverPresentationController.barButtonItem = shadowMusicBtn;
            contentVC.popoverPresentationController.canOverlapSourceViewRect = true;
            contentVC.popoverPresentationController.sourceView = self.view;
            popPC.permittedArrowDirections = UIPopoverArrowDirectionDown;
            popPC.delegate = self;
            popPC.passthroughViews = [NSArray arrayWithObject:self.view];
            [self presentViewController:contentVC animated:YES completion:nil];
            menuType = enumMenuType::MENU_MUSIC;
            
            [FIRAnalytics logEventWithName:kFIREventSelectContent
            parameters:@{
                         kFIRParameterItemCategory:@"Music View",
                         kFIRParameterItemName:@"Show"
                         }];
        }

//        gGravilux->params()->setAntigravity(!(gGravilux->params()->antigravity()));
    }
}

- (IBAction)showSetting:(id)sender { 
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone){
        [self hideAllView:menuSettingView];
    }
    else{
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        SettingViewController * contentVC = [storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
        if(menuType == enumMenuType::MENU_SETTING){
            [self dismissViewControllerAnimated:YES completion:nil];
            menuType = enumMenuType::MENU_NONE;
        }
        else{
            if(menuType != enumMenuType::MENU_SETTING){
                [self dismissViewControllerAnimated:NO completion:nil];
            }
            contentVC.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popPC = contentVC.popoverPresentationController;
            contentVC.popoverPresentationController.backgroundColor = RGB(32, 32, 32);
            contentVC.popoverPresentationController.barButtonItem = shadowSettingBtn;
            contentVC.popoverPresentationController.canOverlapSourceViewRect = true;
            contentVC.popoverPresentationController.sourceView = self.view;
            popPC.permittedArrowDirections = UIPopoverArrowDirectionDown;
            popPC.delegate = self;
            popPC.passthroughViews = [NSArray arrayWithObject:self.view];
            [self presentViewController:contentVC animated:YES completion:nil];
            menuType = enumMenuType::MENU_SETTING;
            
            [FIRAnalytics logEventWithName:kFIREventSelectContent
            parameters:@{
                         kFIRParameterItemCategory:@"Settings View",
                         kFIRParameterItemName:@"Show"
                         }];
        }
    }
}

- (IBAction)onShareButton:(id)sender {
    if (@available(iOS 13.0, *)) {
        if ([self respondsToSelector:NSSelectorFromString(@"overrideUserInterfaceStyle")]) {
            [self setValue:@(UIUserInterfaceStyleDark) forKey:@"overrideUserInterfaceStyle"];
        }
    }
    UIImage *screenImage = [self watermarkImage:[self screenshotImage]];
    NSString* msgString =  [NSString stringWithFormat:@"I created this with Gravilux on my %@. https://www.snibbe.com/gravilux-app", [[UIDevice currentDevice] model]];
    NSArray *items = @[screenImage, msgString];
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    
    controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
//        NSLog(@"completed dialog - activity: %@ - finished flag: %d", activityType, completed);
        
        if (completed) {
            [FIRAnalytics logEventWithName:kFIREventSelectContent
                                parameters:@{
                                    kFIRParameterItemCategory:@"Share View",
                                    kFIRParameterItemName:@"Share",
                                    kFIRParameterItemID: activityType
                                }];
        } else {
            [FIRAnalytics logEventWithName:kFIREventSelectContent
                                parameters:@{
                                    kFIRParameterItemCategory:@"Share View",
                                    kFIRParameterItemName:@"Cancel Share"
                                }];
        }
    };

    controller.view.backgroundColor = RGB(32, 32, 32);
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone){
        [self presentActivityController:controller];
    }
    else{
        if(menuType == enumMenuType::MENU_SHARE){
            [self dismissViewControllerAnimated:YES completion:nil];
            menuType = enumMenuType::MENU_NONE;
        }
        else{
            if(menuType != enumMenuType::MENU_SHARE){
                [self dismissViewControllerAnimated:NO completion:nil];
            }
            [self presentActivityController:controller];
            menuType = enumMenuType::MENU_SHARE;
            
            [FIRAnalytics logEventWithName:kFIREventSelectContent
            parameters:@{
                         kFIRParameterItemCategory:@"Share View",
                         kFIRParameterItemName:@"Show"
                         }];
        }
    }
   [self hideAllView:nil];
    
}

- (IBAction)toggleAntigravity:(id)sender
{
    [FIRAnalytics logEventWithName:kFIREventSelectContent
    parameters:@{
                 kFIRParameterItemCategory:@"Gravity Button",
                 kFIRParameterItemName: gGravilux->params()->antigravity() ? @"Gravity" : @"Antigravity"
                 }];
    
    gGravilux->params()->setAntigravity(!(gGravilux->params()->antigravity()));
    
    [self syncControls];
    [self hideAllView:nil];
    [customDelegate onVisibleMenu:@"showSetting"];
}

- (void)presentActivityController:(UIActivityViewController *)controller {
 
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    [controller.view setBackgroundColor:RGB(32, 32, 32)];
    
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    popController.barButtonItem = shadowShareBtn;
    [popController setBackgroundColor:RGB(32, 32, 32)];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        
    }
    else{
        popController.sourceView = self.view;
        popController.sourceRect = CGRectMake(self.view.bounds.size.width, self.view.bounds.size.height, 0, 0);
        popController.delegate = self;
    }
    self.presentedViewController.view.backgroundColor = RGB(32, 32, 32);
}

- (UIImage *)screenshotImage {
     return [(id) gGraviluxView screenShotImag];    //changed by @solysky20200825
}

- (UIImage*)watermarkImage:(UIImage *)image
{
#ifndef WATERMARK_SCREENSHOT
    return image;
#endif
    
    UIImage *logo = [UIImage imageNamed:WATERMARK_IMAGE];
    
    UIGraphicsBeginImageContext( image.size );
    
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    [logo drawInRect:CGRectMake(WATERMARK_OFFSET_X, image.size.height - logo.size.height - WATERMARK_OFFSET_Y,logo.size.width,logo.size.height) blendMode:kCGBlendModePlusLighter alpha:WATERMARK_ALPHA];
    
    UIImage *composite = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return composite;
}

- (void)hideAllView:(UIView*)sender
{
    if([sender isEqual:menuTextView])
    {
        sender.hidden = !sender.hidden;
        menuMusicView.hidden = YES;
        menuSettingView.hidden = YES;
    }
    else if([sender isEqual:menuMusicView])
    {
        sender.hidden = !sender.hidden;
        menuTextView.hidden = YES;
        menuSettingView.hidden = YES;
    }
    else if([sender isEqual:menuSettingView])
    {
        sender.hidden = !sender.hidden;
        menuMusicView.hidden = YES;
        menuTextView.hidden = YES;
    }
    else
    {
        menuMusicView.hidden = YES;
        menuTextView.hidden = YES;
        menuSettingView.hidden = YES;
    }
   
}
 
- (void)onCloseInfo: (NSString*) name
{
    [menuInfo setHidden:YES];
}

//must insert for full screen
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    [self hideAllView:sender];
    
    if ([segue.identifier isEqualToString:@"MenuSettingView"]) {
        SettingViewController *menuVC = (SettingViewController *)segue.destinationViewController;
         customDelegate = menuVC;
    }
    else if ([segue.identifier isEqualToString:@"InfoViewController"]) {
        InfoViewController *menuVC = (InfoViewController *)segue.destinationViewController;
        menuVC.infoDelegate = self;
    }
    else if ([segue.identifier isEqualToString:@"TextViewController"]) {
        TextViewController *menuVC = (TextViewController *)segue.destinationViewController;
        if (@available(iOS 13.0, *))
        {
            menuVC.modalInPresentation = true;
        }
        
        //[menuVC.view setBounds:CGRectMake(menuVC.view.bounds.origin.x, menuVC.view.bounds.origin.y - 20, menuVC.view.bounds.size.width, menuVC.view.bounds.size.height)];
    }
     
}

#pragma mark - POPOVER PRESENTATION CONTROLLER DELEGATE

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    self.popoverPresentationController.delegate = self;
    popoverPresentationController.passthroughViews = [NSArray arrayWithObject:self.view];
    return NO;
}
 
#pragma mark - UI View Rotation
- (BOOL)shouldAutorotate
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return NO;
    else
        return YES;
}
  
@end
