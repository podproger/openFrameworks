/***********************************************************************
 
 Copyright (c) 2008, 2009, Memo Akten, www.memo.tv
 *** The Mega Super Awesome Visuals Company ***
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of MSA Visuals nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 * ***********************************************************************/ 

#import "ofMain.h"
#import "ofGLProgrammableRenderer.h"
#import "ofAppiOSWindow.h"
#import "ofxiOSEAGLView.h"
#import "ofxiOSAppDelegate.h"
#import "ofxiOSViewController.h"
#import "ofxiOSExtras.h"

//-------------------------------------------------------------------------------------
ofAppiOSWindow::Settings::Settings() {
    enableRetina = false;
    enableDepth = false;
    enableAntiAliasing = false;
    numOfAntiAliasingSamples = 0;
    enableHardwareOrientation = false;
    enableHardwareOrientationAnimation = false;
    enableSetupScreen = true;
    rendererType = OFXIOS_RENDERER_ES1;
    windowMode = OF_FULLSCREEN;
}

//----------------------------------------------------------------------------------- instance.
static ofAppiOSWindow * _instance = NULL;
ofAppiOSWindow * ofAppiOSWindow::getInstance() {
	return _instance;
}

//----------------------------------------------------------------------------------- constructor / destructor.
ofAppiOSWindow::ofAppiOSWindow(Settings _settings) {
	if(_instance == NULL) {
        _instance = this;
    } else {
        ofLogError("ofAppiOSWindow") << "instanciated more than once";
    }
    
    settings = _settings;
    
    if(settings.rendererType == OFXIOS_RENDERER_ES1) {
        enableRendererES1();
    } else if(settings.rendererType == OFXIOS_RENDERER_ES2) {
        enableRendererES2();
    }

    orientation = OF_ORIENTATION_UNKNOWN;
    
    bRetinaSupportedOnDevice = false;
    bRetinaSupportedOnDeviceChecked = false;
}

ofAppiOSWindow::~ofAppiOSWindow() {
    //
}

//----------------------------------------------------------------------------------- opengl setup.
void ofAppiOSWindow::setupOpenGL(int w, int h, ofWindowMode screenMode) {
	settings.windowMode = screenMode; // use this as flag for displaying status bar or not
}

void ofAppiOSWindow::initializeWindow() {
    //
}

void ofAppiOSWindow::runAppViaInfiniteLoop(ofBaseApp * appPtr) {
    startAppWithDelegate("ofxiOSAppDelegate");
}

void ofAppiOSWindow::startAppWithDelegate(string appDelegateClassName) {
    static bool bAppCreated = false;
    if(bAppCreated == true) {
        return;
    }
    bAppCreated = true;
    
    @autoreleasepool {
        UIApplicationMain(nil, nil, nil, [NSString stringWithUTF8String:appDelegateClassName.c_str()]);
    }
}


//----------------------------------------------------------------------------------- cursor.
void ofAppiOSWindow::hideCursor() {
    // not supported on iOS.
}

void ofAppiOSWindow::showCursor() {
    // not supported on iOS.
}

//----------------------------------------------------------------------------------- window / screen properties.
void ofAppiOSWindow::setWindowPosition(int x, int y) {
	// not supported on iOS.
}

void ofAppiOSWindow::setWindowShape(int w, int h) {
	// not supported on iOS.
}

ofPoint	ofAppiOSWindow::getWindowPosition() {
	return *[[ofxiOSEAGLView getInstance] getWindowPosition];
}

ofPoint	ofAppiOSWindow::getWindowSize() {
	return *[[ofxiOSEAGLView getInstance] getWindowSize];
}

ofPoint	ofAppiOSWindow::getScreenSize() {
	return *[[ofxiOSEAGLView getInstance] getScreenSize];
}

int ofAppiOSWindow::getWidth(){
	if(settings.enableHardwareOrientation == true ||
       orientation == OF_ORIENTATION_DEFAULT ||
       orientation == OF_ORIENTATION_180) {
		return (int)getWindowSize().x;
	}
	return (int)getWindowSize().y;
}

int ofAppiOSWindow::getHeight(){
	if(settings.enableHardwareOrientation == true ||
       orientation == OF_ORIENTATION_DEFAULT ||
       orientation == OF_ORIENTATION_180) {
		return (int)getWindowSize().y;
	}
	return (int)getWindowSize().x;
}

ofWindowMode ofAppiOSWindow::getWindowMode() {
	return settings.windowMode;
}

//----------------------------------------------------------------------------------- orientation.
void ofAppiOSWindow::setOrientation(ofOrientation toOrientation) {
    if(orientation == toOrientation) {
        return;
    }
    bool bOrientationPortraitOne = (orientation == OF_ORIENTATION_DEFAULT) || (orientation == OF_ORIENTATION_180);
    bool bOrientationPortraitTwo = (toOrientation == OF_ORIENTATION_DEFAULT) || (toOrientation == OF_ORIENTATION_180);
    bool bResized = bOrientationPortraitOne != bOrientationPortraitTwo;

    orientation = toOrientation;
    
    UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationPortrait;
    switch (orientation) {
        case OF_ORIENTATION_DEFAULT:
            interfaceOrientation = UIInterfaceOrientationPortrait;
            break;
        case OF_ORIENTATION_180:
            interfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        case OF_ORIENTATION_90_RIGHT:
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case OF_ORIENTATION_90_LEFT:
            interfaceOrientation = UIInterfaceOrientationLandscapeRight;
            break;
    }

    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    if([appDelegate respondsToSelector:@selector(glViewController)] == NO) {
        // check app delegate has glViewController,
        // otherwise calling glViewController will cause a crash.
        return;
    }
    ofxiOSViewController * glViewController = ((ofxiOSAppDelegate *)appDelegate).glViewController;
    ofxiOSEAGLView * glView = glViewController.glView;
    
    if(settings.enableHardwareOrientation == true) {
        [glViewController rotateToInterfaceOrientation:interfaceOrientation animated:settings.enableHardwareOrientationAnimation];
    } else {
        [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:settings.enableHardwareOrientationAnimation];
        if(bResized == true) {
            [glView layoutSubviews]; // calling layoutSubviews so window resize notification is fired.
        }
    }
}

