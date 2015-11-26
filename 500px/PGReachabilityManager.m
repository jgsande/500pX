//
//  ReachabilityManager.m
//  500px
//
//  Created by Polo Garcia on 25/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGReachabilityManager.h"
#import "Reachability.h"

@interface PGReachabilityManager ()

@property (strong, nonatomic) Reachability *reachability;

@end

@implementation PGReachabilityManager

-(instancetype)init{
    if (self = [super init]) {
        self.reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
        
        // Start Monitoring
        [self.reachability startNotifier];
    }
    return self;
}

-(BOOL)isReachable {
    return [self.reachability isReachable];
}

-(BOOL)isReachableViaWWAN {
    return [self.reachability isReachableViaWWAN];
}

-(BOOL)isReachableViaWiFi {
    return [self.reachability  isReachableViaWiFi];
}

@end
