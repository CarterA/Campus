//
//  CZXMLParser.m
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

#import "CZXMLParser.h"

@implementation CZXMLParser
@synthesize elementStartHandler, elementEndHandler, errorHandler;
- (id)initWithData:(NSData *)data {
	if ((self = [super initWithData:data])) {
		self.delegate = self;
	}
	return self;
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if (self.elementStartHandler) self.elementStartHandler(elementName, namespaceURI, qualifiedName, attributeDict);
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if (self.elementEndHandler) self.elementEndHandler(elementName, namespaceURI, qName);
}
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	if (self.errorHandler) self.errorHandler(parseError);
}
@end