ofOrientation ofAppiOSWindow::getOrientation() {
	return orientation;
}

bool ofAppiOSWindow::doesHWOrientation() {
    return settings.enableHardwareOrientation;
}

//-----------------------------------------------------------------------------------
void ofAppiOSWindow::setWindowTitle(string title) {
    // not supported on iOS.
}

void ofAppiOSWindow::setFullscreen(bool fullscreen) {
    [[UIApplication sharedApplication] setStatusBarHidden:fullscreen withAnimation:UIStatusBarAnimationSlide];
	if(fullscreen) {
        settings.windowMode = OF_FULLSCREEN;
    } else {
        settings.windowMode = OF_WINDOW;
    }
}

void ofAppiOSWindow::toggleFullscreen() {
	if(settings.windowMode == OF_FULLSCREEN) {
        setFullscreen(false);
    } else {
        setFullscreen(true);
    }
}

//-----------------------------------------------------------------------------------
bool ofAppiOSWindow::enableHardwareOrientation() {
    return (settings.enableHardwareOrientation = true);
}

bool ofAppiOSWindow::disableHardwareOrientation() {
    return (settings.enableHardwareOrientation = false);
}

bool ofAppiOSWindow::enableOrientationAnimation() {
    return (settings.enableHardwareOrientationAnimation = true);
}

bool ofAppiOSWindow::disableOrientationAnimation() {
    return (settings.enableHardwareOrientationAnimation = false);
}

//-----------------------------------------------------------------------------------
bool ofAppiOSWindow::enableRendererES2() {
    if(isRendererES2() == true) {
        return false;
    }
    shared_ptr<ofBaseRenderer> renderer(new ofGLProgrammableRenderer(false));
    ofSetCurrentRenderer(renderer);
    return true;
}

bool ofAppiOSWindow::enableRendererES1() {
    if(isRendererES1() == true) {
        return false;
    }
    shared_ptr<ofBaseRenderer> renderer(new ofGLRenderer(false));
    ofSetCurrentRenderer(renderer);
    return true;
}

bool ofAppiOSWindow::isRendererES2() {
    return (ofGetCurrentRenderer() && ofGetCurrentRenderer()->getType()==ofGLProgrammableRenderer::TYPE);
}

bool ofAppiOSWindow::isRendererES1() {
    return (ofGetCurrentRenderer() && ofGetCurrentRenderer()->getType()==ofGLRenderer::TYPE);
}

//-----------------------------------------------------------------------------------
void ofAppiOSWindow::enableSetupScreen() {
	settings.enableSetupScreen = true;
};

void ofAppiOSWindow::disableSetupScreen() {
	settings.enableSetupScreen = false;
};

bool ofAppiOSWindow::isSetupScreenEnabled() {
    return settings.enableSetupScreen;
}

void ofAppiOSWindow::setVerticalSync(bool enabled) {
    // not supported on iOS.
}

//----------------------------------------------------------------------------------- retina.
bool ofAppiOSWindow::enableRetina() {
    if(isRetinaSupportedOnDevice()) {
        settings.enableRetina = true;
    }
    return settings.enableRetina;
}

bool ofAppiOSWindow::disableRetina() {
    return (settings.enableRetina = false);
}

bool ofAppiOSWindow::isRetinaEnabled() {
    return settings.enableRetina;
}

bool ofAppiOSWindow::isRetinaSupportedOnDevice() {
    if(bRetinaSupportedOnDeviceChecked) {
        return bRetinaSupportedOnDevice;
    }
    
    bRetinaSupportedOnDeviceChecked = true;
    
    @autoreleasepool {
        if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]){
            if ([[UIScreen mainScreen] scale] > 1){
                bRetinaSupportedOnDevice = true;
            }
        }
    }
    
    return bRetinaSupportedOnDevice;
}

//----------------------------------------------------------------------------------- depth buffer.
bool ofAppiOSWindow::enableDepthBuffer() {
    return (settings.enableDepth = true);
}

bool ofAppiOSWindow::disableDepthBuffer() {
    return (settings.enableDepth = false);
}

bool ofAppiOSWindow::isDepthBufferEnabled() {
    return settings.enableDepth;
}

//----------------------------------------------------------------------------------- anti aliasing.
bool ofAppiOSWindow::enableAntiAliasing(int samples) {
	settings.numOfAntiAliasingSamples = samples;
    return (settings.enableAntiAliasing = true);
}

bool ofAppiOSWindow::disableAntiAliasing() {
    return (settings.enableAntiAliasing = false);
}

bool ofAppiOSWindow::isAntiAliasingEnabled() {
    return settings.enableAntiAliasing;
}

int	ofAppiOSWindow::getAntiAliasingSampleCount() {
    return settings.numOfAntiAliasingSamples;
}
