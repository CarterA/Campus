//
//  CampusLoginController.h
//  Campus
//
//  Created by Carter Allen on 2/3/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

@class CZLinkedView;

@interface CampusLoginController : NSWindowController {}
@property (nonatomic, assign) IBOutlet NSView *placeholderView; 
@property (nonatomic, assign) IBOutlet CZLinkedView *currentView;
@property (nonatomic, retain) IBOutlet NSTextField *URLField;
@property (nonatomic, retain) IBOutlet NSTextField *usernameField;
@property (nonatomic, retain) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic, retain) IBOutlet NSButton *nextButton;
@property (nonatomic, retain) IBOutlet NSButton *previousButton;
- (IBAction)next:(id)sender;
- (IBAction)previous:(id)sender;
@end