//
//  TlmFrame.m
//  Pods
//
//  Created by Bobby Skinner on 2/5/16.
//
//

#import "TlmFrame.h"
#import "RVLDebugLog.h"

@implementation TlmFrame

- (instancetype) initWithVolts:(NSInteger)volts
                   temperature:(double)temperature
            advertisementCount:(NSInteger)advertisementCount
                        onTime:(NSInteger)onTime
{
    self = [self init];
    
    if ( self )
    {
        self.batteryVolts = volts;
        self.temperature = temperature;
        self.advertisementCount = advertisementCount;
        self.onTime = onTime;
    }
    
    return self;
}

- (TlmFrame*) frameWithBytes:(char*)bytes
{
    TlmFrame* result = nil;
    NSInteger batteryVolts = 0;
    double temperature = 0.0;
    NSInteger advertisementCount = 0;
    NSInteger onTime = 0;
    
    switch ( bytes[0] )
    {
        case 0:
            batteryVolts = ( bytes[2] << 8 ) + bytes[3];
            temperature = ( bytes[4] << 8 ) + bytes[5];
            advertisementCount = ( bytes[6] << 24 ) + ( bytes[7] << 16 ) +( bytes[8] << 8 ) + bytes[9];
            onTime = ( bytes[10] << 24 ) + ( bytes[11] << 16 ) +( bytes[12] << 8 ) + bytes[13];
            result = [[TlmFrame alloc] initWithVolts: batteryVolts
                                         temperature: temperature
                                  advertisementCount: advertisementCount
                                              onTime: onTime];
            break;
            
        default:
            RVLLog( @"ERROR: Invalid TLM version, only version 0 is supported" );
            break;
    }
    
    return result;
}

@end

/*
 
 if  let batteryVolts = batteryVolts,
 let temperature = temperature,
 let advertisementCount = advertisementCount,
 let onTime = onTime {
 return TlmFrame(batteryVolts: batteryVolts, temperature: temperature, advertisementCount: advertisementCount, onTime: onTime)
 } else {
 log("Invalid TLM frame")
 }
 
 return nil
 }
 
 }
 
 */