//
//  ICCourse.m
//  Campus
//
//  Created by Carter Allen on 1/19/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICCourse.h"
#import "ICAssignment.h"

@implementation ICInstructor
@dynamic name, email;
+ (ICInstructor *)instructor { return [[[ICInstructor alloc] init] autorelease]; }
@end

@implementation ICCourse
@dynamic identifier, instructor, name, url, assignments, assignmentCategoryWeights;
+ (ICCourse *)courseWithIdentifier:(NSString *)theID name:(NSString *)theName {
	return [[[self alloc] initWithIdentifier:theID name:theName] autorelease];
}
- (id)initWithIdentifier:(NSString *)theID name:(NSString *)theName {
	if ((self = [super init])) {
		self.identifier = theID;
		self.name = theName;
		self.assignments = [NSMutableDictionary dictionary];
		self.assignmentCategoryWeights = nil;
	}
	return self;
}
- (void)addAssignmentCategory:(NSString *)categoryName withAssignments:(NSMutableArray *)newAssignments weight:(NSDecimalNumber *)weight {
	// So, here's the deal with this being so complicated. The new category will always be added when a weight is specified, because even if the weight is not added (which happens when other categories don't have specified weights), adding the category won't cause any problems. It won't be added if a weight *isn't* specified for a course whose other categories have weights, because we can't make up a weight for it.
	if (weight) { // If the weight is specified...
		if (self.assignmentCategoryWeights) { // Only add it if the assignment category weights dictionary exists, because we don't want some of the categories to have percentages and some not to. It's all or nothing.
			[self.assignmentCategoryWeights setObject:weight forKey:categoryName];
		}
		else { // If the dictionary doesn't exist, don't add the weight...
			if ([self.assignments count] == 0) { // Unless the assignments dictionary is empty, in which case there just haven't been any assignments *or* weights added yet.
				self.assignmentCategoryWeights = [NSMutableDictionary dictionaryWithObject:weight forKey:categoryName];
			}
		}
	}
	else { // If the category's weight is not specified...
		if (self.assignmentCategoryWeights) { // And if we're trying to add it to a course whose categories have weights... throw an exception. Otherwise, don't do anything, and just let the category get added, because none of them have weights.
			[NSException raise:@"ICMissingAssignmentCategoryWeightException" format:@"A weight was not specified when attempting to add the assignment category \"%@\" to the course \"%@\" A weight must be specified when adding new assignment categores to a course whose other assignment categories have defined weights.", categoryName, self.name]; 
			return; // Exit without adding the category, because we can't make up a weight for it.
		}
	}
	if (newAssignments) { // If the new assignments array is non-nil, add it as the object for the category name.
		[self.assignments setObject:newAssignments forKey:categoryName];
	}
	else { // If not, just set the object to an empty mutable array to be populated with classes later.
		[self.assignments setObject:[NSMutableArray array] forKey:categoryName];
	}
}
- (void)addAssignment:(ICAssignment *)assignment toCategory:(NSString *)categoryName {
	if ([self.assignments objectForKey:categoryName]) {
		[[self.assignments objectForKey:categoryName] addObject:assignment];
	}
}
@end