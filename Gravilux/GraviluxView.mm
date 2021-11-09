//
//  GraviluxView.m
//  Gravilux
//
//  Created by Colin Roache on 9/15/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "GraviluxView.h"
 
 @interface GraviluxView ()
 
 @end

@implementation GraviluxView
 

#pragma mark - Properties

//added by @solysky20200825
 - (UIImage*) screenShotImag
 {
       CGSize winSize = ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size;
       CGRect rect;
       rect.size = winSize;
       int backingWidth = rect.size.width;
       int backingHeight =  rect.size.height;
       CGSize size = CGSizeMake(backingWidth, backingHeight);
       UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
       CGRect rec = CGRectMake(0, 0, backingWidth, backingHeight);
       [self drawViewHierarchyInRect:rec afterScreenUpdates:YES];
       UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
       return image;
 }

- (id)init
{
	if(self = [super init]) {
		self.multipleTouchEnabled = YES; 
	}
	return self;
}
  

- (void)setFramebuffer
{
#ifdef OPENGL_ENABLED
	[super setFramebuffer];
#endif
	CGSize winSize = ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size;
    //float w = winSize.width;
    //float h = winSize.height;
#ifdef OPENGL_ENABLED
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof (0, winSize.width, winSize.height, 0, 1, 0);
	
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
#else
    CGRect rect;
    rect.size = winSize;
    [super initWithFrame:rect];
#endif
      
    
}
 

@end

