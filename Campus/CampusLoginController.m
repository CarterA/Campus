//
//  CampusLoginController.m
//  Campus
//
//  Created by Carter Allen on 2/3/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusLoginController.h"
#import "CZLinkedView.h"
#import <QuartzCore/QuartzCore.h>

@interface CampusLoginController ()
@property (nonatomic, retain) CATransition *transition;
- (void)updateButtons;
@end

@implementation CampusLoginController
@synthesize placeholderView, currentView, URLField, usernameField, passwordField, nextButton, previousButton;
@synthesize transition;
- (void)dealloc {
	[self.URLField release];
	[self.usernameField release];
	[self.passwordField release];
	[self.nextButton release];
	[self.previousButton release];
	[self.transition release];
	[super dealloc];
}
- (void)awakeFromNib {
	
	self.currentView.frame = CGRectMake(0, 0, self.currentView.frame.size.width, self.currentView.frame.size.height);
	[self.placeholderView addSubview:self.currentView];
	
	self.transition = [CATransition animation];
	self.transition.duration = 0.15;
	self.transition.type = kCATransitionPush;
	self.transition.subtype = kCATransitionFromLeft;
	
	[self.placeholderView setAnimations:[NSDictionary dictionaryWithObject:self.transition forKey:@"subviews"]];
	
	[self updateButtons];
	
}
- (void)updateButtons {
	if (self.currentView.previousView) {
		[self.previousButton setEnabled:YES];
		self.previousButton.layer.opacity = 1.0;
	}
	else {
		//[self.previousButton setEnabled:NO];
		self.previousButton.layer.opacity = 0.0;
	}
	if (!self.currentView.nextView) self.nextButton.title = @"Finish";
	else self.nextButton.title = @"Next";
	[self.window setViewsNeedDisplay:YES];
}
- (void)setCurrentView:(CZLinkedView *)newView {
	if (!self.currentView) {
		currentView = newView;
		return;
	}
	[[self.placeholderView animator] replaceSubview:self.currentView with:newView];
	currentView = newView;
	[self updateButtons];
}
- (IBAction)next:(id)sender {
	if (!self.currentView.nextView) {
		[NSApp endSheet:self.window];
		[self.window orderOut:self];
	}
	else {
		self.transition.subtype = kCATransitionFromRight;
		self.currentView = self.currentView.nextView;
	}
}

- (IBAction)previous:(id)sender {
	if (!self.currentView.previousView) return;
	self.transition.subtype = kCATransitionFromLeft;
	self.currentView = self.currentView.previousView;
}
@end