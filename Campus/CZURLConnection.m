//
//  CZURLConnection.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CZURLConnection.h"

@interface CZURLConnection()
@property (nonatomic, retain) NSMutableData *receivedData;
@end

@implementation CZURLConnection
@synthesize completionHandler, errorHandler, receivedData;
- (id)initWithRequest:(NSURLRequest *)request {
	self = [super initWithRequest:request delegate:self startImmediately:NO];
	return self;
}
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
	if ((self = [super initWithRequest:request delegate:self startImmediately:NO])) {
		self.receivedData = [NSMutableData data];
	}
	return self;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data { [self.receivedData appendData:data]; }
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.receivedData = nil;
	self.errorHandler(error);
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.completionHandler(self.receivedData);
	self.receivedData = nil;
}
@end