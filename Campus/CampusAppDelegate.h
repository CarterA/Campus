//
//  CampusAppDelegate.h
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CZProgressIndicator;

@interface CampusAppDelegate : NSObject <NSApplicationDelegate> {}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *mainView;
@property (assign) IBOutlet NSView *accessoryView;
@property (assign) IBOutlet NSView *termListPlaceholderView;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@end
