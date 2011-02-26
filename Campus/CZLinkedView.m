//
//  CZLinkedView.m
//  CZUI/Campus
//
//  Created by Carter Allen on 2/25/11
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CZLinkedView.h"

@implementation CZLinkedView
@synthesize previousView, nextView;
- (void)awakeFromNib { [self setWantsLayer:YES]; }
@end