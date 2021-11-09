//
//  GraviluxView.h
//  Gravilux
//
//  Created by Colin Roache on 9/15/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
#ifdef OPENGL_ENABLED
#include "ofxMSAShape3D.h"
#endif
#include "Gravilux.h"

#ifdef OPENGL_ENABLED
    #import "EAGLView.h"
@interface GraviluxView : EAGLView { }
- (UIImage*)screenShotImag;
@end
#else
    #include <MetalKit/MTKView.h>
@interface GraviluxView : MTKView {
 
}
  
- (UIImage*) screenShotImag;
@end
#endif



