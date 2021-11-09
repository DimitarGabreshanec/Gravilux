//
//  InfoViewController.h
//  Gravilux
//
//  Created by Colin Roache on 10/25/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FirebaseAnalytics/FIRAnalytics.h>
#import "MainViewController.h"
#import <WebKit/WebKit.h>

 
@interface InfoViewController : UIViewController </*UIWebViewDelegate,*/ UIScrollViewDelegate, WKNavigationDelegate>
{
    
}
- (void) loadInfoText;
- (IBAction)infoChange:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)learnMore:(id)sender;
@property (retain, nonatomic) IBOutlet UIView *loadingView;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain, nonatomic) IBOutlet UIButton *backButton;
@property (retain, nonatomic) IBOutlet WKWebView *infoWebView; 
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) id <InfoviewDelegate> infoDelegate;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segButton;

@end

