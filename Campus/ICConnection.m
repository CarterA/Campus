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
#import "CZURLConnection.h"
#import "XPathQuery/XPathQuery.h"

@implementation ICConnection
- (void)scrapeDataWithUsername:(NSString *)username password:(NSString *)password completionHandler:(ICConnectionCompletionHandler)completionHandler {
	[[CampusLogin sharedLogin] loginAsUser:username withPassword:password completionHandler:^(NSData *loginResponse) {
		
		// Find the URL of the portal in the frame.
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
		
		// Load up the portal.
		NSURLRequest *portalRequest = [NSURLRequest requestWithURL:portalURL];
		CZURLConnection *portalConnection = [CZURLConnection connectionWithRequest:portalRequest];
		[portalConnection setCompletionHandler:^(NSData *portalResponseData, NSURLResponse *response) {
			
			// Search for the portal schedule link in this mess...
			//NSString *query = @"/html/body/table/tr[3]/td[1]/table[5]/tr/td[4]/a";
			NSString *query = @"/html/body/table/tr[3]/td[1]//a[contains(., 'Schedule')]";
			NSArray *queryResult = PerformHTMLXPathQuery(portalResponseData, query);
			NSURL *scheduleURL = [NSURL URLWithString:[@"https://campus.dpsk12.org/campus/" stringByAppendingString:[[[[queryResult objectAtIndex:0] objectForKey:@"nodeAttributeArray"] objectAtIndex:0] objectForKey:@"nodeContent"]]];
			NSLog(@"Schedule URL: %@", scheduleURL);
			
			// Load the schedule page.
			NSURLRequest *scheduleRequest = [NSURLRequest requestWithURL:scheduleURL];
			CZURLConnection *scheduleConnection = [CZURLConnection connectionWithRequest:scheduleRequest];
			[scheduleConnection setCompletionHandler:^(NSData *scheduleResponseData, NSURLResponse *response) {
				
				// Create each term.
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
				
				// Populate each term with courses, starting by finding how many rows there are.
				NSString *rowQuery = @"/html/body/table/tr[3]/td[2]/table/tr[3]/td/table/tr";
				NSArray *rowQueryResults = PerformHTMLXPathQuery(scheduleResponseData, rowQuery);
				NSMutableArray *parsedCourses = [NSMutableArray array]; // Create an array which will be used to screen out duplicate courses (e.g. courses which occur twice in one term because the occupy two periods *cough*Chorale*cough*).
				for (NSUInteger rowIndex = 1; rowIndex < rowQueryResults.count; rowIndex++) { // Start at index 1 to ignore the header.
					NSDictionary *row = [rowQueryResults objectAtIndex:rowIndex];
					for (NSUInteger columnIndex = 1; columnIndex < [[row objectForKey:@"nodeChildArray"] count]; columnIndex++) { // Again, start at 1 to ignore the headers.
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
										
										// Parse course title into name and id.
										NSString *courseIdentifier = [[courseTitle componentsSeparatedByString:@" "] objectAtIndex:0];
										NSString *courseName = [[courseTitle componentsSeparatedByString:[courseIdentifier stringByAppendingString:@" "]] objectAtIndex:1];
										
										// Make sure we haven't already parsed this course before parsing it and adding it to the term.
										if (![parsedCourses containsObject:courseIdentifier]) {
											
											// Set up ICCourse object. (Note: teacherEmail is not currently being used, but it's there!)
											ICCourse *course = [ICCourse courseWithIdentifier:courseIdentifier name:courseName];
											ICInstructor *instructor = [ICInstructor instructor];
											instructor.name = courseTeacher;
											instructor.email = teacherEmail;
											course.instructor = instructor;
											course.url = courseURL;
											
											//if ([courseName isEqualToString:@"DSA Chorale Intermediate 2 S1"]) { // For testing only. My brain can only handle one assload of assignment data at once.
												// Scrape and add assignment data to the course, if it contains a gradebook.
												if (course.url) {
													// Load up the gradebook.
													NSURLRequest *gradebookRequest = [NSURLRequest requestWithURL:course.url];
													CZURLConnection *gradebookConnection = [CZURLConnection connectionWithRequest:gradebookRequest];
													[gradebookConnection setCompletionHandler:^(NSData *gradebookResponseData, NSURLResponse *response) {
														
														NSString *tableQuery = @"/html/body/table/tr[3]/td[2]/table/tr[3]/td/table";
														NSArray *tableQueryResults = PerformHTMLXPathQuery(gradebookResponseData, tableQuery);
														
														// Okay. The purpose of this whole clusterfuck is to get an array of the names of all the tables in the gradebook which potentially contain actual assignments. How do we pull that off? We do it by parsing through the "Grading Task Summary" table, whose cells, believe it or not, correspond to specific tables in the gradebook.
														NSMutableDictionary *namesAndTermsOfTablesWithAssignments = [NSMutableDictionary dictionary]; // We're going to have just a plain ol' array of these names later, but we're going to have a dictionary as well so we can look up the terms to which each of the tables belong without unnecessarily parsing out the table names.
														NSMutableArray *termHeaderNames = [NSMutableArray array]; // This is going to contain the names of the *column headers*.
														for (NSUInteger termHeaderIndex = 1; termHeaderIndex < [[[[[tableQueryResults objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:2] objectForKey:@"nodeChildArray"] count]; termHeaderIndex++) { // Start at 1 to skip the "Grading Task" header (which is the column header for the row headers).
															[termHeaderNames addObject:[[[[[[tableQueryResults objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:2] objectForKey:@"nodeChildArray"] objectAtIndex:termHeaderIndex] objectForKey:@"nodeContent"]]; // Add the name of the current column header.
														}
														for (NSUInteger summaryRowIndex = 3; summaryRowIndex < [[[tableQueryResults objectAtIndex:0] objectForKey:@"nodeChildArray"] count]; summaryRowIndex++) { // Start at 3 to skip all of the header rows, only working with rows that might have content.
															NSString *gradingTaskName = [[[[[[tableQueryResults objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:summaryRowIndex] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"]; // The "grading task name" is the name of the *row header*.
															for (NSUInteger summaryCellIndex = 1; summaryCellIndex < [[[[[tableQueryResults objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:2] objectForKey:@"nodeChildArray"] count]; summaryCellIndex++) { // Now we're looping through all of the cells in the current row, excluding the row header cell.
																NSDictionary *summaryCell = [[[[[tableQueryResults objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:summaryRowIndex] objectForKey:@"nodeChildArray"] objectAtIndex:summaryCellIndex]; // Isolate the current cell we're working in so we don't have to type all this crap out in the next few lines.
																if ([[summaryCell objectForKey:@"nodeAttributeArray"] count]) { // If the cell has any attributes...
																	if (![[summaryCell objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"class", @"attributeName", @"gridGradeExpected", @"nodeContent", nil]]) { // Then if the class attribute isn't gridGradeExpected, it has contents, and thus corresponds to a table with assignments.
																		NSString *nameOfTableWithAssignments = [NSString stringWithFormat:@"%@ %@ Detail", [termHeaderNames objectAtIndex:(summaryCellIndex - 1)], gradingTaskName]; // Put together the name of the table based on the pattern we determined IC uses.
																		[namesAndTermsOfTablesWithAssignments setObject:[termHeaderNames objectAtIndex:(summaryCellIndex - 1)] forKey:nameOfTableWithAssignments]; // Add the name of the table and a string containing just the name of the term to which it belongs to the dictionary.
																	}
																}
															}
														}
														NSArray *namesOfTablesWithAssignments = [namesAndTermsOfTablesWithAssignments allKeys]; // And here's our array of table names, which is just the keys from the dictionary (which we still need to look up the terms to which each of these tables belong later on).
														
														// Here are those names we talked about earlier...
														//NSLog(@"%@", namesOfTablesWithAssignments);
														// And here's what needs to happen with them:
														// √ Loop through them like we were doing before, but still check to make sure they have assignments because once in a while they won't.
														// √ Use the *name of the table* to determine which term the grades belong to, and ONLY PARSE THE GRADES FOR THE TERM WE ARE WORKING IN.
														// If the grades for the current term reside within more than one table (see: Chorale), merge them into one theoretical table.
														// In other words, if each table has an "applied voice" category, treat it all as one category, and populate it with the "applied voice" assignments from both tables.
														// √ And after all of this, before we calculate the grade, check to see if one of the tables (which WILL be included in namesOfTablesWithAssignments) is a ChoraleTable™.
														// If it is, get the *points* (not the percentages; use the points to calculate them) directly from that instead of adding the assignments' points up (we're doing this to avoid having to deal with the mix of weighted and unweighted categories).
														// If there's not a ChoraleTable™, go ahead and calculate the course's grade by adding all the points, and respecting category weights if they are present.
														// And with all of this, keep in mind that the final goal is to have duplicate categories merged, without their weights displayed.
														// The weight stuff can all happen in the background; there's no need to actually display them in the app, as we're more interested in the total score for a category than its weight in the class, and overall, in the score for the entire class.
														// That really should be it. We've thought this all through thoroughly, and there's no reason it should need to be redone. That's all.
														
														// I'm not going to break up that paragraph until I've finished all of it, so for now, here is the work in progress:
														// Set up an array of all the actual tables we need to read assignments from.
														NSMutableArray *tablesWithAssignments = [NSMutableArray array]; // Create the empty array to fill with tables.
														for (NSDictionary *table in tableQueryResults) { // Check each table in the query results...
															NSString *tableName = [[[[[table objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"]; // Get the name of the table...
															if ([namesOfTablesWithAssignments containsObject:tableName]) { // And see if it matches one of the names in namesOfTablesWithAssignments.
																if ([[namesAndTermsOfTablesWithAssignments objectForKey:tableName] isEqualToString:[[terms objectAtIndex:(columnIndex - 1)] name]]) { // Only add the table to the array if it belongs to the term we are currently working in.
																	[tablesWithAssignments addObject:table]; // Add the table (which is now guaranteed to contain grades for the current term we are working with) to the array.
																}
															}
														}
														
														// Check for a ChoraleTable™. (Okay, alright. I'll clarify. A ChoraleTable™ is a table containing subtotals of grades from other tables and adding them up, which only exists when grades for a term are split accross multiple tables. ChoraleTables™ earned their name from Chorale, the class in which they were discovered.)
														NSDictionary *choraleTable = nil; // By default, the ChoraleTable™ doesn't exist.
														for (NSDictionary *table in tablesWithAssignments) {
															if ([[[[table objectForKey:@"nodeChildArray"] objectAtIndex:1] objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"class", @"attributeName", @"gridH2", @"nodeContent", nil]]) { // If the second child in the table (the first tr after the table's header) has its class set to gridH2, we have a ChoraleTable™! Rows whose class is gridH2 are never used at the top of a table, *except* for in ChoraleTables™.
																choraleTable = [table copy]; // A ChoraleTable™ does exist, so store it in this variable to deal with later.
																[tablesWithAssignments removeObject:table]; // Remove the ChoraleTable™ from the list so we don't have to deal with it while we're parsing out assignment data.
															}
														}
														
														// This whole thing basically just lumps all of the rows of raw assignment data into arrays for each assignment category so that they're easier to work with.
														NSMutableDictionary *assignmentCategoriesWithRawAssignmentData = [NSMutableDictionary dictionary];
														for (NSDictionary *table in tablesWithAssignments) {
															if ([[table objectForKey:@"nodeChildArray"] count] > 2) { // First, check to see if the table actually contains assignments. (Yes, believe it or not, we can still have empty tables at this point. As far as we know, these are always going to be Progress/Eligibility tables which often contain data in the Grading Summary Table even when they're empty, but you never know.)
																// We've got two variables for the assignment category here so that we can keep track of when we switch into a new category, since they aren't organized hierarchially in IC. (In other words, they DIDN'T add another table for each assignment category. I know, right?)
																NSString *currentAssignmentCategory = nil;
																NSString *lastAssignmentCategory = nil;
																for (NSDictionary *assignmentTableRow in [table objectForKey:@"nodeChildArray"]) {
																	if (!([[assignmentTableRow objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"class", @"attributeName", @"detailFormHeader", @"nodeContent", nil]] || [[assignmentTableRow objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"class", @"attributeName", @"gridH3", @"nodeContent", nil]] || [[assignmentTableRow objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"class", @"attributeName", @"gridH2", @"nodeContent", nil]] || [[assignmentTableRow objectForKey:@"nodeAttributeArray"] containsObject:[NSDictionary dictionaryWithObjectsAndKeys:@"style", @"attributeName", @"height: 0px;", @"nodeContent", nil]])) { // Hooray for obnoxiously long lines of code with even longer comments! For real though, all this does is screen out the types of rows we don't care about.
																		if (![[assignmentTableRow objectForKey:@"nodeAttributeArray"] count]) { // If the row doesn't have any attributes, then it's an assignment category header.
																			currentAssignmentCategory = [[[assignmentTableRow objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"]; // Set the current assignment category to the new one we just found.
																		}
																		else { // If it's just a plain' ol' assignment row...
																			[[assignmentCategoriesWithRawAssignmentData objectForKey:currentAssignmentCategory] addObject:assignmentTableRow]; // Add it to the array of rows to parse for the current assignment category.
																		}
																		if (![currentAssignmentCategory isEqualToString:lastAssignmentCategory]) { // If we found a new assignment category...
																			[assignmentCategoriesWithRawAssignmentData setObject:[NSMutableArray array] forKey:currentAssignmentCategory]; // Add it to the dictionary, and set its object to an empty array to hold its assigment rows.
																			lastAssignmentCategory = currentAssignmentCategory; // And set the last assignment category to the current one, so we know if we run into another new one.
																		}
																	}
																}
															}
														}
														//NSLog(@"%@", [assignmentCategoriesWithRawAssignmentData allKeys]); // Here's yer dang category names!
														
														// Add the completed course to the term in which we are currently working.
														[[terms objectAtIndex:columnIndex-1] addCourse:course];
														
													}];
													[gradebookConnection start];
												}
												else { // If the course doesn't have a gradebook, just add it to the term without parsing assignments.
													[[terms objectAtIndex:columnIndex-1] addCourse:course];
												}
											}
											
											// Add the course we just finished parsing to the list of completed courses so we don't parse it again.
											[parsedCourses addObject:courseIdentifier];
											
										//}
										
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
			[scheduleConnection start];
			
		}];
		[portalConnection start];
		
	}];
}
@end
