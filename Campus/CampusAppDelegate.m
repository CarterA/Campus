//
//  CampusAppDelegate.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusAppDelegate.h"
#import "CampusLoginController.h"
#import "CampusTermsController.h"
#import "ICConnection.h"
#import "EMKeychainItem.h"
#import <QuartzCore/QuartzCore.h>

@interface CampusAppDelegate ()
@property (nonatomic, retain) CampusLoginController *loginController;
@property (nonatomic, retain) CampusTermsController *termsController;
@end

@implementation CampusAppDelegate

@synthesize window, mainView, accessoryView, termListPlaceholderView;
@synthesize progressIndicator;
@synthesize loginController=_loginController;
@synthesize termsController=_termsController;

- (void)dealloc {
	[_loginController release];
	[_termsController release];
	[super dealloc];
}

- (void)awakeFromNib {
	
	// Create the terms view controller
	self.termsController = [[CampusTermsController alloc] initWithNibName:@"CampusTermsView" bundle:[NSBundle mainBundle]];
	self.termsController.view.frame = self.termListPlaceholderView.bounds;
	[self.termListPlaceholderView addSubview:self.termsController.view];
	
	// Add the accessory view to the window
	/*NSView *themeFrame = [[self.window contentView] superview];
	NSRect containerFrame = themeFrame.frame;
	NSRect accessoryViewFrame = self.accessoryView.frame;
	NSRect newFrame = NSMakeRect(containerFrame.size.width - accessoryViewFrame.size.width, containerFrame.size.height - accessoryViewFrame.size.height, accessoryViewFrame.size.width, accessoryViewFrame.size.height);
	self.accessoryView.frame = newFrame;
	[themeFrame addSubview:self.accessoryView];*/
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//self.loginController = [[CampusLoginController alloc] initWithWindowNibName:@"CampusLogin"];
	//[NSApp beginSheet:self.loginController.window modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	// Obtain login information.
	NSString *username = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Username" withExtension:@"txt"] encoding:NSASCIIStringEncoding error:nil];
	EMInternetKeychainItem *item = [EMInternetKeychainItem internetKeychainItemForServer:@"campus.dpsk12.org" withUsername:username path:nil port:0 protocol:kSecProtocolTypeAny];
	
	// Scrape as much data as possible using an ICConnection object.
	ICConnection *campusConnection = [[ICConnection alloc] init];
	[self.progressIndicator setUsesThreadedAnimation:YES];
	[self.progressIndicator startAnimation:self];
	[campusConnection scrapeDataWithUsername:item.username password:item.password completionHandler:^(ICResponse *response) {
		
		[self.progressIndicator stopAnimation:self];
		[self.progressIndicator removeFromSuperview];
		
		self.termsController.terms = response.terms;
		[self.termsController.tableView reloadData];
		
	}];
	[campusConnection release];
	
}

- (BOOL)shouldCloseSheet:(id)sender { return YES; }

@end