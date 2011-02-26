//
//  CampusTermsController.m
//  Campus
//
//  Created by Carter Allen on 2/25/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusTermsController.h"
#import "CampusTermCellView.h"
#import "ICTerm.h"

@implementation CampusTermsController

#pragma mark -
#pragma mark Public Properties
@synthesize terms=_terms;
@synthesize tableView=_tableView;
@synthesize loadedCell=_loadedCell;

#pragma mark -
#pragma mark Construction and Destruction
- (void)loadView {
	[super loadView];
	[self.tableView reloadData];
}
- (void)dealloc {
	[_terms release];
	[_tableView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table View Delegate Methods
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	CampusTermCellView *view = [self.tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	
	if ([tableColumn.identifier isEqualToString:@"terms"]) {
		
		if (!view) {
			[NSBundle loadNibNamed:@"CampusTermCellView" owner:self];
			view = self.loadedCell;
			view.identifier = tableColumn.identifier;
			self.tableView.rowHeight = view.frame.size.height;
		}
		ICTerm *term = (ICTerm *)[self.terms objectAtIndex:row];
		view.nameLabel.stringValue = term.name;
		view.dateLabel.stringValue = term.range;
		
	}
	
	return view;
	
}

#pragma mark -
#pragma mark Table View Data Source Methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSInteger count = 0;
	if (self.terms) count = [self.terms count];
	return count;
}

@end