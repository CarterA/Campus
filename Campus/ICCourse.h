//
//  ICCourse.h
//  Campus
//
//  Created by Carter Allen on 1/19/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "RMModelObject.h"

@class ICAssignment;

@interface ICInstructor : RMModelObject {}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
+ (ICInstructor *)instructor;
@end

@interface ICCourse : RMModelObject {}
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) ICInstructor *instructor;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSMutableDictionary *assignments;
@property (nonatomic, retain) NSMutableDictionary *assignmentCategoryWeights;
+ (ICCourse *)courseWithIdentifier:(NSString *)theID name:(NSString *)theName;
- (id)initWithIdentifier:(NSString *)theID name:(NSString *)theName;
- (void)addAssignmentCategory:(NSString *)categoryName withAssignments:(NSMutableArray *)newAssignments weight:(NSDecimalNumber *)percentage;
- (void)addAssignment:(ICAssignment *)assignment toCategory:(NSString *)categoryName;
@end