//
//  RVLWebServices.m
//  RevealSDK
//
//  Created by Sean Doherty on 1/7/15.
//  Copyright (c) 2015 StepLeader Digital. All rights reserved.
//
//  NOTE: This file is structured strangely to
//        facilitate using the file independantly
//        not for logical code separation

#import <AdSupport/AdSupport.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "RVLWebServices.h"
#import "RVLBeaconManager.h"
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#import "Reveal.h"

#import "RVLLocation.h"

#define LOG       \
    if (self.log) \
    self.log
#define VERBOSE          \
    if (self.logVerbose) \
    self.logVerbose

// http://goodliffe.blogspot.com/2011/02/ios-dynamic-cast-in-objective-c.html
// simuluate dynamic cast
// if object isn't subclass of type given, return nil
#define objc_dynamic_cast(TYPE, object)                                       \
    ({                                                                        \
        TYPE *dyn_cast_object = (TYPE *)(object);                             \
        [dyn_cast_object isKindOfClass:[TYPE class]] ? dyn_cast_object : nil; \
    })

// TODO: this should be generated externally and set with -dSDK_REVISION="1.2.30"
//       but until then we will define it here
#ifndef SDK_REVISION
#define SDK_REVISION @"1.2.30"
#endif

typedef enum {
    ConnectionTypeUnknown,
    ConnectionTypeNone,
    ConnectionType3G,
    ConnectionTypeWiFi
} ConnectionType;

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define IOS_CELLULAR @"pdp_ip0"
#define IOS_WIFI @"en0"
#define IOS_VPN @"utun0"
#define IP_ADDR_IPv4 @"ipv4"
#define IP_ADDR_IPv6 @"ipv6"

NSString *const kGodzillaDefaultsUrl = @"kGodzillaDefaultsUrl";
NSString *const kGodzillaDefaultsKey = @"kGodzillaDefaultsKey";

@implementation RVLWebServices

+ (RVLWebServices *)sharedWebServices
{
    static RVLWebServices *_mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      _mgr = [[RVLWebServices alloc] init];
    });

    return _mgr;
}

// Persist the info to access Godzilla for background operation
- (NSString *)apiKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kGodzillaDefaultsKey];
}

