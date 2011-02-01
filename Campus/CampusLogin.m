//
//  CampusLogin.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CampusLogin.h"

@interface CampusLogin()
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, copy) CampusLoginCompletionHandler completionHandler;
@end

@implementation CampusLogin
@synthesize receivedData, completionHandler;
+ (CampusLogin *)sharedLogin {
	static CampusLogin *globalCampusLogin;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{ globalCampusLogin = [[self alloc] init]; });
	return globalCampusLogin;
}
- (void)loginAsUser:(NSString *)user withPassword:(NSString *)password completionHandler:(CampusLoginCompletionHandler)theCompletionHandler {
	self.completionHandler = theCompletionHandler;
	NSURL *url = [NSURL  URLWithString:@"https://campus.dpsk12.org/campus/verify.jsp"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	[request setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-us) AppleWebKit/533.19.4 (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4" forHTTPHeaderField:@"User-Agent"];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[NSString stringWithFormat:@"screen=1680x1050&appName=icprod&username=%@&password=%@", user, password] dataUsingEncoding:NSUTF8StringEncoding]];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connection) self.receivedData = [NSMutableData data];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data { [self.receivedData appendData:data]; }
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response { [self.receivedData setLength:0]; }
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [connection release];
	self.receivedData = nil;
	NSLog(@"Connection failed. Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.completionHandler(self.receivedData);
	[connection release];
	self.receivedData = nil;
}
@end