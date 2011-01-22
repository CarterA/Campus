//
//  ICTerm.h
//  Campus
//
//  Created by Carter Allen on 1/20/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "RMModelObject.h"

@class ICCourse;

@interface ICTerm : RMModelObject {}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSMutableArray *courses;
+ (ICTerm *)termWithName:(NSString *)theName start:(NSDate *)startDate end:(NSDate *)endDate;
- (id)initWithName:(NSString *)theName start:(NSDate *)startDate end:(NSDate *)endDate;
- (void)addCourse:(ICCourse *)course;
@end