//
//  CampusLogin.h
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

typedef void (^CampusLoginCompletionHandler)(NSData *response);

@interface CampusLogin : NSObject {}
+ (CampusLogin *)sharedLogin;
- (void)loginAsUser:(NSString *)user withPassword:(NSString *)password completionHandler:(CampusLoginCompletionHandler)theCompletionHandler;
@end