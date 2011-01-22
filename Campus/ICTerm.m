//
//  ICTerm.m
//  Campus
//
//  Created by Carter Allen on 1/20/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICTerm.h"

@implementation ICTerm
@dynamic name, start, end, courses;
+ (ICTerm *)termWithName:(NSString *)theName start:(NSDate *)startDate end:(NSDate *)endDate {
	return [[[self alloc] initWithName:theName start:startDate end:endDate] autorelease];
}
- (id)initWithName:(NSString *)theName start:(NSDate *)startDate end:(NSDate *)endDate; {
	if ((self = [super init])) {
		self.name = theName;
		self.start = startDate;
		self.end = endDate;
		self.courses = [NSMutableArray array];
	}
	return self;
}
- (void)addCourse:(ICCourse *)course {
	[self.courses addObject:course];
}
@end