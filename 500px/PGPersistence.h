//
//  Persistence.h
//  YTCoreData
//
//  Created by Polo Garcia on 16/10/15.
//  Copyright © 2015 PoloGarcia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@import CoreData;

@class PGPhotoModel;

@interface PGPersistence : NSObject

/*
 @return: 
     an NSArray of PGPhotoModel objects with the info stored for the specified category
     or
     nil if the category is not persisted
 @warning SYNCHRONOUS method
 */
-(NSArray*)loadObjectsForCategory:(NSString*)categoryName;

/*
 This method asynchronously stores an array of PGPhotoModel object in the persistent store
 and associates them to the specified category.
 */
-(void)saveObjects:(NSArray*)photoModelArray forCategory:(NSString*)categoryName;

/*
 @return:
    The NSData* representation for the thumbnail stored for the specified PGPhotoModel object
    or
    nil if that particular PGPhotoModel object is not found in the persisten store
 @warning SYNCHRONOUS method
 */
-(NSData*)loadThumbnailForPhotoModel:(PGPhotoModel*)photoModel;

/*
 This method asynchronously stores the thumbnail associated to the passed PGPhotoModel object.
 */
-(void)saveThumbnail:(NSData*)thumbnailData forPhotoModel:(PGPhotoModel*)photoModel;

@end
