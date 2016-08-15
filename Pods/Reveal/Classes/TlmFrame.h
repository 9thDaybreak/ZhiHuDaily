//
//  TlmFrame.h
//  Pods
//
//  Created by Bobby Skinner on 2/5/16.
//
//

#import <Foundation/Foundation.h>

@interface TlmFrame : NSObject

@property (nonatomic, assign) NSInteger batteryVolts;
@property (nonatomic, assign) double temperature;
@property (nonatomic, assign) NSInteger advertisementCount;
@property (nonatomic, assign) NSInteger onTime;


@end
