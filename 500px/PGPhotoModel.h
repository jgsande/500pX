//
//  FRPPhotoModel.h
//  FunctionalReactivePixels
//
//  Created by Polo Garcia on 25/09/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGPhotoModel : NSObject

@property (nonatomic, strong) NSString *photoName;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *photographerName;
@property (nonatomic, strong) NSNumber *rating;

@property (nonatomic, strong) NSString *thumbnailURL;

@property (nonatomic, strong) NSString *fullsizedURL;

@end
