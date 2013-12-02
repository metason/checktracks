//
//  NSHelpers.h
//  CheckTracks
//
//  Created by Philipp Ackermann on 1/28/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NSHelpers : NSObject

+(NSString*)getJSONfromURL:(NSString *)urlStr;
+(NSDictionary*)convertJSONfromURL:(NSString *)urlStr;
+(NSImage*)imageFromData:(NSData*)data;
+(NSImage*)coverFromTrack:(id)track;

@end
