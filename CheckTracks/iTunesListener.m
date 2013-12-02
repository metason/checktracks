//
//  iTunesListener.m
//  CheckTracks
//
//  Created by Philipp Ackermann on 2/9/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import "iTunesListener.h"

@implementation iTunesListener

- (void) startListening:(NSObject *)obj {
    actionHandler = obj;
    if (TRUE) { // set to FALSE for logging all notifications
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receivePlayerNotification:)
                                                        name:@"com.apple.iTunes.playerInfo"
                                                        object:nil];
/*        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(receiveSourceNotification:)
                                                                name:@"com.apple.iTunes.sourceSaved"
                                                              object:nil];
*/
    } else {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receiveAnyNotification:)
                                                        name:nil
                                                        object:nil];
    }
    //NSLog(@"iTunesListener started");
}

- (void) stopListening {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"iTunesListener stopped");
}

- (void) receivePlayerNotification:(NSNotification *)note {
    NSDictionary *userInfo = [note userInfo];
    artist = [userInfo valueForKey:@"Artist"];
    albumArtist = [userInfo valueForKey:@"Album Artist"];
    album = [userInfo valueForKey:@"Album"];
/*    NSString *Name = [NSString stringWithFormat:@"%@", [userInfo valueForKey:@"Name"]];
    NSString *Time = [userInfo valueForKey:@"Total Time"];
    NSString *State = [userInfo valueForKey:@"Player State"];
*/
    //NSLog(@"player information: %@", userInfo);
    [actionHandler performSelector:@selector(syncWithiTunes)];
}

- (void) receiveSourceNotification:(NSNotification *)note {
    //NSDictionary *userInfo = [note userInfo];
    //NSLog(@"source information: %@", userInfo);
    //[actionHandler performSelector:@selector(analyseTracks)];
}

- (void) receiveAnyNotification:(NSNotification *)note {
    
    //NSString *object = [note object];
    NSString *name = [note name];
    NSDictionary *userInfo = [note userInfo];
    NSLog(@"%@", name);
    NSLog(@"note: %@", userInfo);
    //NSLog(@"<%p>%s: object: %@ name: %@ userInfo: %@", self, __PRETTY_FUNCTION__, object, name, userInfo);
}

- (NSString*) albumToSync {
    return album;
}

- (NSString*) artistToSync {
    return artist;
}

- (NSString*) albumArtistToSync {
    return albumArtist;
}

@end
