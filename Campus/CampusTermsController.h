//
//  CampusTermsController.h
//  Campus
//
//  Created by Carter Allen on 2/25/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

@class CampusTermCellView;

@interface CampusTermsController : NSViewController <NSTableViewDelegate, NSTableViewDataSource> {}
@property (nonatomic, retain) NSArray *terms;
@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet CampusTermCellView *loadedCell; // Nothing to see here...
@end