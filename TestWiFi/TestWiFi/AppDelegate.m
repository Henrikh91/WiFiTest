//
//  AppDelegate.m
//  TestWiFi
//
//  Created by Genrih Korenujenko on 13.11.17.
//  Copyright © 2017 Koreniuzhenko Henrikh. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreWLAN/CoreWLAN.h>
#import <sys/socket.h>
#import <sys/user.h>
#import <arpa/inet.h>
#import <net/route.h>
#import <netinet/if_ether.h>

#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "NICInfoSummary.h"

#import "MACConvertorIP.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

-(void)printInfoSummary
{
    /// get connecting Wi-Fi SSID
    /*
     NSString *wifiName = nil;
     NSArray *interFaceNames = (__bridge_transfer id)CNCopySupportedInterfaces();
     
     for (NSString *name in interFaceNames) {
     NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)name);
     
     if (info[@"SSID"]) {
     wifiName = info[@"SSID"];
     }
     }
     */
    
    NICInfoSummary *summary = [[NICInfoSummary alloc] init];
    
    for (NICInfo *info in summary.nicInfos)
    {
        printf("\n");
        printf("interfaceName: %@", info.interfaceName);
        printf("\n");
        printf("macAddress: %@", info.macAddress);
        printf("\n");
        
        for (NICIPInfo *ipInfo in info.nicIPInfos)
        {
            printf("ip: %s", ipInfo.ip.UTF8String);
            printf("\n");
            printf("netmask: %s", ipInfo.netmask.UTF8String);
            printf("\n");
            printf("broadcastIP: %s", ipInfo.broadcastIP.UTF8String);
            printf("\n");
        }
        
        //        printf("\n");
        //        printf("- - - - - - - - - - - - - - - ");
        //        printf("\n");
        
        for (NICIPInfo *ipInfo in info.nicIPv6Infos)
        {
            printf("ip: %s", ipInfo.ip.UTF8String);
            printf("\n");
            printf("netmask: %s", ipInfo.netmask.UTF8String);
            printf("\n");
            printf("broadcastIP: %s", ipInfo.broadcastIP.UTF8String);
            printf("\n");
        }
        
        printf("\n\n\n- - - - - - - - - - - - - - - ");
    }
    
    //     en0 is for WiFi
    NICInfo* wifi_info = [summary findNICInfo:@"en0"];
    
    // you can get mac address in 'XX-XX-XX-XX-XX-XX' form
    NSString* mac_address = [wifi_info getMacAddressWithSeparator:@"-"];
    
    // ip can be multiple
    if(wifi_info.nicIPInfos.count > 0)
    {
        NICIPInfo* ip_info = [wifi_info.nicIPInfos objectAtIndex:0];
        
        printf("ip: %s", ip_info.ip.UTF8String);
        printf("\n");
        printf("netmask: %s", ip_info.netmask.UTF8String);
        printf("\n");
        printf("broadcastIP: %s", ip_info.broadcastIP.UTF8String);
        printf("\n");
    }
    else
    {
        NSLog(@"WiFi not connected!");
    }
}


-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
//    [self printInfoSummary];
//    MACConvertorIP *convertor = [MACConvertorIP new];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        CWWiFiClient *wifiClient = [CWWiFiClient sharedWiFiClient];
        CWInterface *interface = wifiClient.interface;
        NSArray *networkScan = [interface scanForNetworksWithName:nil error:nil].allObjects;
        NSMutableDictionary *channels = [self prepareStatisticOfChannels:networkScan];
        [self printStatistics:channels];

        for (CWNetwork *network in networkScan)
        {
            
            NSLog(@"SSID: %@", network.ssid);
            NSLog(@"BSSID: %@", network.bssid);
            NSLog(@"Channel: %tu\n\n", network.wlanChannel.channelNumber);

//            NSLog(@"IP: %@", [convertor processing:network.bssid]);

//            [self jan_mac_addr_test:network.bssid.UTF8String];
//            NSLog(@"channelBand: %tu", network.wlanChannel.channelBand);
//            NSLog(@"%@", [network valueForKey:@"_scanRecord"]);
//            printf("\n\n\n_____________________________\n\n\n");
            
        }

///
//        NSString *command = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s"];
//        NSTask *task = [[NSTask alloc] init];
//        [task setLaunchPath:@"/bin/sh"];
//        NSArray *args = [NSArray arrayWithObjects:@"-c", command, nil];
//        [task setArguments: args];
//        NSPipe *pipe = [NSPipe pipe];
//        [task setStandardOutput: pipe];
//        [task launch];
//        [task waitUntilExit];
//        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
//        NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
//        NSLog(@"RESULT: \n%@", string);
///
    });
}

