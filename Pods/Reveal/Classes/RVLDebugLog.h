//
//  RVLDebugLog.h
//  RevealSDK
//
//  Created by Jay Lyerly on 10/20/14.
//  Copyright (c) 2014 StepLeader Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

void RVLLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void RVLLogWithType(NSString* type, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
void RVLLogVerbose(NSString* type, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

@interface RVLDebugLog : NSObject

/**
 *  Enable debugs
 */
@property (nonatomic, assign) BOOL enabled;

/**
 *  Include verbose logs
 */
@property (nonatomic, assign) BOOL verbose;

/**
 *  Enable the use of color in the logs - Requires the installation of 
 *  XCodeColors: https://github.com/robbiehanson/XcodeColors
 *
 *  Available via Alcatraz http://alcatraz.io/
 */
@property (nonatomic, assign) BOOL useColor;

+ (instancetype)sharedLog;

/**
 *  Log the specified string as type "DEBUG"
 *
 *  @param aString the string to log
 */
- (void) log:(NSString *)aString;

/**
 *  Log the specified string to the console
 *
 *  @param aString the string to log
 *  @param type    the type of log
 */
- (void) log:(NSString *)aString ofType:(NSString*)type;

/**
 *  Log the specified string only if verbose logging is enabled
 *
 *  @param aString the string to log
 *  @param type    the type of log
 */
- (void) logVerbose:(NSString *)aString ofType:(NSString*)type;

@end
