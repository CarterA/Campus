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
#import "CZURLConnection.h"
#import "EMKeychainItem.h"

@interface CampusAppDelegate()
@end

@implementation CampusAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// Obtain login information.
	NSString *username = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Username" withExtension:@"txt"] encoding:NSASCIIStringEncoding error:nil];
	EMInternetKeychainItem *item = [EMInternetKeychainItem internetKeychainItemForServer:@"campus.dpsk12.org" withUsername:username path:nil port:0 protocol:kSecProtocolTypeAny];
	
	// Scrape as much data as possible using an ICConnection object.
	ICConnection *campusConnection = [[ICConnection alloc] init];
	[campusConnection scrapeDataWithUsername:item.username password:item.password completionHandler:^(ICResponse *response) {
		for (ICTerm *term in response.terms) {
			NSLog(@"Term:\n%@\n", term); 
			for (ICCourse *course in term.courses) {
				NSLog(@"Course:\n%@\nInstructor: %@\nEmail: %@\n", course, course.instructor.name, course.instructor.email);
			}
		}
	}];
	[campusConnection release];
	
}

@end