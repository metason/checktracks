//
//  NSImage+Dimension.h
//  CheckTracks
//
//  Created by Philipp Ackermann on 1/27/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Dimension)

-(int)getWidth;
-(int)getHeight;
-(int)saveToFile:(NSString *)fn; // needs filename in POSIX style
-(NSData*)imgData;
@end
