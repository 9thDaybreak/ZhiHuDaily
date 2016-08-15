//
//  RevealSDK.m
//  RevealSDK
//
//  Created by Sean Doherty on 1/8/2015.
//  Copyright (c) 2015 StepLeader Digital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RVLBeaconManager.h"
#import "RVLDebugLog.h"
#import "RVLLocation.h"
#import "RVLWebServices.h"
#import "Reveal.h"
//commented out till fixed to work in cocoapods:
//#import "gitinfo.h"

#ifndef objc_dynamic_cast
#define objc_dynamic_cast(TYPE, object)                                       \
    ({                                                                        \
        TYPE *dyn_cast_object = (TYPE *)(object);                             \
        [dyn_cast_object isKindOfClass:[TYPE class]] ? dyn_cast_object : nil; \
    })
#endif

BOOL serverRegistrationInprogress = false;

@interface Reveal (PrivateMethods)

@end

@implementation Reveal
NSString *const kRevealBaseURLSandbox = @"https://sandboxsdk.revealmobile.com/";
NSString *const kRevealBaseURLProduction = @"https://sdk.revealmobile.com/";
NSString *const kRevealNSUserDefaultsKey = @"personas";
static Reveal *_sharedInstance;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)dealloc
{
}

+ (Reveal *)sharedInstance
{
    // refuse to initialize unless we're at iOS 7 or later.
    if ([[[UIDevice currentDevice] systemVersion] integerValue] < 7)
    {
        return nil;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      _sharedInstance = [[Reveal alloc] init];
      _sharedInstance.debug = NO;
      _sharedInstance.beaconScanningEnabled = YES;
    });

    return _sharedInstance;
}


- (RVLLocationServiceType)locationServiceType
{
    RVLLocationServiceType result = RVLLocationServiceTypeNone;
    
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"])
        result = RVLLocationServiceTypeInUse;
    else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"])
        result = RVLLocationServiceTypeAlways;
    else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationUsageDescription"])
        result = RVLLocationServiceTypeAlways;
    
    return result;
}

- (NSString *)version
{
    return [[RVLWebServices sharedWebServices] version];
}

- (void)setDebug:(BOOL)debug
{
    _debug = debug;

    [[RVLDebugLog sharedLog] setEnabled:_debug];
}

- (Reveal *)setupWithAPIKey:(NSString *)key
{
    return [self setupWithAPIKey:key andServiceType:RVLServiceTypeProduction];
}

- (Reveal *)setupWithAPIKey:(NSString *)key andServiceType:(RVLServiceType)serviceType
{
    if (key == nil) {
        RVLLog(@"No API Key passed in, API Key is required for Reveal to start");
        return nil;
    }
    
    RVLLog( @"Setting up Reveal SDK with key: %@ and ServiceType: %d", key, (int) serviceType );
    
    [[RVLWebServices sharedWebServices] setApiKey:key];
    //Set service type value and update webservices with appropriate base url
    self.serviceType = serviceType;
    if (serviceType == RVLServiceTypeSandbox)
    {
        [[RVLWebServices sharedWebServices] setApiUrl:kRevealBaseURLSandbox];
    }
    else
    {
        [[RVLWebServices sharedWebServices] setApiUrl:kRevealBaseURLProduction];
    }
    RVLLog(@"Setup complete");
    return self;
}

- (void)registerDevice:(BOOL)isStarting
{
    RVLLog(@"Registering device with Server");
    [[RVLWebServices sharedWebServices] registerDeviceWithResult:^(BOOL success, NSDictionary *result, NSError *error) {
      if (success)
      {
          RVLLog(@"Device registered successfully");

          self.personas = objc_dynamic_cast(NSArray, [result objectForKey:@"personas"]);

          //Only start scanning if server returns discovery_enabled = true
          if ([objc_dynamic_cast(NSNumber, result[@"discovery_enabled"]) boolValue])
          {
              if (self.beaconScanningEnabled)
              {
                  NSNumber *cacheTime = result[@"cache_ttl"];
                  if ([cacheTime isKindOfClass:[NSNumber class]])
                      [[[RVLBeaconManager sharedManager] cachedBeacons] setCacheTime:[cacheTime floatValue] * 60.0];
                  
                  NSNumber *scanInterval = result[@"scan_interval"];
                  if ([cacheTime isKindOfClass:[NSNumber class]])
                      [[RVLBeaconManager sharedManager] setScanInterval:[scanInterval floatValue] + 0.123];
                  
                  scanInterval = result[@"scan_length"];
                  if ([cacheTime isKindOfClass:[NSNumber class]])
                      [[RVLBeaconManager sharedManager] setScanDuration:[scanInterval floatValue] + 0.321];
                  
                  // NOTE: On android we only scan for specific secure cast codes as send from the server
                  //       but on iOS we want to get them all since they return only FEEB beacons
                  [[RVLBeaconManager sharedManager] addVendorNamed:@"SecureCast" withCode: BEACON_SERVICE_SECURECAST];
                  
                  // NOTE: These becaon types have been spotted but are not fully deciphered
                  //       leave them commented out until they are fleshed out
                  //[[RVLBeaconManager sharedManager] add:@"Unknown FEFD" withCode: BEACON_SERVICE_UNKNOWN_A];
                  //[[RVLBeaconManager sharedManager] add:@"Unknown 180F" withCode: BEACON_SERVICE_UNKNOWN_B];
                  
                  // Only start scanning if the app is starting up
                  if (isStarting) {
                      //If we have debug UUID's set, ignore list from server
                      if (self.debugUUIDs)
                      {
                          [self startScanningForBeacons:self.debugUUIDs];
                      }
                      else
                      {
                          NSArray *beaconsToScan = objc_dynamic_cast(NSArray, result[@"beacons"]);
                          [self startScanningForBeacons:beaconsToScan];
                      }
                  }
              }
              else
              {
                  RVLLog(@"Beacon scanning was manually disabled");
              }

              
          }
          else
          {
              RVLLog(@"Beacon scanning was disabled from the server");
              [self stopScanningForBeacons];
          }
      }
      else {
          RVLLogWithType(@"ERROR", @"Device registration failed:\n%@\nERROR: %@", result, error);
      }
    }];
}

