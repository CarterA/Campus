//
//  CampusAppDelegate.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusAppDelegate.h"
#import "CampusLoginController.h"
#import "ICConnection.h"
#import "ICTerm.h"
#import "ICCourse.h"
#import "EMKeychainItem.h"
#import <QuartzCore/QuartzCore.h>

@interface CampusAppDelegate ()
@property (nonatomic, retain) CampusLoginController *loginController;
@end

@implementation CampusAppDelegate

@synthesize window, mainView, accessoryView, termListView;
@synthesize progressIndicator;
@synthesize terms;
@synthesize loginController=_loginController;

- (void)dealloc {
	[_loginController release];
	[super dealloc];
}

- (void)awakeFromNib {
	
	// Add the accessory view to the window
	/*NSView *themeFrame = [[self.window contentView] superview];
	NSRect containerFrame = themeFrame.frame;
	NSRect accessoryViewFrame = self.accessoryView.frame;
	NSRect newFrame = NSMakeRect(containerFrame.size.width - accessoryViewFrame.size.width, containerFrame.size.height - accessoryViewFrame.size.height, accessoryViewFrame.size.width, accessoryViewFrame.size.height);
	self.accessoryView.frame = newFrame;
	[themeFrame addSubview:self.accessoryView];*/
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	self.loginController = [[CampusLoginController alloc] initWithWindowNibName:@"CampusLogin"];
	[NSApp beginSheet:self.loginController.window modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	// Obtain login information.
	NSString *username = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Username" withExtension:@"txt"] encoding:NSASCIIStringEncoding error:nil];
	EMInternetKeychainItem *item = [EMInternetKeychainItem internetKeychainItemForServer:@"campus.dpsk12.org" withUsername:username path:nil port:0 protocol:kSecProtocolTypeAny];
	
	// Scrape as much data as possible using an ICConnection object.
	ICConnection *campusConnection = [[ICConnection alloc] init];
	[self.progressIndicator setUsesThreadedAnimation:YES];
	[self.progressIndicator startAnimation:self];
	[self.termListView setMinItemSize:NSMakeSize(20, 60)];
	[campusConnection scrapeDataWithUsername:item.username password:item.password completionHandler:^(ICResponse *response) {
		
		[self.progressIndicator stopAnimation:self];
		[self.progressIndicator removeFromSuperview];
		
		self.terms = response.terms;
		
	}];
	[campusConnection release];
	
}

- (BOOL)shouldCloseSheet:(id)sender { return YES; }

@end