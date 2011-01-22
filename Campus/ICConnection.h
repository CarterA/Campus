//
//  ICConnection.h
//  Campus
//
//  Created by George Woodliff-Stanley on 1/22/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

typedef void (^ICConnectionCompletionHandler)(NSData *response);

@interface ICConnection : NSObject {}
- (void)connectToBaseURL:(NSURL *)baseURL withUsername:(NSString *)username password:(NSString *)password completionHandler:(ICConnectionCompletionHandler)completionHandler;
@end