- (void)setApiKey:(NSString *)apiKey
{
    if ( apiKey )
        [[NSUserDefaults standardUserDefaults] setObject:apiKey forKey:kGodzillaDefaultsKey];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: kGodzillaDefaultsKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//- (NSString *) apiUrl{
//    return [[NSUserDefaults standardUserDefaults] objectForKey:kGodzillaDefaultsUrl];
//}
//
//+(void) setApiUrl:(NSString *)apiUrl {
//    [[NSUserDefaults standardUserDefaults] setObject:apiUrl forKey:kGodzillaDefaultsUrl];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}

- (NSMutableDictionary *)getDefaultParameters
{
    NSString *timeZone = [NSString stringWithFormat:@"%@", [NSTimeZone defaultTimeZone]] ?: @"";
    
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSString *networkType = nil;
    
    switch ([[RVLWebServices sharedWebServices] connectionType])
    {
        case ConnectionTypeWiFi:
            networkType = @"wifi";
            break;
            
        case ConnectionTypeNone:
            networkType = @"none";
            break;
            
        default:
            networkType = telephonyInfo.currentRadioAccessTechnology;
            networkType = [networkType stringByReplacingOccurrencesOfString:@"CTRadioAccessTechnology" withString:@""];
            break;
    }
    
    LOG(@"INFO", @"Network type: %@", networkType);
    
    NSMutableDictionary *fullParameters = [@{
                                             @"os" : @"ios",
                                             @"bluetooth_enabled" : @([[RVLBeaconManager sharedManager] hasBluetooth]),
                                             @"device_id" : [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                             @"app_version" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                             @"sdk_version" : SDK_REVISION,
                                             @"app_id" : [[NSBundle mainBundle] bundleIdentifier],
                                             @"sdk_version" : [self version],
                                             @"time_zone" : timeZone,
                                             @"locationSharingEnabled": @([[Reveal sharedInstance] locationServiceType] != RVLLocationServiceTypeNone ),
                                             } mutableCopy];
    
    if (networkType)
        fullParameters[@"con_type"] = networkType;
    
    CLLocation* location = [[RVLLocation sharedManager] userLocation];
    if (location) {
        CLLocationCoordinate2D coord = location.coordinate;
        NSTimeInterval coordAge = [[NSDate date] timeIntervalSinceDate:location.timestamp];
        NSUInteger coordAgeMS = (NSUInteger)(coordAge * pow(10, 6)); // convert to milliseconds
        NSNumber *floor = @(0);
        NSTimeInterval timeOffset = 999999.99;
        
        if ( location )
            timeOffset = [[location timestamp] timeIntervalSinceNow];
        
        
        if ( [location respondsToSelector: @selector(floor)] ) {
            if (location.floor)
                floor = [NSNumber numberWithInteger:location.floor.level];
        }
        
        [fullParameters setObject: @{
                                     @"lat" : @(coord.latitude),
                                     @"long" : @(coord.longitude),
                                     @"time" : @(coordAgeMS),
                                     @"altitude" : @(location.altitude),
                                     @"speed" : @(location.speed),
                                     @"floor" : floor,
                                     @"accuracy" : @(location.horizontalAccuracy),
                                     @"age" : @(timeOffset)
                                     }
                           forKey:@"location"];
    }
    
    
    
    
    if ( self.build )
        fullParameters[@"sdk_build"] = self.build;
    
    CLPlacemark *addressPlacemark = [[RVLLocation sharedManager] userPlacemark];
    if (addressPlacemark)
    {
        fullParameters[@"address"] = @{
                       @"street" : addressPlacemark.addressDictionary[@"Street"] ?: @"",
                       @"city" : addressPlacemark.locality ?: @"",
                       @"state" : addressPlacemark.administrativeArea ?: @"",
                       @"zip" : addressPlacemark.postalCode ?: @"",
                       @"country" : addressPlacemark.country ?: @"",
                       };
    }
    else
    {
        LOG( @"ERROR", @"Attempt to send to endpoint with no address! Params:\n%@", fullParameters );
    }

    if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled])
    {
        //[DO] idfa is not guaranteed to return a valid string when device firsts starts up
        NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        LOG(@"DEBUG", @"IDFA Available and is %@", idfa);
        if (idfa != nil && ![idfa isEqualToString:@""])
        {
            fullParameters[@"idfa"] = idfa;
        }
    }

    return fullParameters;
}

- (NSString *)version
{
    return SDK_REVISION;
}

- (void)registerDeviceWithResult:(void (^)(BOOL success, NSDictionary *result, NSError *error))result
{
    NSDictionary *params = @{
        @"version" : [[UIDevice currentDevice] systemVersion] ?: @"",
        @"locale" : [[NSLocale currentLocale] localeIdentifier] ?: @"",
        //@"bluetooth_version" : @"4",     // not available on iOS
        @"bluetooth_enabled" : @([[RVLBeaconManager sharedManager] hasBluetooth]),
        @"supports_ble" : @([[RVLBeaconManager sharedManager] hasBluetooth]), // TODO: Is this right?
    };
    NSMutableDictionary *fullParams = [self getDefaultParameters];
    [fullParams addEntriesFromDictionary:params];
    [[RVLWebServices sharedWebServices] sendRequestToEndpoint:@"info" withParams:fullParams forResult:result];
}

