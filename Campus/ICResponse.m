//
//  ICResponse.m
//  Campus
//
//  Created by George Woodliff-Stanley on 1/22/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICResponse.h"

@implementation ICResponse
@dynamic student, terms;
- (void)addTerm:(ICTerm *)term {
	[self.terms addObject:term];
}
@end
