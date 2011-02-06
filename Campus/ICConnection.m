//
//  ICConnection.m
//  Campus
//
//  Created by George Woodliff-Stanley on 1/22/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICConnection.h"
#import "ICTerm.h"
#import "ICCourse.h"
#import "CampusLogin.h"
#import "IKConnectionDelegate.h"
#import "XPathQuery/XPathQuery.h"

@implementation ICConnection
- (void)scrapeDataWithUsername:(NSString *)username password:(NSString *)password completionHandler:(ICConnectionCompletionHandler)completionHandler {
	[[CampusLogin sharedLogin] loginAsUser:username withPassword:password completionHandler:^(NSData *loginResponse) {
		
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
				}
				
				// Populate each term with course, starting by finding how many rows there are.
				NSString *rowQuery = @"/html/body/table/tr[3]/td[2]/table/tr[3]/td/table/tr";
				NSArray *rowQueryResults = PerformHTMLXPathQuery(scheduleResponseData, rowQuery);
				for (NSUInteger rowIndex = 1; rowIndex < rowQueryResults.count; rowIndex++) { // Start at index 1 to ignore the header
					NSDictionary *row = [rowQueryResults objectAtIndex:rowIndex];
					for (NSUInteger columnIndex = 1; columnIndex < [[row objectForKey:@"nodeChildArray"] count]; columnIndex++) { // Again, start at 1 to ignore the headers
						NSDictionary *cell = [[row objectForKey:@"nodeChildArray"] objectAtIndex:columnIndex];
						
						// First off, make sure this is actually a cell with a course in it. It will contain "EMPTY" if it isn't.
						if (![[cell objectForKey:@"nodeContent"] isEqualToString:@"EMPTY"]) {
							
							// Parse out the actual content of the class. Remember, some cells contain more than one course!
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
													courseURL = [NSURL URLWithString:[@"https://campus.dpsk12.org/campus/" stringByAppendingString:[[[item objectForKey:@"nodeAttributeArray"] objectAtIndex:0] objectForKey:@"nodeContent"]]];
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
										ICInstructor *instructor = [ICInstructor instructor];
										instructor.name = courseTeacher;
										instructor.email = teacherEmail;
										course.instructor = instructor;
										course.url = courseURL;
										
										if ([courseName isEqualToString:@"Spanish 3 Honors S2"]) { // For testing only. My brain can only handle one assload of assignment data at once.
											// Scrape and add grade data to the course, if it contains a gradebook.
											if (course.url) {
												NSURLRequest *gradebookRequest = [NSURLRequest requestWithURL:course.url];
												IKConnectionDelegate *gradebookRequestDelegate = [IKConnectionDelegate connectionDelegateWithDownloadProgress:nil uploadProgress:nil completion:^(NSData *gradebookResponseData, NSURLResponse *response, NSError *error) {
													
													NSString *tableQuery = @"/html/body/table/tr[3]/td[2]/table/tr[3]/td/table";
													NSArray *tableQueryResults = PerformHTMLXPathQuery(gradebookResponseData, tableQuery);
													
													
													
													NSUInteger tableIndex = 0;
													// This loop is going to happen twice. The first time, we're checking to see if there's a ChoraleTable™, at which point we'll do something completely different, and the second time, we're actually parsing the grades if it's a normal gradebook.
													for (tableIndex = 1; tableIndex < ([tableQueryResults count] - 2); tableIndex++) { // Starts at 1 and ends 2 tables before the last table to skip grade summary table, progress/eligibility table, and grading scale table.
														
													}
													
													
													
													
													
													// Okay. The number of terms tells us the number of 9 week block tables 
													
													
													
													
													
													for (NSUInteger tableIndex = 1; tableIndex < ([tableQueryResults count] - 2); tableIndex++) { // Starts at 1 and ends 2 tables before the last table to skip grade summary table, progress/eligibility table, and grading scale table.
														NSDictionary *table = [tableQueryResults objectAtIndex:tableIndex];
														// Yeah... it's obnoxious. Don't mess with it till' we're done parsing though, because we need a log more obnoxious than the assignment data itself to be able to quickly distinguish between the tables.
														//NSLog(@"\n\n\n\n\n****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************TABLE, BITCH****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************\n\n\n\n\n%@", table);
														
														// We're now looping through all of the relevant tables (those that might have assignments) in the gradebook. First, check to see if the table contains any assignments at all.
														if ([[table objectForKey:@"nodeChildArray"] count] > 2) {
															// Next, parse the assignments, starting by breaking the table down into its assignment categories.
															NSMutableDictionary *assignmentCategoryRowIndices = [NSMutableDictionary dictionary];
															for (NSUInteger trIndex = 1; trIndex < [[table objectForKey:@"nodeChildArray"] count]; trIndex++) {
																
																if ((![[[table objectForKey:@"nodeChildArray"] objectAtIndex:trIndex] objectForKey:@"nodeAttributeArray"]) && ([[[[table objectForKey:@"nodeChildArray"] objectAtIndex:trIndex] objectForKey:@"nodeChildArray"] count] == 1)) { // A row without any attributes and with exactly one child (a td) is a row containing the name of an assignment category.
																	NSString *assignmentCategoryName = [[[[[table objectForKey:@"nodeChildArray"] objectAtIndex:trIndex] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"];
																
																}
															
															}
														}
														
														//		- Use regex to see if assignment categories include percentages, thus finding out whether grades average or accumulate.
														//		- Parse each individual assignment, and make an array of assignments for each assignment category.
														//		- Add these arrays to a dictionary, and make the keys be the names of the assignment categories.
														// 3) At this point, we should stop working inside of this for loop.
														// 4) Add each assignment dictionary to its course by making it a property in ICCourse.
														// 5) Parse grading scale table, and do some math with assignment grades to determine overall class grade. (Don't just read it from the grade summary – it's unreliable.)
														// 6) Add class grade to each course object by making it an ICCourse property as well.
														// 7) That's it! This block should be complete, and the fully populated course should be added to its term.
														
													}
													
													
													
													
													
													
													
													// Add the completed course to the term in which we are currently working.
													[[terms objectAtIndex:columnIndex-1] addCourse:course];
													
												}];
												[NSURLConnection connectionWithRequest:gradebookRequest delegate:gradebookRequestDelegate];
											}
											else { // If the course doesn't have a gradebook, just add it to the term without parsing assignments.
												[[terms objectAtIndex:columnIndex-1] addCourse:course];
											}
										}
										
									}
								}
							}
							
						}
						
					}
				}
				
				// Create and return ICResponse object to the sender's completion handler.
				ICResponse *campusResponse = [[ICResponse alloc] init];
				campusResponse.terms = terms;
				completionHandler(campusResponse);
				[campusResponse release];
				
			}];
			[NSURLConnection connectionWithRequest:scheduleRequest delegate:scheduleRequestDelegate];
			
		}];
		[NSURLConnection connectionWithRequest:portalRequest delegate:portalRequestDelegate];
		
	}];
}
@end