- (void)sendNotificationOfBeacon:(RVLBeacon *)beacon
                          result:(void (^)(BOOL success, NSDictionary *result, NSError *error))complete
{

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:8];

    NSString* identifier = [[beacon rawBeacon] identifier];
    if ([[beacon proximityUUID] UUIDString])
        params[@"beacon_uuid"] = [[beacon proximityUUID] UUIDString];
    else if ( [identifier length])
        params[@"beacon_uuid"] = identifier;
    else
    {
        LOG(@"ERROR", @"No UUID in beacon when sent: %@", beacon);
    }

    if (beacon.rawBeacon)
    {
        params[@"beacon_rssi"] = @(beacon.rawBeacon.rssi);
        
        if ( beacon.rawBeacon.vendorCode )
            params[@"beacon_vendor"] = @(beacon.rawBeacon.vendorCode);
        
        NSString* venKey = nil;
        
        if ( [beacon.rawBeacon.vendorId length] )
        {
            NSScanner* scanner = [NSScanner scannerWithString: beacon.rawBeacon.vendorId];
            
            unsigned long long value;
            [scanner scanHexLongLong: &value];
            
            if ( value )
            {
                venKey = [NSString stringWithFormat: @"%llx", value];
                params[@"beacon_vendor_key"] = @(value);
            }
        }
        else
        {
            if ( beacon.rawBeacon.key )
            {
                params[@"beacon_vendor_key"] = @(beacon.rawBeacon.key);
                venKey = [NSString stringWithFormat: @"%lx", (long) beacon.rawBeacon.key];
            }
            else
                venKey = beacon.rawBeacon.identifier;
            
            
        }

//        if (beacon.rawBeacon.vendorName)
//            params[@"beacon_vendor_name"] = beacon.rawBeacon.vendorName;

        if (beacon.rawBeacon.payload )
            params[@"beacon_payload"] = beacon.rawBeacon.payloadString;

        if (beacon.rawBeacon.url)
            params[@"beacon_url"] = [NSString stringWithFormat:@"%@", beacon.rawBeacon.url];

        if ( [venKey length] )
            params[@"beacon_uuid"] = venKey;
        else if ([beacon.rawBeacon.uuids count] > 0)
            params[@"beacon_uuid"] = [NSString stringWithFormat:@"%@", beacon.rawBeacon.uuids.firstObject];
    }

    if (beacon.accuracy)
        params[@"beacon_accuracy"] = beacon.accuracy;

    params[@"beacon_rssi"] = beacon.rssi;

    if (beacon.proximity)
        params[@"beacon_proximity"] = beacon.proximity;

    if (beacon.type)
        params[@"beacon_type"] = beacon.type;

//    if (bundleId)
//        params[@"bundle_id"] = bundleId;

    if (beacon.decoded)
    {
        if ( [beacon.major length] )
            params[@"beacon_major"] = beacon.major;

        if ( [beacon.minor length] )
            params[@"beacon_minor"] = beacon.minor;
    }
    
    NSMutableDictionary *fullParams = [self getDefaultParameters];
    [fullParams addEntriesFromDictionary:params];
    
    // use for debugging code remove later if not needed
    //__block RVLBeacon* blockBeacon = beacon;

    [self sendRequestToEndpoint: @"event/rawbeacon"
                     withParams: fullParams
                      forResult: ^(BOOL success, NSDictionary *result, NSError *error)
                {
                    //blockBeacon.sentTime = [NSDate date];
                    
                    if ( complete )
                        complete( success, result, error );
                }];
}

