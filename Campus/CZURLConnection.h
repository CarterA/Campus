//
//  CZURLConnection.h
//  Campus
//
//  Created by Carter Allen on 2/25/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//
//  The basic architecture of this class was created by Mike Ash,
//  and was re-implemented by Carter Allen. The original code can
//  be found here:  https://gist.github.com/837409 Thanks Mike!
//

typedef void(^CZURLConnectionTimeoutHandler)(void);
typedef void(^CZURLConnectionResponseHandler)(NSURLResponse *response);
typedef void(^CZURLConnectionProgressHandler)(long long currentLength, long long totalLength);
typedef void(^CZURLConnectionCompletionHandler)(NSData *data, NSURLResponse *response);
typedef void(^CZURLConnectionErrorHandler)(NSError *error);

@interface CZURLConnection : NSObject {}

#pragma mark -
#pragma mark Creating a Connection
+ (CZURLConnection *)connectionWithRequest:(NSURLRequest *)request;
- (id)initWithRequest:(NSURLRequest *)request;

#pragma mark -
#pragma mark Configuring a Connection
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, assign) NSTimeInterval timeout;

#pragma mark Connection Event Handlers
@property (nonatomic, copy) CZURLConnectionTimeoutHandler timeoutHandler;
@property (nonatomic, copy) CZURLConnectionResponseHandler responseHandler;
@property (nonatomic, copy) CZURLConnectionProgressHandler progressHandler;
@property (nonatomic, copy) CZURLConnectionCompletionHandler completionHandler;
@property (nonatomic, copy) CZURLConnectionErrorHandler errorHandler;

#pragma mark -
#pragma mark Starting and Stopping a Connection
- (void)start;
- (void)cancel;

@end