-(NSMutableDictionary*)prepareStatisticOfChannels:(NSArray<CWNetwork*>*)networks
{
    NSArray *channels = [networks valueForKey:@"wlanChannel"];
    NSMutableDictionary *sortedChannels = [NSMutableDictionary new];
    
    for (CWChannel *channel in channels)
    {
        NSMutableArray *arr = [sortedChannels objectForKey:@(channel.channelNumber)];
        if (!arr)
            arr = [NSMutableArray new];
        
        [arr addObject:channel];
        [sortedChannels setObject:arr forKey:@(channel.channelNumber)];
    }
    
    return sortedChannels;
}

-(void)printStatistics:(NSMutableDictionary<NSNumber*,NSMutableArray*>*)allChannels
{
    [allChannels enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSMutableArray *channels, BOOL *stop)
    {
        CGFloat percent = (CGFloat)channels.count / (CGFloat)allChannels.count * 100.0;
        NSInteger twoGHzCount = [self filter:channels byKey:@"channelBand" valuer:@(kCWChannelBand2GHz)].count;
        NSInteger fiveGHzCount = channels.count - twoGHzCount;
        NSString *frequencyBand = nil;
        
        if (twoGHzCount == fiveGHzCount)
            frequencyBand = [NSString stringWithFormat:@"2GHz/5Ghz"];
        else if (twoGHzCount > fiveGHzCount)
            frequencyBand = [NSString stringWithFormat:@"2GHz"];
        else
            frequencyBand = [NSString stringWithFormat:@"5GHz"];
        
//        NSString *frequency = [self filter:channels byKey:@"channelBand" valuer:@(kCWChannelBand2GHz)].count;
        
        NSLog(@"Channel: %@, load: %.0f%% (%tu/%tu), band: %@", key, percent , channels.count, allChannels.count, frequencyBand);
    }];
}

-(NSArray*)filter:(NSArray*)channels byKey:(NSString*)key valuer:(id)value
{
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ %@ %@", key, ([[value class] isSubclassOfClass:[NSNumber class]]) ? @"==" : @"LIKE[cd]", value];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
    NSArray *result = [channels filteredArrayUsingPredicate:predicate];
    return result;
}

-(void)jan_mac_addr_test:(const char*) host
{
#define BUFLEN (sizeof(struct rt_msghdr) + 512)
#define SEQ 9999
#define RTM_VERSION 5   // important, version 2 does not return a mac address!
#define RTM_GET 0x4 // Report Metrics
#define RTF_LLINFO  0x400   // generated by link layer (e.g. ARP)
#define RTF_IFSCOPE 0x1000000 // has valid interface scope
#define RTA_DST 0x1 // destination sockaddr present
    int sockfd;
    unsigned char buf[BUFLEN];
    unsigned char buf2[BUFLEN];
    ssize_t n;
    struct rt_msghdr *rtm;
    struct sockaddr_in *sin;
    memset(buf,0,sizeof(buf));
    memset(buf2,0,sizeof(buf2));
    
    sockfd = socket(AF_ROUTE, SOCK_RAW, 0);
    rtm = (struct rt_msghdr *) buf;
    rtm->rtm_msglen = sizeof(struct rt_msghdr) + sizeof(struct sockaddr_in);
    rtm->rtm_version = RTM_VERSION;
    rtm->rtm_type = RTM_GET;
    rtm->rtm_addrs = RTA_DST;
    rtm->rtm_flags = RTF_LLINFO;
    rtm->rtm_pid = 1234;
    rtm->rtm_seq = SEQ;
    
    
    sin = (struct sockaddr_in *) (rtm + 1);
    sin->sin_len = sizeof(struct sockaddr_in);
    sin->sin_family = AF_INET;
    sin->sin_addr.s_addr = inet_addr(host);
    write(sockfd, rtm, rtm->rtm_msglen);
    
    n = read(sockfd, buf2, BUFLEN);
    if (n != 0) 
    {
        int index =  sizeof(struct rt_msghdr) + sizeof(struct sockaddr_inarp) + 8;
        // savedata("test",buf2,n);
        NSLog(@"IP %s ::     %2.2x:%2.2x:%2.2x:%2.2x:%2.2x:%2.2x",host,buf2[index+0], buf2[index+1], buf2[index+2], buf2[index+3], buf2[index+4], buf2[index+5]);
        
    }
}

- (NSString*)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

@end
