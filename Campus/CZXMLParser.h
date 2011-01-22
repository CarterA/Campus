//
//  CZXMLParser.h
//  Campus
//
//  Created by Carter Allen on 1/18/11.
//  Copyright 2011 Opt-6 Products, LLC. All rights reserved.
//

/* Example code:
 CZXMLParser *parser = [[CZXMLParser alloc] initWithData:response];
 parser.elementStartHandler = ^(NSString *elementName, NSString *namespaceURI, NSString *qualifiedName, NSDictionary *attributeDict) {
 NSLog(@"Element start. Name: %@", elementName);
 };
 parser.elementEndHandler = ^(NSString *elementName, NSString *namespaceURI, NSString *qualifiedName) {
 NSLog(@"Element end. Name: %@", elementName);
 };
 parser.errorHandler = ^(NSError *error) {
 NSLog(@"Error: %@", error);
 };
 [parser parse];
 */

typedef void (^CZXMLParserElementStartHandler)(NSString *elementName, NSString *namespaceURI, NSString *qualifiedName, NSDictionary *attributeDict);
typedef void (^CZXMLParserElementEndHandler)(NSString *elementName, NSString *namespaceURI, NSString *qualifiedName);
typedef void (^CZXMLParserErrorHandler)(NSError *error);

@interface CZXMLParser : NSXMLParser <NSXMLParserDelegate> {}
@property (nonatomic, copy) CZXMLParserElementStartHandler elementStartHandler;
@property (nonatomic, copy) CZXMLParserElementEndHandler elementEndHandler;
@property (nonatomic, copy) CZXMLParserErrorHandler errorHandler;
@end