//
//  RVLWebServices.h
//  RevealSDK
//
//  Created by Sean Doherty on 1/7/15.
//  Copyright (c) 2015 StepLeader Digital. All rights reserved.
//
//  NOTE: This file is structured strangley to
//        facilitate using the file indepandantly
//        not for logical code separation

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - shared code (duplicated) here -
// NOTE: The following MODEL class definitions are included in the web
//       services file as the master location and are duplicated as needed.
//       Any modifications should be done first in RVLWebServices.h then
//       copied to other locations

#ifndef REVEAL_MODEL_DEFINED
#define REVEAL_MODEL_DEFINED

// known beacon verndor codes
#define BEACON_TYPE_GIMBAL              140
#define BEACON_TYPE_SWIRL               181

// extra beacon (Gimbal?)
#define BEACON_UNKNOWN_A                349

// known service types
#define BEACON_SERVICE_EDDYSTONE        0xfeaa
#define BEACON_SERVICE_EDDYSTONE_STRING @"FEAA"
#define BEACON_SERVICE_SECURECAST       0xfeeb
#define BEACON_SERVICE_UNKNOWN_A        0xfefd
#define BEACON_SERVICE_UNKNOWN_B        0x180f
#define BEACON_SERVICE_TILE             0xfeed
#define BEACON_SERVICE_ESTIMOTE         0x180a

@class CLBeacon;
@class CLBeaconRegion;
@class CBPeripheral;
@class CLPlacemark;
@class CLLocation;

@interface RevealScannerRawBeacon : NSObject <NSCoding>

@property (nonatomic, strong) NSString* vendorName;
@property (nonatomic, assign) NSInteger vendorCode;
@property (nonatomic, assign) NSInteger key;
@property (nonatomic, assign) NSInteger local;
@property (nonatomic, strong) NSData* payload;
@property (nonatomic, strong) NSDictionary* advertisement;
@property (nonatomic, strong) NSArray* uuids;
@property (readonly) NSString* identifier;
@property (nonatomic, assign) NSInteger rssi;
@property (readonly) NSString* payloadString;
@property (nonatomic, strong) NSUUID* bluetoothIdentifier;
@property (nonatomic, strong) NSMutableDictionary* services;
@property (nonatomic, strong) NSMutableDictionary* extendedData;
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, assign) BOOL complete;
@property (nonatomic, strong) NSString* vendorId;

- (NSString*)ident:(NSInteger)index;

@end

@interface RevealBluetoothObject : NSObject

@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) CBPeripheral* peripheral;
@property (nonatomic, strong) NSDictionary* advertisement;
@property (nonatomic, strong) RevealScannerRawBeacon* beacon;
@property (nonatomic, strong) NSDictionary* services;
@property (nonatomic, strong) NSDate* dateTime;
@property (nonatomic, strong) NSArray* uuids;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSMutableDictionary* characteristics;

@property (readonly) BOOL connectable;

@property (readonly) NSString* name;

+ (NSString*) serviceName:(NSString*)serviceName;
+ (NSString*) data:(id)data;

@end

@interface RVLBeacon : NSObject <NSCoding>

@property (nonatomic, strong)   NSUUID   *proximityUUID;
@property (nonatomic, strong)   NSString *major;
@property (nonatomic, strong)   NSString *minor;

@property (nonatomic, copy)     NSString *proximity;
@property (nonatomic, strong)   NSNumber *accuracy;
@property (nonatomic, strong)   NSNumber *rssi;

/**
 *  unique id of beacon
 */
@property (nonatomic, readonly) NSString *rvlUniqString;

@property (nonatomic, strong)   NSDate   *discoveryTime;
@property (nonatomic, strong)   NSDate   *sentTime;

@property (readonly)            NSString* type;
@property (readonly)            BOOL decoded;

@property (nonatomic, strong) RevealScannerRawBeacon* rawBeacon;

- (instancetype) initWithBeacon:(CLBeacon *)beacon;
- (instancetype) initWithBeaconRegion:(CLBeaconRegion *)beaconRegion;
- (instancetype) initWithRawBeacon:(RevealScannerRawBeacon*)beacon;

+ (NSString*)rvlUniqStringWithBeacon:(CLBeacon*) beacon;

@end
#endif


#pragma mark - end shared code (duplicated) -

/**
 *  The Web Services class provides the interface to send beacon data to the Reveal server
 */
@interface RVLWebServices : NSObject

/**
 *  The API Key
 */
@property (nonatomic) NSString* apiKey;

/**
 *  The URL for the server to send information to
 */
@property (nonatomic, strong) NSString* apiUrl;

/**
 *  provide a routine to perform logging functionality
 */
@property (nonatomic, assign) void (*log)( NSString* type, NSString *format, ...);

/**
 *  provide a routine to perform logging functionality
 */
@property (nonatomic, assign) void (*logVerbose)( NSString* type, NSString *format, ...);

/**
 *  The git hash for the current build
 */
@property (nonatomic, strong) NSString* build;

/**
 *  Get the Web Service manager to communicate with the Reveal server
 *
 *  @return the shared instance of the Web Services class
 */
+ (RVLWebServices*) sharedWebServices;

/**
 *  register the device with reveal, sending the device information. it 
 *  returns a dictionary containing scan durations as wells as persona's
 *  to update the client settings from.
 *
 *  Keys:
 *
 *      cache_ttl - time to keep location entries in the cache to prevent 
 *                  duplication
 *      scan_interval - time to wait between scans
 *      scan_length - duration to scan for beacons on each pass
 *      discovery_enabled - beacon scanning is requested, if false the client 
 *                   should not scan
 *      beacons - list of beacons to scan for
 *
 *  @param result callback to receive the response from the server
 */
- (void) registerDeviceWithResult:(void (^)(BOOL success, NSDictionary* result, NSError* error))result;

/**
 *  Notify the server of a new beacon discovery
 *
 *  @param beacon the beacon's details
 *  @param result callback to receive the response from the server
 */
- (void) sendNotificationOfBeacon:(RVLBeacon*) beacon
        result:(void (^)(BOOL success, NSDictionary* result, NSError* error))result;

/**
 *  Get the current IP address
 *
 *  @param preferIPv4 I want the old style
 *
 *  @return the best IP address available
 */
- (NSString *)getIPAddress:(BOOL)preferIPv4;

/**
 *  Get all IP addresses
 *
 *  @return array of IP Addresses
 */
- (NSDictionary *)getIPAddresses;

/**
 *  The version of the SDK
 */
- (NSString*) version;

@end