- (void)startScanningForBeacons:(NSArray *)beacons
{
    RVLLog(@"Starting beacon scanning with %d beacons", (int) [beacons count]);
    
    for (NSString *uuid in beacons)
    {
        RVLLog(@"Scanning for beacons with UUID: %@", uuid);
        [[RVLBeaconManager sharedManager] addBeacon:uuid];
    }
    
    //Start non-iBeacon scanner
    [[RVLBeaconManager sharedManager] startScanner];
}

- (void)stopScanningForBeacons
{
    [[RVLBeaconManager sharedManager] shutdownMonitor];
}

- (void)start
{
    dispatch_async( dispatch_get_main_queue(), ^{
        RVLLogWithType(@"INFO", @"Starting Reveal SDK");
        
        // debugging setup
        [[RVLWebServices sharedWebServices] setLog:RVLLogWithType];
        [[RVLWebServices sharedWebServices] setLogVerbose:RVLLogVerbose];
        [[RVLLocation sharedManager] setLog:RVLLogWithType];
        [[RVLBeaconManager sharedManager] setLog:RVLLogWithType];
        [[RVLBeaconManager sharedManager] setLogVerbose:RVLLogVerbose];
        
//        [[RVLLocation sharedManager] setPassThroughDelegate: [RVLBeaconManager sharedManager]];
        [[RVLLocation sharedManager] startLocationMonitoring];
//        [[RVLBeaconManager sharedManager] setLocationManager:[[RVLLocation sharedManager] locationManager]];
        
        [self handleRegistration: YES];
        
//      RVLLogVerbose(@"DEBUG", @"IP: %@\n%@\n\n", [[RVLWebServices sharedWebServices] getIPAddress:YES], [[RVLWebServices sharedWebServices] getIPAddresses]);
    });
}

- (void)restart
{
    [self handleRegistration:NO];
}

- (void) handleRegistration:(BOOL)isStarting
{
    if (isStarting)
        RVLLogWithType(@"DEBUG", @"Registering device start");
    else
        RVLLogWithType(@"DEBUG", @"Registering device restart");
//    @synchronized (self)
//    {
//        if ( !serverRegistrationInprogress )
//        {
//            serverRegistrationInprogress = YES;
    
            [[RVLLocation sharedManager] waitForValidLocation: ^()
             {
//                 serverRegistrationInprogress = NO;
                 //If we are starting, we need to wait for the bluetooth status to be enabled
                 if (isStarting && [CBCentralManager instancesRespondToSelector:@selector(initWithDelegate:queue:options:)])
                 {
                     RVLLogVerbose(@"DEBUG", @"This device supports Bluetooth LE");
                     // enable beacon scanning if this device supports Bluetooth LE
                     [[RVLBeaconManager sharedManager] addStatusBlock:^(CBCentralManagerState state) {
                         RVLLogVerbose(@"DEBUG", @"Bluetooth status block called");
                         // don't connect to the endpoint until the bluetooth status is ready
                         static BOOL firstTime = YES;
                         
                         if (firstTime)
                         {
                             [self registerDevice: isStarting];
                             firstTime = NO;
                         };
                         
                     }];
                 }
                 else
                 {
                     //If we aren't starting, then just send the notification directly
                     [self registerDevice: isStarting];
                 }
             }];
//        }
//    }
}

- (void)setPersonas:(NSArray *)personas
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:personas forKey:kRevealNSUserDefaultsKey];
    [defaults synchronize];
}

- (NSArray *)personas
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kRevealNSUserDefaultsKey];
}

- (NSDictionary *)beacons
{
    NSDictionary *result = @{};
    CCObjectCache *dict = [[RVLBeaconManager sharedManager] cachedBeacons];

    if (dict)
    {
        result = [dict dictionary];
    }

    return result;
}

- (NSDictionary *)devices
{
    return [[[RVLBeaconManager sharedManager] bluetoothDevices] dictionary];
}

- (CLPlacemark *)location
{
    return [[RVLLocation sharedManager] userPlacemark];
}

- (BOOL) captureAllDevices
{
    return [[RVLBeaconManager sharedManager] captureAllDevices];
}

- (void) setCaptureAllDevices:(BOOL)captureAllDevices
{
    [[RVLBeaconManager sharedManager] setCaptureAllDevices: captureAllDevices];
}

- (NSDictionary<NSString*, RevealBluetoothObject*>*) bluetoothDevices
{
    return [[[RVLBeaconManager sharedManager] bluetoothDevices] dictionary];
}

@end
