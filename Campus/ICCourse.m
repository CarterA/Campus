//
//  ICCourse.m
//  Campus
//
//  Created by Carter Allen on 1/19/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICCourse.h"

@implementation ICInstructor
@dynamic name, email;
+ (ICInstructor *)instructor { return [[[ICInstructor alloc] init] autorelease]; }
@end

@implementation ICCourse
@dynamic identifier, instructor, name, url;
+ (ICCourse *)courseWithIdentifier:(NSString *)theID name:(NSString *)theName {
	return [[[self alloc] initWithIdentifier:theID name:theName] autorelease];
}
- (id)initWithIdentifier:(NSString *)theID name:(NSString *)theName {
	if ((self = [super init])) {
		self.identifier = theID;
		self.name = theName;
	}
	return self;
}
@end