//
//  NSImage+Dimension.m
//  CheckTracks
//
//  Created by Philipp Ackermann on 1/27/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import "NSImage+Dimension.h"

@implementation NSImage (Dimension)

-(int) getWidth {
    NSImageRep *imgRep = [self bestRepresentationForRect:NSMakeRect(0, 0, 1000, 1000) context:nil hints:nil];
    return (int)imgRep.pixelsWide;
}

-(int) getHeight {
    NSImageRep *imgRep = [self bestRepresentationForRect:NSMakeRect(0, 0, 1000, 1000) context:nil hints:nil];
    return (int)imgRep.pixelsHigh;
}

-(int) saveToFile:(NSString *)fn {
    NSArray*  representations  = [self representations];
    NSData* bitmapData = [NSBitmapImageRep representationOfImageRepsInArray: representations usingType: NSJPEGFileType properties:nil];
    BOOL result= NO;
    if (bitmapData != nil) {
        result =  [bitmapData writeToFile:fn atomically:YES];
    }
    return (int) result;
 }

-(NSData*)imgData {
    //NSData* data =  [NSData dataWithData:[self TIFFRepresentation]];
    //NSData* data =  [self TIFFRepresentation];
    //return data;
    NSArray*  representations  = [self representations];
    NSData* bitmapData = [NSBitmapImageRep representationOfImageRepsInArray: representations usingType: NSJPEGFileType properties:nil];
    return bitmapData;
}

@end
