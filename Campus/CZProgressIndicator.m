//
//  CZProgressIndicator.m
//  Campus
//
//  Created by Carter Allen on 1/21/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CZProgressIndicator.h"

#define CZ_PROGRESS_INDICATOR_CAP_WIDTH lroundf((self.bounds.size.height/2))

typedef enum {
	CZProgressIndicatorLeftCapComponent = 1,
	CZProgressIndicatorRightCapComponent = 2,
	CZProgressIndicatorFillComponent = 3
} CZProgressIndicatorComponent;

@interface CZProgressIndicator()
- (CGRect)rectForComponent:(CZProgressIndicatorComponent)component;
- (void)drawComponent:(CZProgressIndicatorComponent)component;
@end

@implementation CZProgressIndicator

#pragma mark -
#pragma mark Properties
@synthesize value, range, controlSize, indeterminate;

#pragma mark -
#pragma mark Initialization
- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
	}
	return self;
}

#pragma mark -
#pragma mark Geometry
- (CGRect)rectForComponent:(CZProgressIndicatorComponent)component {
	CGRect rect = CGRectMake(0, 0, 0, self.bounds.size.height);
	switch (component) {
		case CZProgressIndicatorLeftCapComponent: {
			rect.size.width = CZ_PROGRESS_INDICATOR_CAP_WIDTH;
			break;
		}
		case CZProgressIndicatorRightCapComponent: {
			rect.origin.x = self.bounds.size.width - CZ_PROGRESS_INDICATOR_CAP_WIDTH;
			rect.size.width = CZ_PROGRESS_INDICATOR_CAP_WIDTH;
			break;
		}
		case CZProgressIndicatorFillComponent: {
			rect.origin.x = CZ_PROGRESS_INDICATOR_CAP_WIDTH;
			rect.size.width = self.bounds.size.width - (2 * CZ_PROGRESS_INDICATOR_CAP_WIDTH);
			break;
		}
		default:
			break;
	}
	return rect;
}

#pragma mark -
#pragma mark Drawing
- (void)drawRect:(NSRect)dirtyRect {
	if (CGRectIntersectsRect(dirtyRect, [self rectForComponent:CZProgressIndicatorLeftCapComponent]))
		[self drawComponent:CZProgressIndicatorLeftCapComponent];
	if (CGRectIntersectsRect(dirtyRect, [self rectForComponent:CZProgressIndicatorRightCapComponent]))
		[self drawComponent:CZProgressIndicatorRightCapComponent];
	if (CGRectIntersectsRect(dirtyRect, [self rectForComponent:CZProgressIndicatorFillComponent]))
		[self drawComponent:CZProgressIndicatorFillComponent];
}
- (void)drawComponent:(CZProgressIndicatorComponent)component {
	CGRect rect = [self rectForComponent:component];
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	switch (component) {
		case CZProgressIndicatorLeftCapComponent: {
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathMoveToPoint(path, NULL, rect.size.width, 0);
			CGPathAddArcToPoint(path, NULL, rect.size.width, 0,  0, rect.size.height/2, rect.size.width);
			CGPathAddArcToPoint(path, NULL, 0, rect.size.height/2, rect.size.width, rect.size.height, rect.size.width);
			CGContextAddPath(context, path);
			CGContextSetStrokeColorWithColor(context, CGColorGetConstantColor(kCGColorBlack));
			CGContextStrokePath(context);
			CGPathRelease(path);
			break;
		}
		case CZProgressIndicatorRightCapComponent: {
			CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorBlack));
			CGContextFillRect(context, rect);
			break;
		}
		case CZProgressIndicatorFillComponent: {
			CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorWhite));
			CGContextFillRect(context, rect);
			break;
		}
		default:
			break;
	}
}

@end