//
//  ReachabilityManager.h
//  500px
//
//  Created by Polo Garcia on 25/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

/**
 https://github.com/tonymillion/Reachability 
 */

#import <Foundation/Foundation.h>
@class Reachability;

@interface PGReachabilityManager : NSObject

#pragma mark Class Methods
-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

@end
