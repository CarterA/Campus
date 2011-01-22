//
//  ICResponse.h
//  Campus
//
//  Created by George Woodliff-Stanley on 1/22/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "RMModelObject.h"

@class ICStudent, ICTerm;

@interface ICResponse : RMModelObject {}
@property (nonatomic, retain) ICStudent *student;
@property (nonatomic, retain) NSArray *terms;
//- (void)addTerm:(ICTerm *)term;
@end
