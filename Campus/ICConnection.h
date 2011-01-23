//
//  ICConnection.h
//  Campus
//
//  Created by George Woodliff-Stanley on 1/22/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "ICResponse.h"

typedef void (^ICConnectionCompletionHandler)(ICResponse *response);

@interface ICConnection : NSObject {}
- (void)scrapeDataWithUsername:(NSString *)username password:(NSString *)password completionHandler:(ICConnectionCompletionHandler)completionHandler;
@end
