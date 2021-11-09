//
//  AAPLViewController.m
//  Gravilux
//
//  Created by SolYsky on 2020/9/6.
//  Copyright © 2020 Scott Snibbe Studio. All rights reserved.
//

#import "TextViewController.h"
#import "Parameters.h"
#import "GraviluxView.h"
#import "Visualizer.h"


@interface TextViewController(Private)
- (void)showTypeAuxView:(NSNotification*)notification;
- (void)hideTypeAuxView:(NSNotification*)notification;
- (void)hideAllView:(UIView*)sendor;
 
@end

@implementation TextViewController
@synthesize currentOrientation, baseView;
 
   
- (void)viewDidLoad {
    [super viewDidLoad]; 
    
    if (typeAuxView) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideTypeAuxView:) name:UIKeyboardWillHideNotification object:nil];
    }
    
//    if (typeView) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishEditingText:) name:UITextFieldTextDidEndEditingNotification object:nil];
//    }
    
    rowSkip = (typeSize.maximumValue - typeSize.minimumValue)-(typeSize.value - typeSize.minimumValue)+typeSize.minimumValue;
    
} 

- (IBAction)clearTextView:(id)sender {
    typeText.text = @"";
    gGravilux->resetGrainsType(typeText.text, self.currentOrientation, rowSkip);
    //gGravilux->resetGrains();

    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                            kFIRParameterItemCategory:@"Text View",
                            kFIRParameterItemName:@"Clear Text"
                        }];
}
 
 
#pragma mark - Delegate Methods
#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    NSString * text = [(NSString*)textField.text stringByReplacingCharactersInRange:range withString:string];
    if ([[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        gGravilux->resetGrains();
    } else {
        gGravilux->resetGrainsType(text, self.currentOrientation, rowSkip);
    }
    if ([textField isEqual:typeAuxText]) {
        typeText.text = text;
    }
    else if([textField isEqual:typeText]) {
        typeAuxText.text = text;
    }
    
    return true;
}

- (IBAction)finishEditingText:(id)sender {
    
    if (![[typeText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
                                kFIRParameterItemCategory:@"Text View",
                                kFIRParameterItemName:@"Set Text",
                                kFIRParameterItemID: typeText.text
                            }];
    }
}
 
- (void)showTypeAuxView:(NSNotification *)notification
{
    UIViewAnimationCurve animationCurve;
    double duration;
    CGRect keyboardEndFrame, keyboardBeginFrame;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    [[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBeginFrame];
    
    keyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.superview.superview];
    keyboardBeginFrame = [self.view convertRect:keyboardBeginFrame fromView:self.view.superview.superview];
    
    typeAuxView.hidden = NO;
    typeAuxView.alpha = 0.;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:animationCurve];
    typeAuxView.alpha = 1.;
    typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y - typeAuxView.frame.size.height, keyboardEndFrame.size.width, typeAuxView.frame.size.height);
    [UIView commitAnimations];
    
    [typeAuxText performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:duration];
    [UIView animateWithDuration:duration
                          delay:0.
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         typeAuxView.alpha = 1.;
                         typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y - typeAuxView.frame.size.height, keyboardEndFrame.size.width, typeAuxView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (typeAuxText) {
                             [typeAuxText becomeFirstResponder];
                         }
                     }];
}

- (void)hideTypeAuxView:(NSNotification *)notification
{
    UIViewAnimationCurve animationCurve;
    double duration;
    CGRect keyboardEndFrame, keyboardBeginFrame;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    [[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBeginFrame];
    
    keyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.superview.superview];
    keyboardBeginFrame = [self.view convertRect:keyboardBeginFrame fromView:self.view.superview.superview];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:animationCurve];
    typeAuxView.alpha = 0.;
    typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y, typeAuxView.frame.size.width, typeAuxView.frame.size.height);
    [UIView commitAnimations];
    [UIView animateWithDuration:duration
                          delay:0.
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         typeAuxView.alpha = 0.;
                         typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y, typeAuxView.frame.size.width, typeAuxView.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         typeAuxView.hidden = YES;
                     }];
    
    [self finishEditingText:self];
}
 
- (void)dealloc {
    [super dealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if(typeAuxText != nil)
        [typeAuxText release];
    if(typeAuxSize != nil)
        [typeAuxSize release];
    if(typeAuxView != nil)
        [typeAuxView release];
    if(typeView != nil)
        [typeView release];
    if(typeText != nil)
        [typeText release];
    if(typeSize != nil)
        [typeSize release];
    if(shareButton != nil)
        [shareButton release];
    if(activeColor != nil)
        [activeColor release];
  
}

- (IBAction)resizeType:(id)sender
{
    
    if (![[typeText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        if ([sender isKindOfClass:[UISlider class]]) {
            UISlider * slider = sender;
            if ([slider isEqual:typeSize]) {
                typeAuxSize.value = slider.value;
            }
            else if([slider isEqual:typeAuxSize]) {
                typeSize.value = slider.value;
            }
            
            int scaledValue = (slider.maximumValue - slider.minimumValue)-(slider.value - slider.minimumValue)+slider.minimumValue;
            if (rowSkip != scaledValue) {
                rowSkip = scaledValue;
                gGravilux->resetGrainsType(typeText.text, self.currentOrientation, rowSkip);
            }
        }
    }
}

- (IBAction)finishUpdatingSlider:(id)sender {
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                            kFIRParameterItemCategory:@"Text View",
                            kFIRParameterItemName:@"Set Star Density",
                            kFIRParameterValue: [NSNumber numberWithInt:rowSkip]
                        }];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotate
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return NO;
    else
        return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}
 
 
@end