- (void)sendRequestToEndpoint:(NSString *)endpoint
                   withParams:(NSDictionary *)params
                    forResult:(void (^)(BOOL success, NSDictionary *result, NSError *error))result
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // These gyrations avoid a double slash (http://foo.com//api/info)
      // which gives godzilla the fits.
      NSURL *apiUrl = [NSURL URLWithString:self.apiUrl];
      NSString *methodPath = [NSString stringWithFormat:@"/api/v3/%@", endpoint];
      NSURL *reqUrl = [NSURL URLWithString:methodPath relativeToURL:apiUrl];

      NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:reqUrl];
      [urlRequest setValue:self.apiKey forHTTPHeaderField:@"X-API-KEY"];
      [urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];

      [urlRequest setHTTPMethod:@"POST"];
      NSError *error = nil;
      NSData *body = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];

      if (body)
      {
          [urlRequest setHTTPBody:body];

          // TODO: [JL] This is mostly for debugging and can go when this settles down.
          NSString *requestString = [[NSString alloc] initWithData:urlRequest.HTTPBody encoding:NSUTF8StringEncoding];
          LOG(@"COMM", @"Request post to URL: %@ with data: %@", reqUrl.absoluteURL, requestString);

          NSURLSession *session = [NSURLSession sharedSession];
          NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest
                                                  completionHandler:^(NSData *data,
                                                                      NSURLResponse *response,
                                                                      NSError *error)
                        {
                            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                            if ( statusCode >= 300 )
                            {
                                LOG( @"WARNING", @"HTTP Error: %ld %@\nReq:\n%@\nResponse:\n%@", statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], requestString, response );
                            }
                            else
                            {
                                LOG(@"COMM", @"Response from server is %ld: %@", statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                            }
                            
                            //if error or no data, return error to result
                            if ([data length] == 0 || error)
                            {
                                result(NO, @{ @"errors" : @"Error requesting Reveal API" }, error);
                                return;
                            }

                            //build JSON for result
                            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                     options:NSJSONReadingMutableContainers
                                                                                       error:&error];

                            //if json error, return error to result
                            if (error)
                            {
                                result(NO, @{ @"errors" : @"Error parsing response from Reveal API" }, error);
                                return;
                            }

                            //check json result for error array
                            NSArray *errorsArray = objc_dynamic_cast(NSArray, [jsonDict objectForKey:@"errors"]);
                            if (errorsArray && [errorsArray count] > 0)
                            {
                                //if errors returned from server, return error to result
                                result(NO, jsonDict, error);
                                return;
                            }

                            //if no errors, return success to result
                            dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    result(YES, jsonDict, error);
                                });
                        }];
          
          [task resume];
      }
      else
      {
          LOG(@"ERROR", @"Could not encode Error: %@ body:\n%@", error, params);

          if (result)
          {
                dispatch_async(dispatch_get_main_queue(), ^
                    {
                        result(NO, nil, error);
                    });
          }
      }
    });
}

- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ? @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] : @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ];

    NSDictionary *addresses = [self getIPAddresses];
    VERBOSE(@"INFO", @"addresses: %@", addresses);

    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
      address = addresses[key];
      if (address)
          *stop = YES;
    }];
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if (!getifaddrs(&interfaces))
    {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for (interface = interfaces; interface; interface = interface->ifa_next)
        {
            if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */)
            {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in *)interface->ifa_addr;
            char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];
            if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6))
            {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if (addr->sin_family == AF_INET)
                {
                    if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN))
                    {
                        type = IP_ADDR_IPv4;
                    }
                }
                else
                {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *)interface->ifa_addr;
                    if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN))
                    {
                        type = IP_ADDR_IPv6;
                    }
                }
                if (type)
                {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

// code from: http://stackoverflow.com/questions/7938650/ios-detect-3g-or-wifi
//
// for most things you want to use Reachability, but we are using this simple synchronous call
//
- (ConnectionType)connectionType
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    if (!success)
    {
        return ConnectionTypeUnknown;
    }
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);

    if (!isNetworkReachable)
    {
        return ConnectionTypeNone;
    }
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0)
    {
        return ConnectionType3G;
    }
    else
    {
        return ConnectionTypeWiFi;
    }
}

@end

#pragma mark -
#pragma mark - Beacon Definitions
// NOTE: These objects would normally be in a seperate file but are placed here so that
//       individual files may be included with out using a framework

#pragma mark - RVLBeacon -
@implementation RVLBeacon

- (instancetype)initWithUUID:(NSUUID *)uuid
                       major:(NSString *)major
                       minor:(NSString *)minor
                   proximity:(NSInteger)proximity
                    accuracy:(NSNumber *)accuracy
                        rssi:(NSNumber *)rssi
{
    self = [super init];
    if (self)
    {
        _proximityUUID = uuid;

        _major = @""; // FIXME -- currently logging beacon regions with no major/minor specified.
        _minor = @"";

        if (major)
        {
            _major = major;
        }
        if (minor)
        {
            _minor = minor;
        }

        _proximity = @[ @"unknown", @"immediate", @"near", @"far" ][proximity];
        _accuracy = accuracy;
        _rssi = rssi;
    }

    return self;
}

