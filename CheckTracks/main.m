//
//  main.m
//  CheckTracks
//
//  Created by Philipp Ackermann on 1/23/13.
//  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, char *argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, (const char **)argv);
}
