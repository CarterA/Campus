//
//  CampusAppDelegate.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusAppDelegate.h"
#import "ICConnection.h"
#import "ICTerm.h"
#import "ICCourse.h"
#import "EMKeychainItem.h"
#import "CZProgressIndicator.h"
#import <QuartzCore/QuartzCore.h>

@implementation CampusAppDelegate

@synthesize window, termListParentView;
@synthesize progressIndicator, progressLabel;
@synthesize terms;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
		
	// Obtain login information.
	NSString *username = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Username" withExtension:@"txt"] encoding:NSASCIIStringEncoding error:nil];
	EMInternetKeychainItem *item = [EMInternetKeychainItem internetKeychainItemForServer:@"campus.dpsk12.org" withUsername:username path:nil port:0 protocol:kSecProtocolTypeAny];
	
	// Scrape as much data as possible using an ICConnection object.
	ICConnection *campusConnection = [[ICConnection alloc] init];
	[self.progressIndicator start];
	[campusConnection scrapeDataWithUsername:item.username password:item.password completionHandler:^(ICResponse *response) {
		
		[self.progressLabel setStringValue:@"Loaded."];
		[self.progressIndicator stop];
		self.terms = response.terms;
		
		NSRect bounds = self.termListParentView.bounds;
		NSRect frame = [[self.window contentView] frame];
		NSRect windowFrame = self.window.frame;

		windowFrame.size.height += bounds.size.height;
		windowFrame.origin.y -= bounds.size.height;
		
		[NSAnimationContext beginGrouping];
		[self.window setFrame:windowFrame display:YES animate:YES];
		[self.termListParentView setFrame:NSMakeRect(0, 0 + [self.window contentBorderThicknessForEdge:NSMinYEdge], frame.size.width, bounds.size.height)];
		[self.window.contentView addSubview:self.termListParentView];
		[NSAnimationContext endGrouping];
		
	}];
	[campusConnection release];
	
}

@end