- (instancetype)initWithBeacon:(CLBeacon *)beacon
{
    return [self initWithUUID:beacon.proximityUUID
                        major:[NSString stringWithFormat:@"%@", beacon.major]
                        minor:[NSString stringWithFormat:@"%@", beacon.minor]
                    proximity:beacon.proximity
                     accuracy:@(beacon.accuracy)
                         rssi:@(beacon.rssi)];
}

- (instancetype)initWithBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    return [self initWithUUID:beaconRegion.proximityUUID
                        major:[NSString stringWithFormat:@"%@", beaconRegion.major]
                        minor:[NSString stringWithFormat:@"%@", beaconRegion.minor]
                    proximity:0
                     accuracy:@(0)
                         rssi:@(0)];
}

- (instancetype)initWithRawBeacon:(RevealScannerRawBeacon *)beacon
{
    self = [super init];
    if (self)
    {
        _major = @""; // FIXME -- currently logging beacon regions with no major/minor specified.
        _minor = @"";
        _rawBeacon = beacon;
    }

    return self;
}

- (NSString *)rvlUniqString
{
    if (self.rawBeacon)
        return self.rawBeacon.identifier;
    else
        return [NSString stringWithFormat:@"%@-%@-%@", self.major, self.minor, [self.proximityUUID UUIDString]];
}

+ (NSString *)rvlUniqStringWithBeacon:(CLBeacon *)beacon
{
    return [NSString stringWithFormat:@"%@-%@-%@", beacon.major, beacon.minor, [beacon.proximityUUID UUIDString]];
}

- (NSString *)type
{
    NSString *result = nil;

    if (self.rawBeacon)
    {
        result = self.rawBeacon.vendorName;
        if ([result length] == 0)
            result = [NSString stringWithFormat:@"Type-%ld", (long) self.rawBeacon.vendorCode];
    }
    else
    {
        // apple does not tell us wht type it is so return the generic
        result = @"iBeacon";
    }

    return result;
}

- (BOOL)decoded
{
    return ([[self minor] length] + [[self major] length]) > 0;
}

- (NSString *)description
{
    NSDate *time = self.sentTime;
    NSString* payloadString = @"";
    
    if ( [[[self rawBeacon] payload] isKindOfClass: [NSData class]] )
    {
        payloadString = [NSString stringWithFormat: @" Payload %@", [[self rawBeacon] payload]];
    }

    if (!time)
        time = self.discoveryTime;

    if (time)
        return [NSString stringWithFormat:@"%@ %@ %@%@", self.type,
                self.rvlUniqString, time, payloadString];
    else
        return [NSString stringWithFormat:@"%@ %@%@", self.type, [self.proximityUUID UUIDString],
                payloadString];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.proximityUUID forKey:@"proximityUUID"];
    [coder encodeObject:self.major forKey:@"major"];
    [coder encodeObject:self.minor forKey:@"minor"];
    [coder encodeObject:self.proximity forKey:@"proximity"];
    [coder encodeObject:self.accuracy forKey:@"accuracy"];
    [coder encodeObject:self.rssi forKey:@"rssi"];
    [coder encodeObject:self.discoveryTime forKey:@"discoveryTime"];
    [coder encodeObject:self.sentTime forKey:@"sentTime"];
    [coder encodeObject:self.rawBeacon forKey:@"rawBeacon"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [self init];

    if (self)
    {
        self.proximityUUID = [decoder decodeObjectForKey:@"proximityUUID"];
        self.major = [decoder decodeObjectForKey:@"major"];
        self.minor = [decoder decodeObjectForKey:@"minor"];
        self.proximity = [decoder decodeObjectForKey:@"proximity"];
        self.accuracy = [decoder decodeObjectForKey:@"accuracy"];
        self.rssi = [decoder decodeObjectForKey:@"rssi"];
        self.discoveryTime = [decoder decodeObjectForKey:@"discoveryTime"];
        self.sentTime = [decoder decodeObjectForKey:@"sentTime"];
        self.rawBeacon = [decoder decodeObjectForKey:@"rawBeacon"];
    }

    return self;
}

