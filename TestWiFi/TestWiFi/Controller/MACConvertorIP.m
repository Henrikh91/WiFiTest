//
//  MACConvertorIP.m
//  TestWiFi
//
//  Created by Genrih Korenujenko on 27.11.17.
//  Copyright © 2017 Koreniuzhenko Henrikh. All rights reserved.
//

#import "MACConvertorIP.h"
#include <arpa/inet.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <ifaddrs.h>
#include <sys/socket.h>

@implementation MACConvertorIP

static unsigned char gethex(const char *s, char **endptr)
{
    assert(s);
    while (isspace(*s)) s++;
    assert(*s);
    return strtoul(s, endptr, 16);
}

unsigned char *convert(const char *s, NSInteger *length)
{
    unsigned char *answer = malloc((strlen(s) + 1) / 3);
    unsigned char *p;
    for (p = answer; *s; p++)
        *p = gethex(s, (char **)&s);
    *length = p - answer;
    return answer;
}

#pragma mark - Public Methods
-(NSString*)processing:(NSString*)address
{
    NSMutableArray *addrArray = [address componentsSeparatedByString:@":"].mutableCopy;
    NSArray *bitPosition = @[@(128), @(64), @(32), @(16), @(8), @(4), @(2), @(1)];
    NSArray *binaries = [self hexesToBinaries:addrArray];
    NSMutableArray *decinimals = [NSMutableArray new];
    for (NSString *binary in binaries)
    {
        NSInteger decimal = 0;
        for (NSInteger index = 0; index < binary.length; index++)
        {
            NSString *bin = [binary substringWithRange:NSMakeRange(index, 1)];
            decimal += bin.integerValue * [bitPosition[index] integerValue];
        }
        [decinimals addObject:@(decimal)];
    }
    return [decinimals componentsJoinedByString:@"."];
}

-(NSArray*)hexesToBinaries:(NSArray*)hexes
{
    NSMutableArray *binaries = [NSMutableArray new];
    for (NSString *hex in hexes)
    {
        NSInteger result = [self scanner:hex];
        NSString *binary = [self toBinary:result];
        NSMutableString *addition = [NSMutableString new];
        for (NSInteger index = binary.length;  index < 8; index++)
            [addition appendString:@"0"];
        binary = [addition stringByAppendingString:binary];

        [binaries addObject:binary];
    }
    return binaries;
}

-(NSInteger)scanner:(NSString*)value
{
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:value];
    [scanner setScanLocation:0];
    [scanner scanHexInt:&result];
    return result;
}

-(NSString*)toBinary:(NSUInteger)input
{
    if (input == 1 || input == 0)
        return [NSString stringWithFormat:@"%lu", (unsigned long)input];
    else
        return [NSString stringWithFormat:@"%@%lu", [self toBinary:input / 2], input % 2];
}

@end
