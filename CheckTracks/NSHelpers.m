//
//  NSHelpers.m
//  CheckTracks
//
//  Created by Philipp Ackermann on 1/28/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import "NSHelpers.h"
#import "iTunes.h"

@implementation NSHelpers

+(NSString*)getJSONfromURL:(NSString *)urlStr {
    NSError *error = nil;
    NSStringEncoding enc;
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *str= [[NSString alloc] initWithContentsOfURL:url usedEncoding:&enc error:&error];
    if (error) {
        NSLog(@"JSON read error: %@", [error localizedDescription]);
    }
    return str;
}

+(NSDictionary*)convertJSONfromURL:(NSString *)urlStr {
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSData *urlData= [NSData dataWithContentsOfURL:url options:nil error:&error];
    if (error) {
        NSLog(@"JSON data error: %@", [error localizedDescription]);
        return nil;
    }
    NSDictionary *dictJSON = [NSJSONSerialization JSONObjectWithData:urlData options:NSJSONReadingMutableLeaves error:&error];
    if (error) {
        NSLog(@"JSON parse error: %@", [error localizedDescription]);
        return nil;
    }
    return dictJSON;
}

+(NSImage*)imageFromData:(NSData*)data {
    if (data != nil) {
        NSImage *img = [[NSImage alloc] initWithData:data];
        return img;
    } else {
        NSLog(@"Artwork error!");
    }
    return nil;
}

+(NSImage*)coverFromTrack:(id)track {
    iTunesTrack *this_track = (iTunesTrack*)track;
    SBElementArray *artwork = [this_track artworks];
    if (artwork != nil && [artwork count] > 0) {
        iTunesArtwork *item = [artwork objectAtIndex: 0];
        NSImage *img = [item data];
        if ([img isKindOfClass:[NSImage class]]) {
            return img;
        } else {
            img = [[NSImage alloc] initWithData:[item rawData]];
            if ([img isKindOfClass:[NSImage class]]) {
                return img;
            }
        }
    } else {
        NSLog(@"Artwork error!");
    }
    return nil;
}


@end