@end

#pragma mark - Bluetooth object -

@interface RevealBluetoothObject () <CBPeripheralDelegate>
@end

@implementation RevealBluetoothObject

- (BOOL)connectable
{
    BOOL result = NO;

    NSNumber *num = [self.advertisement objectForKey:@"kCBAdvDataIsConnectable"];
    if ([num isKindOfClass:[NSNumber class]])
        result = YES;

    return result;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.services = [NSMutableDictionary dictionary];
        self.characteristics = [NSMutableDictionary dictionary];
    }

    return self;
}

- (NSString *)name
{
    return [[self peripheral] name];
}

- (void)loadCharacteristics:(CBService *)service
{
    [self.peripheral setDelegate:self];

    [self.peripheral discoverCharacteristics:nil forService:service];
}

- (void)peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    NSMutableDictionary *svc = self.characteristics[characteristic.service.UUID.UUIDString];

    if (svc == nil)
        svc = [NSMutableDictionary dictionary];

    svc[characteristic.UUID.UUIDString] = characteristic;
    self.characteristics[characteristic.service.UUID.UUIDString] = svc;

    //LOG( @"DEBUG", @"CHAR:   %@/%@: %@ = %@", peripheral.identifier.UUIDString, characteristic.service.UUID.UUIDString, characteristic.UUID.UUIDString, characteristic.value );
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    for (CBService *svc in peripheral.services)
    {
        if (svc.characteristics)
            [self peripheral:peripheral didDiscoverCharacteristicsForService:svc error:nil]; //already discovered characteristic before, DO NOT do it again
        else
        {
            [peripheral discoverCharacteristics:nil
                                     forService:svc]; //need to discover characteristics

            // NOTE: discover included services disabled because it does not provide useful
            //       information from our perspective since we are already polling the
            //       primary services
            //[peripheral discoverIncludedServices: nil forService: svc];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error
{
    //LOG( @"DEBUG", @"Discovered included services for %@: %@", peripheral.identifier.UUIDString, service.UUID );

    NSMutableDictionary *svc = self.characteristics[service.UUID.UUIDString];

    if (svc == nil)
        svc = [NSMutableDictionary dictionary];

    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSString *key = [NSString stringWithFormat:@"INC:%@", characteristic.UUID.UUIDString];
        svc[key] = characteristic;
    }

    self.characteristics[service.UUID.UUIDString] = svc;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    //NSMutableString* chars = [NSMutableString string];

    for (CBCharacteristic *c in service.characteristics)
    {
        //[chars appendFormat: @"\n    %@ (%lX)=%@", c.UUID.UUIDString, (long) c.properties, c.value];
        [peripheral readValueForCharacteristic:c];
    }

    //LOG( @"DEBUG", @"Discovered characteristic for %@: %@: %@", peripheral.identifier.UUIDString, service.UUID.UUIDString, chars );
}

+ (NSString *)serviceName:(NSString *)serviceName
{
    NSString *result = serviceName;

    if ([serviceName isEqualToString:@"kCBAdvDataIsConnectable"])
        result = @"C";
    else if ([serviceName isEqualToString:@"kCBAdvDataLocalName"])
        result = @"N";
    else if ([serviceName isEqualToString:@"kCBAdvDataServiceData"])
        result = @"D";
    else if ([serviceName isEqualToString:@"kCBAdvDataManufacturerData"])
        result = @"AM";
    else if ([serviceName isEqualToString:@"kCBAdvDataServiceUUIDs"])
        result = @"SU";

    return result;
}

+ (NSString *)data:(id)data
{
    NSString *result = nil;

    if ([data isKindOfClass:[NSDictionary class]])
    {
        NSMutableString *str = [NSMutableString string];

        for (NSString *key in data)
        {
            if ([str length])
                [str appendString:@","];
            [str appendFormat:@"%@=%@", key, data[key]];
        }

        result = str;
    }
    else if ([data isKindOfClass:[NSArray class]])
    {
        NSMutableString *str = [NSMutableString string];

        for (NSString *key in data)
        {
            if ([str length])
                [str appendString:@","];
            [str appendFormat:@"%@", key];
        }

        result = str;
    }
    else
    {
        result = [NSString stringWithFormat:@"%@", data];
    }

    return result;
}

@end

#pragma mark - RevealScannerRawBeacon -

@implementation RevealScannerRawBeacon

- (NSString *)identifier
{
    NSMutableString *result = [NSMutableString new];

    NSString* ns = self.extendedData[@"namespace"];
    
    if ( ns  )
        [result appendFormat: @"%@", ns];
    else if ( self.vendorId )
    {
        [result appendString: self.vendorId];
    }
    else if (self.vendorCode && self.key )
    {
        [result appendFormat:@"%04X-%X", (int)self.vendorCode, (int)self.key];
        
        if ( self.local )
            [result appendFormat:@"%X", (int)self.local];
    }
    else
    {
        if (self.bluetoothIdentifier)
            [result appendFormat:@"%@", [self.bluetoothIdentifier UUIDString]];
    }

    return result;
}

- (NSString *)ident:(NSInteger)index
{
    NSString *result = nil;

    if (index == 0)
        result = [self identifier];
    else
    {
        switch ([self vendorCode])
        {
            case BEACON_SERVICE_EDDYSTONE:
                switch (index)
                {
                    case 1:
                        result = self.extendedData[@"namespace"];
                        break;

                    case 2:
                        result = self.extendedData[@"instance"];

                    default:
                        break;
                }
                break;

            default:
                switch (index)
                {
                    case 1:
                        if ( self.key )
                            result = [NSString stringWithFormat:@"%ld", (long)self.key];
                        else
                            result = nil;
                        break;

                    case 2:
                        if ( self.local )
                            result = [NSString stringWithFormat:@"%ld", (long)self.local];
                        else
                            result = @"";

                    default:
                        break;
                }
                break;
        }
    }

    return result;
}

- (NSString *)payloadString
{
    NSString *result = nil;

    if (self.payload)
        result = [self.payload base64EncodedStringWithOptions:0];

    return result;
}

- (NSString *)description
{
    if (self.vendorCode == BEACON_SERVICE_EDDYSTONE)
    {
        if (self.url)
            return [NSString stringWithFormat:@"%@ %@ %@", self.url, self.vendorName, self.identifier];
        else
            return [NSString stringWithFormat:@"%ld: %@ %@", (long)self.vendorCode, self.vendorName, self.identifier];
    }
    else
        return [NSString stringWithFormat:@"%ld: %@ %@ %@", (long)self.vendorCode, self.vendorName, self.identifier, self.payload];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.vendorName forKey:@"vendorName"];
    [coder encodeInteger:self.vendorCode forKey:@"vendorCode"];
    [coder encodeInteger:self.key forKey:@"key"];
    [coder encodeInteger:self.local forKey:@"local"];
    [coder encodeObject:self.payload forKey:@"payload"];
    [coder encodeInteger:self.rssi forKey:@"rssi"];
    [coder encodeObject:self.bluetoothIdentifier forKey:@"bluetoothIdentifier"];
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeBool:self.complete forKey:@"complete"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [self init];

    if (self)
    {
        self.vendorName = [decoder decodeObjectForKey:@"vendorName"];
        self.vendorCode = [decoder decodeIntegerForKey:@"vendorCode"];
        self.key = [decoder decodeIntegerForKey:@"key"];
        self.local = [decoder decodeIntegerForKey:@"local"];
        self.payload = [decoder decodeObjectForKey:@"payload"];
        self.rssi = [decoder decodeIntegerForKey:@"rssi"];
        self.bluetoothIdentifier = [decoder decodeObjectForKey:@"bluetoothIdentifier"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.complete = [decoder decodeBoolForKey:@"complete"];
    }

    return self;
}

@end
