//
//  RVLDebugLog.m
//  RevealSDK
//
//  Created by Jay Lyerly on 10/20/14.
//  Copyright (c) 2014 StepLeader Digital. All rights reserved.
//

#import "RVLDebugLog.h"

// How to apply color formatting to your log statements:
//
// To set the foreground color:
// Insert the ESCAPE into your string, followed by "fg124,12,255;" where r=124, g=12, b=255.
//
// To set the background color:
// Insert the ESCAPE into your string, followed by "bg12,24,36;" where r=12, g=24, b=36.
//
// To reset the foreground color (to default value):
// Insert the ESCAPE into your string, followed by "fg;"
//
// To reset the background color (to default value):
// Insert the ESCAPE into your string, followed by "bg;"
//
// To reset the foreground and background color (to default values) in one operation:
// Insert the ESCAPE into your string, followed by ";"

#define XCODE_COLORS_ESCAPE @"\033["

#define XCODE_COLORS_RESET_FG  XCODE_COLORS_ESCAPE @"fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG  XCODE_COLORS_ESCAPE @"bg;" // Clear any background color
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

void RVLLog(NSString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arguments];
    [[RVLDebugLog sharedLog] log:formattedString];
    
    va_end(arguments);
}

void RVLLogWithType(NSString* type, NSString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arguments];
    [[RVLDebugLog sharedLog] log:formattedString ofType: type];
    
    va_end(arguments);
}

void RVLLogVerbose(NSString* type, NSString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arguments];
    [[RVLDebugLog sharedLog] logVerbose: formattedString ofType: type];
    
    va_end(arguments);
}

@implementation RVLDebugLog

+ (RVLDebugLog *) sharedLog
{
    static RVLDebugLog *_mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
        {
            _mgr = [[RVLDebugLog alloc] init];
            
            _mgr.useColor = NO;
            _mgr.verbose = NO;
        });
    
    return _mgr;
}

- (void) log:(NSString *)aString
{
    [self log: aString ofType: @"DEBUG"];
}

- (void) log:(NSString *)aString ofType:(NSString*)type
{
    NSString* theType = type.lowercaseString;
    
    if ( [theType isEqualToString: @"error"] )
        [self logString: aString withRed: 255 green: 0 blue: 0 ofType: type];
    else if ( [theType isEqualToString: @"warning"] )
        [self logString: aString withRed: 238 green: 238 blue: 0 ofType: type];
    else if ( [theType isEqualToString: @"debug"] )
        [self logString: aString withRed: 0 green: 255 blue: 0 ofType: type];
    else if ( [theType isEqualToString: @"standout"] )
        [self logString: aString withRed: 255 green: 128 blue: 0 ofType: type];
    else if ( [theType isEqualToString: @"info"] )
        [self logString: aString withRed: 152 green: 225 blue: 255 ofType: type];
    else if ( [theType isEqualToString: @"comm"] )
        [self logString: aString withRed: 255 green: 0 blue: 255 ofType: type];
    else
        [self logString: aString withRed: -1 green: -1 blue: -1 ofType: type];
}

- (void) logVerbose:(NSString *)aString ofType:(NSString*)type
{
    if ( self.verbose )
        [self log: aString ofType: type];
}

- (void) logString:(NSString *)aString withRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue ofType:(NSString*)type
{
    if (self.enabled)
    {
        if ( self. useColor && red >= 0 )
            NSLog(XCODE_COLORS_ESCAPE @"fg%d,%d,%d;" @"Reveal [%@]: %@" XCODE_COLORS_RESET, (int)red, (int)green, (int)blue, type, aString );
        else
            NSLog(@"Reveal [%@]: %@", type, aString);
    }
}

@end
