//
//  ICCourse.m
//  Campus
//
//  Created by Carter Allen on 1/19/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICCourse.h"

@implementation ICCourse
@synthesize instructor; // I'd @dynamic this, but apparently RMModelObject sucks at making accessors for structs (*cough* opportunity for major improvement *cough*).
@dynamic identifier, name, url;
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