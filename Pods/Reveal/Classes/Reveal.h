//
//  RevealSDK.h
//  RevealSDK
//
//  Created by Sean Doherty on 1/8/2015.
//  Copyright (c) 2015 StepLeader Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RVLWebServices.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

@class CLPlacemark;

@protocol RVLBeaconService <NSObject>

- (void) startBeaconScanning:(NSArray *)targetBeacons;

- (void) stopBeaconScanning;

@end

@protocol RVLLocationService <NSObject>

-(CLLocation*) getCurrentLocation;
-(CLPlacemark*) getCurrentPlacemark;
/**
 *  Start monitoring location services. If your bundle contains the
 *  NSLocationWhenInUseUsageDescription string then requestWhenInUseAuthorization
 *  will be called, otherwise if NSLocationAlwaysUsageDescription is provided
 *  then requestAlwaysAuthorization will be called. If neither string is present
 *  then location services will net be started.
 */
- (void) startLocationMonitoring;

/**
 *  stop monitoring location changes
 */
- (void) stopLocationMonitoring;

/**
 *  Allows functions that need a valid location to wait for a valid location to be available (placemark if possible)
 *  If there is already a valid location available, then the callback returns immediately, otherwise, the callback waits until
 *  there is a valid location or a timeout, in which case the best location we can find will be used
 *
 *  @param callback The method to call when a valid location is available
 */
- (void) waitForValidLocation:(void (^)())callback;

@end

/**
 *  Server selection
 */
typedef NS_ENUM(NSInteger, RVLServiceType) {
    /**
     *  Server for testing only
     */
    RVLServiceTypeSandbox,
    /**
     *  Server for real world use
     */
    RVLServiceTypeProduction
};


//  Location manager constants
typedef NS_ENUM(NSInteger, RVLLocationServiceType) {
    // Location disabled
    RVLLocationServiceTypeNone = 0,
    
    // While in use location detection selected
    RVLLocationServiceTypeInUse,
    
    //  Always location detection selected
    RVLLocationServiceTypeAlways
};

@interface Reveal : NSObject

/**
 *  The server you wish to connect to, may be
 *  RVLServiceTypeProduction or RVLServiceTypeSandbox
 */
@property (assign,nonatomic) RVLServiceType serviceType;

/**
 *  Array of strings, each containing a UUID.  These UUIDs
 *  will override the list retrieved from the Reveal
 *  server.  This is useful to debug/verify that the SDK
 *  can detect a known iBeacon when testing.  This is a
 *  development feature and should not be used in production.
 *  In order to override the UUIDs from the server, this
 * property should be set before starting the service.
 */
@property (nonatomic, strong) NSArray <NSString*> *debugUUIDs;

/**
 *  Debug flag for the SDK.  If this value is YES, the SDK
 *  will log debugging information to the console.
 *  Default value is NO.
 *  This can be toggled during the lifetime of the SDK usage.
 */
@property (nonatomic, assign) BOOL debug;

/**
 *  An option to allow a developer to manually disable beacon scanning
 *  Default value is YES
 */
@property (nonatomic, assign) BOOL beaconScanningEnabled;

/**
 *  Accessor properties for the SDK.
 *  At any time, the client can access the list of errors
 *  and the list of personas.  Both are arrays of NSStrings.
 *  Values may be nil.
 */
@property (nonatomic, strong) NSArray <NSString*> *personas;

/**
 *  get the version of the SDK
 */
@property (nonatomic, strong) NSString* version;

/**
 *  SDK singleton.  All SDK access should occur through this object.
 *
 *  @return the instance
 */
+ (Reveal*) sharedInstance;

/**
 *  Start the SDK with the specified SDK
 *
 *  @param key the API key
 *
 */
-(Reveal*) setupWithAPIKey:(NSString*) key;

/**
 *  Start the SDK with the specified SDK
 *
 *  @param key         the API key
 *  @param serviceType The type
 */
-(Reveal*) setupWithAPIKey:(NSString*) key andServiceType:(RVLServiceType) serviceType;

/**
 *  Start the SDK service.  The SDK will contact the API and retrieve
 *  further configuration info.  Background beacon scanning will begin
 *  and beacons will be logged via the API.
 */
-(void) start;

/**
 *   Notify the SDK that the app is restarting.  To be called in applicationDidBecomeActive
 */
-(void) restart;

/**
 *  list of beacons encountered for debugging only
 */
- (NSDictionary*)beacons;

/**
 *  list of bluetooth devices encountered for debugging if enabled
 */
- (NSDictionary*)devices;

- (RVLLocationServiceType)locationServiceType;

// Bluetooth testing API should be treated as deprecated
@property (nonatomic) BOOL captureAllDevices;
@property (readonly) NSDictionary<NSString*, RevealBluetoothObject*>* bluetoothDevices;

@end
