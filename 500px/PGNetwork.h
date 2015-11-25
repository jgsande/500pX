//
//  PGANetworker.h
//  500px
//
//  Created by Polo Garcia on 10/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGNetwork : NSObject

-(void)fetchContentsOfURL:(NSURL *)url
                completion:(void (^)(NSData *data, NSError *error)) completionHandler;

-(void)downloadFileAtURL:(NSURL *)url
               toLocation:(NSURL *)destinationURL
               completion:(void (^)(NSError *error)) completionHandler;

/*
 @return an NSArray of NSURLRequest objects necessary to download the specified category
 */
-(NSArray*)requestsForCategory:(NSString*)categoryName;

/**
*/
-(void)setNewUserLocation:(NSString*)newLocation;

@end