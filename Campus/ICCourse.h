//
//  ICCourse.h
//  Campus
//
//  Created by Carter Allen on 1/19/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "RMModelObject.h"

@interface ICCourse : RMModelObject {}
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *instructor;
@property (nonatomic, retain) NSURL *url;
+ (ICCourse *)courseWithIdentifier:(NSString *)theID;
- (id)initWithIdentifier:(NSString *)theID;
@end