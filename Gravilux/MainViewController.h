//
//  MainViewController.h
//  Gravilux
//
//  Created by SolYsky on 2020/10/4.
//  Copyright © 2020 SolYsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MetalKit/MTKView.h>
#import "GraviluxViewController.h"
#include "Gravilux.h"
#include "ForceState.h"
#include "Visualizer.h"
 
#import "HelpViewController.h"
#import "MusicViewController.h"
#import "TextViewController.h"
#import <FirebaseAnalytics/FIRAnalytics.h>
 
enum enumMenuType{
    MENU_NONE,
    MENU_SETTING,
    MENU_TEXT,
    MENU_MUSIC,
    MENU_SHARE
};

NS_ASSUME_NONNULL_BEGIN
#define G_SLIDER_EXPONENT           2.0

#define TRANSITION_LENGTH_S         .3f
#define TRANSITION_LENGTH_S         .3f
#define WATERMARK_SCREENSHOT         1
#define WATERMARK_IMAGE              @"symbol.png"
#define WATERMARK_ALPHA             0.8f
#define WATERMARK_OFFSET_X          19
#define WATERMARK_OFFSET_Y          24
 
@protocol InfoviewDelegate <NSObject>
@optional
- (void)onCloseInfo: (NSString*)name;
@end

@protocol CustomDelegate <NSObject>
@optional
- (void)onVisibleMenu: (NSString*)name;
@end

@interface MainViewController : UIViewController<UIScrollViewDelegate, UITextViewDelegate, UITextFieldDelegate, UIColorPickerViewControllerDelegate, UIPopoverPresentationControllerDelegate, MPMediaPickerControllerDelegate, InfoviewDelegate>
{
    GraviluxViewController          *grviluxVC; 
    BOOL portraitView;
    BOOL landscapeView;
    enumMenuType menuType;
    @public 
    IBOutlet UIBarButtonItem *shadowTextBtn;
    IBOutlet UIBarButtonItem *shadowSettingBtn;
    IBOutlet UIBarButtonItem *shadowMusicBtn;
    IBOutlet UIBarButtonItem *shadowShareBtn; 
    MPMediaPickerController* mediaPicker;
} 


@property (retain, nonatomic) IBOutlet UIToolbar *topToolBar;
@property (retain, nonatomic) IBOutlet UIToolbar *bottomToolBar;
@property (retain, nonatomic) IBOutlet UIToolbar *wideToolBar;
@property (retain, nonatomic) IBOutlet UIButton *bottomChevro;
@property (retain, nonatomic) IBOutlet UIButton *antigravityButton_pad;
@property (retain, nonatomic) IBOutlet UIButton *antigravityButton;
@property (retain, nonatomic) IBOutlet UIView *menuTextView;
@property (retain, nonatomic) IBOutlet UIView *menuSettingView;
@property (retain, nonatomic) IBOutlet UIView *menuMusicView;
@property (retain, nonatomic) IBOutlet UIView *menuGravilux;
@property (retain, nonatomic) IBOutlet UIView *menuInfo; 

@property(nonatomic, copy) NSArray *passthroughViews;

@property (nonatomic, weak) id <CustomDelegate> customDelegate;  

- (IBAction)toggleAntigravity:(id)sender;
- (IBAction)resetGrid:(id)sender forEvent:(UIEvent*)event; 
- (IBAction)onMenuHide:(id)sender;
- (IBAction)onMenuShow:(id)sender;
- (IBAction)onShareButton:(id)sender; 
- (IBAction)showText:(id)sender;
- (IBAction)showMusic:(id)sender;
- (IBAction)showSetting:(id)sender;
- (void)pickSong;

@end

NS_ASSUME_NONNULL_END
