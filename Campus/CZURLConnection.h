//
//  CZURLConnection.h
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

typedef void (^CZURLConnectionCompletionHandler)(NSData *data);
typedef void (^CZURLConnectionErrorHandler)(NSError *error);

@interface CZURLConnection : NSURLConnection {}
@property (nonatomic, copy) CZURLConnectionCompletionHandler completionHandler;
@property (nonatomic, copy) CZURLConnectionErrorHandler errorHandler;
- (id)initWithRequest:(NSURLRequest *)request;
@end