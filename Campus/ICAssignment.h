//
//  ICAssignment.h
//  Campus
//
//  Created by George Woodliff-Stanley on 1/30/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "RMModelObject.h"

@interface ICAssignment : RMModelObject {}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSDate *dueDate;
@property (nonatomic, retain) NSDate *assignedDate;
@property (nonatomic, retain) NSDecimalNumber *multiplier;
@property (nonatomic, retain) NSDecimalNumber *possiblePoints;
@property (nonatomic, retain) NSDecimalNumber *score;
@property (nonatomic, retain) NSDecimalNumber *percentScore;
@property (nonatomic, copy) NSString *comments;
@end
