//
//  CampusAppDelegate.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusAppDelegate.h"
#import "CampusLogin.h"
#import "ICTerm.h"
#import "ICCourse.h"
#import "XPathQuery/XPathQuery.h"
#import "CZURLConnection.h"
#import "EMKeychainItem.h"
#import "IKConnectionDelegate.h"

@interface CampusAppDelegate()
@end

@implementation CampusAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// Login as me
	NSString *username = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Username" withExtension:@"txt"] encoding:NSASCIIStringEncoding error:nil];
	EMInternetKeychainItem *item = [EMInternetKeychainItem internetKeychainItemForServer:@"campus.dpsk12.org" withUsername:username path:nil port:0 protocol:kSecProtocolTypeAny];
	[[CampusLogin sharedLogin] loginAsUser:item.username withPassword:item.password completionHandler:^(NSData *loginResponse) {

		// Find the URL of the portal in the frame
		NSString *loginResponseString = [[NSString alloc] initWithData:loginResponse encoding:NSUTF8StringEncoding];
		__block NSURL *portalURL = nil;
		[loginResponseString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			// Find the frame URL, if we have the right line.
			NSRange range = [line rangeOfString:@"frame name=\"frameDetail\" scrolling=\"auto\" marginwidth=\"0\" marginheight=\"0\" src=\""];
			if (range.location != NSNotFound) {
				NSRange endRange = [line rangeOfString:@"\">"];
				NSRange urlRange = NSMakeRange(range.location+range.length, endRange.location-(range.location+range.length));
				portalURL = [[NSURL alloc] initWithString:[@"https://campus.dpsk12.org/campus/" stringByAppendingString:[line substringWithRange:urlRange]]];
				*stop = YES;
			}
		}];
		[loginResponseString release];
		NSLog(@"Portal URL: %@", portalURL);
		
		// Load up the portal
		NSURLRequest *portalRequest = [NSURLRequest requestWithURL:portalURL];
		IKConnectionDelegate *portalRequestDelegate = [IKConnectionDelegate connectionDelegateWithDownloadProgress:nil uploadProgress:nil completion:^(NSData *portalResponseData, NSURLResponse *response, NSError *error) {
			
			// Search for the portal schedule link in this mess...
			//NSString *query = @"/html/body/table/tr[3]/td[1]/table[5]/tr/td[4]/a";
			NSString *query = @"/html/body/table/tr[3]/td[1]//a[contains(., 'Schedule')]";
			NSArray *queryResult = PerformHTMLXPathQuery(portalResponseData, query);
			NSURL *scheduleURL = [NSURL URLWithString:[@"https://campus.dpsk12.org/campus/" stringByAppendingString:[[[[queryResult objectAtIndex:0] objectForKey:@"nodeAttributeArray"] objectAtIndex:0] objectForKey:@"nodeContent"]]];
			NSLog(@"Schedule URL: %@", scheduleURL);
			
			// Load the schedule page
			NSURLRequest *scheduleRequest = [NSURLRequest requestWithURL:scheduleURL];
			IKConnectionDelegate *scheduleRequestDelegate = [IKConnectionDelegate connectionDelegateWithDownloadProgress:nil uploadProgress:nil completion:^(NSData *scheduleResponseData, NSURLResponse *response, NSError *error) {
				
				// Create each term
				NSMutableArray *terms = [NSMutableArray array];
				NSString *termQuery = @"/html/body/table/tr[3]/td[2]/table/tr[3]/td/table/tr[1]/th[@align='center']";
				NSArray *termQueryResults = PerformHTMLXPathQuery(scheduleResponseData, termQuery);
				for (NSDictionary *termNode in termQueryResults) {
					NSString *termString = [termNode objectForKey:@"nodeContent"];
					NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"-()"];
					NSArray *components = [termString componentsSeparatedByCharactersInSet:characterSet];
					NSDate *start = [NSDate dateWithNaturalLanguageString:[components objectAtIndex:1]];
					NSDate *end = [NSDate dateWithNaturalLanguageString:[components objectAtIndex:2]];
					ICTerm *term = [ICTerm termWithName:[components objectAtIndex:0] start:start end:end];
					[terms addObject:term];
					//NSLog(@"Term: %@", term);
				}
				
				// Populate each term with courses
				// Start by finding how many rows there are
				NSString *rowQuery = @"/html/body/table/tr[3]/td[2]/table/tr[3]/td/table/tr";
				NSArray *rowQueryResults = PerformHTMLXPathQuery(scheduleResponseData, rowQuery);
				for (NSUInteger rowIndex = 1; rowIndex < rowQueryResults.count; rowIndex++) { // Start at index 1 to ignore the header
					NSDictionary *row = [rowQueryResults objectAtIndex:rowIndex];
					for (NSUInteger columnIndex = 1; columnIndex < [[row objectForKey:@"nodeChildArray"] count]; columnIndex++) { // Again, start at 1 to ignore the headers
						NSDictionary *cell = [[row objectForKey:@"nodeChildArray"] objectAtIndex:columnIndex];
						
						// First off, make sure this is actually a cell with a course in it. It will contain "EMPTY" if it isn't.
						if (![[cell objectForKey:@"nodeContent"] isEqualToString:@"EMPTY"]) {
							
							// Parse out the actual content of the class. Remember, some cells contain more than one course!
							//NSLog(@"Cell:\n%@\n", cell);
							for (NSUInteger nodeIndex = 0; nodeIndex < [[cell objectForKey:@"nodeChildArray"] count]; nodeIndex++) {
								NSDictionary *node = [[cell objectForKey:@"nodeChildArray"] objectAtIndex:nodeIndex];
								if ([[node objectForKey:@"nodeName"] isEqualToString:@"font"]) { // Each course within a cell is in its own font tag, so this is how we're seperating individual courses within each cell.
									if ([[node objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"attributeName", @"black", @"nodeContent", nil]]) { // Make sure it's a black font tag, because only those contain courses.
										
										// These have to be nilled out so that classes without specified instructors won't be listed as having the instructor of the last course that was parsed.
										NSString *courseTitle = nil;
										NSString *courseTeacher = nil;
										NSString *teacherEmail = nil;
										NSURL *courseURL = nil;
										for (NSUInteger itemIndex = 0; itemIndex < [[node objectForKey:@"nodeChildArray"] count]; itemIndex++) { // Gettin' deeper. Man, look at that gutter.
											NSDictionary *item = [[node objectForKey:@"nodeChildArray"] objectAtIndex:itemIndex];
											NSString *itemName = [item objectForKey:@"nodeName"];
											if ([itemName isEqualToString:@"b"]) { // A plain 'b' tag is the title of a course that doesn't have a gradebook.
												courseTitle = [item objectForKey:@"nodeContent"];
											}
											else if ([itemName isEqualToString:@"a"]) {
												if ([item objectForKey:@"nodeChildArray"]) { // An 'a' tag with a child is the gradebook link (because the link text is inside of a 'b' tag).
													courseTitle = [[[item objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"];
													courseURL = [NSURL URLWithString:[[[item objectForKey:@"nodeAttributeArray"] objectAtIndex:0] objectForKey:@"nodeContent"]];
												}
												else { // ...And one without children is the teacher's name and mailto link.
													courseTeacher = [item objectForKey:@"nodeContent"];
													teacherEmail = [[[[[item objectForKey:@"nodeAttributeArray"] objectAtIndex:0] objectForKey:@"nodeContent"] componentsSeparatedByString:@"mailto:"] objectAtIndex:1];
												}

											}
										}
										
										// Parse course title into name and id
										NSString *courseIdentifier = [[courseTitle componentsSeparatedByString:@" "] objectAtIndex:0];
										NSString *courseName = [[courseTitle componentsSeparatedByString:[courseIdentifier stringByAppendingString:@" "]] objectAtIndex:1];
										
										// Set up ICCourse object. (Note: teacherEmail is not currently being used, but it's there!)
										ICCourse *course = [ICCourse courseWithIdentifier:courseIdentifier name:courseName];
										course.instructor = courseTeacher;
										course.url = courseURL;
										[[terms objectAtIndex:columnIndex-1] addCourse:course];
									
									}
								}
							}
							
						}
						NSLog(@"Term: %@", [terms objectAtIndex:columnIndex-1]);
					}
				}
				//NSLog(@"Row query results: %@", rowQueryResults);
				
				//NSLog(@"Terms:  %@", terms);
				
			}];
			[NSURLConnection connectionWithRequest:scheduleRequest delegate:scheduleRequestDelegate];
			
		}];
		[NSURLConnection connectionWithRequest:portalRequest delegate:portalRequestDelegate];

	
	}];
	
}

@end