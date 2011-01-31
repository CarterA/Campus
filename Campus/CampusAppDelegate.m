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

@synthesize window, mainView, termListView;
@synthesize progressIndicator;
@synthesize terms;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
		
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

@end