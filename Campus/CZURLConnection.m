//
//  CZURLConnection.m
//  Campus
//
//  Created by Carter Allen on 2/25/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CZURLConnection.h"

@interface CZURLConnection ()
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLResponse *response;
@property (nonatomic, retain) NSTimer *timeoutTimer;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, assign) long long estimatedResponseLength;
- (void)connectionDidTimeout;
@end

#pragma mark -
@implementation CZURLConnection

#pragma mark Public Properties
@synthesize request=_request;
@synthesize timeout=_timeout;
@synthesize timeoutHandler=_timeoutHandler;
@synthesize responseHandler=_responseHandler;
@synthesize progressHandler=_progressHandler;
@synthesize completionHandler=_completionHandler;
@synthesize errorHandler=_errorHandler;

#pragma mark -
#pragma mark Private Properties
@synthesize connection=_connection;
@synthesize response=_response;
@synthesize timeoutTimer=_timeoutTimer;
@synthesize receivedData=_receivedData;
@synthesize estimatedResponseLength=_estimatedResponseLength;

#pragma mark -
#pragma mark Initializers
+ (CZURLConnection *)connectionWithRequest:(NSURLRequest *)request {
	return [[[self alloc] initWithRequest:request] autorelease];
}
- (id)initWithRequest:(NSURLRequest *)request {
	if ((self = [super init])) {
		_request = [request retain];
	}
	return self;
}
- (id)init {
	self = [self initWithRequest:nil];
	return self;
}

#pragma mark -
#pragma mark Memory Management
- (void)dealloc {
	[_request release];
	[_response release];
	[_timeoutHandler release];
	[_responseHandler release];
	[_progressHandler release];
	[_completionHandler release];
	[_errorHandler release];
	[_connection release];
	[_timeoutTimer release];
	[_receivedData release];
	[super dealloc];
}

#pragma mark -
#pragma mark Starting and Stopping a Connection
- (void)start {
	if (self.timeout)
		self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(connectionDidTimeout) userInfo:nil repeats:NO];
	if (!self.connection)
		self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
	[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.connection start];
}
- (void)cancel {
	[self.timeoutTimer invalidate];
	[self.connection cancel];
}

#pragma mark -
#pragma mark Connection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = response;
    self.estimatedResponseLength = [response expectedContentLength];
    if (self.responseHandler) self.responseHandler(response);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!self.receivedData) self.receivedData = [NSMutableData data];
    [self.receivedData appendData:data];
    if (self.progressHandler) self.progressHandler([self.receivedData length], self.estimatedResponseLength);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.timeoutTimer invalidate];
    if (self.completionHandler) self.completionHandler(self.receivedData, self.response);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.timeoutTimer invalidate];
    if(self.errorHandler) self.errorHandler(error);
}
- (void)connectionDidTimeout {
	[self cancel];
	if (self.timeoutHandler) self.timeoutHandler();
}

@end
