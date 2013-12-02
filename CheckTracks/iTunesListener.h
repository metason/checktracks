//
//  iTunesListener.h
//  CheckTracks
//
//  Created by Philipp Ackermann on 2/9/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iTunesListener : NSObject
{
    id actionHandler;
    NSString *artist;
    NSString *album;
    NSString *albumArtist;
}
@property (copy) NSString *artist;
@property (copy) NSString *album;
@property (copy) NSString *albumArtist;

-(void) startListening:(NSObject *)handler;
-(void) stopListening;
-(void) receivePlayerNotification:(NSNotification *)notification;
-(void) receiveSourceNotification:(NSNotification *)notification;
-(void) receiveAnyNotification:(NSNotification *)notification; // for logging
-(NSString*) albumToSync;
-(NSString*) artistToSync;
-(NSString*) albumArtistToSync;

@end
